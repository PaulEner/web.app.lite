# frozen_string_literal: true
class Admin::Organizations::MainController < OrganizationController
  prepend_view_path('app/templates/back/organizations/views')
  layout ('back/layout')

  skip_before_action :verify_if_active
  skip_before_action :verify_suspension
  skip_before_action :verify_if_a_collaborator
  skip_before_action :load_organization
  skip_before_action :load_recent_notifications

  before_action :apply_membership
  before_action :load_action_organization, only: ['suspend', 'unsuspend', 'deactivate']
  before_action :verify_admin_rights

  # GET /admin/organizations
  def index
    @organizations = ::Organization.search(search_terms(params[:organization_contains])).order(sort_column => sort_direction).page(params[:page]).per(100)
    @without_address_count = Organization.joins(:addresses).where('addresses.is_for_billing =  ?', true).count
    @debit_mandate_not_configured_count = DebitMandate.not_configured.count
  end

  # GET /admin/organizations/new
  def new
    @organization = Organization.new

    render partial: 'new'
  end

  # POST /admin/organizations/create
  def create
    @organization = Organization::Create.new(organization_params).execute

    if @organization.persisted?
      json_flash[:success] = 'Créé avec succès.'      
    else
      flash[:error] = errors_to_list @organization
    end

    render json: { json_flash: json_flash, url: admin_organizations_path }, status: 200
  end

  # PUT /account/organizations/:id/suspend
  def suspend
    @organization.update_attribute(:is_suspended, true)
    flash[:success] = 'Suspendu avec succès.'
    redirect_to admin_organizations_path
  end

  # PUT /account/organizations/:id/unsuspend
  def unsuspend
    @organization.update_attribute(:is_suspended, false)
    flash[:success] = 'Activé avec succès.'
    redirect_to admin_organizations_path
  end

  # PUT /account/organizations/:id/deactivate
  def deactivate
    Organization::Deactivate.new(@organization.id.to_s).execute
    @organization.update_attribute(:is_active, false)
    flash[:success] = 'Désactivé avec succès.'

    redirect_to admin_organizations_path
  end

  private

  def verify_admin_rights
    redirect_to root_url unless current_user.is_admin
  end

  def organization_params
    if current_user.is_admin
      params.require(:organization).permit(
        :name,
        :code,
        :is_detail_authorized,
        :is_test,
        :is_pre_assignment_date_computed,
        :is_operation_processing_forced,
        :is_operation_value_date_needed,
        :is_duplicate_blocker_activated,
        :preseizure_date_option,
        :subject_to_vat,
        :invoice_mails,
        :jefacture_api_key,
        :specific_mission,
        :default_banking_provider,
        { :quadratus_attributes => %i[id is_used auto_deliver] },
        { :coala_attributes => %i[id is_used auto_deliver] },
        { :cegid_attributes => %i[id is_used auto_deliver] },
        { :fec_agiris_attributes => %i[id is_used auto_deliver] },
        { :fec_acd_attributes => %i[id is_used auto_deliver] },
        { :csv_descriptor_attributes => %i[id is_used auto_deliver] },
        { :exact_online_attributes => %i[id is_used auto_deliver] },
        { :my_unisoft_attributes => %i[id is_used auto_deliver] }
      )
    end
  end

  def sort_column
    params[:sort] || 'name'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'asc'
  end
  helper_method :sort_direction

  def load_action_organization
    @organization = Organization.find params[:id]
  end

end