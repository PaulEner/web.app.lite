class PonctualScripts::FillPeriodFields
  def execute
    periods = Period.where('organization_id > 0').where("DATE_FORMAT(start_date, '%Y%m') >= ? AND DATE_FORMAT(start_date, '%Y%m') < ?", 202111, 202202)

    datas = []

    periods.each do |period|
      next if period.user

      if !period.try(:organization).try(:is_test) && period.try(:organization).try(:is_active) && !period.try(:organization).try(:is_for_admin)
        result = Billing::OrganizationExcess.new(period).execute
        Billing::UpdatePeriodPrice.new(period).execute
      end

      datas << { organization: period.try(:organization).try(:code), period_id: period.reload.id, period_date: period.reload.start_date.strftime('%Y-%m-%d'), basic_excess: period.reload.basic_excess, basic_total_compta_piece: period.reload.basic_total_compta_piece, plus_micro_excess: period.reload.plus_micro_excess, plus_micro_total_compta_piece: period.reload.plus_micro_total_compta_piece} if result
    end

    send_mail_for(datas)
  end

  private

  def send_mail_for(datas)
    log_document = {
      subject: "[FillPeriodFields] Remplissage champ",
      name: "FillPeriodFields",
      error_group: "[FillPeriodFields] Remplissage champ",
      erreur_type: "[FillPeriodFields] - Remplissage champ",
      date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      more_information: {
        datas: datas.to_json
      }
    }

    ErrorScriptMailer.error_notification(log_document).deliver
  end
end