module Jedeclare
  class FetchCustomers
    def initialize(organization)
      @organization = organization
    end

    def get_list
     jedeclare_customers = Hash.from_xml(Jedeclare::Api.new(@organization).get_customers)['listeDossiers']["dossier"]

     jedeclare_customers.each do |jedeclare_customer|
      user = @organization.users.where("registration_number LIKE ?", "%#{jedeclare_customer["client"]["siretPrincipal"]["siren"]}%").first

      if user
        user.update(jedeclare_account_identifier: jedeclare_customer["client"]["id"])
      end
     end
    end

    def get_bank_accounts
      @organization.users.jedeclare_configured.each do |user|
        get_bank_accounts_for_customer(user)
      end
    end

    def get_bank_accounts_for_customer(customer)
      jedeclare_bank_accounts = Hash.from_xml(Jedeclare::Api.new(@organization).get_bank_accounts_for_customer(customer))['listeRibs']

      update_bank_accounts(customer, jedeclare_bank_accounts) if jedeclare_bank_accounts
    end

    def self.refresh_all
      Organization.jedeclare_configured.each do |organization|
        Jedeclare::FetchCustomers.new(organization).get_list
        Jedeclare::FetchCustomers.new(organization).get_bank_accounts
      end
    end

    private

    def update_bank_accounts(customer, jedeclare_bank_accounts)
      if jedeclare_bank_accounts["rib"].is_a?(Array)
        jedeclare_bank_accounts["rib"].each do |bank_account|
          bank_account = customer.bank_accounts.where("number LIKE ?", "%#{bank_account['etablissement']}#{bank_account['guichet']}#{bank_account['compte']}#{bank_account['cle']}%").first

          if bank_account
            bank_account.update(jedeclare_mandate_identifier: bank_accounts["id"])
          end
        end
      elsif jedeclare_bank_accounts["rib"]
        bank_account = customer.bank_accounts.where("number LIKE ?", "%#{jedeclare_bank_accounts["rib"]['etablissement']}#{jedeclare_bank_accounts["rib"]['guichet']}#{jedeclare_bank_accounts["rib"]['numCompte']}#{jedeclare_bank_accounts["rib"]['cle']}%").first

        if bank_account
          bank_account.update(jedeclare_mandate_identifier: jedeclare_bank_accounts["rib"]["id"])
        end
      end
    end
  end
end