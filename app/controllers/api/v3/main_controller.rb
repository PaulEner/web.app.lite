class Api::V3::MainController < ActionController::Base
  skip_before_action :verify_authenticity_token
  before_action :authorize
  helper_method :authenticated_organization


  protected

  def authenticated_organization
    ApiToken.find_by(token: access_token).organization
  end

  def authorize
    unless request.headers['Authorization'].present? && ApiToken.find_by(token: access_token)
      head :unauthorized
    end
  end

  private
  
  def access_token
    pattern = /^Bearer /
    header = request.headers['Authorization']
    header.gsub(pattern, '') if header&.match(pattern)
  end
end