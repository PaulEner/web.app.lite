# -*- encoding : UTF-8 -*-
module SageGecLib
  class DataSender
    def initialize(delivery)
      @delivery = delivery
    end

    def execute(json_data)
      data = JSON.parse(json_data)

      client = SageGecLib::Api::Client.new

      retry_count = 0
      preseizure = @delivery.preseizures.first
      begin
        if preseizure.piece
          retry_count += 1
          file_path = preseizure.piece.cloud_content_object.path
          sleep(1)

          data["attachment"] = Faraday::UploadIO.new(StringIO.new(File.read(file_path)), preseizure.piece.cloud_content.content_type, "#{preseizure.coala_piece_name}.pdf")
        else
          data["attachment"] = nil
        end
      rescue => e
        if retry_count <= 3
          sleep(5)

          retry
        else
          raise e
        end
      end

      date = @delivery.preseizures.first.date

      accountancy_practice_uuid = @delivery.user.organization.sage_gec&.sage_private_api_uuid
      company_uuid = @delivery.user.sage_gec&.sage_private_api_uuid

      periods  = client.get_periods_list(accountancy_practice_uuid, company_uuid)

      period = periods[:body].select { |p| Date.parse(p["startDate"]).to_date <= date.to_date && Date.parse(p["endDate"]).to_date >= date.to_date }.first

      if period
        post_body = { "entry": JSON.dump(data["entry"]), "attachment" => data["attachment"] }

        response = client.send_pre_assignment(accountancy_practice_uuid, company_uuid, period["$uuid"], post_body)

        if response[:status] == "error"
          { success: false, error: response[:body].try(:[], 'message') || 'Unknown error ...' }
        else
          { success: true, response: response }
        end
      else
        { error: "L'exercice correspondant n'est pas défini" }
      end
    end
  end
end