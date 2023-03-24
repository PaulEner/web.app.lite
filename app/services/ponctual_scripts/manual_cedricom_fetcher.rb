class PonctualScripts::ManualCedricomFetcher
  def initialize; end

  def execute(dat = '6-12-2022', fetch = false)
    organization = Organization.find_by_code 'ACC'
    date = Date.parse(dat).strftime("%d%m%Y")

    xml = Hash.from_xml(Cedricom::Api.new(organization).get_reception_list(date))

    if xml && xml['Receptions']
      p "======== Launch fetching ========="

      xml['Receptions']['Reception'].each do |reception|
        next if CedricomReception.where(id: reception['IdReception'], organization_id: organization.id).first

        if fetch
          reception = CedricomReception.create(cedricom_id: reception['IdReception'],
                                               cedricom_reception_date: Date::strptime(reception['DateReception'], '%d%m%Y'),
                                               empty: false,
                                               imported: true,
                                               downloaded: true,
                                               organization: organization)

          next if not reception

          p "==== IMPORT : #{reception.reload.id} #{reception.cedricom_id}"

          content = Cedricom::Api.new(organization).get_reception(reception.cedricom_id)

          if content
            reception.content.attach(io: StringIO.new(content), filename: 'content.txt', content_type: 'text/plain')

            if reception.content
              reception.update(downloaded: true)

              p "=========== Fetch Transactions ====== "

              PonctualScripts::ImportTransactions.new(reception.reload).perform
            end
          else
            p "=========== EMPTY Transactions ====== "

            reception.update(empty: true, downloaded: true)
          end
          p "=========== Done : #{reception.id}"
        else
          p "=== cedricom id: #{reception['IdReception']} =="
        end
      end
    end
  end
end


