# frozen_string_literal: true
class Dematboxes::MainController < FrontController
  before_action :verify_access
  before_action :load_dematbox

  # POST /account/dematboxes
  def create
    @dematbox.subscribe(params[:pairing_code])
    json_flash[:success] = "Configuration de iDocus'Box en cours..."
    
    render json: { json_flash: json_flash }, status: 200
  end

  # DELETE /account/dematboxes
  def destroy
    @dematbox.unsubscribe
    flash[:success] = 'Supprimé avec succèss.'

    redirect_to profiles_path
  end

  private

  def verify_access
    unless @user.my_package.try(:scan_active)
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to profiles_path
    end
  end

  def load_dematbox
    @dematbox = @user.dematbox || Dematbox.create(user_id: @user.id)
  end
end