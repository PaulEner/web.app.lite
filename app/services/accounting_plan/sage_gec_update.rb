class AccountingPlan::SageGecUpdate < AccountingPlan::UpdateService
  def self.execute(user)
    new(user).run
  end

  private

  def execute
    if @user.try(:sage_gec).try(:present?) && @user.sage_gec.used? && @accounting_plan.need_update?
      @accounting_plan.update(is_updating: true, last_checked_at: Time.now)

      @accounting_plan.providers.update_all(is_updated: false)
      @accounting_plan.customers.update_all(is_updated: false)

      sage_accounts = trading_accounts

      cleaned_ranked_entries_by_ledger_and_third_party.each do |ledger, accounts|
        idocus_ledger = account_book_types.select { |abt| abt.pseudonym ==  ledger || abt.name == ledger  }.first
        if idocus_ledger.entry_type == 2
          kind = 'provider'
        elsif idocus_ledger.entry_type == 3
          kind = 'customer'
        end

        accounts.each do |a|
          account_name = sage_accounts.select { |ta| ta["shortName"] == a['third_party_account'] }.first

          account_name = account_name ? account_name["name"] : a['third_party_account']

          data = { name: account_name, number: a['third_party_account'], associate: a['counterpart_account'], kind: kind }

          create_item data if data.present?
        end
      end

      @accounting_plan.is_updating = false
      @accounting_plan.cleanNotUpdatedItems
      @accounting_plan.save
    else
      false
    end
  end

  def account_book_types
    @user.account_book_types.where(entry_type: [2,3])
  end

  def sage_gec_client
    SageGecLib::Api::Client.new
  end

  def accountancy_practice_uuid
    @user.organization.sage_gec&.sage_private_api_uuid
  end

  def company_uuid
    @user.sage_gec&.sage_private_api_uuid
  end

  def periods
    sage_gec_client.get_periods_list(accountancy_practice_uuid, company_uuid)[:body].last(2)
  end

  def trading_accounts
    sage_gec_client.get_trading_accounts_list(accountancy_practice_uuid, company_uuid, periods.last["$uuid"])[:body]
  end

  def entries(period_uuid)
    sage_gec_client.get_entries_list(accountancy_practice_uuid, company_uuid, period_uuid)[:body]
  end

  def entries_by_ledgers
    ledgers = {}
    account_book_types.each {|abt| ledgers["#{!abt.pseudonym.blank? ? abt.pseudonym : abt.name}"] = [] }

    periods.each do |period|
      entries(period["$uuid"]).each do |entry|
        ledgers["#{entry["lines"][0]["financialAccountJournalReference"]}"] << entry if ledgers[entry["lines"][0]["financialAccountJournalReference"]]
      end
    end

    ledgers
  end

  def ranked_entries_by_ledger_and_third_party
    entries_by_ledger_and_third_party = {}

    entries_by_ledgers.each do |ledger, entries|
      entries_by_ledger_and_third_party[ledger] = [] unless entries_by_ledger_and_third_party[ledger]

      entries.each do |entry|
        puts entry.inspect
        vat_account = entry["lines"].select { |l| l["accountReferenceForJournal"][0..2] == "445" }.first
        counterpart_account = entry["lines"].select { |l| l["accountReferenceForJournal"][0] == "6" || l["accountReferenceForJournal"][0] == "7" }.first
        third_party_account = entry["lines"].select { |l| !l["accountReferenceForJournal"][0].in?(%w(1 2 5 6 7)) && l["accountReferenceForJournal"][0..2] != "445"}.first

        if counterpart_account && third_party_account
          entry_by_ledger_and_third_party = entries_by_ledger_and_third_party[ledger].select { |e| e["third_party_account"] == third_party_account["accountReferenceForJournal"] && e["counterpart_account"] == counterpart_account["accountReferenceForJournal"] }.first

          unless entry_by_ledger_and_third_party
            entries_by_ledger_and_third_party[ledger] << { "third_party_account" => third_party_account["accountReferenceForJournal"], "counterpart_account" => counterpart_account["accountReferenceForJournal"], "total_amount" => 0 }

            entry_by_ledger_and_third_party = entries_by_ledger_and_third_party[ledger].select { |e| e["third_party_account"] == third_party_account["accountReferenceForJournal"] && e["counterpart_account"] == counterpart_account["accountReferenceForJournal"] }.first
          end

          if vat_account && vat_account["accountReferenceForJournal"]
            entry_by_ledger_and_third_party["vat_account"] = vat_account["accountReferenceForJournal"]
          end

          if counterpart_account["accountReferenceForJournal"] && counterpart_account["accountReferenceForJournal"][0] == "6"
            entry_by_ledger_and_third_party["total_amount"] += counterpart_account["debit"] if counterpart_account["debit"]
          elsif counterpart_account["accountReferenceForJournal"] && counterpart_account["accountReferenceForJournal"][0] == "7"
            entry_by_ledger_and_third_party["total_amount"] += counterpart_account["credit"] if counterpart_account["credit"]
          end
        end
      end
    end

    entries_by_ledger_and_third_party
  end

  def cleaned_ranked_entries_by_ledger_and_third_party
    final_list = {}

    ranked_entries_by_ledger_and_third_party.each do |ledger, plans|
      final_list[ledger] = [] unless final_list[ledger]

      plans.each do |plan|
        item = final_list[ledger].select { |e| e["third_party_account"] == plan["third_party_account"] && e["counterpart_account"] == plan["counterpart_account"] }.first

        unless item
          final_list[ledger] << plan
        end

        if item && item["total_amount"] < plan["total_amount"]
          item.reject!

          final_list[ledger] << plan
        end
      end
    end

    final_list
  end
end