class Admin::Organizations::GroupsController < BackController
  prepend_view_path('app/templates/back/organizations/views')

  before_action :load_organization_group, except: %w[index new create]

  def index
    @organization_groups = OrganizationGroup.all.page(params[:page]).per(params[:per_page]).order(created_at: :desc)
  end

  def new
    @organization_group = OrganizationGroup.new

    render partial: 'form'
  end

  def create
    @organization_group = OrganizationGroup.new(organization_group_params)
    if @organization_group.save
      json_flash[:success] = 'Créé avec succès.'
     else
      json_flash[:error] = errors_to_list @organization_group
    end

    render json: { json_flash: json_flash, url: admin_organizations_groups_path }, status: 200
  end

  def edit
    @organization_group = OrganizationGroup.find(params[:id])

    render partial: 'form'
  end

  def update
    if @organization_group.update(organization_group_params)
      json_flash[:success] = 'Modifié avec succès.'      
    else
      json_flash[:error] = errors_to_list @organization_group
    end

    render json: { json_flash: json_flash, url: admin_organizations_groups_path }, status: 200
  end

  def destroy
    @organization_group.destroy
    flash[:success] = 'Supprimé avec succès.'
    redirect_to admin_organizations_groups_path
  end

  private

  def organization_group_params
    params.require(:organization_group).permit(:name, :is_auto_membership_activated, organization_ids: [])
  end

  def load_organization_group
    @organization_group = OrganizationGroup.find params[:id]
  end
end
