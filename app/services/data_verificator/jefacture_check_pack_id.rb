# -*- encoding : UTF-8 -*-
class DataVerificator::JefactureCheckPackId < DataVerificator::DataVerificator
  def execute
    message = []
    reports = Pack::Report.where(pack_id: nil).where("DATE_FORMAT(pack_reports.created_at, '%Y%m%d') >= #{2.days.ago.strftime('%Y%m%d')}")

    reports.each do |report|
      operation_size = report.preseizures.where("operation_id > 0").size
      pack = Pack.where(name: report.name.to_s + ' all').first

      if pack && pack.pieces && operation_size <= 0
        report.pack_id = pack.id
        report.save

        message << "Report Maj: #{report.name}, Pack: #{pack.name}"
      end
    end

    {
      title: "JeFactureCheckPackIdIsNil - #{message.size} Reports without pack_id fixed",
      message: message.join("; ")
    }
  end
end