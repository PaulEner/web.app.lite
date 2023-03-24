class Transaction::DestroyBankAccounts
  def initialize(bank_accounts)
    @bank_accounts = bank_accounts
  end

  def execute(reason=nil)
    @bank_accounts.each do |bank_account|
      next if bank_account.api_name != 'budgea' || bank_account.cedricom_mandate_identifier.present?

      bank_account.is_used = false
      bank_account.save

      # bank_account.destroy unless bank_account.reload.retriever
    end
  end
end
