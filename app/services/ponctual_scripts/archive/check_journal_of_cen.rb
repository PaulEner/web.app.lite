class PonctualScripts::CheckJournalOfCen < PonctualScripts::PonctualScript
  class << self
    def execute
      new().run
    end
  end

  private

  def execute
    organization = Organization.find_by_code 'CEN'

    datas = [['user_code', 'Journal', 'Pseudonyme', 'RemoteList']]
    organization.customers.active_at(Time.now).each do |user|
      journals = sage_gec_journals_of user

      next if journals.size == 0

      user.account_book_types.each do |journal|
        next if journal.pseudonym.blank? || journals.include?(journal.pseudonym)

        datas << [user.code, journal.name, journal.pseudonym, journals.to_json]
      end
    end

    send_csv_datas(datas, 'censial_journal_error')
  end

  private

  def sage_gec_journals_of(user)
    if user.sage_gec.try(:used?)
      client   = SageGecLib::Api::Client.new
      periods  = client.get_periods_list(user.organization.sage_gec.sage_private_api_uuid, user.sage_gec.sage_private_api_uuid)

      p "======================"
      p periods.to_s
      return [] if periods.blank? || periods[:body].blank? || periods[:body][0].try(:[], 'startDate').blank?

      period = periods[:body].select{ |p| Date.parse(p["startDate"]).to_date <= Date.today.to_date && Date.parse(p["endDate"]).to_date >= Date.today.to_date }.first

      journals = client.get_ledgers_list(user.organization.sage_gec.sage_private_api_uuid, user.sage_gec.sage_private_api_uuid, period.try(:[], "$uuid"))

      if journals[:status] == "success"
        journals[:body].map do |j|
          j['shortName']
        end
      else
        []
      end
    else
      []
    end
  end
end