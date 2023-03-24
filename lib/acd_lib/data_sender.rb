# -*- encoding : UTF-8 -*-
module AcdLib
  class DataSender
    def initialize(delivery)
      @delivery = delivery
    end

    def execute(json_data)
      data = JSON.parse(json_data)

      organization_acd = @delivery.user.organization.acd

      company_code = @delivery.user.acd&.code

      client = AcdLib::Api::Client.new(organization_acd.username, organization_acd.password, organization_acd.url)

      retry_count = 0
      preseizure = @delivery.preseizures.first
      begin
        if preseizure.piece

          attachment_data = {}

          retry_count += 1
          file_path = preseizure.piece.cloud_content_object.path
          sleep(1)


          attachment_data["idArboged"] = 0
          attachment_data["file"] = Faraday::UploadIO.new(StringIO.new(File.read(file_path)), preseizure.piece.cloud_content.content_type, "#{preseizure.coala_piece_name}.pdf")

          file = client.store_file(company_code, attachment_data)
          data["referenceGED"] = file[:body]["id"]
        else
          data["referenceGED"] = ""
        end
      rescue => e
        if retry_count <= 3
          sleep(5)

          retry
        else
          raise e
        end
      end

      client.select_company(company_code)

      response = client.send_pre_assignment(data)

      if response[:status] == "error"
        { success: false, error: response[:body].try(:[], 'listeErreurs') || 'Unknown error ...' }
      else
        { success: true, response: response }
      end
    end
  end
end