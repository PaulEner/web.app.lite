class SgiApiServices::SendPreAssignmentNeeded
  def self.execute
    new.execute
  end

  def execute
    @lists_pieces = {}
    @errors       = []

    Pack::Piece.need_preassignment.each do |piece|
      next if piece.temp_document.try(:api_name).to_s == 'jefacture'

      @added_piece = false

      compta_types.each do |compta_type|
        next if @added_piece

        @compta_type = compta_type
        if (AccountBookType::TYPES_NAME - ['SPEC'] + ['TEEO']).include?(compta_type)
          next if piece.organization.code.upcase == "TEEO" && compta_type.upcase != "TEEO"

          get_list(piece, (compta_type.upcase == "TEEO" && piece.organization.code.upcase == "TEEO"))
        end
      end
    end

    send_list
  end

  private

  def get_list(piece, is_teeo=false)
    temp_pack = TempPack.find_by_name piece.pack.name

    journal = piece.user.account_book_types.where(name: piece.journal).first

    compta_type_verified = is_teeo ? true : journal.try(:compta_type) == @compta_type

    add_to_list_and_update_state_of(piece, (is_teeo ? 'TEEO' : journal.compta_type)) if journal && temp_pack && temp_pack.is_compta_processable? && !piece.is_a_cover && compta_type_verified

    if journal.nil?
      _error_mess = "Aucun journal correspondant : #{piece.journal}"

      piece.ignored_pre_assignment
      piece.update(pre_assignment_comment: _error_mess)
      Notifications::PreAssignments.new({piece: piece}).notify_pre_assignment_ignored_piece

      @added_piece = true
      @errors << { piece_id: piece.id, error_message: _error_mess}
    end
  end

  def add_to_list_and_update_state_of(piece, compta_type)
    @added_piece = true

    if piece.temp_document.nil? || piece.preseizures.any?
      if piece.pre_assignment_state == 'waiting'
        piece.update(pre_assignment_state: 'ready')     if piece.temp_document.nil?
        piece.update(pre_assignment_state: 'processed') if piece.preseizures.any?
      end
    else
      detected_third_party_id = piece.detected_third_party_id.presence || 6930

      data = { id: piece.id, 
               piece_name: piece.name, 
               url_piece: Domains::BASE_URL + piece.try(:get_access_url), 
               compta_type: compta_type, 
               detected_third_party_id: detected_third_party_id,
               detected_third_party_name: piece.detected_third_party_name,
               detected_invoice_number: piece.detected_invoice_number,
               detected_invoice_date: piece.detected_invoice_date,
               detected_invoice_due_date: piece.detected_invoice_due_date,
               detected_invoice_amount_without_taxes: piece.detected_invoice_amount_without_taxes,
               detected_invoice_taxes_amount: piece.detected_invoice_taxes_amount,
               detected_invoice_amount_with_taxes: piece.detected_invoice_amount_with_taxes,
               recycle: piece.pre_assignment_force_processing?
             }

      begin
        @lists_pieces[compta_type.to_s] << data
      rescue
        @lists_pieces[compta_type.to_s] = [data]
      end
    end
  end

  def compta_types
    ['VT', 'AC', 'NDF', 'BQ', 'TEEO']
  end

  def send_list
    compta_types.each do |compta_type|
      if @lists_pieces[compta_type.to_s].present? && @lists_pieces[compta_type.to_s].size > 0
        p "=== [#{compta_type}] : #{@lists_pieces[compta_type.to_s].size} =="
        send_with_typhoeus(compta_type, { datas: { pieces: @lists_pieces[compta_type.to_s] || [] } })
      end
    end
  end


  ###### NEXT STEP : Create a new sender library for this ################

  def send_with_typhoeus(compta_type, body)
    request = Typhoeus::Request.new(
      "https://production.idocus.com/api/pieces/pre_assigning/#{compta_type.to_s}",
      method:  :post,
      headers:  {
                  'Accept' => 'application/json',
                  'Authorization' => "#{token}",
                  'Content-Type' => "application/json"
                },
      body: body.to_json
    )

    @response = request.run

    p "#{@response.code}"
    p result = JSON.parse(@response.body) if @response.body.present?
  end

  def token
    'eyJhbGciOiJIUzI1NiJ9.eyJleHAiOjQ4MDAwNjQzNDgsImlzcyI6IldhYllSamZkNjRQTnA3SmRLYkFRTWstR2RPVWJpSGtNS0pxdlhvb1ctNm1NN2w0LWlKMkY3VW1YYzVkaldlaUJnMzR6YXh5V0FuWmNEbG5RZEhwbFhVVTZPMmxvWXprdUhqWWxSeEM0ZHZjN05fZWpRcFJrYmMwRVBaeGFHbk9kXzRpZW5BIiwiaWF0IjoxNjQ0MzkwNzQ4fQ.GYmy9Xzh8q4hO1GZSd101I16YAIxyjnLXEKTKseIWpc'
  end

  #########################################################################
end