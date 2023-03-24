class Staffingflow::JefactureWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    UniqueJobs.for 'staffing_flow_jefacture' do
      StaffingFlow.ready_jefacture.each do |sf|
        next if StaffingFlow.processing_jefacture.count > 3 #MAXIMUM THREAD (Concurent job)

        Staffingflow::JefactureWorker::Launcher.delay(queue: :high).process(sf.id)
      end
    end
  end

  class Launcher
    def self.process(staffing_id)
      UniqueJobs.for "staffing_flow_jefacture-#{staffing_id}" do
        sf = StaffingFlow.find(staffing_id)
        params = sf.params

        return false if StaffingFlow.processing_jefacture.count > 3 #MAXIMUM THREAD (Concurent job)

        SgiApiServices::AutoPreAssignedJefacturePieces.process(params[:temp_preseizure_id], params[:piece_id], params[:raw_preseizure]) if sf.processing
        sf.processed
      end
    end
  end
end
