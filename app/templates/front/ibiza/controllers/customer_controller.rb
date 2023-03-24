# frozen_string_literal: true

class Ibiza::CustomerController < CustomerController
  before_action :load_customer
  before_action :verify_rights

  prepend_view_path('app/templates/front/ibiza/views')

  def edit; end

  def update
    @customer.assign_attributes(ibiza_params)

    is_ibiza_id_changed = @customer.try(:ibiza).try(:ibiza_id_changed?)

    if @customer.save
      if @customer.configured?
        if is_ibiza_id_changed && @user.try(:ibiza).try(:ibiza_id?)
          AccountingPlan::IbizaUpdate.new(@user).run
        end

        json_flash[:success] = 'Modifié avec succès'
      end
    else
      json_flash[:error] = 'Impossible de modifier'
    end

    render json: { json_flash: json_flash }, status: 200
  end

  private

  def load_customer
    @customer = customers.find(params[:customer_id])
  end

  def can_manage?
    @user.leader? || @user.manage_customers
  end

  def verify_rights
    authorized = true
    authorized = false unless can_manage?

    if action_name.in?(%w[edit_ibiza update_ibiza]) && !@organization.ibiza.try(:configured?)
      authorized = false
    end

    unless authorized
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to organization_path(@organization)
    end
  end

  def ibiza_params
    params.require(:user).permit(ibiza_attributes: %i[id ibiza_id auto_deliver is_analysis_activated is_analysis_to_validate])
  end
end