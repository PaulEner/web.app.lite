# frozen_string_literal: true

class RetrieverController < FrontController
  before_action :verify_rights
  before_action :load_account

  private

  def verify_rights
    unless (accounts.any? && @user.organization.is_active) || @user.organization.specific_mission
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to root_path
    end
  end

  def load_account
    if params[:_ext]
      s_params = JSON.parse(Base64.decode64(params[:k]))
      session[:retrievers_account_id] = s_params['account_id']
      @account = accounts.where(id: s_params['account_id']).first
    elsif accounts.count == 1
      @account = accounts.first
      session[:retrievers_account_id] = @account.id
    else
      account_id = params[:account_id].presence || session[:retrievers_account_id].presence || 'all'
      @account = nil

      if account_id != 'all'
        @account = accounts.where(id: account_id).first || accounts.first
      end
      session[:retrievers_account_id] = account_id
    end
  end

  def accounts
    if @user.organization.specific_mission
      super
    else
      #### TO DO : Find a better way to get all active retriever users
      # super.joins(:options).where('user_options.is_retriever_authorized = ?', true)
      user_ids = [0] + super.select{ |ac| ac.my_package.try(:bank_active) }.map{ |ac| ac.id }
      super.where(id: user_ids)
    end
  end

  def verif_account
    @account = accounts.first if not @account

    @customer = @account

    redirect_to retrievers_path if not @account
  end
end
