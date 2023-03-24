# -*- encoding : UTF-8 -*-
# Generates a ZIP to import in Cogiog
class PreseizureExport::Software::Ciel
  def initialize(preseizures)
    @preseizures = preseizures
  end


  def execute
    base_name = @preseizures.first.report.name.tr(' ', '_').tr('%', '_')
    file_path = ''

    CustomUtils.mktmpdir('ciel_export', nil, false) do |dir|
      PreseizureExport::Software::Ciel.delay_for(6.hours, queue: :high).remove_temp_dir(dir)

      data = PreseizureExport::PreseizureToTxt.new(@preseizures).execute("ciel")

      file_path = "#{dir}/#{base_name}.txt"
      File.open(file_path, 'w') do |f|
        f.write(data)
      end
    end

    file_path
  end


  def self.remove_temp_dir(dir)
    FileUtils.remove_entry dir if File.exist? dir
  end
end
