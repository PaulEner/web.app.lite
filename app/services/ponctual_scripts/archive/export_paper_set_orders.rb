class PonctualScripts::ExportPaperSetOrders
  class << self
    def execute
      new().execute
    end
  end

  def execute
    data_each_customer = []
    data_each_customer << ["DOSSIER", "DATE COMMANDE ", "COMMANDE", "MONTANT", "STATUT"]

    Organization.billed.each do |organization|
      organization.customers.each do |customer|
        to_add = customer.orders.where("type = 'paper_set' AND DATE_FORMAT(orders.created_at, '%Y') = '2022'")
        next if to_add.empty?

        to_add.each { |order| data_each_customer << [ customer.code, order.created_at.strftime('%d/%m/%y'), order.paper_set_casing_size.to_s + 'g - ' + order.paper_set_casing_count.to_s + ' env - ' + order.paper_set_folder_count.to_s + ' chm - ' + paper_set_date_to_name(order.period_duration, order.paper_set_start_date).to_s + ' à ' + paper_set_date_to_name(order.period_duration, order.paper_set_end_date).to_s, order.price_in_cents_wo_vat * 0.01, Order.state_machine.states[order.state].human_name ] }
      end
    end

    send_mail_for data_each_customer
  end

  private

  def send_mail_for(datas)
    lines = []
    datas.each do |data|
      lines << data.join(';')
    end

    CustomUtils.mktmpdir('export_paper_set_orders', nil, false) do |dir|
      file_path = File.join(dir, "export_paper_set_orders.csv")

      File.write(file_path, lines.join("\n"));

      log_document = {
        subject: "[ExportPaperSetOrders] Exportation Kit courrier",
        name: "ExportPaperSetOrders",
        error_group: "[ExportPaperSetOrders] Exportation Kit courrier",
        erreur_type: "[ExportPaperSetOrders] - Exportation Kit courrier",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S')
      }

      begin
        ErrorScriptMailer.error_notification(log_document, { attachements: [{name: "export_paper_set_orders.csv", file: File.read(file_path)}]} ).deliver
      rescue
        ErrorScriptMailer.error_notification(log_document).deliver
      end

      p file_path
    end
  end

  def paper_set_date_to_name(period_duration, date)
    if period_duration == 1
      date.strftime('%b %Y').capitalize
    elsif period_duration == 3
      "#{quarter_names[(date.month / 3)]} #{date.year}"
    elsif period_duration == 12
      date.year
    end
  end

  def quarter_names
    ['1er trimestre', '2ème trimestre', '3ème trimestre', '4ème trimestre']
  end
end