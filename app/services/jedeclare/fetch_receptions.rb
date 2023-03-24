module Jedeclare
  class FetchReceptions
    def initialize(organization, status)
      @status       = status
      @organization = organization
    end

    def get_list
      receptions = Hash.from_xml(Jedeclare::Api.new(@organization).get_reception_list(@status))["Envelope"]["Body"]["ListeDisponibiliteV2Response"]["liste"]["item"]        

      if receptions.is_a?(Array)
        receptions.each do |reception|
          CedricomReception.create(jedeclare_reception_id: reception['numero'],
                                   empty: false,
                                   imported: false,
                                   downloaded: false,
                                   organization: @organization)
        end
      else
        CedricomReception.create(jedeclare_reception_id: receptions['numero'],
                                 empty: false,
                                 imported: false,
                                 downloaded: false,
                                 organization: @organization)
      end
    end
    
    def self.fetch_missing_contents
      receptions = CedricomReception.jedeclare.to_download

      receptions.each do |reception|
        content = Hash.from_xml(Jedeclare::Api.new(reception.organization).get_reception(reception.jedeclare_reception_id))["Envelope"]["Body"]["DemandeAccuseResponse"]["pieceJointe"]  

        if content
          path = Dir.mktmpdir("ebics-#{reception.id}")

          File.open("#{path}/content.txt", 'w', encoding: 'ascii-8bit') do |f|
            f.puts Base64.decode64(content)
          end

          reception.content.attach(io: File.open("#{path}/content.txt"), filename: 'content.txt', content_type: 'text/plain')

          if reception.content
            reception.update(downloaded: true)
          end
        else
          reception.update(empty: true, downloaded: true)
        end
      end
    end
  end
end