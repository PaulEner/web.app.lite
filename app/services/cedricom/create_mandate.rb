module Cedricom
  class CreateMandate
    def initialize(bank_account)
      @customer     = bank_account.user
      @bank_account = bank_account
      @organization = @customer.organization
    end

    def execute
      cedricom_customer = get_customer

      cedricom_customer = create_customer unless cedricom_customer

      if cedricom_customer
        updated_customer = create_mandate

        if updated_customer
          updated_customer_data = JSON.parse(updated_customer)

          mandate = updated_customer_data["mandats"].select { |m| m["numeroCompte"] == @bank_account.number }.first

          if mandate
            @bank_account.update(cedricom_mandate_identifier: mandate["reference"], cedricom_mandate_state: mandate["etat"])
            
            fetch_pdf_mandate(mandate["reference"])

            true
          else 
            false
          end
        end
      end
    end

    private

    def get_customer
      cedricom_customer = Cedricom::Api.new(@organization).get_customer(@customer.sanitized_code)
    end

    def create_customer
      payload = {
        "reference" =>  @customer.sanitized_code,
        "raisonSociale" => @customer.company,
        "formeJuridique" => @customer.type_of_entity,
        "villeRcs" => @customer.legal_registration_city,
        "sirenRcs" => @customer.registration_number,
        "configurationEnvoiNotifications" => "ENVOYER_AU_CLIENT_ENTREPRISE",
        "adresse" => {
          "rue" => @customer.address_street,
          "codePostal" => @customer.address_zip_code,
          "ville" => @customer.address_city
        },
        "utilisateur" => {
          "email" => @customer.email,
          "civilite" => "M.",
          "nom" => @customer.last_name,
          "prenom" => @customer.first_name,
          "phone" => @customer.phone_number
        },
        "mandats" => []
      }.to_json

      Cedricom::Api.new(@organization).create_customer(payload)
    end

    def create_mandate
      payload = {
        "raisonSociale" => @customer.company,
        "formeJuridique" => @customer.type_of_entity,
        "villeRcs" => @customer.legal_registration_city,
        "sirenRcs" => @customer.registration_number,
        "configurationEnvoiNotifications" => "ENVOYER_AU_CLIENT_ENTREPRISE",
        "adresse" => {
          "rue" => @customer.address_street,
          "codePostal" => @customer.address_zip_code,
          "ville" => @customer.address_city
        },
        "utilisateur" => {
          "email" => @customer.email,
          "civilite" => "M.",
          "nom" => @customer.last_name,
          "prenom" => @customer.first_name,
          "phone" => @customer.phone_number
        },
        "mandats" => [{
          "reference" => nil,
          "bic" => @bank_account.bic,
          "numeroCompte" => @bank_account.number,
          "devise" => @bank_account.currency
        }]
      }.to_json

      Cedricom::Api.new(@organization).update_customer(@customer.sanitized_code, payload)
    end

    def fetch_pdf_mandate(reference)
      payload = { "refsMandats" => [reference] }.to_json

      pdf = Cedricom::Api.new(@organization).fetch_mandate(@customer.sanitized_code, payload)

      if pdf
        @bank_account.cedricom_original_mandate.attach(io: StringIO.new(pdf), filename: 'pdfNonSigne.pdf', content_type: 'application/pdf')
      end
    end
  end
end