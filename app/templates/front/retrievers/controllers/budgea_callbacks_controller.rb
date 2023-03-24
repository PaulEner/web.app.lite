# frozen_string_literal: true
class Retrievers::BudgeaCallbacksController < ApiController
  skip_before_action :authenticate_current_user
  skip_before_action :verify_rights

  def user_synced
    if params['user'].present? && params["connections"].present?
      retriever = Retriever.where(budgea_id: params["connections"][0]['id']).first
      DataProcessor::RetrievedData.delay(queue: :high).execute(params, "USER_SYNCED", retriever.user) if retriever

      render plain: '', status: :ok
    else
      render json: { success: false, error: 'Erreur de données' }, status: 400
    end
  end

  def user_deleted
    if params["id"].present?
      budgea_account = BudgeaAccount.where(identifier: params["id"]).first

      DataProcessor::RetrievedData.delay(queue: :high).execute(params, "USER_DELETED", budgea_account.try(:user))

      render plain: '', status: :ok
    else
      render json: { success: false, error: 'Erreur de données' }, status: 400
    end
  end

  def connection_deleted
    if params["id_user"].present? && params['id'].present?
      retriever = Retriever.where(budgea_id: params['id']).first
      DataProcessor::RetrievedData.delay(queue: :high).execute(params, "CONNECTION_DELETED", retriever.user) if retriever

      render plain: '', status: :ok
    else
      render json: { success: false, error: 'Erreur de données' }, status: 400
    end
  end

  def fetch_webauth_url
    if params[:id].present? && params[:user_id].present?
      user = User.find params[:user_id]

      budgea_account = user.budgea_account
      redirect_uri = retriever_callback_url
      base_uri = "https://#{Budgea.config.domain}/2.0"
      client_id = Budgea.config.client_id

      target = "id_connection=#{params[:id]}"
      target = "id_connector=#{params[:id]}" if params[:is_new].to_s == 'true'

      secure_token = params[:secure_token].present? ? "&token=#{params[:secure_token]}" : ''

      url = "'#{base_uri}/webauth?#{target}&redirect_uri=#{redirect_uri}&client_id=#{client_id}&state=#{params[:state]}#{secure_token.to_s}' -H 'Authorization: Bearer #{budgea_account.access_token}'"

      html_dom = `curl #{url}`

      render json: { success: true, html_dom: html_dom }, status: 200
    else
      render json: { success: false, error: 'Erreur de service interne' }, status: 200
    end
  end

  def callback
    authorization = request.headers['Authorization']

    if authorization.present? && params['user'] #callback for retrieved data
      access_token = authorization.split[1]
      account = BudgeaAccount.where(identifier: params['user']['id']).first

      if account && (account.access_token == access_token || account.identifer.to_i == 210)
        retrieved_data = RetrievedData.new
        retrieved_data.user = account.user
        retrieved_data.json_content = params.except(:controller, :action)
        retrieved_data.state = 'error'
        retrieved_data.error_message = 'pending webhook'
        retrieved_data.save
        render plain: '', status: :ok
      else
        render plain: '', status: :unauthorized
      end
    else #callback for webauth
      if params[:error_description].present? && params[:error_description] != 'None'
        flash[:error] = params[:error_description].presence || 'Id connection not found'

        redirect_to retrievers_path
      elsif params[:id_connection]
        local_params = JSON.parse(Base64.decode64(params[:state])).with_indifferent_access
        remote_params = { id: params[:id_connection], last_update: Time.now.to_s }

        user = User.find local_params[:user_id]
        if user
          Retriever::CreateBudgeaConnection.new(user, local_params, remote_params).execute
          flash[:success] = 'Paramétrage effectué'
        else
          flash[:error] = 'Modification non autorisée'
        end

        redirect_to retrievers_path
      else
        render plain: '', status: :unauthorized
      end
    end
  end
end