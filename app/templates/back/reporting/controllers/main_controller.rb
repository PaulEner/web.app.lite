# frozen_string_literal: true
class Admin::Reporting::MainController < BackController
  prepend_view_path('app/templates/back/reporting/views')

  def index
    @year = begin
              Integer(params[:year])
            rescue StandardError
              Time.now.year
            end
    date = params[:month].present? ? Date.parse("#{@year}-#{'%02d' % Integer(params[:month].to_i)}-01") : Date.parse("#{@year}-01-01")
    @organizations = Organization.billed_for_year(@year).order(name: :asc)

    @total = 12.times.map { |e| [0,0,0] }

    respond_to do |format|
      format.html
      format.xls do
        Timeout.timeout 600 do
          if params[:simplified] == '1'
            filename = "reporting_simplifié_iDocus_#{@year}.xls"
            send_data Report::GlobalToXls.new(@year).execute, type: 'application/vnd.ms-excel', filename: filename
          else
            end_date = params[:month].present? ? date.end_of_month : date.end_of_year

            if params[:organization_id].present? && (organization = Organization.find(params[:organization_id]))
              organization_ids = [organization.id]
              customer_ids = organization.customers.active_at(end_date).pluck(:id)
              filename = "reporting_#{organization.name.downcase.underscore}_#{@year}.xls"
              with_organization_info = false
            else
              organization_ids = @organizations.pluck(:id)
              customer_ids     = User.customers.where(organization_id: organization_ids).active_at(end_date).pluck(:id)
              filename = params[:month].present? ? "reporting_iDocus_#{'%02d' % params[:month].to_i}_#{@year}.xls" : "reporting_iDocus_#{@year}.xls"
              with_organization_info = true
            end

            if @year < 2022
              periods  = Period.includes(:billings).where('user_id IN (?) OR organization_id IN (?)', customer_ids, organization_ids)
                            .where('start_date >= ? AND end_date <= ?', date, end_date)
                            .order(start_date: :asc)

              data = Subscription::PeriodsToXls.new(periods, with_organization_info).execute
            else
              data = BillingMod::BillingToXls.new(customer_ids, @year, params[:month].to_i, with_organization_info).execute
            end

            send_data data, type: 'application/vnd.ms-excel', filename: filename
          end
        end
      rescue Timeout::Error
        puts 'Request too long'
        raise 'Request too long'
      end
    end
  end

  def row_organization
    @year = begin
              Integer(params[:year])
            rescue
              Time.now.year
            end
    date = Date.parse("#{@year}-01-01")


    @organization = Organization.find(params[:organization_id])

    @invoices = BillingMod::Invoice.where(organization_id: params[:organization_id]).invoice_at(date)

    render partial: 'row_organization'
  end

  def total_footer
    @year = begin
              Integer(params[:year])
            rescue
              Time.now.year
            end

    @total = params[:total].transpose

    render partial: 'total_footer'
  end
end