class PonctualScripts::InvoiceSimulation < PonctualScripts::PonctualScript
  def self.execute
    new().run
  end

  def self.rollback
    new().rollback
  end

  private

  def execute
    dir = CustomUtils.mktmpdir('ponctual', nil, false)
    year = 2021
    organization = Organization.find_by_code('GMBA')

    (1..12).to_a.each do |month|
      time = Date.parse("#{year}-#{month}-1")

      logger_infos "[INVOICE SIMULATION] - generating invoice #{month}"

      invoice_dir = Billing::CreateInvoicePdf.for_test(time, [organization])
      file_name   = "#{organization.code}_#{organization.id}.pdf"
      dest_file_name   = "#{organization.code}_#{organization.id}_#{month}.pdf"

      FileUtils.cp "#{invoice_dir}/#{file_name}", "#{dir}/#{dest_file_name}"
      FileUtils.remove_entry(invoice_dir, true)
    end


    logger_infos "[INVOICE SIMULATION] - #{dir}"
  end

  def 

  def backup 
  end
end