class News < ApplicationRecord
  TARGET_AUDIENCES = %w(everyone collaborators customers).freeze

  validates_presence_of :title, :body
  validates_inclusion_of :target_audience, in: TARGET_AUDIENCES

  scope :published, -> { where.not(published_at: nil) }

  state_machine initial: :created do
    state :created
    state :published

    before_transition created: :published do |news, _transition|
      news.published_at = Time.now
    end

    event :publish do
      transition created: :published
    end
  end

  def self.search(contains)
    news = self.all
    news = news.where(target_audience: contains[:target_audience]) if contains[:target_audience].present?
    news = news.where("title LIKE ?", "%#{contains[:title]}%") if contains[:title].present?

    news = news.where("created_at BETWEEN '#{CustomUtils.parse_date_range_of(contains[:created_at]).join("' AND '")}'")     if contains[:created_at].present?
    news = news.where("updated_at BETWEEN '#{CustomUtils.parse_date_range_of(contains[:updated_at]).join("' AND '")}'")     if contains[:updated_at].present?
    news = news.where("published_at BETWEEN '#{CustomUtils.parse_date_range_of(contains[:published_at]).join("' AND '")}'") if contains[:published_at].present?

    news
  end

  def body=(content)
    super ActionController::Base.helpers.sanitize(content, tags: allowed_tags, attributes: allowed_attributes)
  end

  private

  def allowed_tags
    ActionView::Base.sanitized_allowed_tags + %w(u s)
  end

  def allowed_attributes
    ActionView::Base.sanitized_allowed_attributes + %w(style)
  end
end
