# frozen_string_literal: true
class RetrieverParameters::BanksParamsController < RetrieverController
  before_action :verif_account
  before_action :load_bank_account, only: %w[edit update bank_activation download_cedricom_mandate create_cedricom_mandate]
  prepend_view_path('app/templates/front/retriever_parameters/views')

  def index
    @bank_accounts = []

    if params[:bank_account_contains].present?
      @bank_accounts = @account.bank_accounts.used
      @bank_accounts = @bank_accounts.where('bank_name LIKE ?', "%#{search_by('bank_name')}%") if search_by('bank_name').present?
      @bank_accounts = @bank_accounts.where('name LIKE ?', "%#{search_by('name')}%") if search_by('name').present?
      @bank_accounts = @bank_accounts.where('number LIKE ?', "%#{search_by('number')}%") if search_by('number').present?
      @bank_accounts = @bank_accounts.where('journal LIKE ?', "%#{search_by('journal')}%") if search_by('journal').present?
      @bank_accounts = @bank_accounts.where('accounting_number LIKE ?', "%#{search_by('accounting_number')}%") if search_by('accounting_number').present?
    end

    render partial: 'banks_params', locals: { bank_accounts: @bank_accounts }
  end

  def new
    @bank_account = BankAccount.new
    render partial: 'new'
  end

  def create
    @bank_account = BankAccount.create(bank_account_params)

    if @bank_account.persisted?
      if @bank_account.ebics_enabled_starting
        
      end

      success = true
      message = 'Créé avec succès.'
    else
      success = false
      message = errors_to_list @bank_account
    end

    render json: { success: success, message: message }, status: 200
  end


  def edit
    render partial: 'edit'
  end

  def update
    @bank_account.assign_attributes(bank_setting_params)
    changes = @bank_account.changes.dup
    @bank_account.is_for_pre_assignment = true
    start_date_changed = @bank_account.start_date_changed?

    if @bank_account.save
      if start_date_changed && @bank_account.start_date.present?
        @bank_account.operations.not_duplicated.where('is_locked = ? and is_coming = ? and date >= ?', true, false, @bank_account.start_date).update_all(is_locked: false)
      end

      PreAssignment::UpdateAccountNumbers.delay.execute(@bank_account.id.to_s, changes)
      success = true
      message = "Modifié avec succès."
    else
      success = false
      message = errors_to_list @bank_account
    end

    render json: { success: success, message: message.to_s }, status: 200
  end

  def bank_activation
    @bank_account.update(is_to_be_disabled: (params[:type] == 'disable'))

    if params[:type] == 'disable'
      message = "sera désactivé le mois prochain."
    else
      message = "est maintenant actif."
    end

    if @bank_account.save
      render json: { success: true, message: "Compte bancaire : #{@bank_account.number} #{message}" }, status: 200
    else
      render json: { success: false, message: "Impossible de supprimer le compte bancaire : #{@bank_account.number}" }, status: 200
    end
  end

  def download_cedricom_mandate
    if @bank_account.cedricom_original_mandate.attached?
      send_data @bank_account.cedricom_original_mandate.download, filename: @bank_account.cedricom_original_mandate.filename.to_s, content_type: @bank_account.cedricom_original_mandate.content_type
    end
  end

  def create_cedricom_mandate
    if Cedricom::CreateMandate.new(@bank_account).execute
      flash[:success] = "Mandat créé avec succès"
    else
      flash[:error] = "Erreur technique, veuillez-vous rapprocher du support"
    end

    redirect_to retriever_parameters_path
  end

  private

  def bank_setting_params
    params.require(:bank_account).permit(:number, :journal, :currency, :accounting_number, :foreign_journal, :temporary_account, :start_date, :lock_old_operation, :permitted_late_days, :ebics_enabled_starting)
  end

  def bank_account_params
    params.require(:bank_account).permit(
      :user_id,
      :bank_name,
      :is_used,
      :name,
      :type_name,
      :number,
      :bic,
      :journal,
      :currency,
      :foreign_journal,
      :accounting_number,
      :temporary_account,
      :start_date,
      :lock_old_operation,
      :permitted_late_days,
      :api_name,
      :ebics_enabled_starting,
      :cedricom_signed_mandate,
      :original_currency => [:id, :symbol, :prefix, :crypto, :precision, :marketcap, :datetime, :name])
  end

  def load_bank_account
    @bank_account = @account.bank_accounts.find(params[:id])
  end

  def search_by(field)
    params[:bank_account_contains].try(:[], field)
  end
end