class PonctualScripts::ImportTransactions
  CREDIT_OPERATION_CODES = %w(02 04 05 09 12 13 15 16 17 18 24 25 30 31 32 34 35 37 39 40 45 47 49 55 57 59 63 69 72 73 74 77 78 85 87 97 A1 A2 A3 A4 B5 B6 C2 C3 C5)

  def initialize(reception)
    @reception = reception
  end

  def perform
    cfonb_by_line = @reception.content.download.split(/\r\n+/)

    raw_operations = read_cfonb(cfonb_by_line)

    operations = format_operations(raw_operations)

    result = save_operations(operations)

    @reception.update(imported: true,
                skipped_operations_count: result[:skipped_operations_count],
                imported_operations_count: result[:imported_operations_count],
                total_operations_count: result[:total_operations_count])
  end

  private

  def operation_type(line)
    line[0..1]
  end

  def bank_account(line)
    line[2..6] + line[11..15] + line[21..31]
  end

  def currency(line)
    line[16..18]
  end

  def decimals_count(line)
    line[19]
  end

  def operation_code(line)
    line[32..33]
  end

  def date(line)
    line[34..39]
  end

  def value_date(line)
    line[42..47]
  end

  def label(line)
    line[48..78]
  end

  def entry_number(line)
    line[81..87]
  end

  def amount(line)
    line[90..102]
  end

  def amount_last_digit(line)
    line[103..103]
  end

  def operation_reference(line)
    line[104..119]
  end

  def get_last_digit_and_sign(last_digit)
    @sign = nil
    @last_digit = nil

    case last_digit
    when "{"
      @last_digit = "0"
      @sign = "+"
    when "A"
      @last_digit = "1"
      @sign = "+"
    when "B"
      @last_digit = "2"
      @sign = "+"
    when "C"
      @last_digit = "3"
      @sign = "+"
    when "D"
      @last_digit = "4"
      @sign = "+"
    when "E"
      @last_digit = "5"
      @sign = "+"
    when "F"
      @last_digit = "6"
      @sign = "+"
    when "G"
      @last_digit = "7"
      @sign = "+"
    when "H"
      @last_digit = "8"
      @sign = "+"
    when "I"
      @last_digit = "9"
      @sign = "+"
    when "}"
      @last_digit = "0"
      @sign = "-"
    when "J"
      @last_digit = "1"
      @sign = "-"
    when "K"
      @last_digit = "2"
      @sign = "-"
    when "L"
      @last_digit = "3"
      @sign = "-"
    when "M"
      @last_digit = "4"
      @sign = "-"
    when "N"
      @last_digit = "5"
      @sign = "-"
    when "O"
      @last_digit = "6"
      @sign = "-"
    when "P"
      @last_digit = "7"
      @sign = "-"
    when "Q"
      @last_digit = "8"
      @sign = "-"
    when "R"
      @last_digit = "9"
      @sign = "-"
    end

    { last_digit: @last_digit, sign: @sign}
  end

  def format_amount(amount, operation_code, decimals_count, amount_last_digit)
    last_digit_and_sign = get_last_digit_and_sign(amount_last_digit)

    raw_amount = "#{amount}#{last_digit_and_sign[:last_digit]}".to_i

    absolute_amount = (raw_amount.to_f / (10**decimals_count.to_i)).round(2)

    if last_digit_and_sign[:sign] == "-"
      absolute_amount = absolute_amount * -1
    end

    absolute_amount
  end

  def format_date(date)
    Date.strptime(date, '%d%m%y')
  end

  def format_label(label)
    label.squeeze(' ').rstrip
  end

  def customer_bank_account(bank_account)
    banks = BankAccount.ebics_enabled.used.where("bank_accounts.number LIKE ?", "%#{bank_account}%")

    if banks.size == 1
      return banks.first
    else
      __banks = banks.select{ |ba| ba.number.upcase == bank_account.upcase }
      return __banks.first
    end

    return nil
  end

  def read_cfonb(cfonb_by_line)
    raw_operations = []
    lines          = []

    cfonb_by_line.each do |line|
      # REMOVE : FILTER DUPLICATED DATA FROM CEDRICOM RECEPTION
      # next if raw_operations.size > 0 && raw_operations.select{ |raw| raw[:date] == date(line) && raw[:label] == label(line) && raw[:amount] == amount(line) && raw[:bank_account] == bank_account(line) }.size > 0
      # next if lines.size > 0 && lines.include?(line.squish)

      lines << line.squish

      raw_operations << {
        date: date(line),
        label: label(line),
        amount: amount(line),
        currency: currency(line),
        value_date: value_date(line),
        bank_account: bank_account(line),
        entry_number: entry_number(line),
        operation_type: operation_type(line),
        operation_code: operation_code(line),
        decimals_count: decimals_count(line),
        amount_last_digit: amount_last_digit(line),
        operation_reference: operation_reference(line)
      }
    end

    raw_operations
  end

  def format_operations(raw_operations)
    operations = []

    raw_operations.each do |raw_operation|
      if raw_operation[:operation_type] == "04"
        amount = format_amount(raw_operation[:amount],
                               raw_operation[:operation_code],
                               raw_operation[:decimals_count],
                               raw_operation[:amount_last_digit])

        operations << {
          date: format_date(raw_operation[:date]),
          value_date: format_date(raw_operation[:value_date]),
          amount: amount,
          currency: raw_operation[:currency],
          long_label: format_label(raw_operation[:label]),
          short_label: format_label(raw_operation[:label]),
          bank_account: raw_operation[:bank_account]
        }
      elsif raw_operation[:operation_type] == "05"
        operations.last[:long_label] = operations.last[:long_label] + " - #{format_label(raw_operation[:label])}"
      end
    end

    operations
  end

  def check_duplicated(bank_account, cedricom_operation)
    bank_account.operations.where(api_name: 'cedricom', label: cedricom_operation[:long_label], date: cedricom_operation[:date], amount: cedricom_operation[:amount]).first
  end

  def save_operation(bank_account, cedricom_operation)
    duplicate_ope = check_duplicated bank_account, cedricom_operation if bank_account

    operation = Operation.new

    operation.user         = bank_account&.user
    operation.date         = cedricom_operation[:date]
    operation.amount       = cedricom_operation[:amount]
    operation.label        = cedricom_operation[:long_label]
    operation.api_name     = 'cedricom'
    operation.value_date   = cedricom_operation[:value_date]
    operation.organization = bank_account&.user&.organization ? bank_account&.user&.organization : @reception.organization
    operation.bank_account = bank_account
    operation.unrecognized_iban  = bank_account ? nil : cedricom_operation[:bank_account]
    operation.cedricom_reception = @reception
    operation.currency = case cedricom_operation[:currency_code]
                          when 'EUR'
                            @operation.currency = { id: 'EUR', symbol: '€', prefix: false, crypto: false, precision: 2, marketcap: nil, datetime: nil, name: 'Euro'}
                          when 'USD'
                            @operation.currency = { id: 'USD', symbol: '$', prefix: true, crypto: false, precision: 2, marketcap: nil, datetime: nil, name: 'US Dollar'}
                          when 'GBP'
                            @operation.currency = { id: 'GBP', symbol: '£', prefix: false, crypto: false, precision: 2, marketcap: nil, datetime: nil, name: 'British Pound Sterling'}
                          when 'CHF'
                            @operation.currency = { id: 'CHF', symbol: 'CHF', prefix: false, crypto: false, precision: 2, marketcap: nil, datetime: nil, name: 'Swiss Franc'}
                          when 'ZAR'
                            @operation.currency = { id: 'ZAR', symbol: 'R', prefix: false, crypto: false, precision: 2, marketcap: nil, datetime: nil, name: 'South African Rand'}
                          end

    operation.forced_processing_at = Time.now

    operation.is_locked = true ### VERY IMPORTANT

    operation.save!
    
    if operation.persisted? && operation.bank_account
      operation.update(api_id: "manual_ebics_#{operation.id}")
    end

    operation
  end

  def save_operations(operations)
    result = { imported_operations_count: 0, total_operations_count: operations.count, skipped_operations_count: 0}

    operations.each do |operation|
      bank_account = customer_bank_account(operation[:bank_account])
      
      if bank_account
        if operation[:date] <= bank_account.ebics_enabled_starting
          result[:skipped_operations_count] = result[:skipped_operations_count] + 1
          next
        end
      end

      customer_operation = save_operation(bank_account, operation)

      if customer_operation
        result[:imported_operations_count] = result[:imported_operations_count] + 1
      end
    end

    result
  end
end