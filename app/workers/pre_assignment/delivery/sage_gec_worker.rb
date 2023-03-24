class PreAssignment::Delivery::SageGecWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform
    UniqueJobs.for 'PreAssignmentDeliverySageGecWorker' do
      PreAssignmentDelivery.sage_gec.data_built.order(id: :asc).each do |delivery|
        PreAssignment::Delivery::SageGecWorker::Launcher.delay.process(delivery.id)
        sleep(5)
      end
    end
  end

  class Launcher
    def self.process(delivery_id)
      UniqueJobs.for "PreAssignmentDeliverySageGecWorker-#{delivery_id}" do
        delivery = PreAssignmentDelivery.find(delivery_id)
        PreAssignment::Delivery::SageGec.new(delivery).run if delivery.data_built?
      end
    end
  end
end