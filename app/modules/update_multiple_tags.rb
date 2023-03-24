# Update Document tags
module UpdateMultipleTags
  def self.execute(user_id, tags, document_ids, type = 'piece')
    substract = []
    add = []
    user = User.find user_id
    user = Collaborator.new(user) if user.is_prescriber

    tags.split("#").each do |tag|
      next unless tag =~ /-*\w*/

      if tag.strip[0] == '-'
        substract << tag.strip.sub('-', '').sub('*', '.*')
      elsif tag == ""
      else
        add << tag.strip
      end
    end

    document_ids.each do |document_id|
      if type == 'piece'
        document = Pack::Piece.where(id: document_id).first
        doc_user = document.try(:user)
      elsif type == 'pack'
        document = Pack.where(id: document_id).first
        doc_user = document.try(:owner)
      elsif type == 'temp_documents'
        document = TempDocument.where(id: document_id).first
        doc_user = document.try(:user)  
      end

      next unless document && (doc_user == user ||
                  (user.is_prescriber && user.customers.include?(doc_user)) || user.is_admin)

      substract.each do |s|
        tags = document.tags || []

        document.tags.each do |tag|
          tags -= [tag] if tag =~ /#{s}/
        end

        document.tags = tags
      end

      add_tags      = add.any? ? (document.tags || []) + add : (document.tags || [])
      document.tags = add_tags.uniq

      document.save
    end
  end
end
