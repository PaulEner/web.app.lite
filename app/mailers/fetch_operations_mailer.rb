class FetchOperationsMailer < BaseMailer
  def notify(notify_content)
    @notify_content = notify_content

    mail to: Settings.first.notify_errors_to, subject: "[Fetch Operation] - Détail du #{@notify_content[:date_fetch]}"[0..200] if @notify_content[:details].present?
  end
end