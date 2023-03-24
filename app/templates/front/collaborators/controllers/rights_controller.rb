# frozen_string_literal: true
class Collaborators::RightsController < OrganizationController
  before_action :verify_rights
  before_action :load_member

  prepend_view_path('app/templates/front/collaborators/views')

  # GET /account/organizations/:organization_id/collaborators/:collaborator_id/rights/edit
  def edit; end

  # PUT /account/organizations/:organization_id/collaborators/:collaborator_id/rights
  def update
    if @member.update(membership_params)
      flash[:success] = 'Modifié avec succès.'
    else
      flash[:error] = errors_to_list @member
    end

    # render json: { json_flash: json_flash }, status: 200
    redirect_to organization_collaborator_path(@organization, @member, tab: 'authorization')
  end

  private

  def verify_rights
    unless @user.leader? || @user.manage_collaborators?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to organization_path(@organization)
    end
  end

  def membership_params
    params.require(:member).permit(
      :manage_groups,
      :manage_collaborators,
      :manage_customers,
      :manage_journals,
      :manage_customer_journals
    )
  end

  def load_member
    @member = @organization.members.find params[:collaborator_id]
  end
end