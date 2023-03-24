# frozen_string_literal: true

class Journals::ListController < OrganizationController
  before_action :load_customer

  # GET /organizations/:organization_id/customers/:customer_id/list_journals
  def index
    @journals = @customer.account_book_types.order(name: :asc)
  end
end
