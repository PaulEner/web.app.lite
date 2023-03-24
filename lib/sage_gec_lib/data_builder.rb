# -*- encoding : UTF-8 -*-
module SageGecLib
  class DataBuilder
    def initialize(preseizures)
      @preseizures    = preseizures
      @data_count     = 0
      @error_messages = []
    end

    def execute
      response = { data: data_content }

      response[:data_count] = @data_count
      response[:error_messages] = full_error_messages

      if full_error_messages.empty?
        response[:data_built] = true
      else
        response[:data_built] = false
      end

      response
    end

    private

    def data_content
      __data = []

      ledger_code = @preseizures.first.user.account_book_types.where(name: @preseizures.first.journal_name).first.try(:pseudonym).presence || @preseizures.first.journal_name

      @preseizures.each do |preseizure|
        @data_count    += 1
        @preseizure     = preseizure
        deadline        = preseizure.deadline_date&.to_time.to_s

        preseizure.entries.each do |entry|
          if entry.type == Pack::Report::Preseizure::Entry::DEBIT
            debit  = entry.amount.to_f
            credit = 0
          else
            debit  = 0
            credit = entry.amount.to_f
          end

          account_number = entry.account.number

          if preseizure.piece
            label = "#{preseizure.third_party} - #{preseizure.piece_number}"
          else
            label = preseizure.operation.try(:label)
          end

          __data << { "credit" => credit, 
                      "debit" => debit, 
                      "dueDate" => deadline,
                      "date" => preseizure.date.try(:to_date).to_s,
                      "accountReferenceForJournal" => account_number,
                      "originalDocumentReference" => preseizure.coala_piece_name,
                      "description" => "#{label}",
                      "financialAccountJournalReference" => ledger_code }
        end     
      end

      {'attachment' => nil, 'entry' => { 'lines' => __data } }.to_json
    end

    def full_error_messages
      @error_messages.join(',')
    end
  end
end