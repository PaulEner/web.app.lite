class PonctualScripts::FillDeliveryAndExportState < PonctualScripts::PonctualScript
  def self.execute(periods=[])
    new({periods: Array(periods)}).run
  end

  private

  def execute
    @options[:periods].each_with_index do |period, _ind|
      p "==== Period : [#{period}] ===="

      preseizures = Pack::Report::Preseizure.where('DATE_FORMAT(created_at, "%Y%m") = ?', period)
      total       = preseizures.size

      p total

      _show      = 0
      step       = 10

      preseizures.each_with_index do |preseizure, index|
        percentage = ((index * 100) / total).to_i

        if percentage >= (_show + step)
          p "===> #{percentage} %"
          _show += step
        end

        user = preseizure.user

        preseizure.delivery_state = 'not_delivered' if user.uses_api_softwares?
        if preseizure.is_delivered_to.present? || preseizure.delivery_message.to_s.match(/already sent/) || preseizure.pre_assignment_deliveries.where(state: 'sent').size > 0
          preseizure.delivery_state = preseizure.is_delivered_to.presence || 'ibiza'
        elsif preseizure.pre_assignment_deliveries.last.present?
          preseizure.delivery_state = 'failed'
        end

        preseizure.export_state = 'not_exported' if user.uses_non_api_softwares?
        export                  = preseizure.pre_assignment_exports.where(state: 'generated').last
        preseizure.export_state = export.for if export

        preseizure.save
      end

      p "==== DONE ===="
      sleep(120) if (_ind + 1) != @options[:periods].size #SLEEP 2 minutes after each period
    end
  end
end