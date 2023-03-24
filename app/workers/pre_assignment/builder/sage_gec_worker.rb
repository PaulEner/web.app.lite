class PreAssignment::Builder::SageGecWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_and_while_executing

  def perform
    UniqueJobs.for 'PreAssignmentBuilderSageGecWorker' do
      PreAssignmentDelivery.sage_gec.pending.order(id: :asc).each do |delivery|
        PreAssignment::Builder::SageGecWorker::Launcher.delay.process(delivery.id)
        sleep(5)
       end
    end
  end

  class Launcher
    def self.process(delivery_id)
      UniqueJobs.for "PreAssignmentBuilderSageGecWorker-#{delivery_id}" do
        delivery = PreAssignmentDelivery.find(delivery_id)
        PreAssignment::Builder::SageGec.new(delivery).run if delivery.pending?
      end
    end
  end
end