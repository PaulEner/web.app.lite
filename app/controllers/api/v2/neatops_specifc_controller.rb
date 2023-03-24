### TODO : Refactor in a service ###

class Api::V2::NeatopsSpecificController < ActionController::Base
  before_action :authenticate
  skip_before_action :verify_authenticity_token

  def create
    organization_id = allowed_params[:organization_id]
    bank_account_name = allowed_params[:bank_account_name]
    bank_account_number = allowed_params[:bank_account_number]

    customer = User.find_by_code("NEAT%#{allowed_params[:code]}")
    journal  = customer.account_book_types.find_or_create_by(name: "ORG#{organization_id}", pseudonym: "ORG#{organization_id}", description: "ORG#{organization_id}", currency: 'EUR', entry_type: 4)

    bank_account = customer.bank_accounts.find_or_create_by(number: bank_account_number, 
                                             name: bank_account_name, 
                                             bank_name: bank_account_name, 
                                             journal: "ORG#{organization_id}", 
                                             currency: "EUR",
                                             accounting_number: "512000",
                                             temporary_account: "471000",
                                             start_date: "#{Date.today.beginning_of_year}",
                                             api_name: 'idocus',
                                             is_used: true)

    if not journal
      render json: { message: "Unknwown entry type: #{allowed_params[:accounting_type]} - No AccountBookType found" }, status: 404
    elsif not bank_account
      render json: { message: "Can't find or create the bank_account" }, status: 404
    else
      dir = CustomUtils.mktmpdir('temp_document_controller', nil, false)

      filename = File.join(dir, "#{customer.code}_#{allowed_params[:content_file_name]}")

      File.open(filename, 'wb') do |f|
        f.write(Base64.decode64(allowed_params[:file_base64]))
      end

      if !customer.inactive?
        uploaded_document = UploadedDocument.new(File.open(filename),
                                              allowed_params[:content_file_name],
                                              customer,
                                              journal.name,
                                              0,
                                              customer,
                                              allowed_params[:api_name],
                                              nil,
                                              allowed_params[:api_id])

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

  def allowed_params
    params.permit!
  end

  def serializer
    TempDocumentSerializer
  end
end
