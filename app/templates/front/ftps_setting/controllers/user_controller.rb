# frozen_string_literal: true
class FtpsSetting::UserController < FrontController
  before_action :verify_authorization
  before_action :load_by_type

  prepend_view_path('app/templates/front/ftps_setting/views')

  def edit; end

  def update
    @ftps.assign_attributes(_params)
    if @ftps.valid? && Ftp::VerifySettings.new(@ftps, current_user.code).execute
      @ftps.is_configured = true
      @ftps.save
      flash[:success] = 'Votre compte FTP a été configuré avec succès.'
      redirect_to profiles_path
    else
      flash[:error] = @ftps.reload.error_message
      render :edit
    end
  end

  def destroy
    @ftps.reset_info
    flash[:success] = 'Vos paramètres FTP ont été réinitialisé.'
    redirect_to profiles_path
  end

  private

  def verify_authorization
    unless @user.find_or_create_external_file_storage.is_ftp_authorized?
      flash[:error] = "Vous n'êtes pas autorisé à utiliser FTP."
      redirect_to profiles_path
    end
  end

  def load_by_type
    if params[:type] == 'ftp'
      @ftps = @user.find_or_create_external_file_storage.ftp
    else
      @ftps = @user.find_or_create_external_file_storage.sftp
    end
  end

  def _params
    params.require(params[:type]).permit(:host, :port, :is_passive, :login, :password)
  end
end