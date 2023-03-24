# -*- encoding : UTF-8 -*-
class Ticket < ApplicationRecord
  belongs_to :user

  def self.search(contains)
    events = self.where(state: ["ready", "processing", "waiting"])

    events = events.where(id:          contains[:id])          if contains[:id].present?
    events = events.where(action:      contains[:action])      if contains[:action].present?
    events = events.where(target_type: contains[:target_type]) if contains[:target_type].present?
    events = events.where("target_name LIKE ?", "%#{contains[:target_name]}%") if contains[:target_name].present?

    events.order(priority: :desc)
  end

  state_machine :state, initial: :ready do
    state :ready
    state :waiting
    state :processing
    state :processed
    state :closed
    state :reopen

    event :ready do
      transition any => :ready
    end

    event :waiting do
      transition [:ready, :processing] => :waiting
    end

    event :processing do
      transition [:ready, :waiting, :reopen] => :processing
    end

    event :closed do
      transition any => :closed
    end

    event :reopen do
      transition [:closed, :processing] => :reopen
    end
  end
end
