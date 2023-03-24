module CustomHelper
  def favorite_options
    accounts.map do |account|
      [account.info, account.id]
    end
  end
end