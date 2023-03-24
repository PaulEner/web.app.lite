# frozen_string_literal: true
class Notifications::MainController < FrontController
  skip_before_action :verify_suspension
  skip_before_action :verify_if_active

  before_action :load_notifications, except: :link_through

  prepend_view_path('app/templates/front/notifications/views')

  def index
    @notifications.update_all is_read: true, updated_at: Time.now

    render partial: 'index'
  end

  def latest
    render partial: 'notifications'
  end

  def link_through
    notification = Notification.find params[:id]
    notification.update is_read: true if notification.user == true_user
    redirect_to notification.url
  end

  def unread_all_notifications
    if params[:unread].presence
      @user.notifications.update_all is_read: true, updated_at: Time.now
    end
  end

  private

  def load_notifications
    @notifications = @user.notifications.order(is_read: :asc, created_at: :desc).page(params[:page] || 1).per(params[:per_page])
  end
end