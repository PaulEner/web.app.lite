# frozen_string_literal: true
class Invoices::MainController < OrganizationController
  prepend_view_path('app/templates/front/invoices/views')

  def show
    base_content
  end

  def download
    invoice    = BillingMod::Invoice.find params[:id] if params[:id].present?
    authorized = @user.leader?

    if invoice && invoice.organization == @organization && File.exist?(invoice.cloud_content_object.path) && authorized
      filename = File.basename invoice.cloud_content_object.path
      # type = invoice.content_content_type || 'application/pdf'
      # find a way to get active storage mime type
      type = 'application/pdf'
      send_file(invoice.cloud_content_object.path('', true), type: type, filename: filename, x_sendfile: true, disposition: 'inline')
    else
      render body: nil, status: 404
    end
  end

  def insert
    @invoice_setting = (params[:invoice_setting][:id].present?) ? BillingMod::InvoiceSetting.find(params[:invoice_setting][:id]) : BillingMod::InvoiceSetting.new()
    @invoice_setting.update(invoice_setting_params)
    @invoice_setting.organization = @organization
    @invoice_setting.user         = User.find_by_code params[:invoice_setting][:user_code]

    if @invoice_setting.save
      json_flash[:success] = (params[:invoice_setting][:id].present?) ? 'Modifié avec succès' : 'Ajout avec succès.'
    else
      json_flash[:error] = 'Enregistrement non valide, veuillez verifier les informations.'
    end

    render json: { json_flash: json_flash }, status: 200
  end

  def synchronize
    if params[:invoice_setting_id].present?
      invoice_setting = BillingMod::InvoiceSetting.find(params[:invoice_setting_id])

      if params[:invoice_setting_synchronize_contains][:period].present?
        period = (params[:invoice_setting_synchronize_contains][:period]).to_date

        json_flash[:success] = 'Synchronisation des factures en cours ...'

        BillingMod::InvoiceSetting.delay(queue: :high).invoice_synchronize(period, invoice_setting.id)
      end
    else
      json_flash[:error] = 'Synchronisation échouée, veuillez verifier les informations.'
    end

    render json: { json_flash: json_flash }, status: 200
  end


  def remove
    BillingMod::InvoiceSetting.find(params[:id]).destroy

    json_flash[:success] = 'Suppression avec succès.'

    render json: { json_flash: json_flash }, status: 200
  end

  private

  def base_content
    @invoices = @organization.invoices.order(created_at: :desc).page(params[:page]).per(params[:per_page])
    @invoice_settings = @organization.invoice_settings.order(created_at: :desc).page(params[:page]).per(params[:per_page])
    @invoice_setting = BillingMod::InvoiceSetting.new

    @synchronize_date = Date.today
    @synchronize_months = []
    (0..24).each do |month|
      @synchronize_months << [@synchronize_date.prev_month(month).strftime("%b %Y"), @synchronize_date.prev_month(month)]
    end
  end

  def invoice_setting_params
    params.require(:invoice_setting).permit(:user_code, :journal_code)
  end
end