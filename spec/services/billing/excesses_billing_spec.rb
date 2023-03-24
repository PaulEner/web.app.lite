# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe 'Excesses Billing' do
  def create_subscriptions
    flow = [{ pieces: 80, preseizures: 80 }, { pieces: 203, preseizures: 203 }]

    User.all.limit(2).each_with_index do |user, index|
      subscription = user.subscription
      subscription.current_packages = []
      subscription.save

      Subscription::Form.new(subscription).submit({ is_to_apply_now: 'true', is_pre_assignment_active: 'true', subscription_option: 'ido_classique' })

      customer_period = subscription.periods.last
      customer_period.pieces            = flow[index][:pieces]
      customer_period.uploaded_pieces   = flow[index][:pieces]
      customer_period.uploaded_pages    = flow[index][:pieces]
      customer_period.preseizure_pieces = flow[index][:preseizures]

      customer_period.save

      Billing::UpdatePeriod.new(customer_period).execute
    end
  end

  before(:all) do
    DatabaseCleaner.start

    User.destroy_all
    Organization.destroy_all
    Subscription.destroy_all
    Period.destroy_all

    organization = create :organization, code: "TS0"
    Subscription.create(period_duration: 1, tva_ratio: 1.2, user_id: nil, organization_id: organization.id)
    Address.create(first_name: 'Test', last_name: 'Test', company: "TS0", address_1: 'abc rue abc', city: 'Paris', zip: 75113, country: 'France', is_for_billing: true, locatable_type: 'Organization', locatable_id: organization.id)
    organization.subscription.find_or_create_period(Date.today)

    users = [
              { email: "user10@idocus.com", password: '123456', code: "TS0%A10", first_name: "f_name10", last_name: "l_name10", phone_number: "123", company: "Organization" },
              { email: "user20@idocus.com", password: '123456', code: "TS0%B20", first_name: "f_name20", last_name: "l_name20", phone_number: "123", company: "Organization" }
            ]

    users.each do |_user|
      user = User.new(_user)
      user.organization = organization

      user.build_options if user.options.nil?

      user.save

      user.account_book_types.create(name: "AC", description: "AC (Achats)", position: 1, entry_type: 2, currency: "EUR", domain: "AC - Achats", account_number: "0ACC", charge_account: "471000", vat_accounts: {'20':'445660', '8.5':'153141', '13':'754213'}.to_json, anomaly_account: "471000", is_default: true, is_expense_categories_editable: true, organization_id: organization.id)
      Subscription.create(period_duration: 1, current_packages: '["ido_classique", "pre_assignment_option"]', number_of_journals: 5, organization_id: nil, user_id: user.id)

      user.subscription.find_or_create_period(Date.today)
    end
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  before(:each) do
    BillingMod::Invoice.destroy_all
  end

  it 'creates normal excess unit price', :normal do
    user = User.last
    subscription = user.subscription
    subscription.current_packages = []
    subscription.save

    Subscription::Form.new(subscription).submit({ is_to_apply_now: 'true', is_pre_assignment_active: 'true', subscription_option: 'retriever_option' })

    organization_period = user.organization.subscription.periods.last
    Billing::UpdateOrganizationPeriod.new(organization_period).fetch_all
    organization_period.reload

    period = subscription.reload.periods.last

    expect(period.is_active?(:retriever_option)).to be true
    expect(period.unit_price_of_excess_upload).to eq 25
    expect(period.unit_price_of_excess_preseizure).to eq 25
    expect(period.unit_price_of_excess_expense).to eq 25
    expect(period.excesses_price_in_cents_wo_vat).to eq 0

    expect(organization_period.unit_price_of_excess_preseizure).to eq 25
    expect(organization_period.unit_price_of_excess_expense).to eq 25
    expect(organization_period.excesses_price_in_cents_wo_vat).to eq 0
  end

  it 'creates valid excess data', :data do
    create_subscriptions

    organization_period = Organization.first.subscription.periods.last
    Billing::UpdateOrganizationPeriod.new(organization_period).fetch_all(true)
    organization_period.reload

    expect(organization_period.unit_price_of_excess_preseizure).to eq 25
    expect(organization_period.unit_price_of_excess_expense).to eq 25
    expect(organization_period.excesses_price_in_cents_wo_vat).to eq 0

    expect(organization_period.max_preseizure_pieces_authorized).to eq 200
    expect(organization_period.max_expense_pieces_authorized).to eq 200
    expect(organization_period.max_upload_pages_authorized).to eq 200

    expect(organization_period.uploaded_pages).to eq 283
    expect(organization_period.preseizure_pieces).to eq 283
  end

  it 'creates valid cumulative basic excess price', :cumulative_price do
    allow_any_instance_of(Billing::UpdatePeriodData).to receive(:execute).and_return(true)

    create_subscriptions

    organization = Organization.first
    Billing::CreateInvoicePdf.for(organization.id, nil, Time.now, {notify: false, auto_upload: false})

    organization_period = organization.periods.last
    invoice             = organization.invoices.first
    order               = organization_period.product_option_orders.where(name: 'excess_documents_basic').first

    expect(organization_period.basic_total_compta_piece).to eq 283
    expect(organization_period.basic_excess).to eq 83
    expect(order).not_to be nil
    expect(order.price_in_cents_wo_vat).to eq 100 * (83 * 0.25)
  end

  it 'creates valid distinct excess price', :distinct_price do
    allow_any_instance_of(Billing::UpdatePeriodData).to receive(:execute).and_return(true)

    create_subscriptions

    user = User.first
    subscription = user.subscription
    subscription.current_packages = []
    subscription.save

    Subscription::Form.new(subscription).submit({ is_to_apply_now: 'true', is_pre_assignment_active: 'true', subscription_option: 'ido_micro' })

    organization = Organization.first
    Billing::CreateInvoicePdf.for(organization.id, nil, Time.now, {notify: false, auto_upload: false})

    organization_period = organization.periods.last
    invoice             = organization.invoices.first
    order               = organization_period.product_option_orders.where(name: 'excess_documents_basic').first

    expect(organization_period.uploaded_pages).to eq 203
    expect(organization_period.preseizure_pieces).to eq 203

    expect(organization_period.max_preseizure_pieces_authorized).to eq 100
    expect(organization_period.max_expense_pieces_authorized).to eq 100
    expect(organization_period.max_upload_pages_authorized).to eq 100

    expect(order).not_to be nil
    expect(order.price_in_cents_wo_vat).to eq 100 * (103 * 0.25)
  end

  it 'creates valid excess price for iDoMicro', :last do
    allow_any_instance_of(Billing::UpdatePeriodData).to receive(:execute).and_return(true)

    create_subscriptions

    user = User.last
    subscription = user.subscription
    subscription.current_packages = []
    subscription.save

    Subscription::Form.new(subscription).submit({ is_to_apply_now: 'true', is_pre_assignment_active: 'true', subscription_option: 'ido_micro' })

    organization = Organization.first
    Billing::CreateInvoicePdf.for(organization.id, nil, Time.now, {notify: false, auto_upload: false})

    organization_period = organization.periods.last
    invoice             = organization.invoices.first
    order               = organization_period.product_option_orders.where(name: 'excess_documents_basic').first

    c_period            = user.reload.periods.last

    expect(organization_period.uploaded_pages).to eq 80
    expect(organization_period.preseizure_pieces).to eq 80

    expect(c_period.unit_price_of_excess_preseizure).to eq 25
    expect(c_period.unit_price_of_excess_expense).to eq 25

    expect(c_period.preseizure_pieces).to eq 203
    expect(c_period.excesses_price_in_cents_wo_vat).to eq (0.25 * 103) * 100
  end

  it 'creates valid excess price for iDoPlusMicro', :ido_plus_micro do
    allow_any_instance_of(Billing::UpdatePeriodData).to receive(:execute).and_return(true)

    create_subscriptions

    User.all.limit(2).each do |user|
      subscription  = user.subscription
      subscription.current_packages = []
      subscription.save

      Subscription::Form.new(subscription).submit({ is_to_apply_now: 'true', is_pre_assignment_active: 'true', subscription_option: 'ido_plus_micro' })
    end

    organization = Organization.first
    Billing::CreateInvoicePdf.for(organization.id, nil, Time.now, {notify: false, auto_upload: false})

    organization_period = organization.periods.last
    invoice             = organization.invoices.first
    order               = organization_period.product_option_orders.where(name: 'excess_documents_micro').first

    c_period            = User.all.limit(2).last.reload.periods.last

    expect(organization_period.plus_micro_excess).to eq (283 - 40)
    expect(organization_period.plus_micro_total_compta_piece).to eq 283

    expect(c_period.unit_price_of_excess_preseizure).to eq 30
    expect(c_period.unit_price_of_excess_expense).to eq 30

    expect(c_period.preseizure_pieces).to eq 203

    expect(order).not_to be nil
    expect(order.price_in_cents_wo_vat).to eq 243 * 30
  end

end