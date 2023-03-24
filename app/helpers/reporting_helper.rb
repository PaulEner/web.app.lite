# frozen_string_literal: true

module ReportingHelper
  def accounts_options
    accounts.map do |account|
      [account.info, account.id]
    end
  end
end