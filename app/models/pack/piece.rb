# -*- encoding : UTF-8 -*-
class Pack::Piece < ApplicationRecord
  ATTACHMENTS_URLS={'cloud_content' => '/account/documents/pieces/:id/download/:style'}

  attr_accessor :state_change

  serialize :tags

  validates_inclusion_of :origin, within: %w(scan upload dematbox_scan retriever)

  before_validation :set_number

  has_one    :expense, class_name: 'Pack::Report::Expense', inverse_of: :piece
  has_one    :temp_document, inverse_of: :piece

  has_many   :operations,    class_name: 'Operation', inverse_of: :piece
  has_many   :preseizures,   class_name: 'Pack::Report::Preseizure', inverse_of: :piece
  has_many   :pre_assignment_deliveries, through: :preseizures
  has_many   :temp_preseizures,  class_name: 'Pack::Report::TempPreseizure', inverse_of: :piece
  has_many   :remote_files,  as: :remotable, dependent: :destroy

  belongs_to :user
  belongs_to :pack, inverse_of: :pieces
  belongs_to :organization
  belongs_to :analytic_reference, inverse_of: :pieces, optional: true

  has_one_attached :cloud_content
  has_one_attached :cloud_content_thumbnail

  has_attached_file :content, styles: { medium: ['176x248', :png] },
                              path: ':rails_root/files/:rails_env/:class/:attachment/:mongo_id_or_id/:style/:filename',
                              url: '/account/documents/pieces/:id/download/:style'
  do_not_validate_attachment_file_type :content

  Paperclip.interpolates :mongo_id_or_id do |attachment, style|
    attachment.instance.mongo_id || attachment.instance.id
  end

  before_destroy do |piece|
    piece.cloud_content.purge

    current_analytic = piece.analytic_reference
    current_analytic.destroy if current_analytic && !current_analytic.is_used_by_other_than?({ pieces: [piece.id] })
  end

  scope :covers,                 -> { where(is_a_cover: true) }
  scope :not_covers,             -> { where(is_a_cover: false) }
  scope :scanned,                -> { where(origin: 'scan') }
  scope :retrieved,              -> { where(origin: 'retriever') }
  scope :of_month,               -> (time) { where('created_at > ? AND created_at < ?', time.beginning_of_month, time.end_of_month) }
  scope :uploaded,               -> { where(origin: 'upload') }
  scope :not_covers,             -> { where(is_a_cover: [false, nil]) }
  scope :by_position,            -> { order(position: :asc) }
  scope :dematbox_scanned,       -> { where(origin: 'dematbox_scan') }
  scope :pre_assignment_ignored, -> { where(pre_assignment_state: ['ignored', 'force_processing']) }
  scope :deleted,                -> { where.not(delete_at: nil) }

  #WORKARROUND : Get pieces with suplier_recognition state and detected_third_party_id present
  # scope :need_preassignment,   -> { where(pre_assignment_state: 'waiting') }
  scope :need_preassignment,     -> { where("DATE_FORMAT(pack_pieces.created_at, '%Y%m%d') >= #{3.months.ago.strftime('%Y%m%d')}").where('(pack_pieces.pre_assignment_state = "waiting" OR pack_pieces.pre_assignment_state = "force_processing" OR (pack_pieces.pre_assignment_state = "supplier_recognition" && pack_pieces.detected_third_party_id > 0))') }
  scope :awaiting_preassignment, -> { where('pack_pieces.pre_assignment_state = "waiting" OR pack_pieces.pre_assignment_state = "force_processing"') }

  scope :pre_assignment_supplier_recognition, -> { where(pre_assignment_state: ['supplier_recognition']) }
  scope :pre_assignment_adr, -> { where(pre_assignment_state: ['adr']) }

  default_scope { where(delete_at: [nil, '']) }

  scope :of_period, lambda { |time, duration|
    case duration
    when 1
      start_at = time.beginning_of_month
      end_at   = time.end_of_month
    when 3
      start_at = time.beginning_of_quarter
      end_at   = time.end_of_quarter
    when 12
      start_at = time.beginning_of_year
      end_at   = time.end_of_year
    end
    where('created_at >= ? AND created_at <= ?', start_at, end_at)
  }

  state_machine :pre_assignment_state, initial: :ready, namespace: :pre_assignment do
    state :ready
    state :waiting
    state :supplier_recognition
    state :adr
    state :waiting_analytics
    state :force_processing
    state :processed
    state :ignored
    state :truly_ignored
    state :not_processed

    event :ready do
      transition any => :ready
    end

    event :waiting do
      transition [:supplier_recognition, :ready, :waiting_analytics, :adr] => :waiting
    end

    event :recognize_supplier do
      transition :ready => :supplier_recognition
    end

    event :sent_to_adr do
      transition :ready => :adr
    end

    event :waiting_analytics do
      transition :ready => :waiting_analytics
    end

    event :force_processing do
      transition [:ready, :waiting, :waiting_analytics, :ignored] => :force_processing
    end

    event :processed do
      transition [:waiting, :force_processing] => :processed
    end

    event :ignored do
      transition waiting: :ignored
    end

    event :confirm_ignorance do
      transition ignored: :truly_ignored
    end

    event :not_processed do
      transition [:waiting, :force_processing] => :not_processed
    end
  end

  def self.search(text, options = {})
    page = options[:page] || 1
    per_page = options[:per_page] || default_per_page

    query = self

    query = query.joins(:pack) if options[:pack_id].present? || options[:pack_name].present? || options[:pack_ids].present? || options[:pack_name].present?

    query = query.where(id: options[:id])                                                        if options[:id].present?
    query = query.where(id: options[:ids])                                                       if options[:ids].present?
    query = query.where(user_id: options[:user_ids])                                             if options[:user_ids].present?
    query = query.where('packs.id = ?', options[:pack_id] )                                      if options[:pack_id].present?
    query = query.where('packs.id IN (?)', options[:pack_ids])                                   if options[:pack_ids].present?
    query = query.where('packs.name LIKE ?', "%#{options[:pack_name]}%")                         if options[:pack_name].present?
    query = query.where('pack_pieces.tags LIKE ?', "%#{options[:tags]}%")                        if options[:tags].present?
    query = query.where('pack_pieces.name LIKE ?', "%#{options[:piece_name]}%")                  if options[:piece_name].present?
    query = query.where('pack_pieces.number LIKE ?', "%#{options[:piece_number]}%")              if options[:piece_number].present?
    query = query.where('pack_pieces.pre_assignment_state = ?', options[:pre_assignment_state])  if options[:pre_assignment_state].present?

    query = query.where( options[:journal].map{ |jl| "pack_pieces.name LIKE '% #{jl} %'" }.join(' OR ') ) if options[:journal].present?
    query = query.where( options[:period].map{ |pr| "pack_pieces.name LIKE '% #{pr} %'" }.join(' OR ') )  if options[:period].present?

    if options[:position_operation].present?
      query = query.where("pack_pieces.position #{options[:position_operation].tr('012', ' ><')}= ?", options[:position]) if options[:position].present?
    else
      query = query.where("pack_pieces.position IN (#{options[:position].join(',')})" ) if options[:position].present?
    end

    query = query.where("pack_pieces.created_at BETWEEN '#{CustomUtils.parse_date_range_of(options[:created_at]).join("' AND '")}'") if options[:created_at].present?

    query = query.where('pack_pieces.name LIKE ? OR pack_pieces.content_text LIKE ?', "%#{text}%", "%#{text}%") if text.present?

    query = query.joins(:preseizures) if options[:third_party].present? || options[:date].present?

    query = query.where('pack_report_preseizures.third_party LIKE ?', "%#{options[:third_party]}%" )  if options[:third_party].present?
    query = query.where("pack_report_preseizures.date BETWEEN '#{CustomUtils.parse_date_range_of(options[:date]).join("' AND '")}'") if options[:date].present?

    query.order(position: :asc) if options[:sort] == true


    query.page(page).per(per_page)
  end

  def self.with_preseizures(user_ids, options={})
    query = self.where('pack_pieces.user_id IN (?)', Array(user_ids)).left_joins(:preseizures)

    ###### QUERY BY PIECES ########
    query = query.where('pack_pieces.tags LIKE ?', "%#{options[:tags]}%")                        if options[:tags].present?
    query = query.where('pack_pieces.name LIKE ?', "%#{options[:piece_name]}%")                  if options[:piece_name].present?
    query = query.where('pack_pieces.pre_assignment_state = ?', options[:pre_assignment_state])  if options[:pre_assignment_state].present?

    query = query.where( options[:journal].map{ |jl| "pack_pieces.name LIKE '% #{jl} %'" }.join(' OR ') ) if options[:journal].present?
    query = query.where( options[:period].map{ |pr| "pack_pieces.name LIKE '% #{pr} %'" }.join(' OR ') )  if options[:period].present?

    if options[:position_operation].present?
      query = query.where("pack_pieces.position #{options[:position_operation].tr('012', ' ><')}= ?", options[:position]) if options[:position].present?
    else
      query = query.where("pack_pieces.position IN (#{Array(options[:position]).join(',')})" ) if options[:position].present?
    end

    query = query.where("pack_pieces.created_at BETWEEN '#{CustomUtils.parse_date_range_of(options[:created_at]).join("' AND '")}'") if options[:created_at].present?
    query = query.where('pack_pieces.name LIKE ? OR pack_pieces.content_text LIKE ?', "%#{options[:content]}%", "%#{options[:content]}%") if options[:content].present?

    ##### QUERY BY PRESEIZURES ######
    query = query.where('pack_report_preseizures.piece_number LIKE ?', "%#{options[:piece_number]}%")              if options[:piece_number].present?
    query = query.where('pack_report_preseizures.third_party LIKE ?', "%#{options[:third_party]}%" )                                 if options[:third_party].present?
    query = query.where("pack_report_preseizures.date BETWEEN '#{CustomUtils.parse_date_range_of(options[:date]).join("' AND '")}'") if options[:date].present?

    query = query.merge(Pack::Report::Preseizure.delivered)          if options[:is_delivered].present? && options[:is_delivered].to_i == 1
    query = query.merge(Pack::Report::Preseizure.not_delivered)      if options[:is_delivered].present? && options[:is_delivered].to_i == 2
    query = query.merge(Pack::Report::Preseizure.failed_delivery)    if options[:is_delivered].present? && options[:is_delivered].to_i == 3

    query = query.merge(Pack::Report::Preseizure.exported)           if options[:is_delivered].present? && options[:is_delivered].to_i == 4
    query = query.merge(Pack::Report::Preseizure.not_exported)       if options[:is_delivered].present? && options[:is_delivered].to_i == 5

    query = query.where("pack_report_preseizures.cached_amount #{options[:amount_operation].tr('012', ' ><')}= ?", options[:amount].tr(',','.')) if options[:amount].present?
    query = query.where("pack_report_preseizures.delivery_tried_at BETWEEN '#{CustomUtils.parse_date_range_of(options[:delivery_tried_at]).join("' AND '")}'")  if options[:delivery_tried_at].present?

    options[:per_page].present? ? query.page(options[:page].presence || 1).per(options[:per_page]) : query
    
  end

  def self.finalize_piece(id)
    piece = Pack::Piece.find(id)

    unless piece.tags.present?
      piece.init_tags
      piece.save
    end

    return true if piece.is_finalized

    piece.is_finalized = true
    self.extract_content(piece) unless piece.content_text.present?
    self.generate_thumbs(piece.id)

    piece.save
  end

  def self.generate_thumbs(id)
    piece = Pack::Piece.find(id)

    base_file_name = piece.cloud_content_object.filename.to_s.gsub('.pdf', '')

    begin
      image = MiniMagick::Image.read(piece.cloud_content.download).format('png').resize('176x248')

      piece.cloud_content_thumbnail.attach(io: File.open(image.tempfile),
                                           filename: "#{base_file_name}.png",
                                           content_type: "image/png")
    rescue
      piece.is_finalized = false
    end

    piece.save
  end

  def self.extract_content(piece)
    begin
      path = piece.cloud_content_object.path

      POSIX::Spawn.system "pdftotext -raw -nopgbrk -q #{path}"

      dirname  = File.dirname(path)
      filename = File.basename(path, '.pdf') + '.txt'
      filepath = File.join(dirname, filename)

      if File.exist?(filepath)
        text = File.open(filepath, 'r').readlines.map(&:strip).join(' ')
        # remove special character, which will not be used on search anyway
        text = text.each_char.select { |c| c.bytes.size < 4 }.join
        piece.content_text = text
      end

      piece.content_text = ' ' unless piece.content_text.present?

      piece.save
    rescue => e
      piece.is_finalized = false
    end
  end

  def self.correct_pdf_signature_of(piece_id)
    piece = Pack::Piece.find piece_id
    piece.correct_pdf_signature
  end

  def cloud_content_object
    CustomActiveStorageObject.new(self, :cloud_content)
  end

  def recreate_pdf(temp_dir = nil, keep_temp_document = false, attempt=0)
    return false unless temp_document

    p "==//////////////////////////////////////////// ATTEMPT : #{attempt} ///////////////////////////////////////////////////=====" 

    return false if attempt > 2

    piece_file_path = ''


    CustomUtils.mktmpdir('piece', temp_dir, !temp_dir.present?) do |dir|
      piece_file_name = DocumentTools.file_name self.name
      piece_file_path = File.join(dir, piece_file_name)

      original_file_path = File.join(dir, 'original.pdf')

      FileUtils.cp temp_document.cloud_content_object.reload.path, original_file_path

      if temp_document.api_name == 'jefacture'
        self.cloud_content_object.attach(File.open(original_file_path), piece_file_name)
      else
        if keep_temp_document
          piece_file_path = temp_document.cloud_content_object.reload.path
        else
          DocumentTools.correct_pdf_if_needed original_file_path

          DocumentTools.create_stamped_file original_file_path, piece_file_path, user.stamp_name, self.name, {origin: temp_document.delivery_type, is_stamp_background_filled: user.is_stamp_background_filled, dir: dir}
        end

        self.cloud_content_object.attach(File.open(piece_file_path), piece_file_name)

        self.try(:sign_piece) if attempt <= 1

        sleep(3)

        self.recreate_pdf(nil, true, (attempt + 1)) if not DocumentTools.modifiable?(self.cloud_content_object.reload.path)
      end

      self.get_pages_number
    end

    piece_file_path
  end

  def correct_pdf_signature
    begin
      sign_piece if DocumentTools.correct_pdf_if_needed(self.cloud_content_object.path)
    rescue => e
      recreate_pdf
    end
  end

  def sign_piece
    return true if self.temp_document.api_name == 'jefacture'

    begin
      content_file_path = self.cloud_content_object.reload.path
      to_sign_file = File.dirname(content_file_path) + '/signed.pdf'

      DocumentTools.sign_pdf(content_file_path, to_sign_file)

      if File.exist?(to_sign_file.to_s)
        self.is_signed = true
        self.cloud_content_object.attach(File.open(to_sign_file), self.cloud_content_object.filename) if self.save
      else
        System::Log.info('pieces_events', "[Signing] #{self.id} - #{self.name} - Piece can't be saved or signed file not genereted (#{to_sign_file.to_s})")
        self.is_signed = false
        self.save

        Pack::Piece.delay_for(20.minutes, queue: :default).correct_pdf_signature_of(self.id)
      end
    rescue => e
      System::Log.info('pieces_events', "[Signing] #{self.id} - #{self.name} - #{e.to_s} (#{to_sign_file.to_s})")
      self.is_signed = false
      self.save

      Pack::Piece.delay_for(2.hours, queue: :default).correct_pdf_signature_of(self.id)
    end
  end

  def init_tags
    self.tags = pack.name.downcase.sub(' all', '').split

    tags << position if position

    td_tags = self.temp_document.try(:tags).presence || []

    td_tags.each do |tg|
      tags << tg
    end
  end

  def get_token
    if token.present?
      token
    else
      update_attribute(:token, rand(36**50).to_s(36))

      token
    end
  end


  def get_access_url(style = :original)
    "/account/documents/pieces/#{id}/download/#{style}" + '?token=' + get_token
  end


  def journal(name_only = true)
    _name = name.split[1]

    return _name if name_only
    self.user.account_book_types.where(name: _name).first
  end

  def is_deleted?
    self.delete_at.present?
  end

  def scanned?
    origin == 'scan'
  end


  def uploaded?
    origin == 'upload'
  end


  def dematbox_scanned?
    origin == 'dematbox_scan'
  end


  def retrieved?
    origin == 'retriever'
  end

  def from_web?
    temp_document.try(:api_name) == 'web'
  end

  def from_mobile?
    temp_document.try(:api_name) == 'mobile'
  end

  def from_mcf?
    temp_document.try(:api_name) == 'mcf'
  end

  def get_pages_number
    return self.pages_number if self.pages_number > 0

    begin
      self.pages_number = DocumentTools.pages_number(self.cloud_content_object.path)
      save
    rescue
      0
    end
    return self.pages_number
  end

  def is_awaiting_pre_assignment?
    self.pre_assignment_waiting? || self.pre_assignment_force_processing?
  end

  def is_already_pre_assigned_with?(process='preseizure')
    process == 'preseizure' ? preseizures.any? : expense.present?
  end

  def get_state_to(type='image')
    text    = 'none'
    img_url = ''

    if self.pre_assignment_waiting_analytics?
      text    = 'awaiting_analytics'
      img_url = 'application/compta_analytics.png'
    elsif self.is_awaiting_pre_assignment? || self.pre_assignment_adr?
      text    = 'awaiting_pre_assignment'
      img_url = 'application/preaff_pending.png'
    elsif self.preseizures.delivered.count > 0
      text    = 'delivered'
      img_url = 'application/preaff_deliv.png'
    elsif self.preseizures.not_delivered.count > 0 && self.user.uses_api_softwares?
      text    = 'delivery_pending'
      img_url = 'application/preaff_deliv_pending.png'
    elsif self.preseizures.failed_delivery.count > 0
      text    = 'delivery_failed'
      img_url = 'application/preaff_err.png'
    elsif Pack::Report::Preseizure.unscoped.where(piece_id: self.id, is_blocked_for_duplication: true).count > 0
      text    = 'duplication'
      img_url = 'application/preaff_dupl.png'
    elsif self.pre_assignment_ignored? || self.pre_assignment_truly_ignored?
      text    = 'piece_ignored'
      img_url = 'application/preaff_ignored.png'
    elsif self.preseizures.empty? && self.pre_assignment_not_processed?
      text   = 'not_processed'
    elsif self.preseizures.empty? && self.pre_assignment_processed?
      text   = 'processed'
    end

    return text if type.to_s == 'text'
    return img_url
  end

  def get_tags(separator='-')
    filters = self.name.split.collect do |f|
      f.strip.match(/^[0-9]+$/) ? f.strip.to_i.to_s : f.strip.downcase
    end

    _tags = self.tags.present? ? self.tags.select{ |tag| !filters.include?(tag.to_s.strip.downcase) } : []

    _tags.join(" #{separator} ").presence || ''
  end

  def is_forced?
    self.temp_document.is_forced
  end

  private

  def set_number
    self.number = DbaSequence.next('Piece') unless number
  end
end
