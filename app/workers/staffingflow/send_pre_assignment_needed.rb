class Staffingflow::SendPreAssignmentNeededWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    UniqueJobs.for 'send_pre_assignment_needed' do
      SgiApiServices::SendPreAssignmentNeeded.execute
    end
  end
end