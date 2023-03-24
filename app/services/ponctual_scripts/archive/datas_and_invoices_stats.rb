class PonctualScripts::DatasAndInvoicesStats < PonctualScripts::PonctualScript
  def self.execute
    new().run
  end

  def self.rollback
    new().rollback
  end

  private

  def execute
    #Change preseizure excess prices first
    # change_prices(12, 25)
    subscriptions = Subscription.where(unit_price_of_excess_preseizure: 12); nil
    subscriptions.update_all({ unit_price_of_excess_preseizure: 25, unit_price_of_excess_expense: 25 }); nil
    periods = Period.where(unit_price_of_excess_preseizure: 12); nil
    periods.update_all({ unit_price_of_excess_preseizure: 25, unit_price_of_excess_expense: 25 }); nil

    subscription = Subscription.find 88
    subscription.number_of_journals = 5
    subscription.save
    users = User.where(code: ["CF2B%AME001", "CF2B%MNS001"])
    users.update_all(inactive_at: 1.month.ago)


    #rollback prices in the end
    # change_prices(25, 12)
    subscriptions = Subscription.where(unit_price_of_excess_preseizure: 25); nil
    subscriptions.update_all({ unit_price_of_excess_preseizure: 12, unit_price_of_excess_expense: 12 }); nil
    periods = Period.where(unit_price_of_excess_preseizure: 25); nil
    periods.update_all({ unit_price_of_excess_preseizure: 12, unit_price_of_excess_expense: 12 }); nil

    subscription = Subscription.find 88
    subscription.number_of_journals = 6
    subscription.save
    users = User.where(code: ["CF2B%AME001", "CF2B%MNS001"])
    users.update_all(inactive_at: nil)
  end

  def backup; end


  def change_prices(prev_price, new_price)
    subscriptions = Subscription.where(unit_price_of_excess_preseizure: prev_price); nil
    subscriptions.update_all({ unit_price_of_excess_preseizure: new_price, unit_price_of_excess_expense: new_price }); nil

    periods = Period.where(unit_price_of_excess_preseizure: prev_price); nil
    periods.update_all({ unit_price_of_excess_preseizure: new_price, unit_price_of_excess_expense: new_price }); nil
  end
end