# -*- encoding : UTF-8 -*-
class Pack::Report < ApplicationRecord
  self.inheritance_column = :_type_disabled

  has_many   :expenses,     class_name: 'Pack::Report::Expense',    inverse_of: :report, dependent: :destroy
  has_many   :preseizures,  class_name: 'Pack::Report::Preseizure', inverse_of: :report, dependent: :destroy
  has_many   :temp_preseizures,  class_name: 'Pack::Report::TempPreseizure', inverse_of: :report, dependent: :destroy
  has_many   :remote_files, as: :remotable, dependent: :destroy
  has_many   :pre_assignment_deliveries
  has_many   :pre_assignment_exports


  belongs_to :user
  belongs_to :pack, optional: true
  belongs_to :document, class_name: 'PeriodDocument', inverse_of: :report, foreign_key: :document_id, optional: true
  belongs_to :organization

  scope :not_delivered,             -> { joins(:preseizures).merge(Pack::Report::Preseizure.not_deleted.not_delivered).distinct }
  scope :delivered,                 -> { joins(:preseizures).merge(Pack::Report::Preseizure.not_deleted.delivered).distinct }

  scope :locked,                    -> { where(is_locked: true) }
  scope :expenses,                  -> { where(type: 'NDF') }
  scope :not_locked,                -> { where(is_locked: false) }
  scope :preseizures,               -> { where.not(type: ['NDF']) }

  def self.search(options)
    reports = self.all

    reports = reports.where(id: options[:ids])                                  if options[:ids].present?
    reports = reports.where(user_id: options[:user_ids])                        if options[:user_ids].present?
    reports = reports.where('pack_reports.name LIKE ?', "%#{options[:text]}%")  if options[:text].present?
    reports = reports.preseizures.joins(:preseizures).where("pack_report_preseizures.position #{options[:position_operation].tr('012', ' ><')}= ?", options[:position]) if options[:position].present?
    reports = reports.where( options[:journal].map{ |jl| "pack_reports.name LIKE '% #{jl} %'" }.join(' OR ') ) if options[:journal].present?

    reports
  end

  # def self.delivered(software=nil)
  #   reports = self.all
  #   software.nil? ? reports.where.not(is_delivered_to: [nil, '']) : reports.where("is_delivered_to = '#{software}'")
  # end

  def journal(options={ name_only: true })
    #TODO : separate journal and journal name
    result = name.split[1]
    journal = user ? user.account_book_types.where(name: result).first : nil

    if options[:name_only]
      journal.try(:get_name) || result
    else
      journal
    end
  end

  def period
    name.split[2] || '0000'
  end

  def is_delivered?
    self.preseizures.not_deleted.delivered.first.present?

    # self.preseizures.not_deleted.delivered('ibiza').first.present? ||
    # self.preseizures.not_deleted.delivered('exact_online').first.present? ||
    # self.preseizures.not_deleted.delivered('my_unisoft').first.present? ||
    # self.preseizures.not_deleted.delivered('sage_gec').first.present? ||
    # self.preseizures.not_deleted.delivered('acd').first.present? 
  end

  def is_not_delivered?
    self.preseizures.not_deleted.not_delivered.first.present?

    # self.preseizures.not_deleted.not_delivered('ibiza').first.present? ||
    # self.preseizures.not_deleted.not_delivered('exact_online').first.present? ||
    # self.preseizures.not_deleted.not_delivered('my_unisoft').first.present? ||
    # self.preseizures.not_deleted.not_delivered('sage_gec').first.present? ||
    # self.preseizures.not_deleted.not_delivered('acd').first.present?
  end

  def self.failed_delivery(user_ids = [], limit = 50)
    return [] unless user_ids.present? || user_ids.nil?

    _result = Rails.cache.fetch ['report.failed_delivery', user_ids.presence || 'all'], expires_in: 5.minutes do
      collections = []

      if user_ids.present?
        collections = Pack::Report::Preseizure.not_deleted.failed_delivery.where(user_id: user_ids).joins(:report).select(:id, :delivery_tried_at, :delivery_message, :report_id, 'pack_reports.name as name').to_a
      else
        collections = Pack::Report::Preseizure.not_deleted.failed_delivery.joins(:report).select(:id, :delivery_tried_at, :delivery_message, :report_id, 'pack_reports.name as name').to_a
      end

      result = []
      if collections.any?
        collections.sort_by(&:delivery_tried_at).reverse.group_by(&:report_id).each do |report_id, preseizures_by_report|
          preseizures_by_report.group_by(&:delivery_message).each do |message, preseizures|
            preseizures_count     = preseizures.size
            max_date              = preseizures.first.delivery_tried_at
            message_ibiza         = preseizures.first.get_delivery_message_of('ibiza')
            message_exact_online  = preseizures.first.get_delivery_message_of('exact_online')
            message_my_unisoft    = preseizures.first.get_delivery_message_of('my_unisoft')
            message_sage_gec      = preseizures.first.get_delivery_message_of('sage_gec')
            message_acd           = preseizures.first.get_delivery_message_of('acd')

            if message_ibiza.present? && message_exact_online.present? && message_my_unisoft.present?
              full_message = "-iBiza : #{message_ibiza} <br> -ExactOnline : #{message_exact_online} <br> -MyUnisoft : #{message_my_unisoft} <br> -Sage GEC : #{message_sage_gec} <br> -ACD : #{message_acd}"
            else
              full_message = message_ibiza.presence || message_exact_online.presence || message_my_unisoft.presence || message_sage_gec.presence || message_acd.presence
            end

            result << OpenStruct.new({id: report_id, pack_id: Pack::Report.where(id: report_id).pluck(:pack_id).first , date: max_date, document_count: preseizures_count, name: preseizures.first.try(:name), message: full_message})
          end
        end
      end

      result
    end

    _result.take(limit)
  end

  def self.search_failed_delivery(user_ids)
    report = Pack::Report.where(user_id: user_ids)

    report = report.joins(:preseizures).merge(Pack::Report::Preseizure.not_deleted.failed_delivery.recent).group('pack_reports.id', :delivery_message).select('pack_reports.id as report_id', 'pack_reports.name as name', 'pack_report_preseizures.delivery_message as message', 'count(pack_report_preseizures.id) as preseizures_count', 'MAX(pack_report_preseizures.updated_at) as max_date', 'pack_report_preseizures.id as preseizure_id', 'pack_reports.pack_id as pack_id')

    report.order('max_date DESC')
  end

  def delivered_to(software)
    return true if is_delivered_to?(software)

    # softwares = self.is_delivered_to.split(',') || []
    # softwares << software
    # self.is_delivered_to = softwares.sort.join(',')
    self.is_delivered_to = software

    save
  end

  def remove_delivered_to
    # temp_delivered_to = self.is_delivered_to
    # temp_delivered_to = temp_delivered_to.gsub('ibiza', '') if self.user.uses?(:ibiza)
    # temp_delivered_to = temp_delivered_to.gsub('exact_online', '') if self.user.uses?(:exact_online)
    # temp_delivered_to = temp_delivered_to.gsub('my_unisoft', '') if self.user.uses?(:my_unisoft)
    # temp_delivered_to = temp_delivered_to.gsub('sage_gec', '') if self.user.uses?(:sage_gec)
    # temp_delivered_to = temp_delivered_to.gsub('acd', '') if self.user.uses?(:acd)
    # temp_delivered_to = temp_delivered_to.gsub(/^[,]+/, '')
    # temp_delivered_to = temp_delivered_to.gsub(/[,]+$/, '')
    # temp_delivered_to = temp_delivered_to.gsub(/(,)+/, ',')

    update_attribute(:is_delivered_to, '')
  end

  def is_delivered_to?(software='ibiza')
    # self.is_delivered_to.to_s.match(/#{software}/) ? true : false
    self.preseizures.not_deleted.where(delivery_state: software).first.present?
  end

  def set_delivery_message_for(software='ibiza', message="can t open connection")
    begin
      mess = self.delivery_message.present? ? JSON.parse(self.delivery_message) : {}
    rescue
      mess = {}
    end

    if message.present?
      mess[software.to_s] = message
    else
      mess.except!(software.to_s)
    end
    self.delivery_message = mess.to_json.to_s
    save
  end

  def get_delivery_message_of(software='ibiza')
    mess = ''
    if self.delivery_message.present?
      mess = JSON.parse(self.delivery_message) rescue { "#{software.to_s}" => self.delivery_message }
      mess = mess[software.to_s] || '' rescue self.delivery_message
    end
    mess
  end

  def operations
    preseizures = self.preseizures.where('operation_id > 0') || []
    (preseizures.any?)? preseizures.collect(&:operation).flatten.compact : []
  end


  def has_no_delivered_preseizures?
    self.preseizures.failed_delivery.count > 0
  end
end
