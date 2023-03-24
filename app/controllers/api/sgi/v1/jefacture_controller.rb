# frozen_string_literal: true

class Api::Sgi::V1::JefactureController < SgiApiController

    # GET /api/sgi/v1/jefacture/waiting_validation
    def waiting_validation
      data = []

      pieces = Pack::Piece.awaiting_preassignment.joins(:temp_document).where('temp_documents.api_name = "jefacture"')

      pieces.each do |piece|
        pack          = piece.pack
        journal       = piece.user.account_book_types.where(name: piece.journal).first
        temp_document = piece.temp_document

        if !temp_document || !pack
          piece.ignored_pre_assignment

          next
        end

        data << {
                  piece_id: piece.id,
                  piece_name: piece.name,
                  piece_url: Domains::BASE_URL + piece.get_access_url,
                  pack_name: pack.name,
                  compta_type: journal&.compta_type,
                  jefacture_id: temp_document.api_id
                }.with_indifferent_access
      end

      if data.size > 0
          render json: { success: true, data: data, message: '' }, status: 200
      else
          render json: { success: false, data: [], message: 'Aucune pièce jefacture trouvée' }, status: 200
      end
    end

    # POST /api/sgi/v1/jefacture/pre_assigned
    def pre_assigned
        if params[:data_validated].present?
            results = SgiApiServices::AutoPreAssignedJefacturePieces.new(params[:data_validated]).execute

            success = true
            results.select {|result| success &&= result['errors'].empty?}

            render json: { success: success, results: results  }, status: 200
        else
            render json: { success: false, message: 'Paramètre data_validated manquant' }, status: 601
        end
    end
end
