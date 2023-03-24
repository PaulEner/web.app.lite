class Api::V2::TempDocumentsController < ActionController::Base
  before_action :authenticate
  skip_before_action :verify_authenticity_token

  def create
    customer = User.find(temp_document_params[:user_id])
    journal  = customer.account_book_types.where(entry_type: params[:accounting_type]).first

    if not journal
      render json: { message: "Unknwown entry type: #{params[:accounting_type]} - No AccountBookType found" }, status: 404
    else
      dir = CustomUtils.mktmpdir('temp_document_controller', nil, false)

      filename = File.join(dir, "#{customer.code}_#{temp_document_params[:content_file_name]}")

      File.open(filename, 'wb') do |f|
        f.write(Base64.decode64(params[:file_base64]))
      end

      if !customer.inactive? && (customer.authorized_upload? || customer.try(:is_package?, :ido_x))
        uploaded_document = UploadedDocument.new(File.open(filename),
                                              temp_document_params[:content_file_name],
                                              customer,
                                              journal.name,
                                              0,
                                              customer,
                                              temp_document_params[:api_name],
                                              nil,
                                              temp_document_params[:api_id])

        if uploaded_document
          render json: uploaded_document.to_json
        else
          render json: uploaded_document.try(:errors), status: :unprocessable_entity
        end
      else
        render json: { message: 'Upload unauthorized - or - Inactive customer' }, status: 401
      end
    end
  end

  protected

  def authenticate
    unless request.headers['Authorization'].present? && request.headers['Authorization'] == API_KEY
      head :unauthorized
    end
  end

  private

  def temp_document_params
    params.require(:temp_document).permit(:user_id, :file_base64, :accounting_type, :content_file_name, :api_name, :api_id)
  end

  def serializer
    TempDocumentSerializer
  end
end
