# -*- encoding : UTF-8 -*-
# FIXME : whole check
module JournalHelper
  def is_journal_name_disabled
    !(@user.is_admin || Settings.first.is_journals_modification_authorized || !@customer || @journal.is_open_for_modification?)
  end


  def journal_name_hint
    if !@user.is_admin && !Settings.first.is_journals_modification_authorized && @customer && @journal.is_open_for_modification?
      distance_of_time = distance_of_time_in_words_to_now((@journal.created_at || Time.now) + 24.hours)

      "Ne sera plus modifiable après #{distance_of_time}. Assurez-vous qu’il sera bien le nom adopté définitivement."
    else
      ''
    end
  end

  def my_unisoft_journals
    if @customer.my_unisoft.try(:used?)
      Rails.cache.fetch [:my_unisoft, :user, @customer.my_unisoft.id, :journals], expires_in: 1.minutes do
        client   = MyUnisoftLib::Api::Client.new(@customer.organization.my_unisoft.firm_id)
        journals = client.get_diary(@customer.my_unisoft.society_id)

        if journals.first[0].nil?
          journals.map do |j|
            {
              closed:      0,
              name:        j['code'],
              description: j['name'],
              type:        j['diary_type_code']
            }
          end
        else
          []
        end
      end
    else
      []
    end
  end

  def sage_gec_journals
    if @customer.sage_gec.try(:used?)
      Rails.cache.fetch [:sage_gec, :user, @customer.sage_gec.id, :journals], expires_in: 1.minutes do
        begin
          client   = SageGecLib::Api::Client.new
          periods  = client.get_periods_list(@customer.organization.sage_gec.sage_private_api_uuid, @customer.sage_gec.sage_private_api_uuid)

          period = periods[:body].select { |p| Date.parse(p["startDate"]).to_date <= Date.today.to_date && Date.parse(p["endDate"]).to_date >= Date.today.to_date }.first

          journals = client.get_ledgers_list(@customer.organization.sage_gec.sage_private_api_uuid, @customer.sage_gec.sage_private_api_uuid, period.try(:[], "$uuid"))

          if journals[:status] == "success"
            journals[:body].map do |j|
              {
                closed:      0,
                name:        j['shortName'],
                description: j['name'],
                type:        j['originalJournalType']
              }
            end
          else
            []
          end
        rescue => e
          []
        end
      end
    else
      []
    end
  end

  def exact_online_journals
    if @customer.exact_online.try(:fully_configured?) && @customer.uses?(:exact_online)
      Rails.cache.fetch [:exact_online, :user, @customer.exact_online.id, :journals], expires_in: 5.minutes do
        journals = ExactOnlineLib::Data.new(@customer).journals
        if journals
          journals.map do |j|
            {
              closed:      0,
              name:        j['code'],
              description: j['description'],
              type:        j['type']
            }
          end
        else
          []
        end
      end
    else
      []
    end
  end

  def ibiza_journals
    if @customer.try(:ibiza).ibiza_id? && @customer.uses?(:ibiza)
      Rails.cache.fetch [:ibiza, :user, @customer.try(:ibiza).try(:ibiza_id).gsub(/({|})/, ''), :journals], expires_in: 5.minutes do
        service = IbizaLib::Journals.new(@customer)

        service.execute

        if service.success?
          service.journals
        else
          []
        end
      end
    else
      []
    end
  end


  def ibiza_journals_beginning_with_a_number?
    ibiza_journals.select do |j|
      j[:name].match(/\A\d/)
    end.any?
  end


  def ibiza_journals_beginning_with_a_number_hint
    if ibiza_journals_beginning_with_a_number?
      'iDocus ne supportant pas les journaux comptables avec un nom numérique, nous avons rajouter JC devant le nom du journal comptable issu de votre outil'
    end
  end


  def journals_for_select(journal_name, type = nil)
    journals = if @customer.uses?(:exact_online)
                exact_online_journals
              elsif @customer.my_unisoft.try(:used?)
                my_unisoft_journals
              elsif @customer.sage_gec.try(:used?)
                sage_gec_journals
              else
                ibiza_journals
              end

    if journals.any?
      journals = journals.select do |j|
        j[:closed].to_i == 0
      end

      if type == 'bank' && @customer.uses?(:ibiza)
        journals = journals.select do |j|
          j[:type].to_i.in? [5, 6]
        end
      end

      values = journals.map do |j|
        description = "#{j[:name]} (#{j[:description]})"
        description = 'JC' + description if j[:name] =~ /\A\d/ && !@customer.try(:my_unisoft).try(:used?)
        [description, j[:name]]
      end

      if journal_name.present? && !journal_name.in?(values.map(&:last))
        description = journal_name
        description = 'JC' + description if journal_name =~ /\A\d/ && !@customer.try(:my_unisoft).try(:used?)
        values << ["#{description} (inaccessible depuis la ged)", journal_name]
        values.sort_by(&:first)
      end

      if values.any?
        values.unshift(["Aucun", ''])
      else
        values
      end
    elsif journal_name.present?
      description = journal_name
      description = 'JC' + description if journal_name =~ /\A\d/ && !@customer.try(:my_unisoft).try(:used?)
      [["Aucun", ''], ["#{description} (inaccessible depuis la ged)", journal_name]]
    else
      []
    end
  end

  def external_journal_title
    if @customer.uses?(:exact_online)
      'Journaux Exact Online :'
    elsif @customer.uses?(:my_unisoft)
      'Journaux My Unisoft :'
    elsif @customer.uses?(:sage_gec)
      'Journaux Sage GEC :'
    else
      'Journaux Ibiza :'
    end
  end


  def journal_domain_for_select
    AccountBookType::DOMAINS.map do |e|
      e.present? ? [e, e] : ['Aucun', e]
    end
  end

  def journal_currencies
    CurrencyRate.lists
  end


  def original_currencies
    CurrencyRate.original_currencies
  end

  def bank_account_type_name
    BankAccount.type_name_list
  end

  def user_and_journal_list(operation=false)
    result = []

    if operation
      accounts.each{|account| result << { user: account.id, journals: account.bank_accounts.distinct.pluck(:journal).compact  } }
    else
      accounts.each{|account| result << { user: account.id, journals: account.account_book_types.distinct.pluck(:name).compact } }
    end

    result.to_json
  end

  def accounts_journaux(operation=false)
    if operation
      BankAccount.where(user_id: accounts.map(&:id)).distinct.pluck(:journal).compact
    else
      AccountBookType.where(user_id: accounts.map(&:id)).distinct.pluck(:name).compact
    end
  end

  def period_list
    periods  = []
    time_now = Time.now.strftime('%Y%m').to_i

    2.times.each do |y|
      year = y.year.ago.year

      12.times.each do |m|
        month      = m.month.ago.strftime('%m')

        tmp_period = year.to_s + month.to_s

        periods << tmp_period if tmp_period.to_i <= time_now
      end
    end

    periods.sort.reverse
  end

  def list_vat_accounts_for(organization_code)
    CustomUtils.list_vat_of(organization_code).map { |ke, vat| [vat, ke] if ke.to_i != 0 }.compact
  end
end
