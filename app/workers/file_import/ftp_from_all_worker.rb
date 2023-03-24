class FileImport::FtpFromAllWorker
  include Sidekiq::Worker
  sidekiq_options queue: :file_import, retry: false

  def perform
    UniqueJobs.for 'ImportFromAllFTP' do
      Ftp.importable.each do |ftp|
        FileImport::Ftp.delay(queue: :low).process ftp.id
      end
      true
    end
  end
end
