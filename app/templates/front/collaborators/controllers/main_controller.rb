# frozen_string_literal: true
class Collaborators::MainController < OrganizationController
  before_action :verify_rights
  before_action :load_member, except: %w[index new create]

  prepend_view_path('app/templates/front/collaborators/views')

  # GET /organizations/:organization_id/collaborators
  def index
    @members = @organization.members
                            .search(search_terms(params[:user_contains]))
                            .order(sort_column => sort_direction)
                            .page(params[:page])
                            .per(params[:per_page])
  end

  # GET /organizations/:organization_id/collaborators/:id
  def show;  end

  # GET /organizations/:organization_id/collaborators/new
  def new
    @member = Member.new(code: "#{@organization.code}%", role: Member::COLLABORATOR)
    @member.build_user
  end

  # POST /organizations/:organization_id/collaborators
  def create
    @member = User::Collaborator::Create.new(member_params, @organization).execute
    if @member.persisted?
      json_flash[:success] = 'Créé avec succès.'
    else
      json_flash[:error] = errors_to_list @member
    end

    render json: { json_flash: json_flash }, status: 200
  end

  # GET /organizations/:organization_id/collaborators/:id/edit
  def edit; end

  # PUT /organizations/:organization_id/collaborators/:id
  def update
    from_show = params[:from_show].present?

    member = User::Collaborator::Update.new(@member, member_params).execute
    if member.valid?
      message = 'Modifié avec succès.'

      if from_show
        flash[:success] = message
        redirect_to organization_collaborator_path(@organization, @member, tab: 'information')
      else
        render json: { json_flash: { success: message } }, status: 200
      end
    else
      error = errors_to_list member

      if from_show
        flash[:error] = error
        redirect_to organization_collaborator_path(@organization, @member, tab: 'information')
      else
        render json: { json_flash: { error: error } }, status: 200
      end
    end
  end

  # DELETE /organizations/:organization_id/collaborators/:id
  def destroy
    if @member.user.is_admin
      flash[:error] = t('authorization.unessessary_rights')
    elsif @user.leader? || @member.collaborator?
      if User::Collaborator::Destroy.delay(queue: :low).execute(@member.user.id)
        flash[:success] = "Votre compte est en cours de suppression ..., Toute information liée au compte sera supprimée d'ici quelques minutes"
      else
        flash[:error] = 'Impossible de supprimer.'
      end
    else
      flash[:error] = 'Impossible de supprimer.'
    end

    redirect_to organization_collaborators_path(@organization)
  end

  def add_to_organization
    if @user.leader?
      related_organization = @organization.get_associated_organization(params[:oid])

      member = related_organization.members.find_by(user_id: @member.user.id)
      if member
        flash[:notice] = "Ce collaborateur est déjà membre de l'organisation : #{related_organization.name}."
      else
        base_code = "#{@organization.code}%"
        new_base_code = "#{related_organization.code}%"

        member = Member.create(
          organization: related_organization,
          user: @member.user,
          role: 'collaborator', # new collaborator for mutli-organization must have collaborator role by default
          code: @member.code.sub(/^#{base_code}/, new_base_code)
        )

        if member.errors[:code].present?
          member.code += 'X'
          member.save
        end

        if member.persisted?
          flash[:success] = "Ce collaborateur a été ajouté à l'organisation #{related_organization.name}."
        else
          flash[:error] = "Une erreur a empêché d'enregistrer les modifications."
        end
      end
    else
      flash[:error] = t('authorization.unessessary_rights')
    end

    redirect_to organization_collaborator_path(@organization, @member, tab: 'organization_group')
  end

  def remove_from_organization
    if @user.leader?
      related_organization = Organization.find(params[:oid])
      member = related_organization.members.find_by(user_id: @member.user.id)

      if member
        if member.user.memberships.count > 1
          member.destroy
          flash[:success] = "#{@member.name} a été retiré de l'organisation : #{related_organization.name}."

          if related_organization == @organization
            if member.user.id == @user.id
              # Has deleted his own access to the organization, redirecting to another organization
              redirect_to organization_path(@user.organizations.order(:name).first)
            else
              # Has deleted access to this organization for this account, redirecting to list of collaborators
              redirect_to organization_collaborators_path(@organization)
            end
            return
          elsif @organization.organization_groups.empty? && member.user.memberships.count == 1
            redirect_to organization_collaborator_path(@organization, @member)
            return
          end
        else
          flash[:notice] = 'Ne peut supprimer le seul accès de ce collaborateur.'
        end
      else
        flash[:notice] = "Ce collaborateur n'est pas membre de l'organisation."
      end
    else
      flash[:error] = t('authorization.unessessary_rights')
    end
    redirect_to organization_collaborator_path(@organization, @member, tab: 'organization_group')
  end

  private

  def verify_rights
    if @user.leader? || @user.manage_collaborators || @user.manage_groups
      if action_name.in?(%w[new create destroy edit update]) && !@organization.is_active
        flash[:error] = t('authorization.unessessary_rights')
        redirect_to organization_path(@organization)
      end
    else
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to organization_path(@organization)
    end
  end

  def load_member
    @member = @organization.members.find(params[:id])
  end

  def member_params
    attributes = [:code, { group_ids: [] }]
    attributes << :role if @user.leader?
    user_attributes = %i[id company first_name last_name]
    if action_name.in?(%w[new create]) || !@member.user.admin?
      user_attributes << :email
    end
    attributes << { user_attributes: user_attributes }
    params.require(:member).permit(*attributes)
  end

  def sort_column
    if params[:sort].in? %w[created_at code role]
      params[:sort]
    else
      'created_at'
    end
  end
  helper_method :sort_column

  def sort_direction
    if params[:direction].in? %w[asc desc]
      params[:direction]
    else
      'desc'
    end
  end
  helper_method :sort_direction
end