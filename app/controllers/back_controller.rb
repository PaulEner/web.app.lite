class BackController < ApplicationController
  before_action :login_user!
  before_action :verify_admin_rights

  layout ('back/layout')

  private

  def verify_admin_rights
    redirect_to root_url unless current_user.is_admin
  end
end