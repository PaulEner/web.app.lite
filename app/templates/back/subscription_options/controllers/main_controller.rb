# frozen_string_literal: true
class Admin::SubscriptionOptions::MainController < BackController
  prepend_view_path('app/templates/back/subscription_options/views')

  before_action :load_subscription_option, except: %w[new create index]

  # GET /admin/subscription_options
  def index
    @subscription_options = SubscriptionOption.by_position
    @subscription_options = @subscription_options.page(params[:page]).per(params[:per_page])
  end

  # GET /admin/subscription_options/new
  def new
    @subscription_option = SubscriptionOption.new

    render partial: 'form'
  end

  # POST /admin/subscription_options
  def create
    @subscription_option = SubscriptionOption.new(subscription_option_params)

    if @subscription_option.save
      json_flash[:success] = 'Créé avec succès.'      
    else
      json_flash[:error] = errors_to_list @subscription_option
    end

    render json: { json_flash: json_flash, url: admin_subscription_options_path }, status: 200
  end

  # GET /admin/subscription_options/:id/edit
  def edit
    render partial: 'form'
  end

  # PUT /admin/subscription_options/:id
  def update
    if Subscription::UpdateOption.execute(@subscription_option, subscription_option_params)

      json_flash[:success] = 'Modifié avec succès.'      
    else
      json_flash[:error] = errors_to_list @subscription_option
    end

    render json: { json_flash: json_flash, url: admin_subscription_options_path }, status: 200
  end

  # DELETE /admin/subscription_options/:id
  def destroy
    if @subscription_option.destroy
      flash[:notice] = 'Supprimé avec succès.'
    else
      flash[:error] = "Impossible de supprimer l'option d'abonnement : #{@subscription_option.name}"
    end

    redirect_to admin_subscription_options_path
  end

  private

  def load_subscription_option
    @subscription_option = SubscriptionOption.find(params[:id])
  end

  def subscription_option_params
    params.require(:subscription_option).permit(
      :name,
      :price_in_cents_wo_vat,
      :position,
      :period_duration
    )
  end
end