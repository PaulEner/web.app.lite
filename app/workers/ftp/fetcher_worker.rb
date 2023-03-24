class Ftp::FetcherWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform
    if FTPDeliveryConfiguration::IS_ENABLED
      UniqueJobs.for 'FtpFetcher' do
        ### TEMP FIX : SEND FETCHER MANUALLY
        # Ftp::Fetcher.fetch(FTPDeliveryConfiguration::FTP_SERVER, FTPDeliveryConfiguration::FTP_USERNAME, FTPDeliveryConfiguration::FTP_PASSWORD, FTPDeliveryConfiguration::FTP_PATH, FTPDeliveryConfiguration::FTP_PROVIDER)


        Ftp::FetcherWorker::Launcher.check_folder( FTPDeliveryConfiguration::FTP_SERVER,
                                         FTPDeliveryConfiguration::FTP_USERNAME,
                                         FTPDeliveryConfiguration::FTP_PASSWORD,
                                         FTPDeliveryConfiguration::FTP_PATH,
                                         FTPDeliveryConfiguration::FTP_PROVIDER)
      end
    end
  end

  class Launcher
    def self.check_folder(url, username, password, dir = '/', provider = '')
      ftp = Net::FTP.new
      ftp.connect url, 21
      ftp.login username, password
      ftp.passive = true

      ftp.chdir dir

      dirs = ftp.nlst.sort

      new_dir = dirs.select do |e|
        !e.end_with?('ready') && !e.end_with?('fetched') && !e.end_with?('errors') && !e.end_with?('ACCOMPLYS')
      end


      if new_dir.any?
        p "======= New documents found =========="
        log_document = {
          subject: "[FtpFetcher] - new documents injected",
          name: "ftp fetcher - new docs",
          error_group: "[FtpFetcher] new documents injected",
          erreur_type: "[FtpFetcher] - new documents injected",
          date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
          more_information: {
            dirs: new_dir.join(' / '),
          }
        }

        ErrorScriptMailer.error_notification(log_document, { unlimited: true }).deliver

        Ftp::Fetcher.prepare_dir
      else
        p "============ No new documents=================="
      end
    end
  end

end
