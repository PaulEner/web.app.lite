### TODO : Refactor in a service ###
class Api::V3::InboundDocumentsController < Api::V3::MainController
  def create
    if !user || !ledger
      head(404)
    elsif (user && !user.in?(authenticated_organization.users)) || (user && user.inactive?)
      head(403)
    end

    dir = CustomUtils.mktmpdir('temp_document_controller', nil, false)

    filename = File.join(dir, "#{user.code}_#{allowed_params[:filename]}")

    File.open(filename, 'wb') do |f|
      f.write(Base64.decode64(allowed_params[:content_base64]))
    end

    uploaded_document = UploadedDocument.new(File.open(filename),
                                          allowed_params[:filename],
                                          user,
                                          ledger.name,
                                          0,
                                          user,
                                          "upload_api_v3",
                                          nil,
                                          nil)

    if uploaded_document
      head(201)
    else
      render json: uploaded_document.try(:errors), status: :unprocessable_entity
    end
  end

  protected

  def user
    user = if allowed_params[:user_id]
      User.find(allowed_params[:user_id])
    elsif allowed_params[:user_code]
      User.find_by(code: allowed_params[:user_code])
    elsif allowed_params[:user_legal_identifier]
      User.find_by(legal_identifier: allowed_params[:user_legal_identifier])
    end
  end

  def ledger
    if user
      ledger = if allowed_params[:ledger_id]
        AccountBookType.find(allowed_params[:ledger_id])
      elsif allowed_params[:ledger_name]
        AccountBookType.find_by(name: allowed_params[:ledger_name])
      end
    end
  end

  private

  def allowed_params
    params.permit!
  end

  def serializer
    V3::TempDocumentSerializer
  end
end
