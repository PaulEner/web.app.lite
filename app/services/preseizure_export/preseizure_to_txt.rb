# -*- encoding : UTF-8 -*-
# Generates a Quadratus compliant TXT for preseizures
class PreseizureExport::PreseizureToTxt
  def initialize(preseizures)
    @preseizures = Array(preseizures)
  end


  def execute(type_of_export="zip_quadratus")
    case type_of_export
      when "zip_quadratus"
        export_zip_quadratus
      when "cegid_tra"
        export_cegid_tra
      when "fec_acd"
        export_fec_acd
      when "cogilog"
        export_cogilog
      when "ciel"
        export_ciel
      when "fec_agiris"
        export_fec_agiris
      when "fec_agiris_facnote"
        export_fec_agiris_facnote
      else
        export_fec_agiris
    end
  end

  private

  def export_zip_quadratus
    data = []
    @preseizures.each do |preseizure|
      preseizure.accounts.order(type: :asc).each do |account|
        entry = account.entries.first

        next if entry.amount.to_f == 0

        if preseizure.operation
          label = preseizure.operation_label.strip[0..29]
        else
          if preseizure.organization.code == 'ESP'
            label = preseizure.third_party.to_s.strip[0..29]
          else
            label = [preseizure.third_party.presence, preseizure.piece_number.presence].compact.join(' - ').strip[0..29]
          end
        end

        label = ' ' unless label.present?
        line = ' ' * 256
        line[0] = 'M'
        account_number = entry.account.try(:number) || ''

        8.times do |i|
          line[i + 1] = account_number[i] || ' '
        end

        line[9..10]    = preseizure.journal_name[0..1]
        line[11..13]   = '000'
        line[14..19]   = preseizure.computed_date.strftime('%d%m%y') if preseizure.date
        line[20]       = 'F' if CustomUtils.use_vats_2?(preseizure.organization.code)

        e = 21 + label[0..19].size - 1

        line[21..e]    = label[0..19]
        line[41]       = entry.type == 1 ? 'D' : 'C'
        line[42]       = entry.amount.to_f >= 0.0 ? '+' : '-'
        line[43..54]   = '%012d' % entry.amount_in_cents.to_f
        line[63..68]   = preseizure.deadline_date.strftime('%d%m%y') if preseizure.deadline_date
        line[69..73]   = entry.account.lettering.strip[0..4]         if entry.account.lettering.present?
        line[74..78]   = preseizure.piece_number.strip[0..4]         if preseizure.piece_number.present?
        line[99..106]  = preseizure.piece_number.strip[0..7]         if preseizure.piece_number.present?
        line[107..109] = CustomUtils.use_vats_2?(preseizure.organization.code) ? 'FRF' : 'EUR'
        line[110..112] = preseizure.journal_name.strip[0..2]         if preseizure.journal_name.strip.size > 2

        if label.size > 20
          e = 116 + label.size - 1
          line[116..e] = label
        end

        if preseizure.organization.code == 'ESP'
          __name = preseizure.piece.name.split
          line[148..157] = __name[2]+__name[3].to_s[0..9]
        else
          line[148..157] = preseizure.piece_number.strip[0..9].rjust(10, '0') if preseizure.piece_number.present?
        end

        if preseizure.piece
          file_name = preseizure.piece.position.to_s + '.pdf'
          e = 181 + file_name.size - 1
          line[181..e] = file_name
        end

        data << line

      end
    end

    data.join("\n")
  end

  def export_cogilog
    data = []

    if @preseizures.any?
      data << "Journal\tDate\tPièce\tCompte\tSection\tLibellé\tEchéance\tDebit\tCrédit\tIntitulé Journal\tIntitulé Compte\tIntitulé section\tLettrage\tPointage\tCode Fin\tRéférence\tInformations\tVierge\tVierge\tVierge\tVierge\tLien"

      @preseizures.each do |preseizure|
        user = preseizure.user
        journal = preseizure.report.journal({name_only: false})

        preseizure.accounts.each do |account|
          entry = account.entries.first

          if preseizure.piece_id.present?
            general_account = if(account.type == Pack::Report::Preseizure::Account::TVA)
                                journal.try(:get_vat_accounts_of, '0')
                              elsif(account.type == Pack::Report::Preseizure::Account::TTC)
                                journal.try(:account_number)
                              else
                                journal.try(:charge_account)
                              end
          else
            bank_account = preseizure.operation.try(:bank_account)

            general_account = if(
                                  (preseizure.operation.try(:amount).to_i < 0 && entry.credit?) ||
                                  (preseizure.operation.try(:amount).to_i >= 0 && entry.debit?)
                                )
                                bank_account.try(:accounting_number) || 512_000
                              else
                                bank_account.try(:temporary_account) || 471_000
                              end
          end

          auxiliary_account = (general_account.to_s != account.number.to_s)? account.number : ''
          general_account   = auxiliary_account if auxiliary_account.present?

          accounting = user.accounting_plan.providers.where(third_party_account: general_account).limit(1)

          if accounting.size == 0
            accounting = user.accounting_plan.customers.where(third_party_account: general_account).limit(1)
          end

          general_lib = preseizure.third_party


          journal_code     = journal.name
          ecriture_date    = preseizure.computed_date.strftime('%d/%m/%Y') || ""
          piece_ref        = preseizure.piece_number || ""
          compte_num       = general_account || ""
          section          = ""
          compte_lib       = general_lib
          echance_date     = preseizure.computed_deadline_date.try(:strftime, '%d/%m/%Y')
          debit_credit     = entry.type == 1 ? entry.amount.to_f.to_s + "\t" : "\t" + entry.amount.to_f.to_s
          intitule_journal = ""
          intitule_compte  = ""
          intitule_section = ""
          ecriture_let     = account.lettering || ""
          pointage         = ""
          code_fin         = ""
          reference        = ""
          informations     = ""
          vierge           = ""
          vierge           = ""
          vierge           = ""
          vierge           = ""
          lien             = preseizure.piece_id.present? ? Domains::BASE_URL + preseizure.piece.try(:get_access_url) : ""

          data << [[journal_code, ecriture_date, piece_ref, compte_num, section, compte_lib, echance_date, debit_credit, intitule_journal, intitule_compte, intitule_section, ecriture_let, pointage, code_fin, reference, informations, vierge, vierge , vierge, vierge, lien ].join("\t")]

        end
      end
    end

    data.join("\n")
  end

  def export_cegid_tra
    data = []

    line      = ' ' * 222
    line[0]   = '***S5EXPJRLSTD'
    line[33]  = '011'
    line[53]  = 'IDOCUS'
    line[144] = '001'
    line[147]  = '-'
    line[148]  = '-'

    data << line

    @preseizures.each do |preseizure|
      user = preseizure.user

      if preseizure.operation
        label = preseizure.operation_label[0..29]
      else
        label = [preseizure.third_party.presence, preseizure.piece_number.presence].compact.join(' - ')[0..29]
      end

      journal = preseizure.report.journal({ name_only: false })
      nature = case journal.compta_type
               when 'AC'
                if preseizure.entries.where(type: 2).count > 1
                  'AF'
                else
                  'FF'
                end
               when 'VT'
                if preseizure.entries.where(type: 1).count > 1
                  'FC'
                else
                  'AC'
                end
               when 'NDF'
                'OD'
               else
                'BQ'
               end

      preseizure.entries.each do |entry|
        account = case nature
                  when 'AF'
                    if entry.account.type == Pack::Report::Preseizure::Account::TTC
                      user.accounting_plan.general_account_providers.to_s.presence || '401000'
                    else
                      entry.account.try(:number)
                    end
                  when 'FF'
                    if entry.account.type == Pack::Report::Preseizure::Account::TTC
                      user.accounting_plan.general_account_providers.to_s.presence || '401000'
                    else
                      entry.account.try(:number)
                    end
                  when 'AC'
                    if entry.account.type == Pack::Report::Preseizure::Account::TTC
                      user.accounting_plan.general_account_customers.to_s.presence || '411000'
                    else
                      entry.account.try(:number)
                    end
                  when 'FC'
                    if entry.account.type == Pack::Report::Preseizure::Account::TTC
                      user.accounting_plan.general_account_customers.to_s.presence || '411000'
                    else
                      entry.account.try(:number)
                    end
                  else
                    entry.account.try(:number)
                  end


          label = ' ' unless label.present?
          line = ' ' * 222
          line[0] = preseizure.journal_name[0..2]
          line[3..11] = preseizure.computed_date.strftime('%d%m%Y') if preseizure.date
          line[11] = nature
          line[13] = account

          line[30] = 'X' if entry.account.type == Pack::Report::Preseizure::Account::TTC

          account_number = entry.account.try(:number) || ''
          line[31] = account_number if entry.account.type == Pack::Report::Preseizure::Account::TTC

          line[48] = preseizure.piece_number? ? I18n.transliterate(preseizure.piece_number.to_s) : I18n.transliterate(preseizure.third_party.to_s)

          line[83] = I18n.transliterate(label.to_s)

          line[129] = entry.type == 1 ? 'D' : 'C'

          amount = sprintf("%.2f", entry.amount.to_f).to_s.gsub('.', ',')
          window = 150 - amount.size

          line[window..150] = amount

          line[150] = 'N'
          line[151] = preseizure.piece ? preseizure.piece.number.to_s : ' '
          line[172] = 'E--'

          data << line

          file_name = preseizure.piece ? preseizure.piece.name.tr(' ', '_').tr('%', '_') + '.pdf' : ' '

          line = ' ' * 222

          if entry.account.type == Pack::Report::Preseizure::Account::TTC
            line[0] = preseizure.journal_name[0..2]
            line[3..11] = preseizure.computed_date.strftime('%d%m%Y') if preseizure.date
            line[11] = nature
            line[13] = case journal.compta_type
                       when 'AC'
                        user.accounting_plan.general_account_providers.to_s.presence || '401000'
                       when 'VT'
                        user.accounting_plan.general_account_customers.to_s.presence || '411000'
                       when 'NDF'
                        '471000'
                       else
                        '512000'
                       end

            line[30] = 'G'
            line[31] = Pack::Report::Preseizure::Account.where(id: preseizure.entries.pluck(:account_id)).where(type: Pack::Report::Preseizure::Account::TTC).first.try(:number)
            line[48] = preseizure.piece_number? ? I18n.transliterate(preseizure.piece_number.to_s) : I18n.transliterate(preseizure.third_party.to_s)
            line[83] = I18n.transliterate(file_name.to_s)

            data << line
          end
      end
    end

    data.join("\n")
  end

  def export_fec_agiris
    data = []

    if @preseizures.any?
      data << "JournalCode|JournalLib|EcritureNum|EcritureDate|CompteNum|CompteLib|CompAuxNum|CompAuxLib|PieceRef|PieceDate|EcritureLibc|Debit|Credit|EcritureLet|DateLet|ValidDate|Montantdevise|Idevise|MouvementEcriture"

      @preseizures.each do |preseizure|
        user = preseizure.user
        journal = preseizure.report.journal({name_only: false})

        preseizure.accounts.each do |account|
          entry = account.entries.first

          if preseizure.piece_id.present?
            general_account = if(account.type == Pack::Report::Preseizure::Account::TVA)
                                journal.try(:get_vat_accounts_of, '0')
                              elsif(account.type == Pack::Report::Preseizure::Account::TTC)
                                journal.try(:account_number)
                              else
                                journal.try(:charge_account)
                              end
          else
            bank_account = preseizure.operation.try(:bank_account)

            general_account = if(
                                  (preseizure.operation.try(:amount).to_i < 0 && entry.credit?) ||
                                  (preseizure.operation.try(:amount).to_i >= 0 && entry.debit?)
                                )
                                bank_account.try(:accounting_number) || 512_000
                              else
                                bank_account.try(:temporary_account) || 471_000
                              end
          end

          auxiliary_account = (general_account.to_s != account.number.to_s)? account.number : ''
          auxiliary_lib     = ""

          if auxiliary_account.present?
            if preseizure.piece_id.present?
              accounting = user.accounting_plan.providers.where(third_party_account: auxiliary_account).limit(1)
              is_provider = accounting.size > 0
              general_account = user.accounting_plan.general_account_providers.presence || 40_100_001 if is_provider

              unless is_provider
                accounting = user.accounting_plan.customers.where(third_party_account: auxiliary_account).limit(1)
                is_customer = accounting.size > 0
                general_account = user.accounting_plan.general_account_customers.presence || 41_100_001 if is_customer
              end

              general_account = auxiliary_account if general_account.blank? || (!is_provider && !is_customer)

              auxiliary_account = ''                                if general_account == auxiliary_account
              auxiliary_lib     = accounting.first.third_party_name if is_provider || is_customer
            else
              if general_account != bank_account.try(:accounting_number) && general_account != 512_000
                general_account = if entry.debit?
                                    user.accounting_plan.general_account_providers.presence || 40_100_001
                                  else
                                    user.accounting_plan.general_account_customers.presence || 41_100_001
                                  end
              end
            end
          else
            accounting = user.accounting_plan.providers.where(third_party_account: general_account).limit(1)

            if accounting.size == 0
              accounting = user.accounting_plan.customers.where(third_party_account: general_account).limit(1)
            end

            general_lib = accounting.try(:first).try(:third_party_name).to_s
          end

          label = preseizure.piece.try(:name)
          label = preseizure.operation_label[0..34].gsub("\t", ' ') if preseizure.operation_label.present?

          journal_code   = preseizure.journal_name || ""
          journal_lib    = user.account_book_types.where(name: journal_code).first.try(:description).try(:gsub, "\t", ' ').try(:tr, '()', '  ') || ""
          ecriture_num   = ""
          ecriture_date  = preseizure.computed_date.strftime('%Y%m%d') || ""
          compte_num     = general_account || ""
          compte_lib     = general_lib
          comp_aux       = auxiliary_account || ""
          comp_aux_lib   = auxiliary_lib || ""
          piece_ref      = preseizure.piece_number || ""
          piece_date     = preseizure.computed_date.strftime('%Y%m%d') || ""
          ecriture_libc  = label || ""          
          debit_credit   = entry.type == 1 ? entry.amount.to_f.to_s + "|" : "|" + entry.amount.to_f.to_s
          ecriture_let   = account.lettering || ""
          date_let       = ""
          valid_date     = ""
          montant_devise = preseizure.amount.to_f.to_s || ""
          idevise        = preseizure.amount.to_f > 0 ? preseizure.currency.to_s : ""
          mouvement_ecriture = preseizure.third_party

          data << [[journal_code, journal_lib, ecriture_num, ecriture_date, compte_num, compte_lib, comp_aux, comp_aux_lib, piece_ref, piece_date, ecriture_libc, debit_credit, ecriture_let, date_let, valid_date, montant_devise, idevise, mouvement_ecriture].join("\t")]
        end
      end
    end

    data.join("\n")
  end

  def export_fec_agiris_facnote
    data = []

    if @preseizures.any?
      ## HEADER
      line          = ' ' * 50
      line[0..5]    = "VER"
      line[6..24]   = "export_#{Time.now.strftime("%Y%m%d")}"
      data << line

      line          = ' ' * 50
      line[0..5]    = "DOS"
      line[6..24]   = @preseizures.first.organization.name
      data << line

      @preseizures.each do |preseizure|
        user          = preseizure.user
        journal_name  = preseizure.report.journal({name_only: false}).try(:name) || preseizure.journal_name
        piece         = preseizure.piece

        if piece
          #Insert ECR metadata
          line          = ' ' * 270
          line[0..5]    = "ECR"
          line[6..24]   = "#{journal_name.to_s[0..10]}#{piece.created_at.strftime('%d%m%Y')}" || ""
          line[25..77]  = preseizure.third_party.to_s[0..51] || ""
          line[78..93]  = '1'
          line[94..122] = Time.now.strftime("0%d%m%Y%d%m%Y")
          line[123..152]= "0EUR"
          line[153]     = "#{piece.position.to_s[0..25]}.pdf"

          data << line
        end

        preseizure.accounts.each do |account|
          entry         = account.entries.first
          debit_amount  = ''
          credit_amount = ''

          debit_amount  = entry.amount.to_s if entry.debit?
          credit_amount = entry.amount.to_s if entry.credit?

          label = preseizure.piece_number
          label = preseizure.operation_label[0..34].gsub("\t", ' ') if preseizure.operation_label.present?

          line          = ' ' * 270
          line[0..5]    = 'MVT'
          line[6..16]   = account.number.to_s[0..10]
          line[17..47]  = preseizure.third_party.to_s[0..29] || ""
          line[48..61]  = debit_amount.to_s[0..10]
          line[62..97]  = credit_amount.to_s[0..10]
          line[98]      = label.to_s[0..45]

          data << line
        end
      end
    end

    data.join("\n")
  end

  def export_fec_acd
    data = []

    if @preseizures.any?
      data << "JournalCode|JournalLib|EcritureNum|EcritureDate|CompteNum|CompteLib|CompAuxNum|CompAuxLib|PieceRef|PieceDate|EcritureLibc|Debit|Credit|EcritureLet|DateLet|ValidDate|Montantdevise|Idevise|MouvementEcriture"

      @preseizures.each do |preseizure|
        user = preseizure.user
        journal = preseizure.report.journal({name_only: false})

        preseizure.accounts.each do |account|
          entry = account.entries.first

          if preseizure.piece_id.present?
            general_account = if(account.type == Pack::Report::Preseizure::Account::TVA)
                                journal.try(:get_vat_accounts_of, '0')
                              elsif(account.type == Pack::Report::Preseizure::Account::TTC)
                                journal.try(:account_number)
                              else
                                journal.try(:charge_account)
                              end
          else
            bank_account = preseizure.operation.try(:bank_account)

            general_account = if(
                                  (preseizure.operation.try(:amount).to_i < 0 && entry.credit?) ||
                                  (preseizure.operation.try(:amount).to_i >= 0 && entry.debit?)
                                )
                                bank_account.try(:accounting_number) || 512_000
                              else
                                bank_account.try(:temporary_account) || 471_000
                              end
          end

          auxiliary_account = (general_account.to_s != account.number.to_s)? account.number : ''
          auxiliary_lib     = ""

          if auxiliary_account.present?
            if preseizure.piece_id.present?
              accounting = user.accounting_plan.providers.where(third_party_account: auxiliary_account).limit(1)
              is_provider = accounting.size > 0

              unless is_provider
                accounting = user.accounting_plan.customers.where(third_party_account: auxiliary_account).limit(1)
                is_customer = accounting.size > 0
              end

              general_account = if is_provider
                                  user.accounting_plan.general_account_providers.presence || 40_100_001
                                elsif is_customer
                                  user.accounting_plan.general_account_customers.presence || 41_100_001
                                else
                                  auxiliary_account
                                end


              auxiliary_account = ''                                unless is_provider || is_customer
              auxiliary_lib     = accounting.first.third_party_name if is_provider || is_customer
            else
              if general_account != bank_account.try(:accounting_number) && general_account != 512_000
                general_account = if entry.debit?
                                    user.accounting_plan.general_account_providers.presence || 40_100_001
                                  else
                                    user.accounting_plan.general_account_customers.presence || 41_100_001
                                  end
              end
            end
          else
            accounting = user.accounting_plan.providers.where(third_party_account: general_account).limit(1)

            if accounting.size == 0
              accounting = user.accounting_plan.customers.where(third_party_account: general_account).limit(1)
            end

            general_lib = accounting.try(:first).try(:third_party_name).to_s
          end

          if preseizure.piece
            piece_ref = preseizure.piece.name.to_s[-10, 10].tr(' ', '_').tr('%', '_')
          else
            piece_ref = "#{preseizure.report.name.to_s[-6, 10].tr(' ', '_').tr('%', '_')}_#{("%03d" % preseizure.position)}"
          end

          label = preseizure.piece_number
          label = preseizure.operation_label[0..34].gsub("\t", ' ') if preseizure.operation_label.present?

          journal_code   = preseizure.journal_name || ""
          journal_lib    = user.account_book_types.where(name: journal_code).first.try(:description).try(:gsub, "\t", ' ').try(:tr, '()', '  ') || ""
          ecriture_num   = ""
          ecriture_date  = preseizure.computed_date.strftime('%Y%m%d') || ""
          compte_num     = general_account || ""
          compte_lib     = general_lib
          comp_aux       = auxiliary_account || ""
          comp_aux_lib   = auxiliary_lib || ""
          piece_ref      = piece_ref || ""
          piece_date     = preseizure.computed_date.strftime('%Y%m%d') || ""
          ecriture_libc  = label || ""
          debit_credit   = entry.type == 1 ? entry.amount.to_f.to_s + "|" : "|" + entry.amount.to_f.to_s
          ecriture_let   = account.lettering || ""
          date_let       = ""
          valid_date     = ""
          montant_devise = preseizure.amount.to_f.to_s || ""
          idevise        = preseizure.amount.to_f > 0 ? preseizure.currency.to_s : ""
          mouvement_ecriture = (preseizure.piece)? ( [preseizure.piece_number, preseizure.third_party].join(' - ') ) : label

          if entry.amount
            data << [[journal_code, journal_lib, ecriture_num, ecriture_date, compte_num, compte_lib, comp_aux, comp_aux_lib, piece_ref, piece_date, ecriture_libc, debit_credit, ecriture_let, date_let, valid_date, montant_devise, idevise, mouvement_ecriture].join("|")]
          end
        end
      end
    end

    data.join("\n")
  end

  def export_ciel
    data = []

    if @preseizures.any?
      ### HEADERS ####
        data << "##Transfert"
        data << "##Section\tDos"
        data << "EUR"
        data << "##Section\tMvt"
      ### HEADERS ####

      accounting_plan = @preseizures.first.user.accounting_plan

      @preseizures.each_with_index do |preseizure, index|
        user          = preseizure.user
        journal_name  = preseizure.report.journal({name_only: false}).try(:name) || preseizure.journal_name
        piece         = preseizure.piece

        preseizure.accounts.each do |account|
          entry   = account.entries.first

          label   = preseizure.third_party.to_s
          label   = preseizure.operation_label.gsub("\t", ' ') if preseizure.operation_label.present?

          line = []

          third_party_name   = accounting_plan.customers.where(third_party_account: account.number).first.try(:third_party_name)
          third_party_name ||= accounting_plan.providers.where(third_party_account: account.number).first.try(:third_party_name)

          line << "\"#{index.to_s[0..4]}\""
          line << "\"#{journal_name.to_s[0..1]}\""
          line << "\"#{preseizure.date.strftime('%d/%m/%Y')}\""
          line << "\"#{account.number.to_s[0..5]}\""
          line << "\"#{third_party_name.to_s[0..10]}\""
          line << "\"#{entry.amount.to_s[0..12]}\""
          line << "#{entry.debit? ? 'D' : 'C'}"
          line << "B"
          line << "\"#{label}\""
          line << "\"#{preseizure.piece_number.to_s[0..11]}\""
          line << "\"10\""

          data << line.join("\t")
        end
      end
    end

    data.join("\n")
  end
end
