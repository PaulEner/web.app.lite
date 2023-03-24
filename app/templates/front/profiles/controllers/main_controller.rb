# frozen_string_literal: true
class Profiles::MainController < FrontController
  skip_before_action :verify_if_active, only: %w[show]

  prepend_view_path('app/templates/front/profiles/views')

  # GET /profiles
  def show
    if @user.active?
      @external_file_storage = @user.find_or_create_external_file_storage

      if @external_file_storage.is_dropbox_basic_authorized?
        if @external_file_storage.dropbox_basic.access_token
          client = FileImport::Dropbox::Client.new(DropboxApi::Client.new(@external_file_storage.dropbox_basic.access_token))
          begin
            @dropbox_account = client.get_current_account
          rescue StandardError
            @dropbox_account = nil
          end
        end
      end
    end
    @active_panel = params[:panel] || 'change_password'
  end

  # PUT /profiles
  def update
    if params[:user].try(:[], :h_change_password)
      if @user.valid_password?(params[:user].try(:[], :current_password))
        @user.password =              params[:user].try(:[], :password)
        @user.password_confirmation = params[:user].try(:[], :password_confirmation)

        if @user.save
          json_flash[:success] = 'Votre mot de passe a été mis à jour avec succès'
        else
          json_flash[:error] = 'Une erreur est survenue lors de la mise à jour de votre mot de passe'
        end
      else
        json_flash[:error] = "Votre ancien mot de passe n'a pas été saisi correctement"
      end
    elsif params[:user].try(:[], :h_change_notifications) && @user.active?
      params[:user].reject! { |key, _value| key == 'password' || key == 'password_confirmation' }

      if @user.update(user_params)
        json_flash[:success] = 'Modifié avec succès.'
      else
        json_flash[:error] = 'Impossible de sauvegarder.'
      end
    end

    render json: { json_flash: json_flash }, status: 200
  end

  def regenerate_email_code
    if params[:customer].present?
      customer = User.find Base64.decode64(params[:customer])
      if customer && customer.my_package.try(:upload_active) && customer.active? && customer.update_email_code
        flash[:success] = 'Code régénéré avec succès.'
      else
        flash[:error] = "Impossible d'effectuer l'opération demandée"
      end

      redirect_to upload_email_infos_organization_customer_path(customer.organization, customer)
    else
      if !(@user.is_admin || @user.is_prescriber || @user.inactive?) && @user.update_email_code
        json_flash[:success] = 'Code régénéré avec succès.'
      else
        json_flash[:error] = "Impossible d'effectuer l'opération demandée"
      end

      render json: { json_flash: json_flash }, status: 200
    end
  end

  private

  def user_params
    params.require(:user).permit(
      notify_attributes: %i[
        id
        to_send_docs
        published_docs
        reception_of_emailed_docs
        r_wrong_pass
        r_site_unavailable
        r_action_needed
        r_bug
        r_no_bank_account_configured
        r_new_documents
        r_new_operations
        document_being_processed
        paper_quota_reached
        new_pre_assignment_available
        dropbox_invalid_access_token
        dropbox_insufficient_space
        ftp_auth_failure
        detected_preseizure_duplication
        pre_assignment_ignored_piece
        new_scanned_documents
        pre_assignment_delivery_errors
        mcf_document_errors
        pre_assignment_export
      ]
    )
  end
end