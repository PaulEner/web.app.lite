class Billing::CreateInvoicePdfWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high, retry: false

  def perform
    UniqueJobs.for 'CreateInvoicePDF' do
      Billing::CreateInvoicePdf.for_all
      sleep(10)
      Billing::CreateInvoicePdf.for_test
    end
  end
end
