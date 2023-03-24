class PonctualScripts::DeletePieces < PonctualScripts::PonctualScript
  def self.execute(options)    
    new(options).run
  end

  def self.rollback(options)
    new(options).rollback
  end

  private 

  def execute
    @list_deleted_pieces = []
    @list_pieces_with_error = []
    @error_process = false

    @user = User.find_by_code(@options[:user_code])

    if @user
      logger_infos " ================================ [Début du processus] =========================== "

      @user.packs.each do |pack|
        logger_infos " Pack: #{pack.id} - #{pack.name} "

        pack.pieces.each do |piece|
          delete_piece(piece)
          @list_deleted_pieces << piece.id.to_s
        end

        pack.delay(queue: :low).try(:recreate_original_document)
      end

      logger_infos " ================================ [Fin du processus] =========================== "
      logger_infos " Nombre total de pièces supprimées = #{@list_deleted_pieces.size}. "
      logger_infos " Pièce(s) supprimée(s) avec succès : [#{@list_deleted_pieces.join(', ')}]. " if @list_deleted_pieces.size > 0
      logger_infos " Nombre total de pièces qui ont rencontré des erreurs lors de la suppression = #{@list_pieces_with_error.size}. "

      if @list_pieces_with_error.size > 0
        logger_infos " Pièce(s) non supprimée(s) : [#{@list_pieces_with_error.join(', ')}]. "
      end
    else
      logger_infos " Impossible de trouver l'utilisateur associé au code : #{@options[:user_code]} " 
    end
  end

  def backup
  end

  def delete_piece(piece)
    logger_infos " Suppression de la pièce : #{piece.id.to_s} - #{piece.name} en cours ....................... "

    piece.delete_at = DateTime.now
    piece.delete_by = "IDOC%DEV5"

    if piece.save
      @list_deleted_pieces << piece.id.to_s

      temp_document = piece.temp_document

      if temp_document
        temp_document.original_fingerprint    = nil
        temp_document.content_fingerprint     = nil
        temp_document.raw_content_fingerprint = nil
        temp_document.save

        parents_documents = temp_document.parents_documents

        if parents_documents.any?
          parents_documents.each do |parent_document|
            blank_children =  parent_document.children.select{ |child| child.fingerprint_is_nil? }

            if parent_document.children.size == blank_children.size
              parent_document.original_fingerprint    = nil
              parent_document.content_fingerprint     = nil
              parent_document.raw_content_fingerprint = nil
              parent_document.save
            end
          end
        end
      end
    else
      @list_pieces_with_error << piece.id.to_s
    end
  end
end