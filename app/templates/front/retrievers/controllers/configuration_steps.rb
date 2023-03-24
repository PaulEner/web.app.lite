# frozen_string_literal: true
class Retrievers::ConfigurationStepsController < RetrieverController
  before_action :load_retriever, only: %i[destroy trigger retriever_infos update_budgea_error_message]
  before_action :verif_account

  prepend_view_path('app/templates/front/retrievers/views')

  def api_config
    bi_config = {
      url: "https://#{Budgea.config.domain}/2.0",
      c_id: Budgea.config.client_id,
      c_ps: Budgea.config.client_secret,
      c_ky: Budgea.config.encryption_key ? Base64.encode64(Budgea.config.encryption_key.to_json.to_s) : '',
      proxy: Budgea.config.proxy
    }.to_json
    bi_config = Base64.encode64(bi_config.to_s)

    render json: { id: (params[:q] == 'conf')? bi_config : '1234567' }, status: 200
  end

  def account_infos
    if params[:q] != 'conf'
      render json: { message: nil }, status: 200
    else
      user = (params[:user_id].present?)? User.find(params[:user_id]) : @account

      user_token = user.get_authentication_token
      bi_token = user.try(:budgea_account).try(:access_token)

      journals = user.account_book_types.map do |journal|
        "#{journal.id}: #{journal.name}"
      end.join('_')

      contact_company = user.company
      contact_name = user.last_name
      contact_first_name = user.first_name
    end

    render json: { user_token: user_token.to_s, bi_token: bi_token.to_s, journals: journals.to_s, contact_company: contact_company.to_s, contact_name: contact_name.to_s, contact_first_name: contact_first_name.to_s }, status: 200
  end

  def budgea_step2
    @retriever = Retriever.where(id: params[:id] || 0).first
    @connector = params[:connector]

    render partial: 'step2'
  end

  def budgea_step3
    @connector = params[:connector]

    render partial: 'step3'
  end

  def budgea_step4
    ### params[local_accounts] is a collection of api_ids
    retriever = Retriever.where(budgea_id: params[:budgea_id] || 0).first
    Retriever.delay_for(1.minutes, queue: :high).resume(retriever.id, false) if retriever

    render partial: 'step4', locals: { remote_accounts: CustomUtils.arrStr_to_array(params[:remote_accounts]), local_accounts: CustomUtils.arrStr_to_array(params[:local_accounts]) }
  end

  def create
    Retriever::CreateBudgeaConnection.new(@account, params[:data_local], params[:data_remote]).execute
    render json: { success: true }, status: 200
  end

  def create_budgea_user
    account_exist = @account.try(:budgea_account).try(:access_token).present?
    success       = false

    if !account_exist && params[:data_local][:auth_token].present?
      budgea_account              = @account.try(:budgea_account) || BudgeaAccount.new
      budgea_account.identifier   = params[:data_remote]['0'][:id_user]
      budgea_account.user         = @account
      budgea_account.access_token = params[:data_local][:auth_token]
      success                     = budgea_account.save
    end

    error_message = success ? '' : 'Impossible de créer un compte budget insight'
    render json: { success: success, error_message: error_message }, status: 200
  end

  def create_bank_accounts
    if Transaction::CreateBankAccount.execute(@account, (params[:accounts].try(:to_unsafe_h) || []), params[:options])
      render json: { success: true }, status: 200
    else
      render json: { success: false, error_message: 'Impossible de synchroniser un compte bancaire' }, status: 200
    end
  end

  def my_accounts
    if params[:data_local][:connector_id].present?
      banks = @account.retrievers.where(budgea_id: params[:data_local][:connector_id]).try(:first).try(:bank_accounts).try(:used)
    else
      banks = @account.retrievers.linked.map { |r| r.try(:bank_accounts).try(:used) }.compact.flatten
    end

    if params[:data_local][:full_result].present? && params[:data_local][:full_result] == 'true'
      accounts = banks
    else
      accounts = banks.collect(&:api_id) if banks
    end

    render json: { success: true, accounts: accounts || [] }, status: 200
  end

  def add_infos
    retriever = @account.retrievers.where(budgea_id: params[:data_local][:budgea_id]).first
    sleep 2
    retriever.resume_me

    render json: { success: true }, status: 200
  end

  def retriever_infos
    user = @retriever.user
    bi_token = user.try(:budgea_account).try(:access_token)

    if params[:remote_method] == 'DELETE' && !@retriever.budgea_id.present?
      success = false
      if @retriever.destroy_connection
        success = Retriever::DestroyBudgeaConnection.execute(@retriever)
      end
      render json: { success: success, deleted: success, bi_token: bi_token, budgea_id: nil }, status: 200
    else
      render json: { success: true, bi_token: bi_token, budgea_id: @retriever.budgea_id }, status: 200
    end
  end

  def destroy
    Retriever::DestroyBudgeaConnection.execute(@retriever) if params[:success] == 'true' && @retriever.destroy_connection

    render json: { success: true }, status: 200
  end

  def trigger
    if @retriever.budgea_id
      @retriever.sync_at = Time.parse(params[:data_remote][:last_update]) if params[:data_remote].present? && params[:data_remote][:last_update].present?

      @retriever.save

      @retriever.update_state_with params_connection

      #TEMP FIX: reload state from resume after trigger
      sleep(2)
      @retriever.reload.resume_me()

      render json: { success: true }, status: 200
    else
      render json: { success: false }, status: 200
    end
  end

  def update_budgea_error_message
    initial_state = @retriever.to_json

    @retriever.update_state_with params_connection

    sleep(5)

    render json: { success: true }, status: 200
  end

  private
  
  def params_connection
    _params_tmp = params.dup

    if params[:connections].present?
      params[:connections].each do |k,v|
        _params_tmp.merge!(k=>v) if k != 'id'
      end

      _params_tmp.merge!("connections" => '')
    end

    _params_tmp.merge!("source"=>"RetrieversController")

    _params_tmp
  end

  def load_retriever
    @retriever = Retriever.find params[:id]
  end
end