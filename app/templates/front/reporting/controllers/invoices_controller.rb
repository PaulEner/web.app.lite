# frozen_string_literal: true

class Reporting::InvoicesController < Reporting::ABaseController
  skip_before_action :load_report_organization, only: %w(period)
  skip_before_action :load_params, only: %w(period)

  before_action :load_billing_or_period, :verify_rights, only: %w(period)

  prepend_view_path('app/templates/front/reporting/views')

  def period
    if @object.class.name == 'Period'
      render json: PeriodPresenter.new(@object, current_user).render_json, status: 200
    else
      render json: BillingPresenter.new(@object, current_user).render_json, status: 200
    end
  end

  def index
    @year = begin
              Integer(params[:year])
            rescue StandardError
              Time.now.year
            end

    date = Date.parse("#{@year}-01-01")
    periods = Period.includes(:billings, :user, :subscription).where(user_id: @customers_ids)
                    .where('start_date >= ? AND end_date <= ?', date, date.end_of_year)
                    .order(start_date: :asc)
    @periods_by_users = periods.group_by { |period| period.user.id }.each do |_user, periods|
      periods.sort_by!(&:start_date)
    end

    respond_to do |format|
      format.html do
        render partial: 'index'
      end
      format.xls do
        if @year < 2022
          data = Subscription::PeriodsToXls.new(periods).execute
        else
          data = BillingMod::BillingToXls.new(@customers_ids, @year).execute
        end

        send_data data, type: 'application/vnd.ms-excel', filename: "reporting_iDocus_#{@year}.xls"
      end
    end
  end

  private

  def load_billing_or_period
    return @object = nil if params[:id].to_i == 0

    if params[:id].to_i > 0
      @object = BillingMod::Billing.where(id: params[:id].to_i).first
    else
      @object = Period.find(params[:id].to_i * -1)
    end
  end

  def verify_rights
    return true if params[:id].present? && params[:id].to_i == 0

    unless (@object.try(:owner) && @object.owner.in?(accounts)) || (@object.try(:user) && @object.user.in?(accounts))
      json_flash[:error] = 'Action non autorisée'
      render json: { json_flash: json_flash }, status: 200
    end
  end
end