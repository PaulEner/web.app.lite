class Staffingflow::PreassignmentWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    UniqueJobs.for 'staffing_flow_preassignment' do
      StaffingFlow.ready_preassignment.each do |sf|
        next if StaffingFlow.processing_preassignment.count > 15 #MAXIMUM THREAD (Concurent job)

        Staffingflow::PreassignmentWorker::Launcher.delay.process(sf.id)
      end
    end
  end

  class Launcher
    def self.process(staffing_id)
      UniqueJobs.for "staffing_flow_preassignment-#{staffing_id}" do
        sf = StaffingFlow.find(staffing_id)
        params = sf.params

        return false if StaffingFlow.processing_preassignment.count > 15 #MAXIMUM THREAD (Concurent job)

        SgiApiServices::PushPreAsignmentService.process(params[:piece_id], params[:data_preassignment]) if sf.processing
        sf.processed
      end
    end
  end
end