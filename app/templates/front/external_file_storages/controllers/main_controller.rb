# frozen_string_literal: true
class ExternalFileStorages::MainController < FrontController
  before_action :load_external_file_storage

  def use
    service   = params[:service].to_i
    is_enable = params[:is_enable] == 'true'

    response = if is_enable
                 @external_file_storage.use(service)
               else
                 @external_file_storage.unuse(service)
               end

    render json: { response: response.to_json }, status: 200
  end

  def update
    service_name = %i[dropbox_basic google_doc ftp box].select do |key|
      params[key].present?
    end.first

    if service_name && @external_file_storage.send(service_name).update(path: params[service_name][:path])
      json_flash[:success] = 'Modifié avec succés.'
    else
      json_flash[:error] = 'Donnée(s) saisie(s) non valide.'
    end

    render json: { json_flash: json_flash }, status: 200
  end

  private

  def load_external_file_storage
    @external_file_storage = @user.find_or_create_external_file_storage
  end

  def anchor_name(service_name)
    case service_name
    when :dropbox_basic
      :dropbox
    when :google_doc
      :google_drive
    else
      service_name
    end
  end
end