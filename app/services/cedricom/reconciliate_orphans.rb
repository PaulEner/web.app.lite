module Cedricom
  class ReconciliateOrphans
    def self.perform
      Operation.cedricom_orphans.each do |operation|
        bank_account = BankAccount.ebics_enabled.used.where("bank_accounts.number LIKE ?", "%#{operation.unrecognized_iban}%").first

        if bank_account
          operation.update(bank_account: bank_account, unrecognized_iban: nil, api_id: "ebics_#{operation.id}")
        end
      end
    end
  end
end