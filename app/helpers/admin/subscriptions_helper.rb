# frozen_string_literal: true

module Admin::SubscriptionsHelper
  def subscription_period_options_for_select(selected_period)
    list = formated_period_options SubscriptionStatistic.period_options
    options_for_select(list, selected_period || nil)
  end

  def formated_period_options(periods)
    periods.map do |period|
      [I18n.l(period, format: '%b%y').titleize, period]
    end
  end

  def subscription_diff_content_for(value = 0)
    if value.to_i != 0
      content_tag(:span, "(#{if value > 0
                               '+'
                             end}#{value})", class: (value.to_i < 0 ? 'negative' : 'positive'))
    end
  end

  def subscription_customers_popover_content_for(customers, css_class)
    content_tag(:span, customers&.size.to_i, class: (if customers&.size.to_i > 0
                                                       "popover_active #{css_class}"
                                                     end), data: { toggle: 'popover', placement: 'top', title: "#{customers&.size.to_i} dossier(s)", content: customers.try(:join, ' - ') })
  end

  def period_list_options
    periods = []

    __period = CustomUtils.period_of(Time.now)
    periods << ["#{__period.to_s[0..3]} - #{__period.to_s[4..5]}", __period]

    11.times do |i|
      __period = CustomUtils.period_operation(__period, -1)
      periods << ["#{__period.to_s[0..3]} - #{__period.to_s[4..5]}", __period]
    end

    periods
  end
end
