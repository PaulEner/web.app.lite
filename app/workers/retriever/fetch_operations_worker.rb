class Retriever::FetchOperationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform
    UniqueJobs.for 'FetchOperations' do
      Retriever::FetchOperations.execute
    end
  end
end