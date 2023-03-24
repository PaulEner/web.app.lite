# frozen_string_literal: true
class Payments::MainController < OrganizationController
  before_action :apply_membership,               except: :debit_mandate_notify
  before_action :verify_rights,                  except: %w[debit_mandate_notify revoke_payment]

  skip_before_action :load_organization,         only: :debit_mandate_notify
  skip_before_action :login_user!,               only: :debit_mandate_notify
  skip_before_action :load_user_and_role,        only: :debit_mandate_notify, raise: false
  skip_before_action :verify_authenticity_token, only: :debit_mandate_notify, raise: false
  skip_before_action :verify_suspension

  prepend_view_path('app/templates/front/payments/views')

  # GET /account/organizations/:id/edit_payment
  def edit_payment; end

  def prepare_payment
    debit_mandate = @organization.debit_mandate

    if debit_mandate.pending?
      debit_mandate.title             = payment_params[:gender]
      debit_mandate.firstName         = payment_params[:first_name]
      debit_mandate.lastName          = payment_params[:last_name]
      debit_mandate.email             = payment_params[:email]
      debit_mandate.invoiceLine1      = payment_params[:address]
      debit_mandate.invoiceLine2      = payment_params[:address_2]
      debit_mandate.invoiceCity       = payment_params[:city]
      debit_mandate.invoicePostalCode = payment_params[:postal_code]
      debit_mandate.invoiceCountry    = payment_params[:country]
    end

    if debit_mandate.save
      mandate = Billing::DebitMandateResponse.new debit_mandate
      mandate.prepare_order

      if mandate.errors
        render json: { success: false, message: mandate.errors }, status: 200
      else
        debit_mandate.update(reference: mandate.order_reference, transactionStatus: 'started')

        render json: { success: true, frame_64: mandate.get_frame }, status: 200
      end
    else
      render json: { success: false, message: debit_mandate.errors.message }, status: 200
    end
  end

  def confirm_payment
    debit_mandate = @organization.debit_mandate
    if debit_mandate.started?
      Billing::DebitMandateResponse.new(debit_mandate).confirm_payment
    end

    render json: { success: true, debit_mandate: @organization.debit_mandate.reload }, status: 200
  end

  def revoke_payment
    if current_user.is_admin && params[:revoke_confirm] == 'true'
      result = Billing::DebitMandateResponse.new(@organization.debit_mandate).send(:revoke_payment)
      if result.present?
        json_flash[:error]   = result
      else
        json_flash[:success] = 'Mandat supprimé avec succès.'
      end
    else
      json_flash[:error]   = t('authorization.unessessary_rights')
    end

    render json: { json_flash: json_flash }, status: 200
  end

  # POST /account/payment/debit_mandate_notify
  def debit_mandate_notify
    # NOTE: slimpay notification doesn't work so we fetch the debit mandate infos after debit configuration
    render plain: 'OK'
    # attributes = Billing::DebitMandateResponse.new(params[:blob]).execute

    # if attributes.present?
    #   debit_mandate = DebitMandate.where(clientReference: attributes['clientReference']).first

    #   if debit_mandate
    #     debit_mandate.update(attributes)

    #     if debit_mandate.configured? && debit_mandate.organization.is_suspended
    #       debit_mandate.organization.update(is_suspended: false)
    #     end

    #     render plain: 'OK'
    #   else
    #     render plain: 'Erreur'
    #   end
    # else
    #   render plain: 'Erreur'
    # end
  end

  private

  def verify_rights
    authorized = false
    authorized = true if current_user.is_admin || @user.leader?

    if not authorized
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to organization_path(@organization)
    end
  end

  def payment_params
    params.permit(
      :gender,
      :first_name,
      :last_name,
      :email,
      :phone_number,
      :address,
      :address_2,
      :city,
      :postal_code,
      :country
    )
  end
end