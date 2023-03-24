# frozen_string_literal: true

class Api::Mobile::ErrorReportController < MobileApiController
  skip_before_action :authenticate_mobile_user
  skip_before_action :load_user_and_role
  skip_before_action :verify_suspension
  skip_before_action :verify_if_active

  respond_to :json

  def send_error_report
    render json: { success: true }, status: 200
  end
end
