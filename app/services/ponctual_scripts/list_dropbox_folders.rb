class PonctualScripts::ListDropboxFolders < PonctualScripts::PonctualScript
  ERROR_LISTS = {
                  already_exist: 'fichier déjà importé sur iDocus',
                  invalid_period: 'période invalide',
                  journal_unknown: 'journal invalide',
                  invalid_file_extension: 'extension invalide',
                  file_size_is_too_big: 'fichier trop volumineux',
                  pages_number_is_too_high: 'nombre de page trop important',
                  file_is_corrupted_or_protected: 'Votre document est en-cours de traitement',
                  real_corrupted_document: 'fichier corrompu ou protégé par mdp',
                  unprocessable: 'erreur fichier non valide pour iDocus'
                }.freeze

  def self.execute(user_code, delete=false)   
    new({user: user_code, delete: delete}).run
  end

  private 

  def execute
    user     = User.get_by_code @options[:user]
    @dropbox = user.external_file_storage.dropbox_basic

    return false if not @dropbox

    logger_infos "[DropboxFile] - Checked at : #{@dropbox.checked_at_for_all}"

    @dropbox.import_folder_paths.each do |path|
      begin
        with_error = false
        result = client.list_folder(path)
      rescue => e
        logger_infos "=======> [Dropbox Error] - #{e.to_s}"

        with_error = true
      end

      next if with_error

      result.entries.each do |entry|
        process_entry(entry) if entry.is_a?(DropboxApi::Metadata::File)
      end
    end
  end

  def client
    @client ||= FileImport::Dropbox::Client.new(DropboxApi::Client.new(@dropbox.access_token))
  end

  def process_entry(entry)
    file_path = entry.path_display
    path      = File.dirname file_path
    file_name = File.basename file_path

    paths     = path.split('/')
    user_code = paths[3].split('-')[0].strip
    customer  = User.where(code: user_code).first

    CustomUtils.mktmpdir('dropbox_import') do |dir|
      File.open File.join(dir, file_name), 'wb' do |file|
        begin
          client.download file_path do |content|
            file.puts content.force_encoding('UTF-8')
            file.flush
          end

          fingerprint = DocumentTools.checksum(file.path)

          if customer
            temp_document = customer.temp_documents.where(original_fingerprint: fingerprint).first
          else
            temp_document    = FakeObject.new
            temp_document.id = user_code
          end

          corrupted     = Archive::DocumentCorrupted.where(fingerprint: fingerprint).first

          logger_infos "[DropboxFile] - #{file_path} / fingerprint: #{fingerprint} / user: #{user_code} / temp_doc: #{temp_document.try(:id).to_i} / corrupted: #{corrupted.try(:id).to_i} / valid_name: #{valid_file_name(file_name)} / valid_extension: #{UploadedDocument.valid_extensions.include?(File.extname(file_path).downcase)} / modif_client: #{entry.client_modified} / size: #{entry.size}"
        rescue => e
          logger_infos "[DownloadError] => #{e.to_s}"
        end
      end
    end
  end

  def valid_file_name(file_name)
    ERROR_LISTS.each do |pattern|
      return false if file_name =~ /#{pattern.last}/i
    end

    return true
  end
end