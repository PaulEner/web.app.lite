# frozen_string_literal: true
class Admin::Dematboxes::MainController < BackController
  prepend_view_path('app/templates/back/dematboxes/views')

  before_action :load_dematbox, except: :index

  # GET /admin/dematboxes
  def index
    @dematboxes = Dematbox.order(created_at: :desc).includes(:user)
    @dematboxes = @dematboxes.page(params[:page]).per(params[:per_page])
  end

  # GET /admin/dematboxes/:id
  def show; end

  # DELETE /admin/dematboxes/:id
  def destroy
    @dematbox.unsubscribe

    flash[:notice] = 'Supprimé avec succès.'

    redirect_to admin_dematboxes_path
  end

  # POST /admin/dematboxes/:id/subscribe
  def subscribe
    @dematbox.subscribe

    flash[:notice] = 'Configuration en cours...'

    redirect_to admin_dematboxes_path
  end

  private

  def load_dematbox
    @dematbox = Dematbox.find(params[:id])
  end
end