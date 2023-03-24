# frozen_string_literal: true
class ExternalFileStorages::EfsOrganizationController < OrganizationController
  before_action :load_mcf_settings
  before_action :load_ftp
  before_action :load_sftp
  prepend_view_path('app/templates/front/external_file_storages/views')

  def index; end

  private

  def load_mcf_settings
    @mcf_settings = @organization.mcf_settings || McfSettings.create(organization: @organization)
  end

  def load_ftp
    @ftp = @organization.ftp
    @ftp ||= @organization.ftp = Ftp.create(organization: @organization, path: 'OUTPUT/:code/:year:month/:account_book/')
  end

  def load_sftp
    @sftp = @organization.sftp
    @sftp ||= @organization.sftp = Sftp.create(organization: @organization, path: 'OUTPUT/:code/:year:month/:account_book/')
  end
end