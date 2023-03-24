# frozen_string_literal: true

class Documents::OperationsController < Documents::AbaseController
  skip_before_action :verify_if_active, only: %w[index show]
  before_action :set_is_operation
  before_action :load_report, except: %w[index]
  before_action :load_params, only: %w[index show]

  prepend_view_path('app/templates/front/documents/views')

  # GET /operations
  def index
  	@reports = Pack::Report.where(pack_id: [nil, '']).search(@options).distinct.order(updated_at: :desc).page(@options[:page]).per(@options[:per_page])
  end

  # GET /operations/:id
  def show
    preseizures = @report.preseizures.where('operation_id > 0')

    preseizures = preseizures.filter_by(@options[:by_preseizure])

    if @options[:text].present?
      preseizures = preseizures.joins(:operation).where("operations.label LIKE '%#{@options[:text]}%'")
    end

    @preseizures = preseizures.distinct.order(updated_at: :desc).page(@options[:page]).per(10)
  end

  private

  def load_report
    @report = Pack::Report.where(id: params[:id], pack_id: [nil, '']).first
    # @report = nil if not account_ids.include? @report.user_id #disable temporarly to be enable later

    redirect_to operations_path if not @report
  end

  def set_is_operation
    @is_operations = true
  end
end