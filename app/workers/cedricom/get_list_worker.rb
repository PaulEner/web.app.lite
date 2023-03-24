class Cedricom::GetListWorker
  include Sidekiq::Worker
  sidekiq_options queue: :cedricom, retry: false

  def perform
    UniqueJobs.for 'GetList' do
      Organization.cedricom_configured.each do |organization|
        begin 
          Cedricom::FetchReceptions.new(organization).get_list
        rescue => e
          log_document = {
            subject: "[Cedricom-GetList] Error connexion",
            name: "Cedricom-GetList",
            error_group: "[cedricom] Error connexion",
            erreur_type: "Error connexion",
            date_erreur: Time.now.strftime('%Y-%M-%d %H:%M:%S'),
            more_information: {
              error_message: e.to_s,
              organization: organization.try(:code)
            }
          }

          ErrorScriptMailer.error_notification(log_document).deliver
        end
      end
    end
  end
end