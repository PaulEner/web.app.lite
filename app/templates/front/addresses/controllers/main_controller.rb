# frozen_string_literal: true
class Addresses::MainController < FrontController
  before_action :verify_access
  before_action :load_address, only: %w[destroy]

  prepend_view_path('app/templates/front/addresses/views')

  # DELETE /account/addresses/:address_id
  def destroy
    @address.destroy
    render json: { json_flash: { success: 'Supprimé avec succès.' } }, status: 200
  end

  def update_all
    if params[:addr_for] == 'user'
      object = User.find(params[:id])
    else
      object = Organization.find(params[:id])
    end

    error = []

    3.times do |i|
      if i == 0 && params[:paper_return]
        address = object.addresses.for_paper_return.first || object.addresses.new(is_for_paper_return: true)
        address.assign_attributes( address_params(:paper_return) )
        address.is_for_paper_set_shipping = false
        address.is_for_dematbox_shipping  = false
      elsif i == 1 && params[:paper_set_shipping]
        address = object.addresses.for_paper_set_shipping.first || object.addresses.new(is_for_paper_set_shipping: true)
        address.assign_attributes( address_params(:paper_set_shipping) )
        address.is_for_paper_return       = false
        address.is_for_dematbox_shipping  = false
      else
        if object.is_a?(User) && params[:dematbox_shipping]
          address = object.addresses.for_dematbox_shipping.first || object.addresses.new(is_for_dematbox_shipping: true)
          address.is_for_paper_set_shipping = false
          address.is_for_paper_return       = false
          address.assign_attributes( address_params(:dematbox_shipping) )
        elsif object.is_a?(Organization) && params[:billing]
          address = object.addresses.for_billing.first || object.addresses.new(is_for_billing: true)
          address.is_for_paper_set_shipping = false
          address.is_for_paper_return       = false
          address.assign_attributes( address_params(:billing) )
        end
      end

      if address
        error << errors_to_list(address) unless address.save
      end
    end

    if error.any?
      json_flash[:error] = error.join('<hr />')
    else
      json_flash[:success] = 'Mise à jour avec succès'
    end

    render json: { json_flash: json_flash }, status: 200
  end

  private

  def verify_access
    unless @user
      render json: { json_flash: { error: t('authorization.unessessary_rights') } }, status: 200
    end
  end

  def load_address
    @address = Address.find(params[:id])
  end

  def address_params(type)
    params.require(type.to_sym).permit(
      :first_name,
      :last_name,
      :company,
      :company_number,
      :address_1,
      :address_2,
      :city,
      :zip,
      :state,
      :country,
      :building,
      :place_called_or_postal_box,
      :door_code,
      :other,
      :phone,
      :is_for_billing,
      :is_for_paper_return,
      :is_for_paper_set_shipping,
      :is_for_dematbox_shipping
    )
  end
end