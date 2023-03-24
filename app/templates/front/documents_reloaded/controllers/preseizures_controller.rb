# frozen_string_literal: true

class DocumentsReloaded::PreseizuresController < DocumentsReloaded::AbaseController
  skip_before_action :verify_if_active, only: %w[index show]
  before_action :load_preseizure, except: %w[accounts_list update_multiple_preseizures edit_multiple_preseizures]

  prepend_view_path('app/templates/front/documents_reloaded/views')

  def index
    render partial: 'preseizure_box', locals: { preseizure: @preseizure, piece: @preseizure.try(:piece), operation: @preseizure.try(:operation) }
  end

  def show
    if params[:view] == 'by_type'
      if @preseizure.operation
        render file: Rails.root.join('app/templates/front/documents_reloaded/views/documents/operations/_operation_box.html.haml'), locals: { preseizure: @preseizure, animation: 'toLeft' }
      else
        @pieces = [@preseizure.piece]
        render file: Rails.root.join('app/templates/front/documents_reloaded/views/documents/pieces/_piece_box.html.haml')
      end
    else
      render partial: 'show'
    end
  end

  def update
    if @user.has_collaborator_action?
      error = ''
      if params[:partial_update].present?
        @preseizure.date = params[:date] if params[:date].present?
        if params[:deadline_date].present?
          @preseizure.deadline_date  = params[:deadline_date]
        end
        if params[:third_party].present?
          @preseizure.third_party    = params[:third_party]
        end

        error = @preseizure.errors.full_messages unless @preseizure.save
      else
        @preseizure.assign_attributes params[:pack_report_preseizure].permit(:date, :deadline_date, :third_party, :operation_label, :piece_number, :amount, :currency, :conversion_rate, :observation)
        if @preseizure.conversion_rate_changed? || @preseizure.amount_changed?
          @preseizure.update_entries_amount
        end

        error = @preseizure.errors.full_messages unless @preseizure.save
      end

      render json: { error: error }, status: 200
    else
      render json: { error: "Authorisation requise" }, status: 200
    end
  end

  def update_account
    if @user.has_collaborator_action?
      error = ''
      if params[:type] == 'account'
        account = Pack::Report::Preseizure::Account.find params[:account_id]
        account.number = params[:new_value]
        error = account.errors.full_messages if not account.save
      elsif params[:type] == 'entry'
        entry = Pack::Report::Preseizure::Entry.find params[:account_id]
        entry.amount = params[:new_value]
        error = entry.errors.full_messages if not entry.save
      elsif params[:type] == 'change_type'
        entry = Pack::Report::Preseizure::Entry.find params[:account_id]
        entry.type = params[:new_value]
        error = entry.errors.full_messages if not entry.save
      end

      render json: { error: error }, status: 200
    else
      render json: { error: '' }, status: 200
    end
  end

  def accounts_list
    account        = Pack::Report::Preseizure::Account.find params[:account_id]
    @accounts_name = account.get_similar_accounts

    render partial: 'accounts_list'
  end

  def edit_multiple_preseizures
    @preseizure = Pack::Report::Preseizure.new

    render partial: 'show'
  end

  def update_multiple_preseizures
    if @user.has_collaborator_action?
      preseizures = Pack::Report::Preseizure.where(id: params[:preseizures_ids].split(','))

      real_params = update_multiple_preseizures_params
      begin
        error = ''
        preseizures.update_all(real_params) if real_params.present?
      rescue StandardError => e
        error = 'Impossible de modifier la séléction'
      end

      render json: { error: error }, status: 200
    else
      render json: { error: '' }, status: 200
    end
  end

  def edit_third_party
    value = params[:value]

    @preseizure.third_party = value if params[:type] == 'name'
    
    if params[:type] == 'date'
      tmp_date = value.split('/')

      date_value = "#{tmp_date[2]}-#{tmp_date[1]}-#{tmp_date[0]} 23:00:00"
      @preseizure.date = date_value
    end

    if @preseizure.save
      render json: { error: "" }, status: 200
    else
      render json: { error: @preseizure.errors.messages }, status: 200
    end   
  end

  private

  def update_multiple_preseizures_params
    {
      date: params[:pack_report_preseizure][:date].presence,
      deadline_date: params[:pack_report_preseizure][:deadline_date].presence,
      third_party: params[:pack_report_preseizure][:third_party].presence,
      conversion_rate: params[:pack_report_preseizure][:conversion_rate].presence,
      observation: params[:pack_report_preseizure][:observation].presence
    }.compact
  end

  def load_preseizure
    @preseizure = Pack::Report::Preseizure.find params[:id]
  end
end
