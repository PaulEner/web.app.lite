# frozen_string_literal: true
class AccountSharings::OrganizationController < OrganizationController
  before_action :load_account_sharing, only: %w[accept destroy_account]
  before_action :load_guest_collaborator, only: %w[edit_contact update_contact destroy_contact]

  prepend_view_path('app/templates/front/account_sharings/views')

  def index; end

  def get_accounts
    @account_sharings = AccountSharing.unscoped.where(account_id: account_ids)
                                      .search(search_terms(params[:account_sharing_contains]))
                                      .order(sort_column => sort_direction)
                                      .page(params[:page])
                                      .per(params[:per_page])

    render partial: 'accounts'
  end

  def get_contacts
    @guest_collaborators = @organization.guest_collaborators
                                        .search(search_terms(params[:guest_collaborator_contains]))
                                        .order(sort_column => sort_direction)
                                        .page(params[:page])
                                        .per(params[:per_page])

    render partial: 'contacts'
  end

  def new_account
    @account_sharing    = AccountSharing.new

    if @user.leader?
      @customers_options  = @organization.customers.active.map{ |c| [c.info, c.id] }
      @users_options      = @organization.users.active.map{ |c| [c.info, c.id] }
    else
      @customers_options  = @user.customers.active.map{ |c| [c.info, c.id] }
      @users_options      = @organization.users.active.select{|c| c.is_guest || @user.customers.include?(c) }.map{ |c| [c.info, c.id] }
    end

    render partial: 'share_account_form'
  end

  def create_account
    @account_sharing = AccountSharing::ShareAccount.new(@user, account_sharing_params, current_user).execute
    if @account_sharing.persisted?
      json_flash[:success] = 'Dossier partagé avec succès.'
    else
      json_flash[:error]   = "Une erreur s'est produite lors du partage, Veuillez reéssayer ultérieurement"
    end

    render json: { json_flash: json_flash }, status: 200
  end

  def accept
    AccountSharing::AcceptRequest.new(@account_sharing).execute
    flash[:success] = "Le dossier \"#{@account_sharing.account.info}\" a été partagé au contact \"#{@account_sharing.collaborator.info}\" avec succès."
    
    redirect_to account_sharings_organization_path(@organization)
  end

  def destroy_account
    AccountSharing::Destroy.new(@account_sharing).execute
    flash[:success] = "Partage du dossier \"#{@account_sharing.account.info}\" au contact \"#{@account_sharing.collaborator.info}\" supprimé."

    redirect_to account_sharings_organization_path(@organization)
  end

  def new_contact
    @guest_collaborator = User.new(code: "#{@organization.code}%")
    render partial: 'share_contact_form'
  end

  def edit_contact
    render partial: 'share_contact_form'
  end

  def create_contact
    @guest_collaborator = AccountSharing::CreateContact.new(user_params, @organization).execute

    if @guest_collaborator.persisted?
      json_flash[:success] = 'Créé avec succès.'
    else
      json_flash[:error]   = "Une erreur s'est produite lors de l'ajout, Veuillez reéssayer ultérieurement"
    end

    render json: { json_flash: json_flash }, status: 200
  end

  def update_contact
    @guest_collaborator.update(user_params)

    if @guest_collaborator.save
      json_flash[:success] = 'Modifié avec succès.'
    else
      json_flash[:error]   = "Une erreur s'est produite lors de l'edition, Veuillez reéssayer ultérieurement"
    end

    render json: { json_flash: json_flash }, status: 200
  end

  def destroy_contact
    User::Collaborator::Destroy.new(@guest_collaborator).execute
    flash[:success] = 'Supprimé avec succès.'
    
    redirect_to account_sharings_organization_path(@organization, tab: 'contacts')
  end

  private

  def account_sharing_params
    params[:account_sharing] ? params.require(:account_sharing).permit(:collaborator_id, :account_id) : {}
  end

  def user_params
    params[:user] ? params.require(:user).permit(:email, :company, :first_name, :last_name) : {}
  end

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction

  def load_account_sharing
    @account_sharing = AccountSharing.unscoped.where(account_id: account_ids).find params[:id]
  end

  def load_guest_collaborator
    @guest_collaborator = @organization.guest_collaborators.find params[:id]
  end
end