# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe BillingMod::PrepareUserBilling do
  def create_operation(user)
    operation = Operation.create(
      created_at: "2020-03-01 21:00:00", updated_at: "2020-03-01 21:00:00",
      date: "2020-02-02", value_date: "2020-02-02", transaction_date: "2020-02-02", label: "SARL 231E47", amount: 500.0,
      category: "Autres recettes", processed_at: "2020-02-02 04:30:51",
      is_locked: false, organization_id: user.organization.id, user_id: user.id, bank_account_id: 1,
      api_id: "456654546", api_name: "capidocus",
      is_coming: false, deleted_at: nil, forced_processing_at: nil, forced_processing_by_user_id: nil, currency: {}
    )
  end

  def create_paper_processes(user)
    pp = PaperProcess.create(
      created_at: "2020-03-01 21:00:00", updated_at: "2020-03-01 21:00:00",
      type: 'scan', tracking_number: '001', customer_code: user.code, pack_name: "#{user.code} AC 202003", user_id: user.id
    )
  end

  def create_orders(user)
    Order.create(
      created_at: "2020-03-01 21:00:00", updated_at: "2020-03-01 21:00:00",
      paper_set_start_date: "2020-01-01 00:00:00", paper_set_end_date: "2020-12-01 00:00:00",
      type: 'paper_set', user_id: user.id, organization_id: user.organization.id, price_in_cents_wo_vat: 30000, state: 'confirmed', period_v2: CustomUtils.period_of(Time.now),
      dematbox_count: 1
    )

    Order.create(
      created_at: "2020-03-01 21:00:00", updated_at: "2020-03-01 21:00:00",
      paper_set_start_date: "2020-01-01 00:00:00", paper_set_end_date: "2020-12-01 00:00:00",
      type: 'dematbox', user_id: user.id, organization_id: user.organization.id, price_in_cents_wo_vat: 30000, state: 'confirmed', period_v2: CustomUtils.period_of(Time.now),
      dematbox_count: 1
    )
  end

  def create_extra_order(user)
    BillingMod::ExtraOrder.create(
      created_at: "2020-03-01 21:00:00", updated_at: "2020-03-01 21:00:00",
      name: 'Test extra order', owner: user, price: -300, period: CustomUtils.period_of(Time.now)
    )
  end

  before(:all) do
    Timecop.freeze(Time.local(2020,03,15))
    DatabaseCleaner.start

    2.times do |i|
      organization = create :organization, code: "TS#{i}"
      Address.create(first_name: 'Test', last_name: 'Test', company: "TS#{i}", address_1: 'abc rue abc', city: 'Paris', zip: 75113, country: 'France', is_for_billing: true, locatable_type: 'Organization', locatable_id: organization.id)

      users = [
                { email: "user1#{i}@idocus.com", password: '123456', code: "TS#{i}%A1#{i}", first_name: "f_name1#{i}", last_name: "l_name1#{i}", phone_number: "123", company: "Organization" },
                { email: "user2#{i}@idocus.com", password: '123456', code: "TS#{i}%B2#{i}", first_name: "f_name2#{i}", last_name: "l_name2#{i}", phone_number: "123", company: "Organization" }
              ]

      users.each do |_user|
        user = User.new(_user)
        user.organization = organization

        user.build_options if user.options.nil?
        package   = BillingMod::Package.create(period: CustomUtils.period_of(Time.now), user: user, name: 'ido_classic', upload_active: true, bank_active: true, scan_active: true, mail_active: true, preassignment_active: false)
        package_s = BillingMod::PackageSimulation.create(period: CustomUtils.period_of(Time.now), user: user, name: 'ido_classic', upload_active: true, bank_active: true, scan_active: true, mail_active: true, preassignment_active: false)

        package.save
        package_s.save
        user.save

        user.account_book_types.create(name: "AC", description: "AC (Achats)", position: 1, entry_type: 2, currency: "EUR", domain: "AC - Achats", account_number: "0ACC", charge_account: "471000", vat_accounts: {'20':'445660', '8.5':'153141', '13':'754213'}.to_json, anomaly_account: "471000", is_default: true, is_expense_categories_editable: true, organization_id: organization.id)
        # Subscription.create(period_duration: 1, current_packages: '["ido_classique", "pre_assignment_option"]', number_of_journals: 5, organization_id: nil, user_id: user.id)
      end
    end

    # Timecop.freeze(Time.local(2020,04,15)) #Jump in time to next month
  end

  after(:all) do
    Timecop.return
    DatabaseCleaner.clean
  end

  before(:each) do
    allow_any_instance_of(User).to receive_message_chain('pieces.count').and_return(1)

    BillingMod::Billing.destroy_all
    BillingMod::Invoice.destroy_all
    Operation.destroy_all
  end

  it 'create basic package', :basic_package do
    user = User.last
    
    user.deactivate_simulation
    package = user.my_package

    user.activate_simulation
    package_s = user.my_package

    expect(package.is_a?(BillingMod::Package)).to eq true
    expect(package_s.is_a?(BillingMod::PackageSimulation)).to eq true

    expect(package.name).to eq 'ido_classic'
    expect(package_s.name).to eq 'ido_classic'

    expect(package.period).to eq CustomUtils.period_of(Time.now)
    expect(package_s.period).to eq CustomUtils.period_of(Time.now)

    expect(package.base_price).to eq 20
    expect(package_s.base_price).to eq 20

    expect(package.excess_price).to eq 0.25
    expect(package_s.excess_price).to eq 0.25

    expect(package.flow_limit).to eq 100
    expect(package_s.flow_limit).to eq 100

    expect(package.excess_duration).to eq 'month'
    expect(package_s.excess_duration).to eq 'month'
  end

  it 'collect data flow', :data_flow do
    user = User.last

    data_flow = user.current_flow

    expect(data_flow.period).to eq CustomUtils.period_of(Time.now)
    expect(data_flow.pieces).to eq 0
    expect(data_flow.operations).to eq 0
    expect(data_flow.all_compta_transactions).to eq 0
  end

  it 'get valid exception price', :reduced_price do
    organization = Organization.first

    organization.code = 'ALM'
    organization.save

    user = organization.customers.first

    reduced_retriever_price = BillingMod::Configuration.price_of('ido_retriever', user)

    expect(reduced_retriever_price).to eq 3

    organization.code = 'TS1'
    organization.save
  end

  it 'creates remaining month price', :remaining_month do
    user = User.last

    period = CustomUtils.period_of(Time.now) - 1
    prev_period = CustomUtils.period_operation(period, -1)

    package      = user.package_of(period)
    prev_package = package.dup
    prev_package.user   = user
    prev_package.period = prev_period
    prev_package.name   = 'ido_nano'
    prev_package.commitment_start_period = CustomUtils.period_operation(period, -6)
    prev_package.commitment_end_period = CustomUtils.period_operation(period, +6)
    prev_package.save

    BillingMod::PrepareUserBilling.new(user, period).execute

    billings = user.reload.billings

    bill      = billings.where(name: 'ido_classic').first
    remaining = billings.where(name: 'remaining_month').first

    expect(billings.collect(&:name)).to include('ido_classic', 'remaining_month')

    expect(prev_package.base_price).to eq 5
    expect(package.base_price).to eq 20

    expect(bill.price).to eq 20 * 100

    expect(remaining.title).to eq "iDo'Nano : engagement 6 mois restant(s)"
    expect(remaining.price).to eq 5 * 6 * 100
  end

  context 'Basic and normal billing', :basic_billing do
    before(:each) do
      BillingMod::Billing.destroy_all
      BillingMod::Invoice.destroy_all
      Operation.destroy_all
    end

    it 'creates classic billing' do
      user = User.last

      BillingMod::PrepareUserBilling.new(user, CustomUtils.period_of(Time.now)).execute

      billings   = user.reload.billings
      first_bill = billings.first

      package    = user.my_package

      expect(billings.size).to be > 0

      expect(first_bill.is_a?(BillingMod::Billing)).to be true
      expect(first_bill.period).to eq CustomUtils.period_of(Time.now)
      expect(first_bill.name).to eq "ido_classic"
      expect(first_bill.title).to eq BillingMod::Configuration::LISTS[package.name.to_sym][:label]
      expect(first_bill.price).to eq 20 * 100
    end

    it 'creates valid billings' do
      period = CustomUtils.period_of(Time.now)
      user   = User.last

      BillingMod::PrepareUserBilling.new(user, period).execute

      billings = user.reload.billings

      expect(billings.size).to eq 4
      expect(billings.collect(&:name)).to include('ido_classic', 'bank_option', 'mail_option', 'preassignment_option')

      discount_bill = billings.where(kind: 'discount').first
      expect(discount_bill.title).to eq 'Remise sur pré-affectation'
      expect(discount_bill.price).to eq -9 * 100

      expect(user.total_billing_of(period)).to eq (35 - 9) * 100
    end

    it 'creates normal paper set and dematbox order billings', :order do
      period = CustomUtils.period_of(Time.now)
      user   = User.last

      create_orders(user)

      BillingMod::PrepareUserBilling.new(user, period).execute

      billings = user.reload.billings

      expect(billings.collect(&:name)).to include('paper_set_order', 'dematbox_order')

      orders = billings.where(kind: 'order')

      expect(orders.size).to eq 2
      expect(orders.first.price).to eq 30000
    end

    it 'creates normal extra order billings', :extra_order do
      period = CustomUtils.period_of(Time.now)
      user   = User.last

      create_extra_order(user)

      BillingMod::PrepareUserBilling.new(user, period).execute

      billings = user.reload.billings

      expect(billings.collect(&:name)).to include('extra_order')

      extra = billings.where(kind: 'extra')

      expect(extra.size).to eq 1
      expect(extra.first.price).to eq -30000
    end
  end

  context 'Flow excess billing', :flow_excess_billing do
    before(:each) do
      BillingMod::Billing.destroy_all
      BillingMod::Invoice.destroy_all
      Operation.destroy_all
    end

    it 'creates compta piece excess billing - month excess', :normal_excess do
      allow_any_instance_of(BillingMod::FetchFlow).to receive(:execute).and_return(true)

      period = CustomUtils.period_of(Time.now)
      user = User.last

      package = user.my_package
      package.update(name: 'ido_mini', upload_active: true, preassignment_active: true, bank_active: false, mail_active: false, scan_active: false)

      data_flow               = user.current_flow
      data_flow.compta_pieces = 200
      data_flow.save

      BillingMod::PrepareUserBilling.new(user, period).execute

      billings = user.reload.billings

      expect(billings.size).to eq 5
      expect(billings.collect(&:name)).to include('excess_billing')

      excess_bill = billings.where(kind: 'excess').first

      excess_price = 100 * 0.25
      expect(excess_bill.price).to eq excess_price * 100
      expect(user.total_billing_of(period)).to eq ((35 - 9) + excess_price) * 100
    end

    it 'creates compta piece excess billing - annual excess' do
      allow_any_instance_of(BillingMod::FetchFlow).to receive(:execute).and_return(true)

      period      = CustomUtils.period_of(Time.now)
      prev_period = CustomUtils.period_of(1.month.ago)

      user = User.last

      package      = user.my_package
      package.update(name: 'ido_micro', upload_active: true, preassignment_active: true, bank_active: true, mail_active: false, scan_active: true)

      prev_package        = package.dup
      prev_package.user   = user
      prev_package.period = prev_period
      prev_package.save

      prev_flow               = user.flow_of(prev_period)
      prev_flow.compta_pieces = 20
      prev_flow.save

      data_flow               = user.current_flow
      data_flow.compta_pieces = 200
      data_flow.save

      BillingMod::PrepareUserBilling.new(user, period).execute

      billings = user.reload.billings

      expect(billings.size).to eq 2
      expect(billings.collect(&:name)).to include('ido_micro', 'excess_billing')

      excess_bill = billings.where(kind: 'excess').first

      excess_price = 120 * 0.25
      expect(excess_bill.associated_hash[:excess]).to eq 120
      expect(excess_bill.price).to eq excess_price * 100
      expect(user.total_billing_of(period)).to eq (10 + excess_price) * 100
    end

    it 'creates compta piece excess billing - micro annual excess - (a previous excess_billing exist)', :annual_excess do
      allow_any_instance_of(BillingMod::FetchFlow).to receive(:execute).and_return(true)

      period      = CustomUtils.period_of(Time.now)
      prev_period = CustomUtils.period_of(1.month.ago)

      user = User.last

      package     = user.my_package
      package.update(name: 'ido_micro', upload_active: true, preassignment_active: true, bank_active: true, mail_active: false, scan_active: true)

      prev_package        = package.dup
      prev_package.user   = user
      prev_package.period = prev_period
      prev_package.save

      prev_flow               = user.flow_of(prev_period)
      prev_flow.compta_pieces = 200
      prev_flow.save

      data_flow               = user.current_flow
      data_flow.compta_pieces = 200
      data_flow.save

      BillingMod::PrepareUserBilling.new(user, prev_period).execute
      BillingMod::PrepareUserBilling.new(user, period).execute

      billings = user.reload.billings

      expect(billings.size).to eq 4
      expect(billings.collect(&:name)).to include('ido_micro', 'excess_billing')

      previous_excess_bill = billings.of_period(period - 1).where(kind: 'excess').last
      excess_bill          = billings.of_period(period).where(kind: 'excess').last

      previous_excess_price = 100 * 0.25
      excess_price          = 200 * 0.25

      expect(data_flow.period_version).to eq prev_flow.period_version

      expect(previous_excess_bill.associated_hash[:excess]).to eq 100
      expect(previous_excess_bill.price).to eq previous_excess_price * 100

      expect(excess_bill.associated_hash[:excess]).to eq 200
      expect(excess_bill.price).to eq excess_price * 100
      expect(user.total_billing_of(period)).to eq (10 + excess_price) * 100
    end

    it 'skip unlimited excess count', :ido_x do
      allow_any_instance_of(BillingMod::FetchFlow).to receive(:execute).and_return(true)

      period = CustomUtils.period_of(Time.now)

      user = User.last

      package = user.my_package
      package.update(name: 'ido_x', upload_active: false, preassignment_active: true, bank_active: false, mail_active: false, scan_active: false, period: period)

      data_flow                = user.current_flow
      data_flow.compta_pieces  = 500
      data_flow.save

      BillingMod::PrepareUserBilling.new(user, period).execute

      billings = user.billings

      expect(billings.where(name: 'ido_x').size).to eq 1
      expect(billings.where(kind: 'excess').size).to eq 0
    end
  end

  context 'Service excess billing', :service_excess_billing do
    before(:each) do
      BillingMod::Billing.destroy_all
      BillingMod::Invoice.destroy_all
      Operation.destroy_all
    end

    it 'creates valid bank and journal excess' do
      allow_any_instance_of(BillingMod::FetchFlow).to receive(:execute).and_return(true)

      period = CustomUtils.period_of(Time.now)

      user = User.last

      data_flow                = user.current_flow
      data_flow.bank_excess    = 5
      data_flow.journal_excess = 5
      data_flow.save

      BillingMod::PrepareUserBilling.new(user, period).execute

      billings = user.reload.billings

      expect(billings.collect(&:name)).to include('bank_excess', 'journal_excess')

      bank_excess_bill    = billings.where(name: 'bank_excess').first
      journal_excess_bill = billings.where(name: 'journal_excess').first

      expect(bank_excess_bill.price).to eq (5 * 2) * 100
      expect(journal_excess_bill.price).to eq (5 * 1) * 100
    end

    it 'creates previous operation billing' do
      period = CustomUtils.period_of(Time.now)

      user = User.last

      package      = user.my_package
      package.update(name: 'ido_retriever', upload_active: false, preassignment_active: true, bank_active: true, mail_active: false, scan_active: false)

      create_operation(user)

      BillingMod::PrepareUserBilling.new(user, period).execute

      billings = user.reload.billings

      expect(billings.size).to eq 2
      expect(billings.collect(&:name)).to include('ido_retriever', 'operations_billing')

      operation_billing = billings.where(name: 'operations_billing').first

      expect(operation_billing.price).to eq 5 * 100
      expect(user.total_billing_of(period)).to eq 10 * 100
    end

    it 'creates digitize package billing' do
      allow_any_instance_of(BillingMod::FetchFlow).to receive(:execute).and_return(true)

      period = CustomUtils.period_of(Time.now)

      user = User.last

      create_paper_processes(user)
      package = user.my_package
      package.update(name: 'ido_digitize', upload_active: false, preassignment_active: true, bank_active: false, mail_active: false, scan_active: false)

      data_flow                = user.current_flow
      data_flow.scanned_sheets = 5
      data_flow.save

      BillingMod::PrepareUserBilling.new(user, period).execute

      billings = user.reload.billings

      expect(billings.collect(&:name)).to include('ido_digitize', 'scanned_sheets', 'paper_processes')

      digitize            = billings.where(name: 'ido_digitize').first
      scanned_sheets_bill = billings.where(name: 'scanned_sheets').first
      paper_processes_bill = billings.where(name: 'paper_processes').first

      scanned_sheets_price  = 5 * 0.1
      paper_processes_price = 1 * 1

      expect(digitize.price).to eq 0
      expect(scanned_sheets_bill.price).to eq scanned_sheets_price * 100
      expect(paper_processes_bill.price).to eq paper_processes_price * 100

      expect(user.total_billing_of(period)).to eq (scanned_sheets_price + paper_processes_price) * 100
    end
  end

  context 'Simulation billing', :simulation do
    before(:each) do
      BillingMod::Billing.destroy_all
      BillingMod::BillingSimulation.destroy_all
      BillingMod::Invoice.destroy_all
      Operation.destroy_all
    end

    it 'create data to simulation table instead of real table' do
      user = User.last

      BillingMod::PrepareUserBilling.new(user, CustomUtils.period_of(Time.now), true).execute

      user.activate_simulation
      billings   = user.reload.evaluated_billings
      first_bill = billings.first

      package    = user.my_package

      expect(first_bill.is_a?(BillingMod::BillingSimulation)).to be true
      expect(package.is_a?(BillingMod::PackageSimulation)).to be true      

      expect(billings.size).to be > 0
      expect(first_bill.period).to eq CustomUtils.period_of(Time.now)
      expect(first_bill.name).to eq "ido_classic"
      expect(first_bill.title).to eq BillingMod::Configuration::LISTS[package.name.to_sym][:label]
      expect(first_bill.price).to eq 20 * 100

      user.deactivate_simulation
      real_billings = user.reload.evaluated_billings

      expect(real_billings.size).to eq 0
    end
  end
end