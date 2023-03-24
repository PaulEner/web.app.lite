class PonctualScripts::CreateCustomerViaCsv
  def initialize(file_path=nil, requester_code=nil)
    @file_path      = file_path || Rails.root.join('spec/support/files/ponctual_scripts/new_customer_2.csv')
    @requester_code = requester_code || 'ALM%ZG'
  end

  def execute
    return false if not File.exist?(@file_path)

    data_errors = []
    data_bank   = []
    data_not_created   = []
    data_file   = File.read(@file_path)

    user      = User.get_by_code(@requester_code)
    requester = Collaborator.new(user)
    match_bank_name = BankAccount.all.collect(&:bank_name).uniq

    data_file.each_line do |line|
      data = line.split(",")

      next if data[1].strip == 'Code'

      organization = Organization.find_by_code(data[1].split('%')[0]).presence
      customer     = User.find_by_code(data[1].strip)

      if not customer
        p "========= CREATE: #{data[1].strip}=========="
        user_params  = { company: data[2], code: data[1], first_name: data[4], last_name: data[3], phone_number: data[9], email: data[10] }
        customer = Subscription::CreateCustomer.new(organization, requester, user_params, nil, nil).execute if organization && requester
        params_subscription = { subscription_option: "ido_plus_micro", number_of_journals: 5, is_pre_assignment_active: 'true', retriever_option: 'true' }

        Subscription::Form.new(customer.subscription, requester, nil).submit(params_subscription) if customer.persisted?
      end

      if organization && customer.persisted?
        if data[11].strip.present?
          bank_name = ''
          match_bank_name.each{ |_name| bank_name = _name if bank_name.blank? && data[13].downcase.include?(_name.tr('éèếÉ', 'eeee').downcase) }

          if bank_name.blank?
            data_not_created << { user: customer.code, bank_name: data[13] }
          end

          bank_account                   = customer.bank_accounts.where(api_name: 'idocus', name: bank_name, number: data[11].strip).first || BankAccount.new
          bank_account.user              = customer
          bank_account.api_name          = 'idocus'
          bank_account.bank_name         = bank_name
          bank_account.name              = data[13].strip
          bank_account.number            = data[11].strip
          bank_account.journal           = data[15].strip
          bank_account.currency          = data[12].strip
          bank_account.original_currency = {"id"=>"EUR", "symbol"=>"€", "prefix"=>false, "precision"=>2, "marketcap"=>nil, "datetime"=>nil, "name"=>"Euro"}
          bank_account.accounting_number = data[14].strip
          bank_account.temporary_account = "471000"
          bank_account.start_date        = data[16].gsub(/\n/, '')
          bank_account.is_used           = true

          data_bank << { csv: data[13], base: bank_name.titleize }  if !bank_name.blank? && bank_name.downcase != data[13].downcase

          if not bank_account.save
            data_errors << { code: data[1], error_bank_message: bank_account.try(:errors).try(:messages) }
          end
        end
      else
        data_errors << { code: data[1], message: customer.try(:errors).try(:messages) }
      end
    end

    send_mail_for(data_bank, data_errors, data_not_created)
    p data_errors
  end 

  private

  def send_mail_for(data_bank, data_errors, data_not_created)
    # lines = []
    # data_bank.each do |data|
    #   lines << data.join(';')
    # end

    CustomUtils.mktmpdir('create_customers_via_csv', nil, false) do |dir|
      # file_path = File.join(dir, "create_customers_via_csv.csv")

      # File.write(file_path, lines.join("\n"));

      log_document = {
        subject: "[CreateCustomerViaCsv] creation dossier via CSV",
        name: "CreateCustomerViaCsv",
        error_group: "[CreateCustomerViaCsv] creation dossier via CSV",
        erreur_type: "[CreateCustomerViaCsv] - creation dossier via CSV",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          data_banks: data_bank.to_json,
          data_errors: data_errors.to_json,
          data_not_created: data_not_created.to_json,
        }
      }

      # begin
      #   ErrorScriptMailer.error_notification(log_document, { attachements: [{name: "create_customers_via_csv.csv", file: File.read(file_path)}]} ).deliver
      # rescue
        ErrorScriptMailer.error_notification(log_document).deliver
      # end

      # p file_path
    end
  end
end