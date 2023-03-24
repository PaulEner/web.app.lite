class Cedricom::ReconciliateOrphansWorker
  include Sidekiq::Worker
  sidekiq_options queue: :cedricom, retry: false

  def perform
    UniqueJobs.for 'ReconciliateOrphans' do
      Cedricom::ReconciliateOrphans.perform
    end
  end
end