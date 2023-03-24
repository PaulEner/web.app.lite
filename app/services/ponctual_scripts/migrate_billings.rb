class PonctualScripts::MigrateBillings < PonctualScripts::PonctualScript
  def self.execute    
    new().run
  end

  def self.rollback
    new().rollback
  end

  private 

  def execute
    Period.where('DATE_FORMAT(created_at, "%Y%m") >= 202201 AND DATE_FORMAT(created_at, "%Y%m") < 202205 AND duration = 1').where(user_id: user_ids).each do |period|
      # create_packages_from(period)
      create_billings_from(period)
    end
  end

  def backup
  end

  def create_packages_from(period)
    user = period.user
    return false if not user
    return false if user.organization.nil? || user.organization.code == 'TEEO'

    __period = CustomUtils.period_of(period.start_date.to_date)

    package = user.package_of(__period)
    logger_infos("Existing Package ==========>: #{__period} / #{user.code} / #{package.try(:name)}")
    return false if package

    package         = BillingMod::Package.new
    package.period  = __period
    package.user    = user

    name = 'ido_classic'
    if period.is_package?(:ido_classique)
      name = 'ido_classic'
    elsif period.is_package?(:ido_nano)
      name = 'ido_nano'
    elsif period.is_package?(:ido_micro)
      name = 'ido_micro'
    elsif period.is_package?(:ido_plus_micro)
      name = 'ido_micro_plus'
    elsif period.is_package?(:ido_x)
      name = 'ido_x'
    elsif period.is_package?(:ido_mini)
      name = 'ido_mini'
    elsif period.get_active_packages.empty?
      if period.get_active_options.include?(:retriever_option)
        name = 'ido_retriever'
      elsif period.get_active_options.include?(:digitize_option)
        name = 'ido_digitize'
      end
    end

    logger_infos("Creating Package: #{__period} / #{user.code} / #{name}")

    package_infos   = BillingMod::Configuration::LISTS[name.to_sym]
    package.name    = name
    package.preassignment_active = period.is_active?(:pre_assignment_option) || package_infos[:options][:preassignment] == 'strict'
    package.mail_active          = period.is_active?(:mail_option) || package_infos[:options][:mail] == 'strict'
    package.bank_active          = period.is_active?(:retriever_option) || package_infos[:options][:bank] == 'strict'
    package.upload_active        = period.is_active?(:ido_classique) || period.is_active?(:ido_micro) || period.is_active?(:ido_plus_micro) || period.is_active?(:ido_mini) || period.is_active?(:ido_nano)
    package.scan_active          = period.is_active?(:digitize_option) || (!CustomUtils.is_manual_paper_set_order?(user.organization) && package_infos[:options][:scan] == 'strict')
    package.journal_size         = period.subscription.try(:number_of_journals) || 5


    if package_infos[:commitment].to_i > 0
      subscription = period.subscription

      if subscription.start_date && subscription.end_date && period.is_active?(subscription.current_package?)
        package.commitment_start_period = CustomUtils.period_of(subscription.start_date.to_date)
        package.commitment_end_period   = CustomUtils.period_of(subscription.end_date.to_date)
      else
        package.commitment_start_period = __period
        package.commitment_end_period   = __period
      end
    end

    logger_infos("Error Package: #{package.errors.messages.to_s}") if not package.save
  end

  def create_billings_from(period)
    __period = CustomUtils.period_of(period.start_date.to_date)
    owner = period.user.presence || period.organization

    return false if !owner || owner.try(:code) == 'TEEO' || owner.try(:organization).try(:code) == 'TEEO'

    # owner.billings.of_period(__period).destroy_all

    return true if owner.billings.of_period(__period).size > 0

    logger_infos("Creating Billing: #{__period} / #{owner.code}")

    period.product_option_orders.each do |order|
      billing        = BillingMod::Billing.new
      billing.period = __period
      billing.owner  = owner

      corr_name      = correspondence_name(order.name)
      billing.name   = corr_name
      billing.title  = order.title
      billing.kind   = correspondence_kind(corr_name)
      billing.associated_hash = nil
      billing.price  = order.price_in_cents_wo_vat

      billing.is_frozen = false

      logger_infos("Error Billing: #{billing.errors.messages.to_s}") if not billing.save
    end

    if period.excesses_price_in_cents_wo_vat.to_f > 0
      billing        = BillingMod::Billing.new
      billing.period = __period
      billing.owner  = owner

      billing.name   = 'excess_billing'
      billing.title  = 'Pré-affectation en excès'
      billing.kind   = 'excess'
      billing.associated_hash = { excess: 0, price: 0 }
      billing.price  = period.excesses_price_in_cents_wo_vat.to_f

      billing.is_frozen = false

      logger_infos("Error Billing: #{billing.errors.messages.to_s}") if not billing.save
    end
  end

  def correspondence_name(name)
    tabs =  {
              'basic_package_subscription' => 'ido_classic',
              'retriever_package_subscription' => 'bank_option',
              'mail_package_subscription' => 'mail_option',
              'mini_package_subscription' => 'ido_mini',
              'micro_package_subscription' => 'ido_micro',
              'plus_micro_package_subscription' => 'ido_micro_plus',
              'idox_package_subscription' => 'ido_x',
              'digitize_package_subscription' => 'digitize_option',
              'nano_package_subscription' => 'ido_nano',
              'pre_assignment_option' => 'preassignment_option',
              'excess_journals' => 'journal_excess',
              'extra_option' => 'extra_order',
              'excess_bank_accounts' => 'bank_excess',
              'billing_previous_operations' => 'operations_billing',
            }

    tabs[name.to_s].presence || name.to_s.presence || 'extra_order'
  end

  def correspondence_kind(name)
    tabs =  {
              'bank_excess' => 'excess',
              'journal_excess' => 'excess',
              'operations_billing' => 're-sit',
              'extra_order' => 'extra',
              'discount_option' => 'discount',
            }

    tabs[name.to_s].presence || 'normal'
  end

  def fill_period_document_v2
    PeriodDocument.where('DATE_FORMAT(created_at, "%Y%m") >= 201901').each do |doc|
      next if not doc.period

      doc.period_v2 = CustomUtils.period_of(doc.period.start_date)
      doc.save
    end
  end

  def fill_invoice_period_v2
    BillingMod::Invoice.where('DATE_FORMAT(created_at, "%Y%m") >= 201901').each do |invoice|
      invoice.period_v2 = CustomUtils.period_of(invoice.created_at - 1.month)
      invoice.save
    end
  end

  def migrate_ido_basique_to_ido_classic
    BillingMod::Billing.where(name: 'ido_basique').update_all(name: 'ido_classic')
  end

  def user_ids
    org = Organization.find_by_code 'FA'

    org.customers.pluck(:id)
  end
end