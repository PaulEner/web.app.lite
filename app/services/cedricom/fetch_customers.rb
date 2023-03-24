module Cedricom
  class FetchCustomers
    def initialize(organization, customer = nil)
      @customer     = customer
      @organization = organization
    end

    def get_list
     users = User.where(id: BankAccount.where(user_id: @organization.customers.pluck(:id)).pluck(:user_id))

     users.each do |user|
      Cedricom::FetchCustomers.new(@organization, user).get
     end
    end

    def get
      cedricom_customer = Cedricom::Api.new(@organization).get_customer(@customer.sanitized_code)

      if cedricom_customer
        cedricom_customer_data = JSON.parse(cedricom_customer)

        update_bank_accounts(cedricom_customer_data)
      end
    end

    def self.refresh_all
      Organization.cedricom_configured.each do |organization|
        Cedricom::FetchCustomers.new(organization).get_list
      end
    end

    private

    def update_bank_accounts(cedricom_customer_data)
      cedricom_customer_data["mandats"].each do |mandate|
        bank_account = @customer.bank_accounts.find_by_number(mandate["numeroCompte"])

        if bank_account
          bank_account.update(cedricom_mandate_identifier: mandate["reference"], cedricom_mandate_state: mandate["etat"])
        end
      end
    end
  end
end