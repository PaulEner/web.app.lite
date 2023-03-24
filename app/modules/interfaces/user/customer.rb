module Interfaces::User::Customer
  def active_at?(period)
    self.created_at.strftime('%Y%m').to_i <= period.to_i && ( !self.inactive_at.present? || (self.inactive_at.present? && self.inactive_at.strftime('%Y%m').to_i > period.to_i) )
  end

  def active?
    !inactive?
  end

  def inactive?(time=nil)
    return false if inactive_at.blank?

    return true if inactive_at.present? && time.nil?
    return inactive_at < time && time.present?
  end

  def still_active?
    active? || inactive_at.to_date > Date.today.end_of_month
  end

  def configured?
    current_configuration_step.nil?
  end

  def uses_many_exportable_softwares?
    softwares_count = 0

    Interfaces::Software::Configuration::SOFTWARES.each do |software|
      softwares_count += 1 if uses?(software.to_sym)
    end

    softwares_count > 1
  end


  def uses_api_softwares?
    uses_value = false

    Interfaces::Software::Configuration::API_SOFTWARES.each do |software|
      uses_value = uses_value || uses?(software.to_sym)
    end

    uses_value
  end


  def uses_non_api_softwares?
    uses_value = false

    Interfaces::Software::Configuration::NON_API_SOFTWARES.each do |software|
      uses_value = uses_value || uses?(software.to_sym)
    end

    uses_value
  end


  def uses?(software)
    self.try(software).try(:used?) && self.organization.try(software).try(:used?)
  end


  def uses_ibiza_analytics?
    uses?(:ibiza) && self.try(:ibiza).ibiza_id.present? && self.try(:ibiza).try(:compta_analysis_activated?)
  end


  def validate_ibiza_analytics?
    uses_ibiza_analytics? && self.try(:ibiza).try(:analysis_to_validate?)
  end


  def uses_manual_delivery?
    ( uses?(:ibiza) && !self.try(:ibiza).try(:auto_deliver?) ) ||
    ( uses?(:exact_online) && !self.try(:exact_online).try(:auto_deliver?) )
  end

  def jefacture_api_key
    organization.jefacture_api_key
  end

  def find_or_create_subscription
    self.subscription ||= Subscription.create(user_id: id)
  end

  def create_or_update_software(attributes)
    if attributes[:software].to_s == "my_unisoft"
      MyUnisoftLib::Setup.new({organization: @organization, customer: self, columns: {is_used: attributes[:columns][:is_used], action: "update"}}).execute
    elsif attributes[:software].to_s == "sage_gec"
      SageGecLib::Setup.new({organization: @organization, customer: self, columns: {is_used: attributes[:columns][:is_used], action: "update"}}).execute
    elsif attributes[:software].to_s == "acd"
      AcdLib::Setup.new({organization: @organization, customer: self, columns: {is_used: attributes[:columns][:is_used], action: "update"}}).execute
    else
      software = self.send(attributes[:software].to_sym) || Interfaces::Software::Configuration.softwares[attributes[:software].to_sym].new
      begin
        software.assign_attributes(attributes[:columns])
      rescue
        software.assign_attributes(attributes[:columns].to_unsafe_hash)
      end

      counter = 0

      Interfaces::Software::Configuration::API_SOFTWARES.each do |api_software|
        counter += 1 if software.try(api_software.to_sym).try(:used?)
      end

      if counter <= 1
        if software.is_a?(Software::Ibiza) # Assign default value to avoid validation exception
          software.state                            = 'none'
          software.state_2                          = 'none'
          software.voucher_ref_target               = 'piece_number'
          software.is_auto_updating_accounting_plan = true
        end

        software.owner = self
        software.save
        software
      else
        software = nil
      end
    end
  end

  def prescribers
    collaborator? ? [] : ((organization&.admins || []) | group_prescribers)
  end

  def group_prescribers
    collaborator? ? [] : groups.flat_map(&:collaborators)
  end

  def compta_processable_journals
    account_book_types.compta_processable
  end

  def pre_assignement_displayed?
    collaborator? || is_pre_assignement_displayed
  end

  def has_collaborator_action?
    collaborator? || (is_pre_assignement_displayed && act_as_a_collaborator_into_pre_assignment)
  end

  def authorized_all_upload?
    return false if self.inactive?
    return false if not self.organization.try(:can_upload_documents?)
    # (self.try(:options).try(:upload_authorized?) && authorized_bank_upload?) || self.organization.try(:specific_mission)
    ( authorized_basic_upload? && authorized_bank_upload? ) || self.organization.try(:specific_mission)
  end

  def authorized_upload?
    return false if self.inactive?
    return false if not self.organization.try(:can_upload_documents?)
    # self.try(:options).try(:upload_authorized?) || authorized_bank_upload? || self.organization.try(:specific_mission)
    authorized_basic_upload? || authorized_bank_upload? || self.organization.try(:specific_mission)
  end

  def authorized_basic_upload?
    return false if self.inactive?
    return false if not self.organization.try(:can_upload_documents?)
    self.my_package.try(:is_active) && self.my_package.try(:upload_active)
  end

  def authorized_bank_upload?
    return false if self.inactive?
    return false if not self.organization.try(:can_upload_documents?)

    self.my_package.try(:is_active) && self.my_package.try(:bank_active)
  end

  def banking_provider
    is_budgea = self.options.banking_provider == 'budget_insight'
    is_bridge = self.options.banking_provider == 'bridge'

    if !is_budgea && !is_bridge
      is_budgea = self.organization.try(:banking_provider) == 'budget_insight'
      is_bridge = self.organization.try(:banking_provider) == 'bridge'
    end

    return 'budget_insight' if is_budgea
    return 'bridge'         if is_bridge
  end

  def has_maximum_journal?
    return false if self.organization.specific_mission

    self.account_book_types.count >= self.my_package.try(:journal_size).to_i
  end
end