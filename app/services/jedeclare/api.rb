module Jedeclare
  class Api
    CONFIG = YAML.load_file('config/jedeclare.yml').freeze

    def initialize(organization)
      @organization = organization

      @connection = Faraday.new(CONFIG['jedeclare']['base_url']) do |faraday|
        faraday.request :basic_auth, @organization.jedeclare_user, organization.jedeclare_password
        faraday.response :logger
        faraday.adapter Faraday.default_adapter
        faraday.headers['Content-Type'] = "application/xml"
      end
    end

    def get_reception_list(status)
      path = "/webservices/wspid_spring/CommunicationV2Service/"

      payload = get_receptions_list_payload(status)

      @connection = Faraday.new(CONFIG['jedeclare']['base_url']) do |faraday|
        faraday.response :logger
        faraday.adapter Faraday.default_adapter
        faraday.headers["Accept"] = "*/*"
        faraday.headers["Accept-Encoding"] = "gzip, deflate, br"
        faraday.headers["Content-Type"] = "text/xml;charset=UTF-8"
      end

      result = @connection.post do |request|
        request.url path
        request.body = payload
      end

      result.body
    end

    def get_reception(reception_id)
      path = "/webservices/wspid_spring/CommunicationV2Service/"

      payload = get_reception_payload(reception_id)

      @connection = Faraday.new(CONFIG['jedeclare']['base_url']) do |faraday|
        faraday.response :logger
        faraday.adapter Faraday.default_adapter
        faraday.headers["SOAPAction"] = ""
        faraday.headers["Content-Type"] = "text/xml;charset=UTF-8"
      end

      result = @connection.post do |request|
        request.url path
        request.body = payload
      end

      if result.status == 200
        result.body
      else
        nil
      end
    end

    def get_customers
      path = "/webservice/gestion/compte/#{@organization.jedeclare_account_identifier}/dossierClient"

      result = @connection.get do |request|
        request.url path
      end

      if result.status == 200
        result.body
      else
        nil
      end
    end

    def get_bank_accounts_for_customer(customer)
      path = "/webservice/gestion/compte/#{@organization.jedeclare_account_identifier}/dossierClient/#{customer.jedeclare_account_identifier}/rib"

      result = @connection.get do |request|
        request.url path
      end

      if result.status == 200
        result.body
      else
        nil
      end
    end

    private

    def get_receptions_list_payload(status)
      "<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:sch='http://experian.com/communicationV2/schemas'>
         <soapenv:Header/>
         <soapenv:Body>
            <sch:ListeDisponibiliteV2Request>
               <sch:Authentification>
                  <sch:motDePasse>#{@organization.jedeclare_password}</sch:motDePasse>
                  <sch:nom>#{@organization.jedeclare_user}</sch:nom>
               </sch:Authentification>
               <sch:Identification>
                  <sch:editeur>iDocus</sch:editeur>
                  <sch:logiciel>my.idocus.com</sch:logiciel>
                  <sch:version>1.0</sch:version>
               </sch:Identification>
               <sch:RequeteListe>
                  <sch:statutPiece>#{status}</sch:statutPiece>
                  <sch:typeDeListe>03</sch:typeDeListe>
                  <sch:typeProcedure>RELEVE</sch:typeProcedure>
               </sch:RequeteListe>
            </sch:ListeDisponibiliteV2Request>
         </soapenv:Body>
      </soapenv:Envelope>"
    end

    def get_reception_payload(reception_id)
      "<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:sch='http://experian.com/communicationV2/schemas'>
         <soapenv:Header/>
         <soapenv:Body>
            <sch:DemandeAccuseRequest>
               <sch:Authentification>
                  <sch:motDePasse>#{@organization.jedeclare_password}</sch:motDePasse>
                  <sch:nom>#{@organization.jedeclare_user}</sch:nom>
               </sch:Authentification>
               <sch:Identification>
                  <sch:editeur>iDocus</sch:editeur>
                  <sch:logiciel>my.idocus.com</sch:logiciel>
                  <sch:version>1.0</sch:version>
               </sch:Identification>
               <sch:RequeteDemandePiece>
                  <sch:mimeTypeReponse>autre</sch:mimeTypeReponse>
                  <sch:numero>#{reception_id}</sch:numero>
                  <sch:typePiece>03</sch:typePiece>
               </sch:RequeteDemandePiece>
            </sch:DemandeAccuseRequest>
         </soapenv:Body>
      </soapenv:Envelope>"
    end
  end
end