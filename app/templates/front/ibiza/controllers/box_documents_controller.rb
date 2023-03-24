# frozen_string_literal: true

class Ibiza::BoxDocumentsController < CustomerController
  before_action :load_customer
  before_action :load_document, except: %w[index select validate]

  prepend_view_path('app/templates/front/ibiza/views')

  def index
    collection = @customer.temp_documents.from_ibizabox.joins([ibizabox_folder: :journal]).select('temp_documents.*, account_book_types.name as journal')
    @documents = TempDocument.search_ibizabox_collection(collection, search_terms(params[:document_contains])).includes(:retriever).includes(:piece).order("#{sort_column} #{sort_direction}")
    @documents_count = @documents.size
    @documents = @documents.page(params[:page]).per(params[:per_page])
  end

  def show
    if File.exist?(@document.cloud_content_object.path)
      send_file(@document.cloud_content_object.path('', true), type: 'application/pdf', filename: @document.original_file_name, x_sendfile: true, disposition: 'inline')
    else
      render body: nil, status: 404
    end
  end

  def piece
    if @document.piece
      if File.exist?(@document.piece.cloud_content_object.path)
        send_file(@document.piece.cloud_content_object.path('', true), type: 'application/pdf', filename: @document.piece.cloud_content_object.filename, x_sendfile: true, disposition: 'inline')
      else
        render body: nil, status: 404
      end
    else
      render body: nil, status: 404
    end
  end

  def select
    collection = @customer.temp_documents.wait_selection.from_ibizabox.joins([ibizabox_folder: :journal]).where("ibizabox_folders.state in ('waiting_selection','ready')").select('temp_documents.*, account_book_types.name as journal')
    @documents = TempDocument.search_ibizabox_collection(collection, search_terms(params[:document_contains])).includes(:piece).order("#{sort_column} #{sort_direction}").page(params[:page]).per(params[:per_page])
  end

  def validate
    documents = @customer.temp_documents.wait_selection.from_ibizabox.find(params[:document_ids] || [])

    if documents.count == 0
      json_flash[:error] = 'Aucun document sélectionné.'
    else
      documents.map(&:ibizabox_folder).compact.uniq.each do |ibizabox_folder|
        ibizabox_folder.ready if ibizabox_folder.waiting_selection?
      end
      documents.each do |document|
        if DocumentTools.need_ocr?(document.cloud_content_object.path)
          document.ocr_needed
        else
          document.ready
        end
      end
      if documents.count > 1
        json_flash[:success] = "Les #{documents.count} documents sélectionnés seront intégrés."
      else
        json_flash[:success] = 'Le document sélectionné sera intégré.'
      end
    end

    render json: { json_flash: json_flash }, status: 200
  end

  private

  def load_customer
    @customer = customers.find(params[:customer_id])
  end

  def load_document
    @document = @customer.temp_documents.from_ibizabox.find(params[:id])
  end

  def sort_column
    if params[:sort].in? %w[created_at]
      "ibizabox_folders.#{params[:sort]}"
    elsif params[:sort].in? %w[original_file_name pages_number]
      "temp_documents.#{params[:sort]}"
    elsif params[:sort].in? %w[journal]
      "account_book_types.name"
    else
      'ibizabox_folders.created_at'
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
end
