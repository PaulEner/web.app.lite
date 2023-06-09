# -*- encoding : UTF-8 -*-
require 'mini_magick'

class TempDocument < ApplicationRecord
  ATTACHMENTS_URLS={'cloud_content' => '/account/documents/processing/:id/download/:style'}

  attr_accessor :file_base64, :accounting_type

  serialize :scan_bundling_document_ids, Array
  serialize :parents_documents_pages, Array
  serialize :parents_documents_ids, Array

  serialize :tags

  validates_inclusion_of :delivery_type, within: %w(scan upload dematbox_scan retriever)

  serialize :retrieved_metadata, Hash
  serialize :metadata, Hash

  belongs_to :user
  belongs_to :email, optional: true
  belongs_to :piece, class_name: 'Pack::Piece', inverse_of: :temp_document, optional: true
  belongs_to :temp_pack
  belongs_to :organization
  belongs_to :document_delivery, optional: true
  belongs_to :retriever, optional: true
  belongs_to :ibizabox_folder, optional: true
  belongs_to :analytic_reference, optional: true
  has_many :notifiables, dependent: :destroy, as: :notifiable
  # TODO : rename me
  has_one    :metadata2, class_name: 'TempDocumentMetadata'

  has_many :archive_already_exist, class_name: 'Archive::AlreadyExist'

  has_one_attached :cloud_content
  has_one_attached :cloud_raw_content
  has_one_attached :cloud_content_thumbnail

  has_attached_file :content, styles: { medium: ['176x248', :png] },
                              path: ':rails_root/files/:rails_env/:class/:mongo_id_or_id/:filename',
                              url: '/account/documents/processing/:id/download/:style'
  do_not_validate_attachment_file_type :content

  has_attached_file :raw_content, path: ':rails_root/files/:rails_env/:class/:mongo_id_or_id/raw_content/:filename'
  do_not_validate_attachment_file_type :raw_content

  Paperclip.interpolates :mongo_id_or_id do |attachment, style|
    attachment.instance.mongo_id || attachment.instance.id
  end

  # before_content_post_process :is_thumb_generated

  after_create_commit do |temp_document|
    unless Rails.env.test?
      TempDocument.delay_for(10.seconds, queue: :high).generate_thumbs(temp_document.id)
    end
  end

  after_save do |temp_document|
    unless Rails.env.test?
      Rails.cache.write(['user', temp_document.user.id, 'temp_documents', 'last_updated_at'], Time.now.to_i)
    end
  end

  before_destroy do |temp_document|
    temp_document.cloud_content.purge
    temp_document.cloud_raw_content.purge

    current_analytic = temp_document.analytic_reference
    current_analytic.destroy if current_analytic && !current_analytic.is_used_by_other_than?({ temp_documents: [temp_document.id] })
  end

  scope :scan,              -> { where(delivery_type: 'scan') }
  scope :valid,             -> { where(state: %w(ready ocr_needed bundle_needed bundled processed)) }
  scope :ready,             -> { where(state: 'ready', is_locked: false) }
  scope :locked,            -> { where(is_locked: true) }
  scope :upload,            -> { where(delivery_type: 'upload') }
  scope :retrieved,         -> { where(delivery_type: 'retriever') }
  scope :created,           -> { where(state: 'created') }
  scope :bundled,           -> { where(state: 'bundled') }
  scope :originals,         -> { where(is_an_original: true) }
  scope :processed,         -> { where(state: %w(processed bundled)) }
  scope :not_locked,        -> { where(is_locked: false) }
  scope :unreadable,        -> { where(state: 'unreadable') }
  scope :ocr_needed,        -> { where(state: 'ocr_needed') }
  scope :by_position,       -> { order(position: :asc) }
  scope :not_processed,     -> { where.not(state: %w(processed)) }
  scope :dematbox_scan,     -> { where(delivery_type: 'dematbox_scan') }
  scope :not_published,     -> { where.not(state: %w(processed bundled wait_selection unreadable)) }
  scope :bundle_needed,     -> { where(state: 'bundle_needed', is_locked: false) }
  scope :wait_selection,    -> { where(state: 'wait_selection') }
  scope :ocr_layer_applied, -> { where(is_ocr_layer_applied: true) }
  scope :from_ibizabox,     -> { where.not(ibizabox_folder_id: nil) }
  scope :not_deleted,       -> { where.not(original_fingerprint: nil) }
  scope :from_mobile,       -> { where("state='processed' AND delivery_type = 'upload' AND api_name = 'mobile'") }
  scope :by_source, -> (delivery_type) { where('delivery_type = ?', delivery_type) }
  scope :with, -> (period) { where(updated_at: period) }


  state_machine initial: :created do
    state :ready
    state :created
    state :bundled
    state :processed
    state :unreadable
    state :ocr_needed
    state :bundle_needed
    state :wait_selection


    before_transition any => any do |temp_document, _transition|
      temp_document.stated_at = Time.now
    end

    after_transition on: :ocr_needed do |temp_document, _transition|
      AccountingWorkflow::OcrProcessing.delay_for(10.seconds, queue: :high).send_document(temp_document.id)
    end


    event :unreadable do
      transition [:created, :ready] => :unreadable
    end


    event :wait_selection do
      transition created: :wait_selection
    end


    event :ocr_needed do
      transition [:created, :wait_selection] => :ocr_needed
    end


    event :bundle_needed do
      transition [:created, :unreadable, :wait_selection, :ocr_needed] => :bundle_needed
    end


    event :bundled do
      transition bundle_needed: :bundled
    end


    event :ready do
      transition [:created, :unreadable, :wait_selection, :ocr_needed] => :ready
    end


    event :processed do
      transition [:ready] => :processed
    end
  end

  def self.search(options, text="")
    page     = options[:page] || 1
    per_page = options[:per_page] || 20

    query = self.all

    query = query.where(temp_pack_id: options[:temp_pack_ids])                                   if options[:temp_pack_ids]

    query = query.where(user_id: options[:user_ids])                                             if options[:user_ids].present?
    query = query.where('temp_documents.tags LIKE ?', "%#{options[:tags]}%")                     if options[:tags].present?
    query = query.where('temp_documents.original_file_name LIKE ? OR temp_documents.tags LIKE ?', "%#{text}%", "%#{text}%")    if text.present?
    query = query.joins(:piece)                                                                  if options[:position].present? || options[:pre_assignment_state].present?
    query = query.where('pack_pieces.pre_assignment_state = ?', options[:pre_assignment_state])  if options[:pre_assignment_state].present?

    if options[:position_operation].present?
      query = query.where("pack_pieces.position #{options[:position_operation].tr('012', ' ><')}= ?", options[:position]) if options[:position].present?
    else
      query = query.where("pack_pieces.position IN (#{options[:position].join(',')})" ) if options[:position].present?
    end

    query.page(page).per(per_page)      
  end

  def self.find_with(options)
    where(options).first
  end


  def self.find_or_initialize_with(options)
    if (temp_document = find_with(options))
      temp_document
    else
      TempDocument.new(options)
    end
  end


  def self.find_by_dematbox_doc_id(id)
    where(dematbox_doc_id: id).first
  end


  def self.find_or_initialize_by_dematbox_doc_id(id)
    if (temp_document = find_by_dematbox_doc_id(id))
      temp_document
    else
      TempDocument.new(dematbox_doc_id: id)
    end
  end


  def self.generate_thumbs(id)
    temp_document = TempDocument.find(id)

    base_file_name = temp_document.cloud_content_object.filename.to_s.gsub('.pdf', '')

    begin
      temp_document.is_thumb_generated = true

      image = MiniMagick::Image.read(temp_document.cloud_content.download).format('png').resize('176x248')

      temp_document.cloud_content_thumbnail.attach(io: File.open(image.tempfile), 
                                                   filename: "#{base_file_name}.png", 
                                                   content_type: "image/png")
    rescue
      temp_document.is_thumb_generated = false
    end

    #TEMP : check temp_document saving error (if temp_pack becomes nil)
    raise temp_document.errors.messages.to_s unless temp_document.save
  end


  def self.search_dematbox_files(contains)
    dematbox_files = TempDocument.dematbox_scan.originals

    dematbox_files = dematbox_files.where(dematbox_doc_id: contains[:dematbox_doc_id]) if contains[:dematbox_doc_id]

    dematbox_files = dematbox_files.where("created_at BETWEEN '#{CustomUtils.parse_date_range_of(contains[:created_at]).join("' AND '")}'") if contains[:created_at].present?

    dematbox_files = dematbox_files.where(delivered_by: contains[:delivered_by]) if contains[:delivered_by]

    dematbox_files = dematbox_files.where('content_file_name LIKE ?', "%#{contains[:content_file_name]}%") if contains[:content_file_name]

    dematbox_files = dematbox_files.where(dematbox_is_notified: contains[:dematbox_is_notified]) if contains[:dematbox_is_notified]

    dematbox_files
  end


  def self.search_for_collection(collection, contains)
    user = collection.first.user if collection.first

    if user
      if contains[:service_name]
        retriever_ids = user.retrievers.where("name LIKE ?", "%#{contains[:service_name]}%").pluck(:id)
        collection = collection.where(retriever_id: retriever_ids)
      elsif contains[:retriever_id]
        retriever = user.retrievers.find(contains[:retriever_id])
        collection = collection.where(retriever_id: retriever.id)
      end
    end

    collection = collection.where("temp_document_metadata.date BETWEEN '#{CustomUtils.parse_date_range_of(contains[:date]).join("' AND '")}'")  if contains[:date].present?

    collection = collection.where("temp_document_metadata.name LIKE ?", "%#{contains[:name]}%") if contains[:name].present?

    if contains[:amount_operation].present?
      collection = collection.where("temp_document_metadata.amount #{contains[:amount_operation].tr('012', ' ><')}= ?", contains[:amount].to_f) if contains[:amount].present?
    else
      collection = collection.where("temp_document_metadata.amount = ?", contains[:amount].to_f) if contains[:amount].present?
    end

    collection
  end

  def self.search_ibizabox_collection(collection, contains)
    if contains[:name]
      collection = collection.where("original_file_name LIKE ?", "%#{contains[:name]}%")
    end

    if contains[:journal]
      collection = collection.where("account_book_types.name LIKE ?", "%#{contains[:journal]}%")
    end

    if contains[:date]
      contains[:date].each do |operator, value|
        collection = collection.where("created_at #{operator} ?", value) if operator.in?(['>=', '<='])
      end
    end

    collection
  end

  def self.recreate_grouped_document(temp_doc_id)
    temp_document = TempDocument.find temp_doc_id
    temp_document.recreate_grouped_document
  end


  def self.api_names
    api_names = TempDocument.with([30.days.ago..Time.now]).select(:api_name).distinct.pluck(:api_name)

    api_names_count = []
    api_names.each do |api_name|
      count = TempDocument.with([30.days.ago..Time.now]).where(api_name: api_name).size
      api_name = 'aucun' if !api_name.present?
      api_names_count << {api_name: api_name, count: count}
    end

    total = 0
    api_names_count.each{|_count| total += _count[:count]}
    api_names_count << {api_name: 'total', count: total}

    api_names_count
  end

  def children
    result    = []

    self.temp_pack.temp_documents.each do |td|
      result << td if Array(td.parents_documents_ids.presence).include? self.id
    end

    return result
  end

  def fingerprint_is_nil?
    original_fingerprint.blank? && content_fingerprint.blank? && raw_content_fingerprint.blank?
  end

  def recreate_pdf
    raw_path = self.cloud_raw_content_object.reload.path

    if File.exist?(raw_path.to_s)
      self.cloud_content_object.attach(File.open(raw_path), "#{self.content_file_name}.pdf")

      if not ['bundled', 'processed'].include?(self.state)
        self.state = 'ocr_needed'
        self.save

        AccountingWorkflow::OcrProcessing.delay_for(10.seconds, queue: :high).send_document(self.id)
      end

      self.cloud_content_object.reload.path
    else
      return false
    end
  end

  def recreate_grouped_document
    _parents_documents_pages = self.parents_documents_pages
    if parents_documents.any? && _parents_documents_pages.present? && _parents_documents_pages.any?
      retries_number = 0

      begin
        CustomUtils.mktmpdir('recreate_grouped_document') do |dir|
          merged_paths        = []
          pages               = []
          parent_document_ids = []

          _parents_documents_pages.each do |parent_document_pages|
            parent_document_ids << parent_document_pages[:parent_document_id]
            _parent_document = TempDocument.find parent_document_pages[:parent_document_id]
            pages << parent_document_pages[:pages]

            merged_dir = File.join(dir, "#{parent_document_pages[:parent_document_id]}")
            FileUtils.mkdir_p merged_dir

            merged_paths << merged_dir

            Pdftk.new.burst _parent_document.cloud_content_object.path, merged_dir, "page_#{parent_document_pages[:parent_document_id]}", DataProcessor::TempPack::POSITION_SIZE
          end

          file_path = File.join(dir, self.temp_pack.name.tr('%', '_').tr(' ', '_') + '.pdf')

          files = file_paths(merged_paths, pages, parent_document_ids)

          if files.size > 1
            is_merged = Pdftk.new.merge files, file_path
          else
            is_merged = true
            FileUtils.cp files.first, file_path
          end

          if is_merged
            self.update_attributes(pages_number: DocumentTools.pages_number(file_path), original_fingerprint: DocumentTools.checksum(file_path))
            self.cloud_content_object.attach(File.open(file_path), File.basename(file_path))
            self.ready if self.state == 'unreadable'
          elsif retries_number < 3
            raise
          end
        end
      rescue
        sleep(30)
        retries_number += 1
        retry
      end
    end

    self.reload.cloud_content_object.reload.path.present?
  end

  def cloud_content_object
    CustomActiveStorageObject.new(self, :cloud_content)
  end

  def cloud_raw_content_object
    CustomActiveStorageObject.new(self, :cloud_raw_content)
  end

  def name_with_position
    name = File.basename self.cloud_content_object.filename, '.*'
    name.sub!(/_\d+\z/, '') if scanned?
    name = name.gsub('%', '_')

    "#{name}_%0#{DataProcessor::TempPack::POSITION_SIZE}d" % position
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
    "/account/documents/temp_documents/#{id}/download/#{style}" + '?token=' + get_token
  end


  def file_name_with_position
    extension = File.extname(self.cloud_content_object.filename)

    "#{name_with_position}#{extension}"
  end


  def scanned?
    delivery_type == 'scan'
  end


  def uploaded?
    delivery_type == 'upload'
  end


  def scanned_with_dematbox?
    delivery_type == 'dematbox_scan'
  end


  def retrieved?
    delivery_type == 'retriever'
  end

  def from_ibizabox?
    delivered_by == 'ibiza'
  end

  def get_tags(separator='-')
    if tags.present?
      tags.join(" #{separator} ").presence || '-'
    else
      '-'
    end
  end

  def is_a_cover?
    if scanned?
      if !Array(self.parents_documents_ids.presence).any? && original_file_name.present?
        case original_file_name
        when /\A#{Pack::CODE_PATTERN}(_| )#{Pack::JOURNAL_PATTERN}(_| )#{Pack::PERIOD_PATTERN}(_| )#{Pack::POSITION_PATTERN}#{Pack::EXTENSION_PATTERN}\z/
          File.basename(original_file_name, '.*').tr(' ', '_').split('_')[3].match(/\A0*\z/).present?
        when /\A#{Pack::CODE_PATTERN}(_| )#{Pack::JOURNAL_PATTERN}(_| )#{Pack::PERIOD_PATTERN}(_| )page\d{3,4}#{Pack::EXTENSION_PATTERN}\z/
          File.basename(original_file_name, '.*').tr(' ', '_').split('_')[3].match(/\Apage0001\z/).present?
        else
          is_a_cover
        end
      else
        is_a_cover
      end
    else
      false
    end
  end

  def is_bundle_needed?
    return false if self.temp_pack.organization_id == Organization.find_by_code('TEEO').try(:id)

   ( self.scanned? || self.pages_number > 2 || (self.api_name == 'mobile' && self.pages_number > 1) ) && self.temp_pack.is_compta_processable? && !self.from_ibizabox? && !self.retrieved?
  end

  def corruption_notified
    self.is_corruption_notified = true
    self.corruption_notified_at = Time.now

    save
  end

  def parents_documents
    self.temp_pack.temp_documents.where(id: Array(self.parents_documents_ids.presence))
  end

  private

  def file_paths(merged_paths, pages, parent_document_ids)
    _file_paths = []

    pages.each_with_index do |pages, index_page|
      pages.map{|page| _file_paths << File.join(merged_paths[index_page], "page_#{parent_document_ids[index_page]}_" + ("%03d" % page) + ".pdf") }
    end

    _file_paths
  end
end
