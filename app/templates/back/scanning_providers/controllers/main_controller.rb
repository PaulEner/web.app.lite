# frozen_string_literal: true
class Admin::ScanningProviders::MainController < BackController
  prepend_view_path('app/templates/back/scanning_providers/views')
before_action :load_scanning_provider, except: %w[index new create]

  # GET /admin/scanning_providers
  def index
    @scanning_providers = ScanningProvider.all.order(created_at: :desc).page(params[:page]).per(params[:per_page])
  end

  # GET /admin/scanning_providers/new
  def new
    @scanning_provider = ScanningProvider.new

    render partial: 'form'
  end

  # POST /admin/scanning_providers
  def create
    @scanning_provider = ScanningProvider.new(scanning_provider_params)

    if @scanning_provider.save
       json_flash[:success] = 'Créé avec succès.'      
    else
      json_flash[:error] = errors_to_list @scanning_provider
    end

    render json: { json_flash: json_flash }, status: 200
  end

  # GET /admin/scanning_providers/:id/edit
  def edit 
    render partial: 'form'
  end

  # PUT /admin/scanning_providers/:id
  def update
    if @scanning_provider.update(scanning_provider_params)

      json_flash[:success] = 'Modifié avec succès.'
    else
      json_flash[:error] = errors_to_list @scanning_provider
    end

    render json: { json_flash: json_flash }, status: 200
  end

  # DELETE /admin/scanning_providers/:id
  def destroy
    @scanning_provider.destroy
    flash[:notice] = 'Supprimé avec succès.'
    redirect_to admin_scanning_providers_path
  end

  private

  def load_scanning_provider
    @scanning_provider = ScanningProvider.find(params[:id])
  end

  def scanning_provider_params
    params.require(:scanning_provider).permit(
      :name,
      :code,
      :is_default,
      :customer_tokens
    ).tap do |whitelist|
      whitelist[:addresses_attributes] = params[:scanning_provider][:addresses_attributes].permit!
    end
  end
end