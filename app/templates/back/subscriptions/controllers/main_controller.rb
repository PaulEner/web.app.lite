# frozen_string_literal: true
class Admin::Subscriptions::MainController < BackController
  prepend_view_path('app/templates/back/subscriptions/views')

  # GET /admin/subscriptions
  def index
    @param_period = params[:p].presence || CustomUtils.period_of(Time.now)

    if params[:export].present?
      filename = "forfaits_options_#{@param_period}.csv"
      send_data Subscription::Export.new(@param_period).execute, type: 'application/vnd.ms-excel', filename: filename
    else
      @organization_ids = concerned_organization_ids
      get_recapitulation
    end
  end

  def row_organization
    @organization = Organization.find params[:organization_id]
    @period       = params[:period]
    @date         = CustomUtils.period_to_date(@period)

    parse_organization_data

    render partial: 'row_organization'
  end

  def accounts
    packages = get_recapitulation(params[:type])

    accounts = User.where(id: packages.pluck(:user_id)).select(:id, :code)

    render partial: 'accounts', layout: false, locals: { data_accounts: accounts }
  end

  private

  def concerned_organization_ids
    Organization.billed.order(code: :asc).pluck(:id)
  end

  def packages_list
    # IMPORTANT : don't user ido_micro_plus (merge it with ido_micro)
    ['ido_premium', 'ido_classic', 'ido_micro', 'ido_nano', 'ido_x', 'ido_retriever', 'ido_digitize']
  end

  def options_list
    ['mail_active', 'bank_active', 'preassignment_active', 'scan_active']
  end

  def get_recapitulation(type = nil)
    @counts   = {}
    period    = CustomUtils.period_of(Time.now)
    org_ids   = params[:org_id].presence || concerned_organization_ids
    type      = type
    result    = nil

    user_ids     = User.where(is_prescriber: false, organization_id: org_ids).active_at(Time.now.end_of_month).pluck(:id)
    packages     = BillingMod::Package.where(period: period, user_id: user_ids)

    packages_list.each do |package|
      next if type && package != type

      if package == 'ido_micro'
        _pkg = packages.where(name: ['ido_micro', 'ido_micro_plus'])
      else
        _pkg = packages.where(name: package)
      end

      if type
        result = _pkg
      else
        @counts[package.to_sym] = _pkg.count
      end
    end
    
    options_list.each do |option|
      next if type && option != type

      _pkg = packages.where("#{option} = true")

      if type
        result = _pkg
      else
        @counts[option.to_sym] = _pkg.count if not type
      end
    end

    result
  end

  def parse_organization_data
    @counts       = {}

    @accounts_ids = @organization.customers.active_at(@date.end_of_month).pluck(:id)
    @packages     = BillingMod::Package.where(user_id: @accounts_ids, period: @period)

    packages_list.each do |package|
      if package == 'ido_micro'
        @counts[:ido_micro] = @packages.where(name: ['ido_micro', 'ido_micro_plus']).count
      else
        @counts[package.to_sym] = @packages.where(name: package).count
      end
    end

    options_list.each do |option|
      @counts[option.to_sym] = @packages.where("#{option} = true").count
    end
  end
end