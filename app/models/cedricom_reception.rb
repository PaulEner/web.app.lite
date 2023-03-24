class CedricomReception < ApplicationRecord
  has_one_attached :content

  belongs_to :user, optional: true
  belongs_to :organization
  has_many :operations

  validates_uniqueness_of :cedricom_id, scope: :organization_id, allow_blank: true
  validates_uniqueness_of :jedeclare_reception_id, scope: :organization_id, allow_blank: true

  scope :cedricom,    -> { where.not(cedricom_id: nil) }
  scope :jedeclare,   -> { where.not(jedeclare_reception_id: nil) }
  scope :to_import,   -> { where(imported: false, empty: false, downloaded: true) }
  scope :to_download, -> { where(downloaded: false) }
end
