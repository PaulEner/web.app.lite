class BillingMod::PrepareBillingsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high, retry: false

  def perform
    UniqueJobs.for 'BillingMod::PrepareBillings' do
      w_day = Time.now.strftime('%w').to_i
      today = Time.now.strftime('%d').to_i

      BillingMod::CreateInvoice.launch_test if (w_day % 2) == 0 && ![30,31,1,2].include?(today.to_i)
    end
  end
end
