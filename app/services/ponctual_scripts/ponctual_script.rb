# -*- encoding : UTF-8 -*-
class PonctualScripts::PonctualScript
  def initialize(options={})
    @options = options.with_indifferent_access
    @class_name = self.class.name
  end

  def run
    start_time = Time.now
    logger_infos "[START] - #{start_time}"
    execute
    logger_infos "[END] - #{Time.now} - within #{Time.now - start_time} seconds"
  end

  def rollback
    start_time = Time.now
    logger_infos "[ROLLBACK-START] - #{start_time}"
    backup
    logger_infos "[ROLLBACK-END] - #{Time.now} - within #{Time.now - start_time} seconds"
  end

  def logger_infos(message)
    infos = "[#{@class_name}] - #{message}"
    p infos #print infos to console and log
    System::Log.info('ponctual_scripts', infos)
  end

  def send_csv_datas(datas, filename=nil)
    filename = Time.now.strftime('%Y%m%d%H%M%S') if filename.blank?

    lines = []
    datas.each do |data|
      lines << data.join(';')
    end

    CustomUtils.mktmpdir(filename, nil, false) do |dir|
      file_path = File.join(dir, "#{filename}.csv")

      File.write(file_path, lines.join("\n"));

      log_document = {
        subject: "[PonctualScript] - #{filename}",
        name: "PonctualScript - #{filename}",
        error_group: "[PonctualScript] - #{filename}",
        erreur_type: "[PonctualScript] - #{filename}",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S')
      }

      begin
        ErrorScriptMailer.error_notification(log_document, { attachements: [{name: "#{filename}.csv", file: File.read(file_path)}]} ).deliver
      rescue
        ErrorScriptMailer.error_notification(log_document).deliver
      end

      p file_path
    end
  end

  private

  def ponctual_dir
    dir = "#{Rails.root}/spec/support/files/ponctual_scripts"

    FileUtils.makedirs(dir)
    FileUtils.chmod(0777, dir)
    dir
  end

  def lock_with(file_name, mode='w+')
    if !File.exist?(ponctual_dir.to_s + '/' + file_name.to_s)
      file = File.open(file_name, mode)

      yield(file_name) if block_given?

      file.close
    else
      logger_infos "Script has already launched!!"
    end
  end

  # Define execute method on the child class (without params, use initializer options if you need params)
  def execute; end

  # Define backup method on the child class (without params, use initializer options if you need params)
  def backup; end
end