# frozen_string_literal: true
class Ibiza::MainController < OrganizationController
  before_action :verify_rights
  before_action :load_ibiza, except: :create

  prepend_view_path('app/templates/front/ibiza/views')

  # GET /organizations/:organization_id/ibiza/edit
  def setting
    @ibiza = @organization.ibiza
  end

  # PUT /organizations/:organization_id/ibiza
  def update
    if @ibiza.update(ibiza_params)
      #Clear cache of IbizaLib::Client base domain
      Rails.cache.delete(['ibiza_base_domaine', @ibiza.access_token]) if @ibiza.access_token.present?

      if @ibiza.need_to_verify_access_tokens?
        IbizaLib::VerifyAccessTokens.new(@ibiza.id.to_s).execute
      end

      software_users = params[:software_account_list] || ''
      @organization.customers.active.each do |customer|
        softwares_params = { columns: { is_used: (software_users.include?(customer.to_s) && !customer.uses?(:exact_online)) }, software: 'ibiza' }

        customer.create_or_update_software(softwares_params)
      end

      json_flash[:success] = 'Modifié avec succès.'
    else
      json_flash[:error] = errors_to_list @ibiza
    end

    render json: { json_flash: json_flash }, status: 200
  end

  private

  def verify_rights
    unless @user.leader?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to organization_path(@organization)
    end
  end

  def load_ibiza
    @ibiza = @organization.ibiza
  end

  def ibiza_params
    params.require(:software_ibiza).permit(:specific_url_options, :ibiza_id, :access_token, :access_token_2, :auto_deliver, :is_analysis_activated, :is_analysis_to_validate, :description_separator, :piece_name_format_sep, :voucher_ref_target).tap do |whitelist|
      whitelist[:description]       = JSON.parse(params[:software_ibiza][:description]).with_indifferent_access
      whitelist[:piece_name_format] = JSON.parse(params[:software_ibiza][:piece_name_format]).with_indifferent_access
    end
  end
end