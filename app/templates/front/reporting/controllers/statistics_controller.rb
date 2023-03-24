# frozen_string_literal: true

class Reporting::StatisticsController < Reporting::ABaseController
  skip_before_action :load_params, only: %w(index)

  prepend_view_path('app/templates/front/reporting/views')

  def injected_documents
    respond_to do |format|
      format.html do
        @pieces = Pack::Piece.where(user: @customers_ids).joins(:user).select(:updated_at, :user_id).group(:user_id).order(updated_at: :desc).limit(10)

        render partial: 'lastest_sending_docs'
      end
      format.json do
        range_date   = []
        pieces_count = []

        7.times.reverse_each do |i|
          date = i.days.ago
          range_date << date.strftime("%d/%m")

          pieces_count << Pack::Piece.where(user_id: @customers_ids).where("DATE(created_at) = '#{date.strftime("%Y-%m-%d")}'").count
        end

        render json: { range_date: range_date, pieces_count: pieces_count, max_count: pieces_count.max, min_count: pieces_count.min }, state: 200
      end
    end
  end

  def pre_assignment_accounts
    respond_to do |format|
      format.html do
        @reports = Pack::Report.where("created_at BETWEEN '#{@date_range.join("' AND '")}'").where(user_id: @customers_ids).order(updated_at: :desc).limit(10)

        render partial: 'pre_assignment_accounts'
      end
      format.json do
        journals = Rails.cache.fetch [:journals], expires_in: 1.hours, compress: true do
          AccountBookType.where(user_id: @customers_ids).select(:user_id, :anomaly_account, :account_number, :default_account_number).to_a
        end

        anomaly_accounts = []
        waiting_accounts = []
        default_accounts = []
        journals.each do |journal|
          anomaly_accounts << journal.anomaly_account        if journal.anomaly_account.present?
          waiting_accounts << journal.account_number         if journal.account_number.present?
          default_accounts << journal.default_account_number if journal.default_account_number.present?
        end

        preseizures_ids = Rails.cache.fetch [:preseizures], expires_in: 1.hours, compress: true do
          Pack::Report::Preseizure.where("created_at BETWEEN '#{@date_range.join("' AND '")}'").where(user_id: @customers_ids).select(:id, :user_id, :report_id).to_a.uniq
        end

        anomaly_accounts_size = 0
        waiting_accounts_size = 0
        default_accounts_size = 0
        all_accounts    = Pack::Report::Preseizure::Account.where(preseizure_id: preseizures_ids.pluck(:id)).select(:number)

        all_accounts.each do |account|
          if anomaly_accounts.include?(account.number)
            anomaly_accounts_size += 1
          elsif waiting_accounts.include?(account.number)
            waiting_accounts_size += 1
          elsif default_accounts.include?(account.number)
            default_accounts_size += 1
          end
        end

        normal_accounts_size  = all_accounts.size - anomaly_accounts_size - waiting_accounts_size - default_accounts_size

        render json: { labels: ['Compte normale', 'Compte anomalie', 'Compte par défaut', "Compte d'attente"], counts: [normal_accounts_size, anomaly_accounts_size, default_accounts_size, waiting_accounts_size] }, state: 200
      end
    end
  end

  def retrievers_report
    @retrievers = Retriever.where("updated_at BETWEEN '#{@date_range.join("' AND '")}'").where(user_id: @customers_ids)

    respond_to do |format|
      format.html do
        @retrievers = @retrievers.where(state: 'error')

        render partial: 'failed_retrievers'
      end
      format.json do
        retrievers = @retrievers.count
        retrievers_error = @retrievers.where(state: 'error').count
        retrievers_error_percentage = (retrievers > 0) ? ((retrievers_error * 100) / retrievers).ceil : 0

        render json:{ actif_percentage: ((retrievers > 0) ? (100 - retrievers_error_percentage) : 0), error_percentage: retrievers_error_percentage }, state: 200
      end
    end
  end

  def index
    render file: Rails.root.join('app/templates/front/reporting/views/reporting/_index.html.haml')
  end

  def export_xls
    data = nil

    Timeout.timeout 3600 do
      data = Reporting::StatisticToXls.new(@customers_ids, @date_range).execute(params[:to_export])
    end

    send_data(data, type: 'application/vnd.ms-excel', filename: "Statistic_#{params[:to_export]}.xls", disposition: 'inline')
  end
end