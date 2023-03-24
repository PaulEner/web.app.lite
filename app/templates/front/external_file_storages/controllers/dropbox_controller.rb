# frozen_string_literal: true
class ExternalFileStorages::DropboxController < FrontController
  skip_before_action :verify_authenticity_token, only: %w(webhook verify)
  skip_before_action :login_user!, only: %w(webhook verify)
  skip_before_action :load_user_and_role, only: %w(webhook verify)
  skip_before_action :verify_suspension, only: %w(webhook verify)
  skip_before_action :verify_if_active, only: %w(webhook verify)

  before_action :verify_authorization, only: %w(authorize_url callback)
  before_action :load_dropbox, only: %w(authorize_url callback)
  before_action :load_authenticator, only: %w(authorize_url callback)

  def webhook
    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), Rails.application.credentials[Rails.env.to_sym][:dropbox_api][:secret], request.body.read)

    if signature == request.headers['X-Dropbox-Signature']
      DropboxBasic.where(dropbox_id: params[:delta][:users]).update_all(changed_at: Time.now)
      render status: :ok, plain: 'OK'
    else
      #Tmp Oversight: dropbox webhook
      System::Log.info('dropbox_webhook', "[Webhook - signature] #{signature}")
      System::Log.info('dropbox_webhook', "[Webhook - header] #{request.headers['X-Dropbox-Signature']} - match : #{(signature == request.headers['X-Dropbox-Signature']).to_s}")

      log_document = {
        subject: "[DropboxesController] webhook dropboxes unauthorized",
        name: "DropboxesController",
        error_group: "[dropboxes-controller] webhook dropboxes",
        erreur_type: "Webhook - Dropboxes",
        date_erreur: Time.now.strftime('%Y-%M-%d %H:%M:%S'),
        more_information: {
          signature: signature,
          header: request.headers['X-Dropbox-Signature']
        }
      }
      ErrorScriptMailer.error_notification(log_document).deliver

      render status: :unauthorized, plain: 'Unauthorized.'
    end
  end

  def verify
    render(plain: params[:challenge]) && return if params[:challenge].present?
    render plain: 'challenge parameter is missing'
  end

  def authorize_url
    redirect_to @authenticator.authorize_url(redirect_uri: callback_dropbox_url)
  end

  def callback
    if params[:error] == 'access_denied'
      flash[:error] = "Vous avez refusé l'accès à votre compte Dropbox."
    else
      begin
        auth_bearer = @authenticator.get_token params[:code], redirect_uri: callback_dropbox_url
        begin
          if @dropbox.is_configured?
            DropboxApi::Client.new(@dropbox.access_token).revoke_token
          end
        rescue DropboxApi::Errors::HttpError => e
          raise unless e.message.match /HTTP 401/
        end

        @dropbox.update(
          access_token: auth_bearer.token,
          dropbox_id: auth_bearer.params['uid'],
          delta_cursor: nil,
          delta_path_prefix: nil,
          changed_at: Time.now
        )

        flash[:success] = 'Votre compte Dropbox a été configuré avec succès.'
      rescue StandardError => e
        if e.class.name == 'OAuth2::Error'
          flash[:error] = "Impossible de configurer votre compte Dropbox. L'autorisation a peut être expiré."
        else
          flash[:error] = e.to_s
        end
      end
    end

    redirect_to profiles_path
  end

  private

  def verify_authorization
    unless @user.find_or_create_external_file_storage.is_dropbox_basic_authorized?
      flash[:error] = "Vous n'êtes pas autorisé à utiliser Dropbox."
      redirect_to profiles_path
    end
  end

  def load_authenticator
    @authenticator = DropboxApi::Authenticator.new(Rails.application.credentials[Rails.env.to_sym][:dropbox_api][:key], Rails.application.credentials[Rails.env.to_sym][:dropbox_api][:secret])
  end

  def load_dropbox
    @dropbox = @user.find_or_create_external_file_storage.dropbox_basic
  end
end