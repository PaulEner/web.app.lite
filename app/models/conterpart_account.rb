# -*- encoding : UTF-8 -*-
class ConterpartAccount < ApplicationRecord
  has_and_belongs_to_many :accounting_plan_items

  belongs_to :user
  belongs_to :accounting_plan

  validates_presence_of :name, :number
  validates_inclusion_of :kind, in: ['customer', 'provider']

  scope :customer, ->{ where(kind: 'customer') }
  scope :provider, ->{ where(kind: 'provider') }
  scope :is_default, -> { where(is_default: true) }
end
