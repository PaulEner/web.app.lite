# -*- encoding : UTF-8 -*-
class Reporting::StatisticToXls
  def self.accounts_repartition_stat(report, date)
    user = report.user

    journals = Rails.cache.fetch([:journals]).map { |jl| jl if jl.user_id == user.id }.compact.uniq

    anomaly_accounts = []
    waiting_accounts = []
    default_accounts = []
    journals.each do |journal|
      anomaly_accounts << journal.anomaly_account  if journal.anomaly_account.present?
      waiting_accounts << journal.account_number   if journal.account_number.present?
      default_accounts << journal.default_account_number if journal.default_account_number.present?
    end

    preseizures = Rails.cache.fetch([:preseizures]).map { |pre| pre if pre.user_id == user.id && pre.report_id == report.id }.compact.uniq

    anomaly_accounts_size = 0
    waiting_accounts_size = 0
    default_accounts_size = 0
    all_accounts    = Pack::Report::Preseizure::Account.where(preseizure_id: preseizures.pluck(:id)).select(:number)

    all_accounts.each do |account|
      if anomaly_accounts.include?(account.number)
        anomaly_accounts_size += 1 
      elsif waiting_accounts.include?(account.number)
        waiting_accounts_size += 1
      elsif default_accounts.include?(account.number)
        default_accounts_size += 1
      end
    end

    { all_accounts_size: all_accounts.size, anomaly_accounts_size: anomaly_accounts_size, waiting_accounts_size: waiting_accounts_size, default_accounts_size: default_accounts_size }
  end

  def initialize(user_ids, date)
    @user_ids = user_ids
    @date     = date
  end

  def execute(action='injected_documents')
    case action
    when "pre_assignment_accounts"
      export_pre_assignment_accounts
    when "latest_sending_docs"
      export_latest_sending_docs
    when "failed_delivery"
      export_failed_delivery
    end    
  end

  private

  def export_pre_assignment_accounts
    datas = []

    reports = Pack::Report.where("pack_reports.created_at BETWEEN '#{@date.join("' AND '")}'").where(user_id: @user_ids).order(updated_at: :desc)    

    reports.each do |report|     
      result = Reporting::StatisticToXls.accounts_repartition_stat(report, @date)

      anomaly_accounts_size = result[:anomaly_accounts_size]
      waiting_accounts_size = result[:waiting_accounts_size]
      default_accounts_size = result[:default_accounts_size]

      datas << [report.name.presence || "", anomaly_accounts_size, waiting_accounts_size, default_accounts_size]
    end

    header = ["Nom du lot", "Part de compte anomalie", "Part de compte d'attente", "Part de compte par défaut"]

    make_export(header, datas)
  end

  def export_latest_sending_docs
    datas = []

    pieces = Pack::Piece.where("pack_pieces.created_at BETWEEN '#{@date.join("' AND '")}'").where(user: @user_ids).joins(:user).select(:updated_at, :user_id).group(:user_id).order(updated_at: :desc)

    pieces.each do |piece|
      datas << [piece.user.code, piece.updated_at.strftime('%d/%m/%Y')]
    end

    header = ['Nom du lot', 'Date du dernier doc.']
    
    make_export(header, datas)
  end

  def export_failed_delivery
    datas = []

    retrievers = Retriever.where("updated_at BETWEEN '#{@date.join("' AND '")}'").where(user_id: @user_ids, state: 'error')

    retrievers.each do |retriever|
      datas << [retriever.user.info, retriever.updated_at.strftime("%d/%m/%Y"), retriever.service_name, retriever.error_message]
    end

    header = ['Nom du dossier', 'Date de modification', 'Automate', 'Status']
    
    make_export(header, datas)
  end

  def make_export(header, datas)
    book = Spreadsheet::Workbook.new

    sheet = book.create_worksheet name: 'Statistique'

    sheet.row(0).concat header

    datas.each_with_index do |data, index|
      sheet.row(index + 1).replace(data)
    end

    io = StringIO.new('')
    book.write(io)
    io.string
  end
end