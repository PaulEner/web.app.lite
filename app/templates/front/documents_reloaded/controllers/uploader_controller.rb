# frozen_string_literal: true
class DocumentsReloaded::UploaderController < DocumentsReloaded::AbaseController
  before_action :load_upload_user, except: %w[create]

  def create
    data = nil
    customer = if params[:file_code].present?
                 accounts.active.find_by_code(params[:file_code])
               else
                 @user
               end

    if params[:force]
      already_doc = Archive::AlreadyExist.find params[:id]

      file              = already_doc.path
      original_filename = params[:original_filename]
      customer          = User.find_by_code params[:file_code]

      to_upload = File.exist?(file)
    elsif params[:files].present?
      file              = params[:files][0].tempfile
      original_filename = params[:files][0].original_filename
      to_upload = true
    end
    
    if params[:for_customer].present?
      journal = AccountBookType.find params[:l_journal]

      params[:file_account_book_type] = journal.name
    end

    if customer && !customer.inactive? && ( (customer.authorized_upload? && to_upload) || customer.organization.specific_mission )
      uploaded_document = UploadedDocument.new(File.open(file),
                                               original_filename,
                                               customer,
                                               params[:file_account_book_type],
                                               params[:file_prev_period_offset],
                                               current_user,
                                               'web',
                                               params[:analytic],
                                               nil,
                                               params[:force],
                                               params[:tags])

      data = present(uploaded_document).to_json
    else
      data = { files: [{ name: params[:files].try(:[], 0).try(:original_filename), error: 'Accès non autorisé.' }] }.to_json
    end

    respond_to do |format|
      format.json { render json: data }
      format.html { render json: data } # IE8 compatibility
    end

  end

  def periods
    period_service = Billing::Period.new user: @upload_user
    current_time = Time.now

    period_duration = period_service.period_duration

    results = [[period_option_label(period_duration, current_time), 0]]

    if period_service.prev_expires_at.nil? || period_service.prev_expires_at > Time.now
      period_service.authd_prev_period.times do |i|
        current_time -= period_duration.month

        results << [period_option_label(period_duration, current_time), i + 1]
      end
    end

    render json: results, status: 200
  end

  def journals
    account_book_types = []

    if params[:is_customer].present?
      account_book_types = @upload_user.account_book_types

      options = account_book_types.map do |j|
        [j.full_name, j.id, '0']
      end
    else
      if @upload_user.organization.try(:specific_mission)
        account_book_types = @upload_user.account_book_types.specific_mission.by_position
      elsif @upload_user.authorized_upload?
        account_book_types_all      = @upload_user.account_book_types.by_position
        account_book_types_bank     = @upload_user.account_book_types.bank_processable.by_position

        account_book_types = account_book_types_all

        if not @upload_user.authorized_bank_upload?
          account_book_types = account_book_types_all - account_book_types_bank
        elsif not @upload_user.authorized_basic_upload?
          account_book_types = account_book_types_bank
        end
      end
      options = account_book_types.map do |j|
        [j.name + ' ' + j.description, j.name, (j.compta_processable? ? '1' : '0')]
      end
    end

    render json: options, status: 200
  end

  private

  def load_upload_user
    @upload_user = User.where(code: params[:upload_user], is_prescriber: false).first
  end

  def period_option_label(period_duration, time)
    case period_duration
    when 1
      time.strftime('%m %Y')
    when 3
      "T#{quarterly_of_month(time.month)} #{time.year}"
    when 12
      time.year.to_s
    end
  end

  def quarterly_of_month(month)
    if month < 4
      1
    elsif month < 7
      2
    elsif month < 10
      3
    else
      4
    end
  end
end