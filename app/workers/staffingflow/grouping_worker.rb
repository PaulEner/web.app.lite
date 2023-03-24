class Staffingflow::GroupingWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    UniqueJobs.for 'staffing_flow_grouping' do
      StaffingFlow.ready_grouping.each do |sf|
        next if StaffingFlow.processing_grouping.count > 10 #MAXIMUM THREAD (Concurent job)

        Staffingflow::GroupingWorker::Launcher.delay(queue: :low).process(sf.id)
      end
    end
  end

  class Launcher
    def self.process(staffing_id)
      UniqueJobs.for "staffing_flow_grouping-#{staffing_id}" do
        sf = StaffingFlow.find(staffing_id)
        params = sf.params

        return false if StaffingFlow.processing_grouping.count > 10 #MAXIMUM THREAD (Concurent job)

        if sf.processing
          SgiApiServices::GroupDocument.processing(params[:json_content], params[:temp_document_ids], params[:temp_pack_id], sf)
          SgiApiServices::GroupDocument.delay_for(2.hours, queue: :low).retry_processing(sf.id, 1)
        end
      end
    end
  end
end