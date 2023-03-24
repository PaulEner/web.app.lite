class PonctualScripts::SendPreAssignmentNeeded < PonctualScripts::PonctualScript
  def self.execute
    new().run
  end

  private

  def execute
    ['VT', 'AC', 'NDF'].each do |compta_type|
      p "============= CREATING #{compta_type} ========="
      @compta_type = compta_type
      @lists_pieces = []
      @errors = []

      if (AccountBookType::TYPES_NAME - ['SPEC'] + ['TEEO']).include?(compta_type)
        Pack::Piece.need_preassignment.each do |piece|
          next if piece.organization.code.upcase == "TEEO" && compta_type.upcase != "TEEO"

          get_list(piece, (compta_type.upcase == "TEEO" && piece.organization.code.upcase == "TEEO"))
        end

        # i = 0
        # if @lists_pieces.size > 0
        #   @lists_pieces.each_slice(100) do |list|
        #     i = i + 1
        #     write_to_json(list, i)
        #   end
        # end

        write_to_json(@lists_pieces, 1)
      end

      sleep(1)
    end
  end

  def get_list(piece, is_teeo=false)
    temp_pack = TempPack.find_by_name piece.pack.name

    journal = piece.user.account_book_types.where(name: piece.journal).first

    compta_type_verificator = is_teeo ? true : journal.try(:compta_type) == @compta_type

    add_to_list_and_update_state_of(piece, journal.compta_type) if journal && temp_pack && temp_pack.is_compta_processable? && !piece.is_a_cover && compta_type_verificator

    if journal.nil?
      _error_mess = "Aucun journal correspondant : #{piece.journal}"

      piece.ignored_pre_assignment
      piece.update(pre_assignment_comment: _error_mess)
      Notifications::PreAssignments.new({piece: piece}).notify_pre_assignment_ignored_piece

      @errors << { piece_id: piece.id, error_message: _error_mess}
    end
  end

  def add_to_list_and_update_state_of(piece, compta_type)
    if piece.temp_document.nil? || piece.preseizures.any?
      if piece.pre_assignment_state == 'waiting'
        piece.update(pre_assignment_state: 'ready')     if piece.temp_document.nil?
        piece.update(pre_assignment_state: 'processed') if piece.preseizures.any?
      end

      log_document = {
        subject: "[Api::Sgi::V1::PreassignmentController] re-init pre assignment state",
        name: "Api::Sgi::V1::PreassignmentController",
        error_group: "[Api-sgi-pre-assignment] re-init pre assignment state",
        erreur_type: "Re-init pre assignment state",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          piece_id: piece.id,
          piece_name: piece.name,
          temp_doc: piece.temp_document.nil?,
          preseizures: piece.preseizures.any?,
          state: piece.pre_assignment_state,
          piece:  piece.inspect
        }
      }

      ErrorScriptMailer.error_notification(log_document).deliver
    else
      detected_third_party_id = piece.detected_third_party_id.presence || 6930

      @lists_pieces << { id: piece.id, 
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
                         recycle: piece.pre_assignment_force_processing? }
    end
  end

  def write_to_json(list, ind)
    file_path = Rails.root.join('files', 'preaff', "#{@compta_type}_#{ind}.json")
    File.write(file_path, list.to_json)

    p "==========DONE: #{file_path}"
  end
end
