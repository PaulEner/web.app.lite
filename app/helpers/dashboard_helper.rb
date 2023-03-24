# frozen_string_literal: true

module DashboardHelper
  def tag_state(state='good')
    if state.to_s == 'good'
      content_tag :span, t('dashboard.good_state'), class: 'state state-good'
    elsif state.to_s == 'medium'
      content_tag :span, t('dashboard.medium_state'), class: 'state state-medium'
    elsif state.to_s == 'critical'
      content_tag :span, t('dashboard.critical_state'), class: 'state state-critical'
    else
      content_tag :span, state, class: 'state state-medium'
    end
  end
end