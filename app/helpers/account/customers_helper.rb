# frozen_string_literal: true

module Account::CustomersHelper
  def software_uses(software_name)
    case software_name
    when 'ibiza'
      @organization.try(:ibiza).try(:used?) && !@customer.uses?(:exact_online) && !@customer.uses?(:my_unisoft) && !@customer.uses?(:sage_gec) && !@customer.uses?(:acd)
    when 'exact_online'
      @organization.try(:exact_online).try(:used?) && !@customer.uses?(:ibiza) && !@customer.uses?(:my_unisoft) && !@customer.uses?(:sage_gec) && !@customer.uses?(:acd)
    when 'my_unisoft'
      @organization.try(:my_unisoft).try(:used?) && !@customer.uses?(:ibiza) && !@customer.uses?(:exact_online) && !@customer.uses?(:sage_gec) && !@customer.uses?(:acd)
    when 'sage_gec'
      @organization.try(:sage_gec).try(:used?) && !@customer.uses?(:ibiza) && !@customer.uses?(:exact_online) && !@customer.uses?(:my_unisoft) && !@customer.uses?(:acd)
    when 'acd'
      @organization.try(:acd).try(:used?) && !@customer.uses?(:ibiza) && !@customer.uses?(:exact_online) && !@customer.uses?(:my_unisoft) && !@customer.uses?(:sage_gec)
    end
  end

  def sage_gec_companies_list_options_for_select(organization)
    companies = SageGecLib::Api::Client.new.get_companies_list(organization.sage_gec&.sage_private_api_uuid)

    if companies[:status] == "success"
      companies[:body].map { |c| [c['name'], c['id']] }
    else
      []
    end
  end

  def my_unisoft_companies_list_options_for_select(organization)
    companies = MyUnisoftLib::Api::Client.new(organization.my_unisoft&.firm_id).get_societies_list

    if companies[:status] == "success"
      companies[:body]["society_array"].map { |c| [c['name'], c['society_id']] }
    else
      []
    end
  end

  def acd_companies_list_options_for_select(organization)
    companies = AcdLib::Api::Client.new(organization.acd.username, organization.acd.password, organization.acd.url).get_companies_list

    if companies[:status] == "success"
      companies[:body].map { |c| [c['Nom'], c['Code']] }
    else
      []
    end
  end
end