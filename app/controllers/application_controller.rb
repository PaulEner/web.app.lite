# frozen_string_literal: true

class ApplicationController < ActionController::Base
  attr_accessor :json_flash

  protect_from_forgery

  helper_method :format_price, :format_price_00
  before_action :configure_permitted_parameters, only: [:login_user!]
  before_action :init_vars
  before_action :set_raven_context

  if %w[staging sandbox production].include?(Rails.env)
    before_action :redirect_to_https
  end
  #around_action :catch_error if %w[sandbox production test].include?(Rails.env)
  #around_action :log_visit

  def self.renderer_async_id
    begin
      @@renderer_async_id = @@renderer_async_id.to_i + 1
    rescue
      @@renderer_async_id = 1
    end

    @@renderer_async_id
  end


  def after_sign_in_path_for(resource_or_scope)
    # TODO : reactivate when paths are sanitized
    # if session[:targeted_path]
    #   path = session[:targeted_path]
    #   session[:targeted_path] = nil
    #   path
    # else
    case resource_or_scope
    when :user, User
      root_url
    when :admin
      admin_root_url
    else
      super
    end
    # end
  end

  def after_sign_out_path_for(_resource_or_scope)
    'https://www.idocus.com'
  end

  def login_user!
    unless current_user && request.path.match(%r{\A/users.*})
      # TODO : find a way to clean path
      session[:targeted_path] = request.path
    end
    authenticate_user!
  end

  def load_user(name = :@user)
    user = nil

    if current_user&.is_admin
      if request.path.match(%r{^/admin/})
        user = current_user
      else
        if params[:user_code].present?
          session.delete(:params_document_operation)
          session.delete(:params_document_piece)
        end

        if params[:user_code].present? || session[:user_code].present?
          user = User.includes(:options, :acd, :ibiza, :exact_online, :my_unisoft, :coala, :sage_gec, :cegid, :cogilog, :fec_agiris, :quadratus, :csv_descriptor, :organization).get_by_code(params[:user_code].presence || session[:user_code].presence)
          user ||= current_user
          prev_user_code = session[:user_code]
          session[:user_code] = if user == current_user
                                  nil
                                else
                                  params[:user_code].presence || session[:user_code].presence
                                end
        end
      end
    end

    user ||= current_user
    instance_variable_set name, user
  end

  def load_user_and_role(name = :@user)
    instance = load_user(name)
    if instance&.collaborator?
      collaborator = Collaborator.new(instance)
      yield(collaborator) if block_given?
      instance_variable_set name, collaborator
    end
  end

  def accounts
    return @accounts if @accounts

    @accounts = if @user
                  if @user.collaborator?
                    @user.customers.includes(:options).order(code: :asc)
                  elsif @user.is_guest
                    @user.accounts.includes(:options).order(code: :asc)
                  else
                    User.includes(:options).where(id: ([@user.id] + @user.accounts.map(&:id))).order(code: :asc)
                  end
                else
                  []
    end
  end
  helper_method :accounts

  def account_ids
    accounts.map(&:id)
  end
  helper_method :account_ids

  def present(object, klass = nil)
    klass ||= "#{object.class}Presenter".constantize
    klass.new(object)
  end

  def load_recent_notifications
    if @user
      @last_notifications = @user.notifications.order(is_read: :asc, created_at: :desc).limit(5)
    end
  end

  def all_packs
    Pack.where(owner_id: account_ids)
  end

  private

  def errors_to_list(object=nil)
    contents = ''

    if object
      name   = object.model_name.param_key
      errors = object.try(:errors).try(:messages) || []
      errors.each do |key, val|
        if key.match(/\./)
          label = t("simple_form.labels.#{key.to_s}")
        else
          label = t("simple_form.labels.#{name}.#{key.to_s}")
        end
        
        label = key.to_s if label.match(/translation missing/)
        contents += "<li class='errors_element'><span class='fs-6 italic'>#{label}: </span><span class='bold fs-6'>#{ val.join('; ') rescue val.to_s }</span></li>"
      end
    end

    "<ul class='errors_list'>#{contents}</ul>".html_safe
  end

  def json_flash=(index, data)
    @json_flash[index] = data
  end

  def init_vars
    @json_flash = {}
    #init renderer_async_id
    @@renderer_async_id = rand.to_s.split('.')[1]
  end

  def set_raven_context
    Raven.user_context(id: session[:current_user_id]) # or anything else in session
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end

  def search_terms(search_terms_from_parameters)
    @contains ||= {}
    if search_terms_from_parameters && @contains.blank?
      @contains = search_terms_from_parameters.delete_if do |_, value|
        if value.blank? && !value.is_a?(Hash)
          true
        elsif value.is_a? Hash
          value.delete_if { |_k, v| v.blank? }
          value.blank?
        else
          false
        end
      end
    end
    @contains
  end
  helper_method :search_terms

  def format_price_with_dot(price_in_cents)
    format('%0.2f', (price_in_cents.round / 100.0))
  end

  def format_price_00(price_in_cents)
    format_price_with_dot(price_in_cents).tr('.', ',')
  end

  def format_price(price_in_cents)
    format_price_00(price_in_cents).gsub(/,00/, '')
  end

  def current_user
    @current_user ||= super && User.includes(:options, :acd, :ibiza, :exact_online, :my_unisoft, :coala, :sage_gec, :cegid, :fec_agiris, :quadratus, :csv_descriptor, :organization).find(@current_user.id)
  end

  protected

  def redirect_to_https
    if !request.ssl? && !request.path.match(%r{(^/dematbox/|debit_mandate_notify)})
      url = request.url.gsub('http', 'https')
      redirect_to(url)
    end
  end

  def catch_error
    yield
  rescue ActionController::RoutingError,
         AbstractController::ActionNotFound,
         ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { render '/404', status: :not_found, layout: (@user ? 'front/layouts/layout' : 'error') }
      format.json { render json: { error: 'Not Found' }, status: :not_found }
    end
  rescue Budgea::Errors::ServiceUnavailable => e
    respond_to do |format|
      format.html { render '/503', status: :service_unavailable, layout: 'front/layouts/layout' }
      format.json { render json: { error: 'Service Unavailable' }, status: :service_unavailable }
    end
  rescue StandardError => e
    respond_to do |format|
      format.html { render '/500', status: :internal_server_error, layout: (@user ? 'front/layouts/layout' : 'error') }
      format.json { render json: { error: 'Internal Server Error' }, status: :internal_server_error }
    end
  end

  def authenticate_admin_user!
    authenticate_user!
    unless current_user&.is_admin
      flash[:error] = "Vous n'avez pas accès à cette page!"
      redirect_to root_path
    end
  end

  def log_visit
    unless request.path.match('(dematbox|system|assets|num|preview)') || !params[:action].in?(%w[index show]) || (controller_name == 'retrievers' && params[:part].present?) || controller_name == 'compta'
      unless current_user&.is_admin
        event = Event.new
        event.action      = 'visit'
        event.target_name = request.path
        event.target_type = 'page'
        event.user        = current_user
        event.path        = request.path
        event.ip_address  = request.remote_ip
        event.save
      end
    end
    yield
  end

  def organizations_suspended?
    if @user.class == Collaborator
      @user&.organizations_suspended?
    else
      @user&.organization&.is_suspended
    end
  end
  helper_method :organizations_suspended?

  def true_user
    @user.class == Collaborator ? @user.user : @user
  end
  helper_method :true_user

  def verify_if_active
    if !organizations_suspended? && @user&.inactive?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to documents_path
    end
  end

  def verify_suspension
    if controller_path == 'suspended/main'
      redirect_to root_path unless organizations_suspended?
    elsif organizations_suspended?
      unless ((controller_path == 'organizations/main' && action_name == 'show')) && @user.leader?
        redirect_to suspended_path
      end
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: %i[email password])
  end
end
