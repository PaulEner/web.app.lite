# frozen_string_literal: true
class ReminderEmails::MainController < OrganizationController
  before_action :verify_rights
  before_action :load_reminder_email, except: %w[index new create]

  prepend_view_path('app/templates/front/reminder_emails/views')

  def index
    @reminder_emails = @organization.reminder_emails.order(created_at: :desc).page(params[:page]).per(params[:per_page])
  end

  def show; end

  # GET /organizations/:organization_id/reminder_emails/new
  def new
    @reminder_email = ReminderEmail.new

    if params[:template].present?
      template = @organization.reminder_emails.find params[:template]

      @reminder_email.name    = template.name
      @reminder_email.period  = template.period
      @reminder_email.subject = template.subject
      @reminder_email.content = template.content
      @reminder_email.delivery_day = template.delivery_day
    end

    render partial: 'form'
  end

  # POST # GET /organizations/:organization_id/reminder_emails
  def create
    @reminder_email = ReminderEmail.new reminder_email_params

    @reminder_email.organization = @organization

    if @reminder_email.save
      json_flash[:success] = 'Créé avec succès.'
    else
      json_flash[:error] = errors_to_list @reminder_email
    end

    render json: { json_flash: json_flash }, status: 200
  end

  # GET /organizations/:organization_id/reminder_emails/:id/edit
  def edit
    render partial: 'form'
  end

  # PUT /organizations/:organization_id/reminder_emails/:id
  def update
    if @reminder_email.update(reminder_email_params)
      json_flash[:success] = 'Modifié avec succès.'
    else
      json_flash[:error] = errors_to_list @reminder_email
    end

    render json: { json_flash: json_flash }, status: 200
  end

  # DELETE /organizations/:organization_id/reminder_emails/:id
  def destroy
    @reminder_email.destroy

    json_flash[:success] = 'Supprimé avec succès.'

    render json: { json_flash: json_flash }, status: 200
  end

  # POST /organizations/:organization_id/reminder_emails/:id/deliver
  def deliver
    result = @reminder_email.deliver

    if result.is_a?(TrueClass) || result.is_a?(FalseClass) && result == true
      json_flash[:success] = 'Envoyé avec succès.'
    elsif result.is_a?(Array) && result.empty?
      json_flash[:notice] = 'Les mails ont déjà été envoyés.'
    else
      json_flash[:error] = 'Une erreur est survenu lors de la livraison.'
    end

    render json: { json_flash: json_flash }, status: 200
  end

  private

  def verify_rights
    unless @user.is_admin || (@user.is_prescriber && @user.organization == @organization)
      flash[:error] = t('authorization.unessessary_rights')

      redirect_to organization_path(@organization)
    end
  end

  def load_reminder_email
    @reminder_email = @organization.reminder_emails.find params[:id]
  end

  def reminder_email_params
    params.require(:reminder_email).permit(
      :name,
      :delivery_day,
      :period,
      :subject,
      :content
    )
  end
end