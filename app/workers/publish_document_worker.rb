class PublishDocumentWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform
    counter_limit = TempPack.where('document_delivery_id > 0').size

    TempPack.not_processed.order(updated_at: :asc).limit(10).each do |temp_pack|
      next if counter_limit > 5

      DataProcessor::TempPack.delay(queue: :low).process(temp_pack.name)
    end
  end
end