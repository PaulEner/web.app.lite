class Reporting::ABaseController < FrontController #Must be loaded first that's why there is an "A" in the name
  before_action :load_report_organization
  before_action :load_params

  private

  def load_report_organization
    session_organization = params[:organization_id].presence || session[:reporting_organization_id].presence  || nil

    if session_organization
      @report_organization ||= Organization.where(id: session_organization).first
    elsif @user.has_one_organization?
      @report_organization ||= @user.organization
    else
      @report_organization ||= @user.organizations.first
    end

    session[:reporting_organization_id] = @report_organization.id
  end

  def load_params
    @customers_ids = (@report_organization)? @report_organization.customers.where(id: account_ids).collect(&:id) : account_ids

    # @date_range  = CustomUtils.parse_date_range_of(params[:date_range])
    @date_range    = Rails.env == 'production' ? [15.days.ago.strftime('%Y-%m-%d 00:00:00'), Time.now.strftime('%Y-%m-%d 23:59:59')] : ['2012-01-01 00:00:00',  '2016-08-01 23:59:59']

    if params[:ids].present? && params[:ids] != "null"
      if params[:ids].is_a?(Array)
        @customers_ids = params[:ids]
      else
        @customers_ids = params[:ids].split(',')
      end
    end
  end
end