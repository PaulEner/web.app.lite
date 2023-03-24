# frozen_string_literal: true

class Organizations::ApiTokensController < OrganizationController
  prepend_view_path('app/templates/front/organizations/views')

  def index
    @api_tokens = @organization.api_tokens
  end

  def create
    @organization.api_tokens.create

    redirect_to organization_api_tokens_path(@organization)
  end

  def edit; end

  def destroy
    token = @organization.api_tokens.find(params[:id])

    token.destroy

    redirect_to organization_api_tokens_path(@organization)
  end
end
