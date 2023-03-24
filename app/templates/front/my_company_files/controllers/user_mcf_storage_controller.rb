# frozen_string_literal: true

class MyCompanyFiles::UserMcfStorageController < CustomerController

  before_action :load_customer
  before_action :verify_rights

  prepend_view_path('app/templates/front/my_company_files/views')

  def index; end

  def edit_mcf; end

  def retake_mcf_errors
    if params[:confirm_unprocessable_mcf].present?
      confirm_unprocessable_mcf
    elsif params[:retake_mcf_documents].present?
      retake_mcf_documents
    end

    redirect_to organization_customer_my_company_files_path(@organization, @customer)
  end

  def update_mcf
    if @customer.update(mcf_params)
      flash[:success] = 'Modifié avec succès.'
    else
      flash[:success] = "Impossible de modifier: #{@customer.errors.messages.to_s}"
    end

    redirect_to organization_customer_my_company_files_path(@organization, @customer)
  end

  private

  def verify_rights
    unless @user.leader? || @user.manage_customers
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to organization_path(@organization)
    end
  end

  def mcf_params
    params.require(:user).permit(:mcf_storage)
  end

  def retake_mcf_documents
    mcf_documents_errors = @customer.mcf_documents.where(id: params[:mcf_documents_ids])
    if mcf_documents_errors.any?
      mcf_documents_errors.each(&:reset)
      flash[:success] = 'Récupération en cours...'
    end
  end

  def confirm_unprocessable_mcf
    unprocessable_mcf = @customer.mcf_documents.where(id: params[:mcf_documents_ids]).not_processable
    if unprocessable_mcf.any?
      unprocessable_mcf.each(&:confirm_unprocessable)
      flash[:success] = 'Modifié avec succès.'
    else
      flash[:error] = 'Impossible de traiter la demande.'
    end
  end

  def load_customer
    @customer = customers.find(params[:id] || params[:customer_id])
  end
end
