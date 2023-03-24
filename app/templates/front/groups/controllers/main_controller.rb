# frozen_string_literal: true
class Groups::MainController < OrganizationController
  before_action :verify_rights, except: %w[index show]
  before_action :load_group, except: %w[index new create]

  prepend_view_path('app/templates/front/groups/views')

  # GET /organizations/:organization_id/groups
  def index
    base_content

    render partial: 'index'
  end

  # GET /organizations/:organization_id/groups/:id
  def show; end

  # GET /organizations/:organization_id/groups/new
  def new
    @group = @organization.groups.new
  end

  # POST /organizations/:organization_id/groups
  def create
    @group = @organization.groups.new safe_group_params

    if @group.save
      FileImport::Dropbox.changed(@group.collaborators)
      json_flash[:success] = 'Créé avec succès.'
      render json: { json_flash: json_flash }, status: 200
    else
      json_flash[:error] = errors_to_list @group
      render json: { json_flash: json_flash }, status: 200
    end
  end

  # GET /organizations/:organization_id/groups/:id/edit
  def edit; end

  # PUT /organizations/:organization_id/groups/:id
  def update
    previous_collaborators = @group.collaborators

    if @group.update(safe_group_params)
      collaborators = (@group.collaborators + previous_collaborators).uniq
      FileImport::Dropbox.changed(collaborators)
      json_flash[:success] = 'Modifié avec succès.'
      render json: { json_flash: json_flash }, status: 200
    else
      json_flash[:error] = errors_to_list @group
      render json: { json_flash: json_flash }, status: 200
    end
  end

  # DELETE /organizations/:organization_id/groups/:id
  def destroy
    @group.destroy
    FileImport::Dropbox.changed(@group.collaborators)
    json_flash[:success] = 'Supprimé avec succès.'

    render json: { json_flash: json_flash }, status: 200
  end

  private

  def verify_rights
    unless (@user.leader? || @user.manage_collaborators || @user.manage_groups) && @organization.is_active
      if action_name.in?(%w[new create destroy]) || (action_name.in?(%w[edit update]) && !@user.manage_groups) || !@organization.is_active
        json_flash[:error] = t('authorization.unessessary_rights')

        render json: { json_flash: json_flash }, status: 200
      end
    end
  end

  def group_params
    if @user.admin?
      params.require(:group).permit(
        :name,
        :description,
        :dropbox_delivery_folder,
        :is_dropbox_authorized,
        member_ids: [],
        customer_ids: []
      )
    elsif @user.leader? || @user.manage_collaborators || @user.manage_groups
      params.require(:group).permit(
        :name,
        :description,
        member_ids: [],
        customer_ids: []
      )
    else
      params.require(:group).permit(customer_ids: [])
    end
  end

  def safe_group_params
    if @user.leader?
      safe_ids = @organization.members.map(&:id).map(&:to_s)
      ids = params[:group].try(:[], :member_ids) || []
      ids.delete_if { |id| !id.in?(safe_ids) }
      params[:group][:member_ids] = ids
    end

    safe_ids = @organization.customers.map(&:id).map(&:to_s)
    ids = params[:group].try(:[], :customer_ids) || []
    ids.delete_if { |id| !id.in?(safe_ids) }
    params[:group][:customer_ids] = ids

    group_params
  end

  def load_group
    @group = @organization.groups.find(params[:id])
  end

  def base_content
    @groups = @user.groups.search(search_terms(params[:group_contains]))
                   .order(sort_column => sort_direction)
                   .page(params[:page])
                   .per(21)
  end

  def sort_column
    params[:sort] || 'name'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'asc'
  end
  helper_method :sort_direction
end