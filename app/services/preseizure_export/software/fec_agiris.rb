# -*- encoding : UTF-8 -*-
class PreseizureExport::Software::FecAgiris
  def initialize(preseizures)
    @preseizures = preseizures
  end


  def execute(type = 'fec_agiris')
    base_name = @preseizures.first.report.name.tr(' %', '__')
    file_path = ''

    CustomUtils.mktmpdir('fec_agiris_export', nil, false) do |dir|
      PreseizureExport::Software::FecAgiris.delay_for(6.hours, queue: :high).remove_temp_dir(dir)

      data      = PreseizureExport::PreseizureToTxt.new(@preseizures).execute(type) # Generate a txt with preseizures
      extension = (type == 'fec_agiris')? 'txt' : 'ecr'

      File.open("#{dir}/#{base_name}.#{extension}", 'w') do |f|
        f.write(data)
      end

      file_path = "#{dir}/#{base_name}.#{extension}"

      Dir.chdir dir
    end

    file_path
  end


  def self.remove_temp_dir(dir)
    FileUtils.remove_entry dir if File.exist? dir
  end
end