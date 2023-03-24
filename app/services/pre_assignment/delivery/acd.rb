class PreAssignment::Delivery::Acd < PreAssignment::Delivery::DataService
  def self.retry_delivery(delivery_id, retry_count)
    delivery = PreAssignmentDelivery.find delivery_id

    delivery.update(state: 'pending', error_message: "retry_sending_#{retry_count}") if delivery.state == 'error'
  end

  def self.execute(delivery)
    new(delivery).run
  end

  def initialize(delivery)
    super
  end

  private

  def execute
    @delivery.sending
    @previous_error = @delivery.error_message

    if @delivery.preseizures.select{|pres| pres.pre_assignment_deliveries.where(state: 'sent').count > 0 }.size > 0
      handle_delivery_success
    else
      begin
        send_data = AcdLib::DataSender.new(@delivery)
        response  = send_data.execute(@delivery.cloud_content.download)

        if response[:error].present?
          handle_delivery_error(response[:error])

          #DONT ACTIVATE RETRY SENDING DELIVERY
          #retry_sending
        else
          handle_delivery_success
        end
      rescue => e
        log_document = {
          name: "PreAssignment::Delivery::acd",
          error_group: "[pre-assignment-delivery-acd] active storage can't read file",
          erreur_type: "Active Storage, can't read file",
          date_erreur: Time.now.strftime('%Y-%M-%d %H:%M:%S'),
          more_information: {
            delivery: @delivery.inspect,
            error: e.to_s
          }
        }
        ErrorScriptMailer.error_notification(log_document).deliver

        handle_delivery_error 'Internal service error!'

        retry_sending
      end
    end

    @delivery.sent?
  end

  def retry_sending
    retry_count  = @previous_error.gsub('retry_sending_', '').to_i
    retry_count += 1

    PreAssignment::Delivery::SageGec.delay_for(1.hours, queue: :default).retry_delivery(@delivery.id, retry_count) if retry_count <= 3
  end
end