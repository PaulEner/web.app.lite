class FrontController < ApplicationController
  XHR_TOKEN  = 'dHkgbnkgdG9rZW4gYW5sZSBhamF4'
  before_action :login_user!
  before_action :load_user_and_role
  before_action :verify_suspension
  before_action :verify_if_active
  # before_action :check_xhr_token


  layout :define_layout

  def check_xhr_token
    xhr_token = params[:xhr_token].to_s
    path      = request.path.to_s

    if xhr_token != FrontController::XHR_TOKEN && path != '/'
      next_path = Base64.encode64 path
      redirect_to "#{root_path}?r=#{next_path}"
    end
  end

  protected

  def load_user_and_role(name = :@user)
    super do |collaborator|
      if params[:organization_id].present?
        organization = collaborator.organizations.find(params[:organization_id])
        collaborator.with_organization_scope(organization)
      end
    end
  end

  def define_layout
    if request.env["SERVER_NAME"].include?("axelium")
      'front/layout_axelium'
    elsif request.env["SERVER_NAME"].include?('dkpartners')
      'front/layout_dk_partners'
    elsif request.env["SERVER_NAME"].include?('censial')
      'front/layout_censial'
    elsif request.env["SERVER_NAME"].include?('orial')
      'front/layout_orial'
    else
      'front/layout'
    end
  end
end