class AccountingWorkflow::SendPieceToInvoiceRecognition
  def self.execute(pieces)
    pieces.each do |piece|
      new(piece).execute unless piece.is_a_cover
    end
  end

  def initialize(piece)
    @piece = piece
  end

  def execute    
    payload = {
      document: {
        source: 'main',
        name: @piece.name,
        file_base64: Base64.encode64(@piece.cloud_content.download),
        source_identifier: @piece.id
      }
    }.to_json

    connection = Faraday.new(INVOICE_RECOGNITION_URL) do |faraday|
      faraday.use FaradayMiddleware::FollowRedirects

      faraday.response :logger
      faraday.adapter Faraday.default_adapter
      faraday.headers['Content-Type'] = 'application/json'
      faraday.headers['Authorization'] = "Bearer #{INVOICE_RECOGNITION_TOKEN}"
    end

    request = connection.post('', payload)

    begin
      if request.status == 201
        @piece.sent_to_adr_pre_assignment
      else
        @piece.waiting_pre_assignment
      end
    rescue
      @piece.waiting_pre_assignment
    end
  end
end