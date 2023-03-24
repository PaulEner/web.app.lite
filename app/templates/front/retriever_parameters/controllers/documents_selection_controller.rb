# frozen_string_literal: true
class RetrieverParameters::DocumentsSelectionController < RetrieverController
  before_action :verif_account
  prepend_view_path('app/templates/front/retriever_parameters/views')

  def index
    @documents = TempDocument.search_for_collection(
                                @account.temp_documents.retrieved.joins(:metadata2), search_terms(params[:document_contains])
                              )
                             .wait_selection
                             .includes(:retriever, :piece)
                             .order(order_param)
                             .page(params[:page])
                             .per(params[:per_page])

    if params[:document_contains].try(:[], :retriever_id).present?
      @retriever = @account.retrievers.find(params[:document_contains][:retriever_id])
      @retriever.ready if @retriever.waiting_selection?
    end

    render partial: 'documents_selection', locals: { documents: @documents }
  end

  def integrate
    documents = @account.temp_documents.where(id: params[:document_ids] || [])

    if documents.count == 0
      message = 'Aucun document sélectionné.'
    else
      documents.map(&:retriever).compact.uniq.each do |retriever|
        retriever.ready if retriever.waiting_selection?
      end

      documents.each do |document|
        document.ready if document.wait_selection?
      end

      if documents.count > 1
        message = "Les #{documents.count} documents sélectionnés seront intégrés."
      else
        message = 'Le document sélectionné sera intégré.'
      end
    end
    
    render json: { message: message }, status: 200
  end

  private

  def sort_column
    if params[:sort].in? %w[created_at retriever_id date name pages_number amount]
      params[:sort]
    else
      'created_at'
    end
  end
  helper_method :sort_column

  def sort_direction
    if params[:direction].in? %w[asc desc]
      params[:direction]
    else
      'desc'
    end
  end
  helper_method :sort_direction

  def order_param
    if sort_column.in?(%w[date name amount])
      "temp_document_metadata.#{sort_column} #{sort_direction}"
    else
      { sort_column => sort_direction }
    end
  end
end