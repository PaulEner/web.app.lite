# -*- encoding : UTF-8 -*-
class DataVerificator::NotFinalizedPiece < DataVerificator::DataVerificator
  def execute
    pieces = Pack::Piece.where("updated_at >= ?", 3.days.ago).where(is_finalized: false).order(updated_at: :desc)

    messages = []

    pieces.each_with_index do |piece, index|
      messages << "piece_id: #{piece.id}, piece_name: #{piece.name}, updated_at: #{piece.updated_at.strftime('%d-%m-%Y')}" if index <= 10

      Pack::Piece.delay_for(10.seconds, queue: :low).finalize_piece(piece.id)
    end

    {
      title: "NotFinalizedPiece - #{pieces.size} piece(s)",
      type: "table",
      message: messages.join('; ')
    }
  end 
end