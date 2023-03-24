# frozen_string_literal: true
class ExternalFileStorages::AuthorizationController < OrganizationController
  before_action :load_someone
  before_action :verify_rights

  prepend_view_path('app/templates/front/external_file_storages/views')

  # PUT /account/organizations/:organization_id/collaborators/:collaborator_id/file_storage_authorizations
  def update
    # @someone.update(user_params)
    efs = @someone.external_file_storage
    if params['dropbox_basic']
      c_value = efs.is_dropbox_basic_authorized
      efs.is_dropbox_basic_authorized = c_value ? 0 : 1
    elsif params['google_docs']
      c_value = efs.is_google_docs_authorized
      efs.is_google_docs_authorized = c_value ? 0 : 1
    elsif params['ftp']
      c_value = efs.is_ftp_authorized
      efs.is_ftp_authorized = c_value ? 0 : 1
    elsif params['sftp']
      c_value = efs.is_sftp_authorized
      efs.is_sftp_authorized = c_value ? 0 : 1
    elsif params['box']
      c_value = efs.is_box_authorized
      efs.is_box_authorized = c_value ? 0 : 1
    end
    
    if efs.save
      json_flash[:success] = 'Modifié avec succès.'
    else
      json_flash[:error] = errors_to_list efs
    end
    
    render json: { json_flash: json_flash }, status: 200
  end

  private

  def verify_rights
    if !current_user.is_admin || @someone.nil? || @someone.inactive?
      json_flash[:error] = t('authorization.unessessary_rights')

      render json: { json_flash: json_flash }, status: 200
    end
  end

  def load_someone
    @someone = nil
    if params[:user_id]
      @someone = User.where(id: params[:user_id]).first
    end
  end
end