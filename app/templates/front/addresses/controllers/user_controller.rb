# frozen_string_literal: true

class Addresses::UserController < CustomerController

  before_action :load_customer
  before_action :verify_rights

  prepend_view_path('app/templates/front/addresses/views')

  def index; end

  private

  def load_customer
    @customer = customers.find(params[:customer_id])
  end
end