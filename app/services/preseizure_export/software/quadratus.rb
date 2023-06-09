# -*- encoding : UTF-8 -*-
# Generates a ZIP to import in quadratus
class PreseizureExport::Software::Quadratus
  def initialize(preseizures)
    @preseizures = preseizures
  end


  def execute
    base_name = @preseizures.first.report.name.tr(' ', '_').tr('%', '_')
    file_path = ''

    CustomUtils.mktmpdir('quadratus_export', nil, false) do |dir|
      PreseizureExport::Software::Quadratus.delay_for(6.hours, queue: :high).remove_temp_dir(dir)

      data = PreseizureExport::PreseizureToTxt.new(@preseizures).execute # Generate a txt with preseizures

      File.open("#{dir}/#{base_name}.txt", 'w') do |f|
        f.write(data)
      end

      # Copy pieces to temp directory
      @preseizures.each do |preseizure|
        @piece = preseizure.piece
        FileUtils.cp @piece.cloud_content_object.path, File.join(dir, preseizure.piece.position.to_s + '.pdf') if preseizure.piece && File.exist?(@piece.cloud_content_object.path)
      end

      file_path = File.join(dir, base_name + '.zip')

      Dir.chdir dir

      # Finaly zip the temp dir
      POSIX::Spawn.system "zip #{file_path} *"
    end

    file_path
  end


  def self.remove_temp_dir(dir)
    FileUtils.remove_entry dir if File.exist? dir
  end
end
