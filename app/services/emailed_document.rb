class EmailedDocument
  attr_reader :temp_documents

  class << self
    attr_accessor :config
  end

  def self.configure
    yield config
    update_config
  end


  def self.config
    @config ||= Configuration.new
  end


  def self.config=(new_config)
    config.is_enabled = new_config['is_enabled']
    config.address    = new_config['address']    if new_config['address']
    config.port       = new_config['port']       if new_config['port']
    config.user_name  = new_config['user_name']  if new_config['user_name']
    config.password   = new_config['password']   if new_config['password']
    config.enable_ssl = new_config['enable_ssl'] if new_config['enable_ssl']
    update_config
  end


  def self.update_config
    Mail.defaults do
      retriever_method :pop3, address: EmailedDocument.config.address,
                              port: EmailedDocument.config.port,
                              user_name: EmailedDocument.config.user_name,
                              password: EmailedDocument.config.password,
                              enable_ssl: EmailedDocument.config.enable_ssl
    end
  end


  def self.fetch_all
    is_ok = true

    tries = 0
    begin
      Mail.find_and_delete do |mail|
        begin
          EmailedDocument.receive(mail)
        rescue => e
          is_ok = false
          mail.skip_deletion
        end
      end
    rescue SocketError => e
      if e.message.match(/^getaddrinfo/) && tries < 3
        tries += 1
        sleep(2)
        retry
      else
        raise
      end
    end

    is_ok
  end


  def self.receive(mail, rescue_error = true)
    email = Email.find_by(message_id: mail.message_id)
    mail.subject = mail.subject.to_s.gsub(/fwd([ ]+)?(:)?/i, '').strip

    return false unless mail.subject

    unless email
      mail_to = mail.to.try(:grep, /@fw.idocus.com/i).try(:first)
      mail_to = mail.cc.try(:grep, /@fw.idocus.com/i).try(:first) unless mail_to.present?

      return false unless mail_to.present?

      email                       = Email.new
      email.message_id            = mail.message_id
      email.originally_created_at = mail.date
      email.to                    = mail_to
      email.from                  = mail.from.first
      email.subject               = mail.subject
      email.from_user             = User.find_by_email(mail.from.first)
      email.to_user               = User.find_by(email_code: mail_to.split('@')[0])

      email.save

      # System::Log.info('emails', email.inspect)

      CustomUtils.mktmpdir('emailed_document') do |dir|
        file_path = "#{dir}/#{email.id}.eml"

        File.open file_path, 'w' do |f|
          f.write mail.to_s
        end

        # email.update_attribute(:original_content, File.open(file_path))
        email.cloud_original_content_object.attach(File.open(file_path), "#{email.id}.eml")
      end
    end

    if email.processed? || email.unprocessable?
      email
    else
      begin
        if email.to_user.try(:my_package).try(:upload_active)
          emailed_document = EmailedDocument.new mail

          email.attachment_names = emailed_document.attachments.map(&:name) unless email.attachment_names.present?
          email.size             = emailed_document.total_size              unless email.size > 0
          email.save

          if emailed_document.valid?
            email.success

            emailed_document.temp_documents.each do |temp_document|
              email.temp_documents << temp_document
            end

            email.save

            if emailed_document.get_invalid_attachments.any?
              email.update_attribute(:errors_list, emailed_document.errors)
              EmailedDocumentMailer.notify_finished_with_failure(email, emailed_document).deliver
            else
              if email.from_user_id.presence.to_i > 0
                sender = User.find email.from_user_id
                EmailedDocumentMailer.notify_success(email, emailed_document).deliver if sender.try(:notify).try(:reception_of_emailed_docs)
              end
            end
          else
            email.update_attribute(:errors_list, emailed_document.errors)
            email.failure
            emailed_document.user && EmailedDocumentMailer.notify_failure(email, emailed_document).deliver

          end
          [emailed_document, email]
        else
          email.reject
          email
        end
      rescue => e
        email.error unless email.error?
        if email.to_user && !email.is_error_notified
          attachment_names = mail.attachments.map(&:filename).select do |filename|
            File.extname(filename).casecmp('.pdf').zero?
          end
          EmailedDocumentMailer.notify_error(email, attachment_names).deliver

          email.update_attribute(:is_error_notified, true)
        end
        if rescue_error
          email
        else
          raise e
        end
      end
    end
  end

  def initialize(mail)
    @mail = mail
    errors # instanciate errors
    save_attachments if valid?
    attachments.each(&:clean_dir)
  end

  def file_name
    "#{user.code}_#{journal}_#{period}.pdf"
  end

  def email_code
    mail_to = @mail.to.grep(/@fw.idocus.com/i).first

    @email_code ||= mail_to.split('@')[0]
  end

  def user
    @user ||= User.find_by(email_code: email_code)
  end

  def journal
    @journal ||= get_journal
  end

  def period_service
    @period_service ||= Billing::Period.new user: @user
  end

  def period
    @period ||= get_period
  end

  def pack_name
    DocumentTools.pack_name file_name
  end

  def attachments
    @attachments ||= get_attachments
  end

  def total_size
    attachments.sum(&:size)
  end

  def valid_total_size?
    total_size <= 100000.megabytes
  end

  def valid_attachments?
    @valid_attachments ||= attachments.any? && valid_individual_attachments? && valid_total_size?
  end

  def valid_individual_attachments?
    @valid_individual_attachments ||= attachments.inject(true) do |acc, attachment|
      acc && attachment.valid?
    end
  end

  def valid_attachment_sizes?
    @valid_attachment_sizes ||= attachments.inject(true) do |acc, attachment|
      acc && attachment.valid_size?
    end
  end

  def valid_attachment_contents?
    @valid_attachment_contents ||= attachments.inject(true) do |acc, attachment|
      acc && attachment.valid_content?
    end
  end

  def valid_attachment_pages_numbers?
    @valid_attachment_pages_numbers ||= attachments.inject(true) do |acc, attachment|
      acc && attachment.valid_pages_number?
    end
  end

  def invalid_attachment_contents?
    !valid_attachment_contents?
  end

  def unique_individual_attachments?
    @unique_individual_attachments ||= attachments.inject(true) do |acc, attachment|
      acc && attachment.unique?
    end
  end

  def get_invalid_attachments
    if attachments.any? && @invalid_attachments.nil?
      @invalid_attachments = []

      attachments.each do |attachment|
        next if attachment.valid?(true)
        attachment_errors = []
        attachment_errors << attachment.name
        attachment_errors << :size          unless attachment.valid_size?
        attachment_errors << :content       unless attachment.valid_content?
        attachment_errors << :pages_number  unless attachment.valid_pages_number?
        attachment_errors << :already_exist unless attachment.unique?
        @invalid_attachments << attachment_errors
      end
    end

    @invalid_attachments || []
  end

  # syntactic sugar ||= does not store false/nil value
  def valid?
    if @valid.nil?
      @valid = get_errors(false).present? ? false : true
    else
      @valid
    end
  end

  def invalid?
    !valid?
  end

  def errors
    @errors ||= get_errors
  end

  private

  def get_journal
    if user && @mail.subject.present?
      full_subject = @mail.subject
      pattern      = full_subject.split(' ')[0]

      journal   = user.account_book_types.where(name: pattern)
      journal ||= user.account_book_types.where("description LIKE '%#{pattern}%'")

      journal = user.account_book_types.where("description LIKE '%#{full_subject}%'") if journal.size != 1

      return nil if journal.size != 1
      journal.first.try(:name)
    end
  end

  def get_period
    if @mail.subject.present?
      _period = @mail.subject.split(' ')[1]
      _period = Time.now.strftime('%Y%m') if _period.to_i == 0

      period_service.include?(_period) ? _period : nil
    end
  end

  def get_attachments
    if user.present? && journal.present? && period.present?
      @mail.attachments.select do |attachment|
        supported_attachment_filename? attachment.filename
      end.map { |a| Attachment.new(a, file_name, user) }
    else
      []
    end
  end

  def supported_attachment_filename?(filename)
    return true if File.extname(filename).downcase.in?(UploadedDocument::VALID_EXTENSION)
    false
  end

  def get_errors(check_individual_attachments=true)
    _errors = []
    _errors << :code       unless user.present?
    _errors << :journal    unless journal.present?
    _errors << :period     unless period.present?
    _errors << :total_size unless valid_total_size?
    if attachments.any?
      _errors += get_invalid_attachments if check_individual_attachments
    else
      _errors << if @mail.attachments.empty?
                   :no_attachments
                 else
                   :no_acceptable_attachments
                 end
    end
    _errors
  end

  def save_attachments
    @temp_documents = []
    pack = nil

    uploader = User.find_by_email(@mail.from.first)
    prev_period_offset = Period.period_offsets(period_service)[period].to_i || 0

    attachments.each do |attachment|
      if attachment.valid?
        options = {
          delivery_type:         'upload',
          delivered_by:          uploader.try(:my_code),
          api_name:              'email',
          original_file_name:    attachment.name,
          is_content_file_valid: true,
          original_fingerprint:  attachment.fingerprint
        }

        pack ||= TempPack.find_or_create_by_name pack_name

        File.open(attachment.processed_file_path) do |file|
          @temp_documents << AddTempDocumentToTempPack.execute(pack, file, options)
        end
      else
        if attachment.corrupted?
          corrupted_doc = Archive::DocumentCorrupted.where(fingerprint: attachment.fingerprint).first || Archive::DocumentCorrupted.new

          if !corrupted_doc.persisted? && user && journal
            corrupted_doc.assign_attributes({ fingerprint: attachment.fingerprint, user: user, state: 'ready', retry_count: 0, is_notify: false, error_message: 'Votre document est en-cours de traitement', params: { original_file_name: attachment.name, uploader: uploader, api_name:  'email', journal: journal, prev_period_offset: prev_period_offset.to_i, analytic: nil, api_id: nil }})
            begin
                corrupted_doc.cloud_content_object.attach(File.open(attachment.processed_file_path), CustomUtils.clear_string(attachment.name)) if corrupted_doc.save
            rescue
            end
          end
        end
      end
    end

    pack.update_pack_state if pack
    @temp_documents
  end
end
