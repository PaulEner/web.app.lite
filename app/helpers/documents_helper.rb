# -*- encoding : UTF-8 -*-
# FIXME : whole check
module DocumentsHelper
  def linked_users_option
    has_multiple_accounts? ? accounts.map { |u| [u, u.id] } : []
  end

  def active_users(users, year)
    users.select do |u|
      if u.created_at.year <= year
        u.active? ? true : u.inactive_at.year >= year
      else
        false
      end
    end
  end


  def filter_list_of_users(users, year)
    active_users(users, year).sort_by { |u| [u.code, u.company, u.name, u.email] }.collect { |u| [u.info, u.id] }
  end

  # build an array who's values are either a period or nil
  def annual_periods_for_user(periods)
    _periods = []
    current_month = 1
    current_period = 0

    while current_month < 13
      if periods[current_period] && periods[current_period].start_date.month == current_month
        _periods << periods[current_period]
        current_month += periods[current_period].duration
        current_period += 1
      else
        _periods << nil
        current_month += 1
      end
    end

    _periods
  end

  def active_year_for_user?(year, user, periods)
    if user.created_at.year <= year && (user.inactive_at || Time.now).year >= year && user.inactive_at.try(:month) != 1
      true
    else
      periods.compact.present? || (user.billings.where("period LIKE '#{year}%'").count > 0)
    end
  end

  def price_of_period_by_time(periods, time)
    period = periods.select { |p| p.start_date <= time.to_date && p.end_date >= time.to_date }.first

    period.try(:price_in_cents_wo_vat) || 0
  end


  def active_clients(clients, date)
    end_date = date.end_of_month

    clients.select do |client|
      client.inactive_at.nil? || client.inactive_at > end_date ? true : false
    end
  end


  def thead(columns)
    content_tag :thead do
      content_tag :tr do
        columns.each_with_index do |c, index|
          if index < 2
            concat(content_tag(:th, c))
          else
            concat(content_tag(:th, c, style: 'text-align:right'))
          end
        end
      end
    end
  end


  def tbody(items)
    content_tag :tbody do
      items.each_with_index do |(k,v),index|
        concat(content_tag(:tr){
          concat content_tag :td, "#{index + 1}"
          concat content_tag :td, "#{l(k[:date].localtime)}"
          concat content_tag :td, "#{k[:uploaded]}", style: 'text-align:right'
          concat content_tag :td, "#{k[:scanned]}", style: 'text-align:right'
          concat content_tag :td, "#{k[:dematbox_scanned]}", style: 'text-align:right'
          concat content_tag :td, "#{k[:retrieved]}", style: 'text-align:right'
          }
        )
      end
    end
  end


  def custom_table_for(columns, items)
    content_tag :table, class: 'table table-condensed table-striped' do
      thead(columns) + tbody(items)
    end
  end


  def tinformations(pack, content_width)
    content_tag :table, class: 'table table-condensed' do
      content_tag :tbody do
        concat content_tag :tr, content_tag(:td, content_tag(:b, 'Nom du document'),       width: content_width) + content_tag(:td, "#{pack.name}.pdf")
        concat content_tag :tr, content_tag(:td, content_tag(:b, 'Date de mise en ligne'), width: content_width) + content_tag(:td, l(pack.created_at).to_s)
        concat content_tag :tr, content_tag(:td, content_tag(:b, 'Date de modification'),  width: content_width) + content_tag(:td, l(pack.updated_at).to_s)
        concat content_tag :tr, content_tag(:td, content_tag(:b, 'Nombre de pages'),       width: content_width) + content_tag(:td, pack.pages_count.to_s)
        unless pack.is_fully_processed
          concat content_tag :tr, content_tag(:td, content_tag(:b, 'Nombre de pages en cours de traitement'), width: content_width) + content_tag(:td, TempPack.find_by_name(pack.name).temp_documents.not_published.sum(:pages_number).to_i.to_s)
        end
        concat content_tag :tr, content_tag(:td, content_tag(:b, 'Tags: '), width: content_width) + content_tag(:td, pack.tags.try(:join, ' '), class: 'tags')
      end
    end
  end

  def preseizures_informations(pack_or_report, content_width)
    software =  if pack_or_report.user.try(:uses?, :ibiza)
                  { human_name: 'Ibiza', name: 'ibiza' }
                elsif pack_or_report.user.try(:uses?, :exact_online)
                  { human_name: 'Exact Online', name: 'exact_online' }
                else
                  { human_name: '', name: '' }
                end

    first_created_at       = pack_or_report.preseizures.select('MIN(pack_report_preseizures.created_at) as min_created_at').first.try(:min_created_at)
    last_created_at        = pack_or_report.preseizures.select('MAX(pack_report_preseizures.created_at) as max_created_at').first.try(:max_created_at)
    last_delivery_tried_at = pack_or_report.preseizures.select('MAX(pack_report_preseizures.delivery_tried_at) as max_delivery_tried_at').first.try(:max_delivery_tried_at)

    content_tag :table, class: 'table table-condensed' do
      content_tag :tbody do
        concat content_tag :tr, content_tag(:td, content_tag(:b, "Date d'ajout de la première écriture"), width: content_width) + content_tag(:td, first_created_at ? l(first_created_at).to_s : '')
        concat content_tag :tr, content_tag(:td, content_tag(:b, "Date d'ajout de la dernière écriture"), width: content_width) + content_tag(:td, last_created_at ? l(last_created_at).to_s : '')

        if software[:name].present?
          concat content_tag :tr, content_tag(:td, content_tag(:b, "Date de dernière envoi [#{software[:human_name]}]"),  width: content_width) + content_tag(:td, last_delivery_tried_at ? l(last_delivery_tried_at).to_s : '')
          concat content_tag :tr, content_tag(:td, content_tag(:b, "Message d'erreur d'envoi [#{software[:human_name]}]") + content_tag(:span, pack_or_report.get_delivery_message_of(software[:name]).to_s, style: 'display:block'), colspan: 2)
        end
      end
    end
  end

  def html_pack_info(pack)
    columns = ['N°', 'Date', 'Télév.', 'Num.', "iDocus'Box", 'Auto.']

    contents = ''
    contents += content_tag :h4, 'Informations'
    contents += content_tag :div, tinformations(pack, 220)

    if pack.preseizures.any?
      contents += content_tag :h4, 'Ecritures Comptables'
      contents += content_tag :div, preseizures_informations(pack, 220)
    end

    contents += content_tag :h4, 'Historique des ajouts de pages'
    contents += content_tag :div, custom_table_for(columns, pack.content_historic)
    content_tag :div, contents.html_safe, style: 'width: 100%'
  end

  def html_report_info(report)
    contents = ''
    contents += content_tag :h4, 'Ecritures Comptables'
    contents += content_tag :div, preseizures_informations(report, 220)
    content_tag :div, contents, style: 'width: 100%'
  end

  def html_piece_view(piece, temp_document=false)
    contents = ''
    contents += content_tag :h4, "Pièce n° #{piece.position} - #{piece.name}" if not temp_document
    contents += content_tag :div, content_tag(:iframe, "", :src => piece.get_access_url, :class => "piece_view", :style => "width:100%; height: 700px;")
    content_tag :div, contents, style: 'padding: 10px; z-index:200'

    contents.html_safe
  end

  def quarterly_of_month(month)
    if month < 4
      1
    elsif month < 7
      2
    elsif month < 10
      3
    else
      4
    end
  end


  def options_for_period(period_service = @period_service, time = Time.now)
    current_time = time

    period_duration = period_service.period_duration

    results = [[period_option_label(period_duration, time), 0]]

    if period_service.prev_expires_at.nil? || period_service.prev_expires_at > Time.now
      period_service.authd_prev_period.times do |i|
        current_time -= period_duration.month

        results << [period_option_label(period_duration, current_time), i + 1]
      end
    end

    results
  end


  def period_option_label(period_duration, time)
    case period_duration
    when 1
      time.strftime('%m %Y')
    when 3
      "T#{quarterly_of_month(time.month)} #{time.year}"
    when 12
      time.year.to_s
    end
  end

  def file_upload_users_list
    if @user.organization.specific_mission
      @user.organization.customers.active.order(code: :asc)
    else
      @file_upload_users_list ||= accounts.includes(:options, :ibiza, :subscription, organization: [:ibiza, :exact_online, :my_unisoft, :coala, :cogilog, :sage_gec, :acd, :quadratus, :cegid, :csv_descriptor, :fec_agiris]).active.order(code: :asc).select { |user| user.authorized_upload? }
    end
  end

  def file_upload_params
    result = {}

    account_book_types = AccountBookType.where(user: file_upload_users_list)

    file_upload_users_list.each do |user|
      user_account_book_types = account_book_types.select { |abt| abt.user_id == user.id }.sort_by(&:name)
      user_bank_processable_account_book_types = user_account_book_types.select { |ubpabt| ubpabt.entry_type == 4 || ubpabt.domain == 'BQ - Banque' }

      period_service              = Billing::Period.new user: user
      journals                    = []
      journals_compta_processable = []

      if user.authorized_upload?
        journals_bank = user_bank_processable_account_book_types.map{|j| j.name + ' ' + j.full_name(true)}
        journals_all  = user_account_book_types.map{|j| j.name + ' ' + j.full_name(true) }

        journals_compta_processable_bank = user_bank_processable_account_book_types.map{|j| j.name if j.compta_processable? }.compact
        journals_compta_processable_all  = user_account_book_types.map{|j| j.name if j.compta_processable? }.compact

        journals                    = journals_all
        journals_compta_processable = journals_compta_processable_all

        if !user.authorized_bank_upload?
          journals                    = journals_all - journals_bank
          journals_compta_processable = journals_compta_processable_all - journals_compta_processable_bank
        elsif !user.authorized_basic_upload?
          journals                    = journals_bank
          journals_compta_processable = journals_compta_processable_bank
        end
      end

      hsh = {
        journals: journals,
        journals_compta_processable: journals_compta_processable,
        periods:  options_for_period(period_service),
        is_analytic_used: (user.try(:ibiza).try(:ibiza_id?) && user.uses?(:ibiza) && user.try(:ibiza).try(:compta_analysis_activated?))
      }

      if period_service.prev_expires_at
        hsh[:message] = {
          period: period_option_label(period_service.period_duration, Time.now - period_service.period_duration.month),
          date:   l(period_service.prev_expires_at, format: '%d %B %Y à %H:%M')
        }
      end

      result[user.code] = hsh
    end

    result
  end

  def verif_debit_credit_somme_of(preseizure_entries)
    debit_value = credit_value = 0

    preseizure_entries.each do |entry|
      #NOTE : Don't use entry.amount.to_f or to_i here, debit_value and credit_value can't be converted before addition
      if entry.type == 1
        debit_value += entry.amount || 0
      else
        credit_value += entry.amount || 0
      end
    end

    debit_value.to_f != credit_value.to_f
  end

  def data_analytic_of(preseizure)
    analytics = preseizure.analytic_reference
    data_analytics = []

    if analytics
      3.times do |i|
        j = i + 1
        references = analytics.send("a#{j}_references")
        name       = analytics.send("a#{j}_name")
        next unless references.present?

        references = JSON.parse(references)
        references.each do |ref|
          if name.present? && ref['ventilation'].present? && (ref['axis1'].present? || ref['axis2'].present? || ref['axis3'].present?)
            data_analytics << { name: name, ventilation: ref['ventilation'], axis1: ref['axis1'], axis2: ref['axis2'], axis3: ref['axis3'] }
            end
        end
      end
    end

    data_analytics
  end

  def currencies_of(organization_id)
    Rails.cache.fetch "preseizures_currencies_of_#{organization_id}", expires_in: 24.hours do
      (Pack::Report::Preseizure.where(organization_id: organization_id).pluck(:currency) + ['EUR']).uniq.select{|q| q.present? && q.size >= 2}
    end
  end
end