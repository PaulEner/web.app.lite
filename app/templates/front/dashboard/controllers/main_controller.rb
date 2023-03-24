# frozen_string_literal: true
class Dashboard::MainController < FrontController
  skip_before_action :verify_suspension
  skip_before_action :verify_if_active

  prepend_view_path('app/templates/front/dashboard/views')

  def index
    redirect_to documents_path if !@user.collaborator?

    @favorites = @user.favorite_customers.try(:customer_ids) || []
  end

  def add_customer_to_favorite
    favorite              = @user.favorite_customers || FavoriteCustomer.new
    favorite.user         = @user.try(:user) || @user
    favorite.customer_ids = params.try(:[], 'favorite_customers') || []
    favorite.save

    @favorites = @user.reload.favorite_customers.try(:customer_ids) || []

    json_flash['success'] = 'Dossier favoris mis à jour avec succès'

    render json: { json_flash: json_flash }, status: 200
  end

  def choose_default_summary
    @user.options.update(dashboard_default_summary: params[:service_name])
    redirect_to dashboard_main_index_path
  end

  def last_scans
    @last_kits = Rails.cache.fetch ['user', @user.id, 'last_kits'], expires_in: 5.minutes do
      PaperProcess.where(user_id: user_ids).kits.order(updated_at: :desc).includes(user: :organization).limit(5).to_a
    end
    @last_receipts = Rails.cache.fetch ['user', @user.id, 'last_receipts'], expires_in: 5.minutes do
      PaperProcess.where(user_id: user_ids).receipts.order(updated_at: :desc).includes(user: :organization).limit(5).to_a
    end
    @last_scanned = Rails.cache.fetch ['user', @user.id, 'last_scanned'], expires_in: 5.minutes do
      PeriodDocument.where(user_id: user_ids).where.not(scanned_at: [nil]).order(scanned_at: :desc).includes(:pack).limit(5).to_a
    end
    @last_returns = Rails.cache.fetch ['user', @user.id, 'last_returns'], expires_in: 5.minutes do
      PaperProcess.where(user_id: user_ids).returns.order(updated_at: :desc).includes(user: :organization).limit(5).to_a
    end

    render partial: 'last_scans'
  end

  def last_uploads
    @last_uploads = Rails.cache.fetch ['user', @user.id, 'last_uploads', temp_documents_key] do
      TempDocument.where(user_id: user_ids).where.not(original_file_name: nil).upload.order(created_at: :desc).includes({ user: :organization }, :piece, :temp_pack).limit(10).to_a
    end

    render partial: 'last_uploads'
  end

  def last_dematbox_scans
    @last_dematbox_scans = Rails.cache.fetch ['user', @user.id, 'last_dematbox_scans', temp_documents_key] do
      TempDocument.where(user_id: user_ids).dematbox_scan.order(created_at: :desc).includes({ user: :organization }, :piece, :temp_pack).limit(10).to_a
    end

    render partial: 'last_dematbox_scans'
  end

  def last_retrieved
    @last_retrieved = Rails.cache.fetch ['user', @user.id, 'last_retrieved', temp_documents_key] do
      TempDocument.where(user_id: user_ids).retrieved.order(created_at: :desc).includes({ user: :organization }, :piece, :temp_pack).limit(10).to_a
    end

    @last_operations = Rails.cache.fetch ['user', @user.id, 'last_operations', operations_key] do
      Operation.where(user_id: user_ids).order(created_at: :desc).includes({ user: :organization }, :bank_account).limit(10).to_a
    end

    render partial: 'last_retrieved'
  end

  private

  def user_ids
    @user_ids ||= accounts.active.map(&:id).sort
  end

  def get_key_for(_name)
    timestamps = user_ids.map do |user_id|
      # Rails.cache.fetch ['user', user_id, name, 'last_updated_at'] { Time.now.to_i }
    end
    Digest::MD5.hexdigest timestamps.join('-')
  end

  def temp_documents_key
    get_key_for 'temp_documents'
  end

  def operations_key
    get_key_for 'operations'
  end
end