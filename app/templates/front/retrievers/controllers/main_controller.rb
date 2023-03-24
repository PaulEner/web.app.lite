# frozen_string_literal: true
class Retrievers::MainController < RetrieverController
  skip_before_action :verify_rights, only: %w[subscription]
  before_action :verif_account, except: %w[index subscription edit export_connector_to_xls get_connector_xls new_internal api_config]
  before_action :get_banking_provider, except: %w[subscription]
  before_action :load_retriever, except: %w[index subscription list new export_connector_to_xls get_connector_xls new_internal create api_config]
  before_action :verify_retriever_state, except: %w[index subscription list new export_connector_to_xls get_connector_xls new_internal edit_internal create api_config]
  before_action :load_retriever_edition, only: %w[new edit]
  before_action :load_params, only: %w[index]

  prepend_view_path('app/templates/front/retrievers/views')

  def index
    retrievers =  if @account
                    @account.retrievers
                  else
                    Retriever.where(user: accounts)
                  end

    @retrievers = Retriever.search_for_collection(retrievers, search_terms({ name: params[:name], state: params[:state] }))
                           .joins(:user)
                           .order("#{sort_column} #{sort_direction}")
                           .page(params[:page])
                           .per(20)

    @retrievers.last.try(:created_at) #WORKAROUND: @retrievers bugs if this line is not present
  end

  def subscription;  end

  def list; end

  def new
    if params[:create] == '1'
      flash[:success] = 'Édition terminée'
      redirect_to retrievers_path
    end
  end

  def new_internal
    @retriever = Retriever.new
    @connectors = Connector.idocus

    render partial: 'form_internal'
  end

  def create
    @retriever = Retriever.new(retriever_params)

    @retriever.user         = @account
    @retriever.service_name = @retriever.connector.try(:name)
    @retriever.capabilities = @retriever.connector.try(:capabilities)

    if @retriever.save
      json_flash[:success] = 'Automate créer avec succès'
    else
      json_flash[:error] = errors_to_list @retriever
    end

    render json: { json_flash: json_flash }, status: 200
  end

  def edit; end

  def edit_internal
    @retriever = Retriever.find(params[:id])
    @connectors = Connector.idocus

    render partial: 'form_internal'
  end

  def update
    @retriever = Retriever.find(params[:id])

    if @retriever.update(retriever_params)
      json_flash[:success] = 'Automate mis à jours avec succès'
    else
      json_flash[:error] = errors_to_list @retriever
    end

    render json: { json_flash: json_flash }, status: 200
  end

  def export_connector_to_xls
    array_document = params[:documents].to_s.split(/\;/)
    array_bank     = params[:banks].to_s.split(/\;/)
    file           = nil

    CustomUtils.mktmpdir('retrievers_controller', '/nfs/tmp', false) do |dir|
      file           = OpenStruct.new({path: "#{dir}/list_des_automates.xls", close: nil})
      xls_data       = []

      max_length     = array_document.size > array_bank.size ? array_document.size : array_bank.size

      tmp_data       = {}
      tmp_data[:documents] = "Documents"
      tmp_data[:banques]   = "Banques"
      xls_data << OpenStruct.new(tmp_data)

      max_length.times do |i|
        tmp_data = {}
        tmp_data[:documents] = array_document[i] if array_document[i].present?
        tmp_data[:banques]   = array_bank[i]     if array_bank[i].present?
        next if !array_document[i].present? && !array_bank[i].present?
        xls_data << OpenStruct.new(tmp_data)
      end

      ToXls::Writer.new(xls_data, columns: [:documents, :banques], headers: false).write_io(file.path)

      FileUtils.delay_for(5.minutes, queue: :high).remove_entry(dir, true)
    end

    render json: { key: Base64.encode64(file.path.to_s), status: :ok }
  end

  def get_connector_xls
    file_path = Base64.decode64(params[:key])

    send_data File.read(file_path), filename: 'liste_automates.xls'
  end

  private

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction

  def load_retriever
    if @account
      @retriever = @account.retrievers.find params[:id]
    else
      @retriever = Retriever.find params[:id]
      @account = @retriever.user
      session[:retrievers_account_id] = @account.id
    end
  end

  def verify_retriever_state
    is_ok = false

    if action_name.in? %w[edit update]
      if @retriever.ready? || @retriever.error? || @retriever.waiting_additionnal_info?
        is_ok = true
      end
    end

    unless is_ok
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to retrievers_path
    end
  end

  def load_retriever_edition
    @user_token = @account.get_authentication_token
    @bi_token = @account.try(:budgea_account).try(:access_token)
    @journals = @account.account_book_types.map do |journal|
      "#{journal.id}:#{journal.name}"
    end.join('_')
    @contact_company = @account.company
    @contact_name = @account.last_name
    @contact_first_name = @account.first_name
  end

  def pattern_index
    return '[0-9]' if params[:index] == 'number'

    params[:index].to_s
  end

  def verif_account
    if @account.nil?
      redirect_to retrievers_path
    end
  end

  def retriever_params
    params.require(:retriever).permit(:connector_id, :user_id, :journal_id, :login, :password, :name, :connector_id)
  end

  def get_banking_provider
    @is_specific_mission = @user.organization.specific_mission

    return false if not @account

    @is_budgea = @account.banking_provider == 'budget_insight'
    @is_bridge = @account.banking_provider == 'bridge'
  end

  def load_params
    @_params = params[:_ext].present? ? JSON.parse(Base64.decode64(params[:k])).with_indifferent_access : params
  end
end