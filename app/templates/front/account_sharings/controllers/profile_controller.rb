# frozen_string_literal: true
class AccountSharings::ProfileController < FrontController
  prepend_view_path('app/templates/front/account_sharings/views')

  def create
    # WARNING : flash success must be a falsh not a json_flash due to JS redirection
    @contact, @account_sharing = AccountSharing::ShareMyAccount.new(@user, account_sharing_params, current_user).execute
    if @account_sharing.persisted?
      flash[:success] = 'Votre compte a été partagé avec succès.'
    elsif Array(@account_sharing.errors[:account] || @account_sharing.errors[:collaborator]).include?('est déjà pris.')
      flash[:success] = 'Ce contact a déjà accès à votre compte.'
    elsif @contact.errors[:email].include?('est déjà pris.') || @account_sharing.errors[:collaborator_id].include?("n'est pas valide")
      flash[:error] = "Vous ne pouvez pas partager votre compte avec le contact : #{@contact.email}."
    else
      flash[:error] = "Veuillez remplir correctement les champs obligatoires svp!"
    end

    render json: { json_flash: flash }, status: 200
  end

  def destroy
    @account_sharing = AccountSharing.unscoped.where(id: params[:id]).where('account_id = :id OR collaborator_id = :id', id: @user.id).first!
    if AccountSharing::Destroy.new(@account_sharing, @user).execute
      flash[:success] = 'Le partage a été annulé avec succès.'
    else
      flash[:error] = 'Impossible de supprimer le partage.'
    end

    redirect_to profiles_path
  end

  def create_request
    # WARNING : flash success must be a falsh not a json_flash due to JS redirection
    @account_sharing_request = AccountSharingRequest.new(account_sharing_request_params)
    @account_sharing_request.user = @user
    if @account_sharing_request.save
      flash[:success] = 'Demande envoyé avec succès.'
    else
      flash[:error] = 'Impossible de faire la demande, code ou email invalide'
    end

    render json: { json_flash: flash }, status: 200
  end

  private

  def account_sharing_params
    params.require(:user).permit(:email, :company, :first_name, :last_name)
  end

  def account_sharing_request_params
    params.require(:account_sharing_request).permit(:code_or_email)
  end
end