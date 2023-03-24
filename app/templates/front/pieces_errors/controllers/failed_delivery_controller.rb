# frozen_string_literal: true

class PiecesErrors::FailedDeliveryController < FrontController
  skip_before_action :verify_if_active, only: %w[index]
  prepend_view_path('app/templates/front/pieces_errors/views')

  # GET /account/pre_assignment_blocked_duplicates
  def index
    @errors = Pack::Report.search_failed_delivery(params[:account_id].presence || account_ids).page(params[:page]).per(params[:per_page].presence || 20)

    render partial: 'index'
  end
end