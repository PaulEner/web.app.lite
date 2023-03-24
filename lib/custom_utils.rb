class CustomUtils
  class << self
    def period_of(date=Time.now)
      "#{date.to_date.year}#{(sprintf '%02d', date.to_date.month)}".to_i
    end

    def period_to_date(period)
      _period_s = period.to_s

      date = Date.new(_period_s[0..3].to_i, _period_s[4..5].to_i, 1)
    end

    def period_operation(period, step=1)
      __period = period.to_i
      __step   = step.to_i.abs

      __step.times do |i|
        if step > 0
          __period += 1
        else
          __period -= 1
        end

        if __period.to_s[4..6].to_i == 0
          __period -= 88
        elsif __period.to_s[4..6].to_i == 13
          __period += 88
        end
      end

      __period
    end

    def period_diff(period1, period2)
      _diff = 0
      _tmp_period = period1
      _step = 1
      _step = -1 if period2.to_i < period1.to_i

      while _tmp_period.to_i != period2.to_i && period2.to_i > 0 && _diff < 200
        _tmp_period = CustomUtils.period_operation(_tmp_period, _step)
        _diff += 1
      end

      p "WARNING : The difference is too dipper, abort infinite loopping risk" if _diff >= 150

      _diff
    end

    def parse_date_range_of(date='')
      _date = date

      if date.try(:[], '>=') || date.try(:[], '<=')
        _t_date = []
        _t_date[0] = date.try(:[], '>=').presence || 10.years.ago.strftime('%Y-%m-%d')
        _t_date[1] = date.try(:[], '<=').presence || 1.days.after.strftime('%Y-%m-%d')

        _t_date[0] = Date.parse(_t_date[0]).to_date.strftime("%d/%m/%Y")
        _t_date[1] = Date.parse(_t_date[1]).to_date.strftime("%d/%m/%Y")

        _date = _t_date.join('-')
      end

      parsed_date = _date.gsub(' ', '').split('-')

      begin
        date1 = parsed_date[0].split('/')[2].to_s + '-' + parsed_date[0].split('/')[1].to_s + '-' + parsed_date[0].split('/')[0].to_s
        date2 = parsed_date[1].split('/')[2].to_s + '-' + parsed_date[1].split('/')[1].to_s + '-' + parsed_date[1].split('/')[0].to_s
      rescue
        date1 = ''
        date2 = ''
      end

      if !date1.match(/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) && !date2.match(/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/)
        date1 = 10.years.ago.strftime('%Y-%m-%d')
        date2 = 10.years.ago.strftime('%Y-%m-%d')
      end

      ["#{date1.to_s} 00:00:00", "#{date2.to_s} 23:59:59"]
    end

    def replace_code_of(code) #replace old code 'AC0162' with 'MVN%GRHCONSULT'
      if code.match(/^AC0162/)
        code.gsub('AC0162', 'MVN%GRHCONSULT')
      elsif code.match(/^MFA[%]ADAPTO/)
        code.gsub('MFA%ADAPTO', 'ACC%0455')
      elsif code.match(/^ACC[%]0424/)
        code.gsub('ACC%0424', 'SEL%0424')
      elsif code.match(/^ACC[%]0419/)
        code.gsub('ACC%0419', 'SEL%0419')
      elsif code.match(/^ACC[%]0333/)
        code.gsub('ACC%0333', 'SEL%0333')
      elsif code.match(/^CRE[%]000CAPIO2/)
        code.gsub('CRE%000CAPIO2', 'ACC%BYMO2')
      elsif code.match(/^ACC[%]CAPIO2/)
        code.gsub('ACC%CAPIO2', 'ACC%BYMO2')
      else
        code
      end
    end

    def replace_period_of(pack_name)
      ['CMPZ%ABOURILLON', 'CMPZ%AZEPA', 'CMPZ%EUSKAL', 'CMPZ%PHARMACIE', 'CMPZ%MORVAN', 'CMPZ%ERMITECH'].each do |code|
        if pack_name.match(/^#{code}/)
          spl = pack_name.strip.split(' ')
          spl[spl.size - 1] = spl.last.gsub('2022', '2021')

          pack_name = spl.join(' ')
        end
      end

      pack_name
    end

    def arrStr_to_array(data)
      return [] if data.blank?

      is_array = true
      begin
        data.size
      rescue
        is_array = false
      end

      if is_array
        data
      else
        exist   = true
        i       = 0
        result  = []
        while exist
          dt = data[i.to_s]
          i += 1
          if dt.present?
            result << dt
          else
            exist = false
         end
        end

        result
      end
    end


    def manual_scans_codes
      ['AC0162', 'MFA%ADAPTO']
    end


    def clear_string(str, replacement = '_')
      str = str.gsub(/[^a-z0-9_.éèàçôêîù:\/]/i, replacement.to_s)
      str = str.gsub(/#{replacement.to_s}+/, replacement.to_s) if replacement.present?

      str
    end

    def add_chmod_access_into(nfs_directory, type=0777)
      directory = Rails.env == "production" ? nfs_directory : nfs_directory.sub(/nfs/, 'tmp')

      FileUtils.chmod(type, directory)
    end

    def customize_file_name(file_naming_policy, options)
      options = options.with_indifferent_access

      data = []

      data << [options['user_code'],    file_naming_policy.first_user_identifier_position]  if file_naming_policy.first_user_identifier == 'code'
      data << [options['user_company'], file_naming_policy.first_user_identifier_position]  if file_naming_policy.first_user_identifier == 'company'

      data << [options['user_code'],    file_naming_policy.second_user_identifier_position] if file_naming_policy.second_user_identifier == 'code'
      data << [options['user_company'], file_naming_policy.second_user_identifier_position] if file_naming_policy.second_user_identifier == 'company'

      data << [options['period'],  file_naming_policy.period_position]  if file_naming_policy.is_period_used
      data << [options['journal'], file_naming_policy.journal_position] if file_naming_policy.is_journal_used

      data << [options['third_party'],  file_naming_policy.third_party_position]  if file_naming_policy.is_third_party_used
      data << [options['piece_number'], file_naming_policy.piece_number_position] if file_naming_policy.is_piece_number_used

      data << [options['invoice_date'],   file_naming_policy.invoice_date_position]   if file_naming_policy.is_invoice_date_used
      data << [options['invoice_number'], file_naming_policy.invoice_number_position] if file_naming_policy.is_invoice_number_used

      file_name = data.sort_by(&:last)
                      .map(&:first)
                      .compact
                      .map(&:strip)
                      .join(file_naming_policy.separator)
                      .gsub(/\s*(\/|\||\\|:|&)+\s*/, file_naming_policy.separator)
                      .gsub(/\s+/, file_naming_policy.separator)

      file_name + options['extension']
    end

    def mktmpdir(from, specific_dir=nil, with_remove=true)
      default_tmp_dir = Rails.root.join("tmp")

      final_dir = specific_dir || default_tmp_dir

      final_dir = default_tmp_dir if final_dir.present? && final_dir.to_s.match(/nfs/).present? && Rails.env != "production"

      begin
        add_chmod_access_into(final_dir)
        final_dir = File.join(final_dir, Time.now.strftime("%Y%m%d%H%M%s_#{SecureRandom.alphanumeric}"))
        FileUtils.mkdir_p final_dir
        add_chmod_access_into(final_dir)

        yield(final_dir) if block_given?

        FileUtils.delay_for(rand(2..10).minutes, queue: :high).remove_entry(final_dir, true) if block_given? && with_remove && final_dir
      rescue => e
        log_document = {
          subject: "[CustomUtils] error on tmp dir creation",
          name: "CustomTempDir",
          error_group: "[CustomTempDir] error on tmp dir creation",
          erreur_type: "temp dir error creation",
          date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%s'),
          more_information: {
            from: from.to_s,
            final_dir: final_dir,
            error: e.to_s,
          }
        }

        ErrorScriptMailer.error_notification(log_document).deliver
      end

      final_dir
    end

    def is_manual_paper_set_order?(organization)
      ["MCN", "CEN", "IDOC"].include?(organization.code)
    end

    def reduced_retriever_price?(organization_code)
      ['ADV', 'ALM'].include?(organization_code)
    end

    def use_vats_2?(organization_code)
      ['MCA', 'MCAC'].include?(organization_code)
    end

    def list_vat_of(organization_code)
      return { "-1" => "0", "0" => "22", "11" => "11", "6" => "6", "3" => "3" } if use_vats_2?(organization_code)

      return { "-1" => "0", "0" => "20", "10" => "10", "8.5" => "8.5", "5.5" => "5.5", "2.1" => "2.1" }
    end

    def is_ido_premium?(organization_code)
      BillingMod::Configuration::PREMIUM[organization_code.to_sym].present?
    end

    def use_final_documents?(user)
      return true #Everybody uses final doc now

      # return true if ['IDOC', 'MCN'].include?(user.organization.code)
      # return false
    end

    def can_create_budgea_documents(customer)
      return true if ["ACC%0336"].include?(customer.try(:my_code).to_s)
      return true if ["IDOC", "AFH", "AGEC"].include?(customer.try(:organization).try(:code).to_s)

      return false
    end

    def mailing_authorized_for?(organization)
      return false if not organization

      !["ALM"].include?(organization.code)
    end

    def format_price(price_in_cents)
      price_in_euros = price_in_cents.blank? ? "" : price_in_cents.round / 100.0
      ("%0.2f" % price_in_euros)
    end
  end
end