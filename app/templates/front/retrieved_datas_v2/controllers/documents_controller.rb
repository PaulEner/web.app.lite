# frozen_string_literal: true
class RetrievedDatasV2::DocumentsController < RetrieverController
  before_action :verif_account
  before_action :load_document, only: %w[show piece]
  prepend_view_path('app/templates/front/retrieved_datas_v2/views')

  def index
    @documents = TempDocument.search_for_collection(
      @account.temp_documents.retrieved.joins(:metadata2), search_terms(params[:document_contains])
    )
                             .includes(:retriever, :piece)
                             .order(order_param)
                             .page(params[:page])
                             .per(params[:per_page])
    # @is_filter_empty = search_terms(params[:document_contains]).empty?

    render partial: 'documents', locals: { documents: @documents }
  end

  def show
    if File.exist?(@document.cloud_content_object.path)
      file_name = @document.metadata['name'] + '.pdf'
      send_file(@document.cloud_content_object.path('', true), type: 'application/pdf', filename: file_name, x_sendfile: true, disposition: 'inline')
    else
      render body: nil, status: 404
    end
  end

  def piece
    if @document.piece
      if File.exist?(@document.piece.cloud_content_object.path.to_s)
        send_file(@document.piece.cloud_content_object.path('', true), type: 'application/pdf', filename: @document.piece.cloud_content_object.filename, x_sendfile: true, disposition: 'inline')
      else
        render body: nil, status: 404
      end
    else
      render body: nil, status: 404
    end
  end

  def select
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
    @is_filter_empty = search_terms(params[:document_contains]).empty?
  end

  def validate
    documents = @account.temp_documents.find(params[:document_ids] || [])
    if documents.count == 0
      flash[:notice] = 'Aucun document sélectionné.'
    else
      documents.map(&:retriever).compact.uniq.each do |retriever|
        retriever.ready if retriever.waiting_selection?
      end
      documents.each do |document|
        document.ready if document.wait_selection?
      end
      if documents.count > 1
        flash[:success] = "Les #{documents.count} documents sélectionnés seront intégrés."
      else
        flash[:success] = 'Le document sélectionné sera intégré.'
      end
    end
    redirect_to retrievers_path
  end

  private

  def load_document
    @document = @account.temp_documents.retrieved.find(params[:id])
  end

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