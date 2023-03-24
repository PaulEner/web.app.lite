# frozen_string_literal: true

class Organizations::AddressesController < OrganizationController
  before_action :load_address, only: %w[edit update destroy]

  prepend_view_path('app/templates/front/organizations/views')

  # GET /account/organizations/:organization_id/addresses
  def index; end
end
