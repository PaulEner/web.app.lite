class Jedeclare::GetListWorker
  include Sidekiq::Worker
  sidekiq_options queue: :cedricom, retry: false

  def perform
    UniqueJobs.for 'GetList' do
      Organization.jedeclare_configured.each do |organization|
        begin 
          Jedeclare::FetchReceptions.new(organization, "00").get_list
        rescue => e
          log_document = {
            subject: "[Jedeclare-GetList] Error connexion",
            name: "Jedeclare-GetList",
            error_group: "[jedeclare] Error connexion",
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