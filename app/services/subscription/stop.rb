# -*- encoding : UTF-8 -*-
# Disable user services when a subscription is stoped
class Subscription::Stop
  def initialize(user, close_now = false)
    @user = user
    @close_now = close_now == 'on' ? true : false
  end

  def execute
    return false if @user.inactive_at.present?

    # period = @user.subscription.find_period(Date.today)

    # Disable period and disable user
    # if period
    #   if @close_now
    #     is_billed = period.billings.map(&:amount_in_cents_wo_vat).select { |e| e > 0 }.present?

    #     unless is_billed
    #       @user.inactive_at = period.start_date.to_time
    #       period.destroy
    #     end
    #   else
    #     @user.inactive_at = period.start_date.to_time + period.duration.month
    #   end
    # else
    #   @user.inactive_at = Time.now
    # end

    if @close_now
      @user.inactive_at = Time.now
      @user.billings.of_period(CustomUtils.period_of(Time.now)).destroy_all
    else
      @user.inactive_at = 1.month.after.beginning_of_month
    end

    return false unless @user.inactive_at

    my_package = @user.my_package
    my_package.update(is_active: false)

    next_period  = CustomUtils.period_of(1.month.after)
    next_package = @user.package_of( next_period )
    next_package.destroy if next_package

    # Revoke authorization
    @user.email_code             = nil
    @user.is_dematbox_authorized = false
    @user.account_number_rules   = []
    @user.save

    # Revoke authorizations stored in options
    # @user.options.is_retriever_authorized     = false
    # @user.options.max_number_of_journals      = 0
    # @user.options.is_preassignment_authorized = false
    # @user.options.is_upload_authorized        = false
    # @user.options.save
    # @user.account_number_rules = []

    # Disable external services
    Retriever::Remove.delay(queue: :high).execute(@user.id.to_s)

    new_provider_requests = @user.new_provider_requests.not_processed
    if new_provider_requests.any?
      new_provider_requests.each(&:reject)
      new_provider_requests.update_all(notified_at: Time.now)
    end

    @user.dematbox.try(:unsubscribe)

    @user.external_file_storage.try(:destroy)

    FileImport::Dropbox.changed(@user.reload)


    # Remove composition
    if @user.composition.present? && File.exist?("#{Rails.root}/files/compositions/#{@user.composition.id}")
      system("rm -r #{Rails.root}/files/compositions/#{@user.composition.id}")
    end
    @user.composition.try(:destroy)

    true
  end
end
