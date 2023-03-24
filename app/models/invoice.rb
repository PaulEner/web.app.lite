class Invoice < ApplicationRecord
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


  belongs_to :organization

  # TO DO : Find a way to migrate cloud_content to BillingMod::Invoice
  # IMPORTANT : this model is a workarround for cloud_content migration error
  # See BillingMod::Invoice for real invoice model

  def cloud_content_object
    CustomActiveStorageObject.new(self, :cloud_content)
  end
end