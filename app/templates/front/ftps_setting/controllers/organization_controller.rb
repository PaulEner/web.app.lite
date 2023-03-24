# frozen_string_literal: true

class FtpsSetting::OrganizationController < OrganizationController
  before_action :verify_rights
  before_action :load_by_type

  def update
    _params = ftps_params.delete_if { |k, _| k == 'password' }

    is_connection_params_changed = false
    is_connection_params_changed = true if @object.host != _params[:host]
    is_connection_params_changed = true if @object.port != _params[:port].to_i
    is_connection_params_changed = true if @object.login != _params[:login]

    if ftps_params[:password].present? || is_connection_params_changed
      @object.assign_attributes password: ftps_params[:password]
    end

    @object.assign_attributes _params

    result = @object.valid?
    is_verified = false
    if result && @object.password_changed?
      if params[:type] == 'ftp'
        result = Ftp::VerifySettings.new(@object, current_user.code).execute
      else
        result = Sftp::VerifySettings.new(@object, current_user.code).execute
      end
      is_verified = true
    end
    if result
      @object.is_configured = true if is_verified
      @object.save
      json_flash[:success] = "Vos paramètres #{params[:type].upcase} ont été modifiés avec succès."
    else
      json_flash[:error] = @object.reload.error_message
    end

    render json: { json_flash: json_flash }, status: 200
  end

  def destroy
    @object.reset_info
    json_flash[:success] = "Vos paramètres #{params[:type].upcase} ont été réinitialisés."

    render json: { json_flash: json_flash }, status: 200
  end

  def fetch_now
    if @object.configured?
      if params[:type] == 'ftp'
        FileImport::Ftp.delay.process @object.id
      else
        FileImport::Sftp.delay.process @object.id
      end
      json_flash[:notice] = "Tentative de récupération des documents depuis votre #{params[:type].upcase} en cours."
    else
      json_flash[:error] = "Votre #{params[:type].upcase} n'a pas été configuré correctement."
    end

    render json: { json_flash: json_flash }, status: 200
  end

  private

  def verify_rights
    unless @user.leader?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to organization_path(@organization)
    end
  end

  def load_by_type
    if params[:type] == 'ftp'
      @object = @organization.ftp
      @object ||= @organization.ftp = Ftp.create(organization: @organization, path: 'OUTPUT/:code/:year:month/:account_book/')
    else
      @object = @organization.sftp
      @object ||= @organization.sftp = Sftp.create(organization: @organization, path: 'OUTPUT/:code/:year:month/:account_book/')
    end
  end

  def ftps_params
    params.require(params[:type].to_sym).permit(:host, :port, :is_passive, :login, :password, :root_path, :path)
  end
end
