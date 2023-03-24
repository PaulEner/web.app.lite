class Staffingflow::SendBundleNeededWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    UniqueJobs.for 'send_bundle_needed_worker' do
      SgiApiServices::SendBundleNeeded.execute
    end
  end
end