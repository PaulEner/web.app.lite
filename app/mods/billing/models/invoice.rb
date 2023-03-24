# -*- encoding : UTF-8 -*-
class BillingMod::Invoice < ApplicationRecord
  self.table_name = 'invoices'

  ATTACHMENTS_URLS={'cloud_content' => '/account/invoices/:id/download/:style'}

  has_one_attached :cloud_content
  
  has_attached_file :content,
                            styles: {
                              thumb: ['46x67>', :png]
                            },
                            path: ':rails_root/files/:rails_env/:class/:attachment/:id/:style/:filename',
                            url: '/account/invoices/:id/download/:style'
  do_not_validate_attachment_file_type :content


  validates_presence_of   :number
  validates_uniqueness_of :number
  validates_presence_of :period_v2

  before_validation :set_number


  belongs_to :organization, optional: true
  # INFO : keeping those 3 relations for backward compatibility
  belongs_to :user, optional: true
  belongs_to :period, optional: true
  belongs_to :subscription, optional: true
  has_many   :invoice_settings, class_name: 'BillingMod::InvoiceSetting'


  scope :invoice_at, -> (time) { where(created_at: time.end_of_month..(time.end_of_month + 12.month)) }
  scope :of_period,  -> (period){ where(period_v2: period.to_i) }
 
  before_destroy do |invoice|
    invoice.cloud_content.purge
  end

  def self.search(contains)
    invoices = BillingMod::Invoice.all.includes(:organization, :user)

    invoices = invoices.where("number LIKE ?", "%#{contains[:number]}%") unless contains[:number].blank?

    if contains[:amount_in_cents_w_vat].present?
      comparison_operator = contains[:amount_in_cents_w_vat_comparison_operator]
      if comparison_operator.in?(%w(= <= >=))
        invoices = invoices.where("amount_in_cents_w_vat #{comparison_operator} ?", contains[:amount_in_cents_w_vat])
      end
    end

    if contains[:user_contains] && contains[:user_contains][:code].present?
      user = User.where(code: contains[:user_contains][:code]).first

      invoices = invoices.where(user_id: user.id) if user
    end

    if contains[:organization_contains] && contains[:organization_contains][:name].present?
      organizations = Organization.where("name LIKE ?", "%#{contains[:organization_contains][:name]}%")

      invoices = invoices.where(organization_id: organizations.pluck(:id))
    end

    invoices = invoices.where("created_at BETWEEN '#{CustomUtils.parse_date_range_of(contains[:created_at]).join("' AND '")}'")     if contains[:created_at].present?

    invoices
  end

  def cloud_content_object
    # IMPORTANT : We fetch cloud_content_object from Invoice model instead of BillingMod::Invoice

    invoice = ::Invoice.where(id: self.id).first
    return nil if not invoice

    invoice.cloud_content_object
  end

  private

  def set_number
    unless number
      prefix = 1.month.ago.strftime('%Y%m')
      txt = DbaSequence.next('invoice_' + prefix)
      self.number = prefix + ('%0.4d' % txt)
    end
  end
end
