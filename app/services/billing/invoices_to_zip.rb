# -*- encoding : UTF-8 -*-
# Creates a Zip archive with instanciated invoices
class Billing::InvoicesToZip
  def initialize(invoice_ids)
    @invoice_ids = invoice_ids
  end


  def execute
    zip_path = ''

    CustomUtils.mktmpdir('invoice_to_zip', nil, false) do |dir|
      Billing::InvoicesToZip.delay_for(6.hours, queue: :high).remove_temp_dir(dir)

      @invoice_ids.each do |invoice_id|
        invoice = BillingMod::Invoice.find invoice_id
        filepath = invoice.cloud_content_object.reload.path

        next unless File.exist?(filepath)

        if invoice.organization
          filename = invoice.organization.name.to_s + ' - ' + invoice.period_v2.to_s + '.pdf'
        else
          filename = File.basename(filepath)
        end

        new_filepath = File.join dir, filename

        FileUtils.cp(filepath, new_filepath)
      end

      # Finaly zip the temp
      zip_file_name      = "factures.zip"
      zip_path           = "#{dir}/#{zip_file_name}"
      Dir.chdir dir
      POSIX::Spawn.system "zip #{zip_file_name} *"
    end

    zip_path
  end


  def self.remove_temp_dir(dir)
    FileUtils.rm_rf dir if File.exist? dir
  end
end
