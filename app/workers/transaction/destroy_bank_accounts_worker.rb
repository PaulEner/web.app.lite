class Transaction::DestroyBankAccountsWorker
  include Sidekiq::Worker

  def perform(bank_account_ids, reason=nil)
    bank_accounts = BankAccount.where(id: bank_account_ids)
    Transaction::DestroyBankAccounts.new(bank_accounts).execute(reason)
  end
end
