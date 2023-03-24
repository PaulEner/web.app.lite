# frozen_string_literal: true
class News::MainController < FrontController
  layout false

  skip_before_action :verify_suspension
  skip_before_action :verify_if_active

  prepend_view_path('app/templates/front/news/views')

  def index
    @news = News.published.where(target_audience: target_audience).where('published_at > ?', current_user.news_read_at || 1.week.ago).order(published_at: :desc).limit(5)

    @news_present = @news.size > 0
    current_user.update_column(:news_read_at, Time.now) if @news_present

    render partial: 'index'
  end

  private

  def target_audience
    current_user.is_prescriber ? %w[everyone collaborators] : %w[everyone customers]
  end
end