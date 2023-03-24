# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe PreAssignment::Delivery::MyUnisoft do
  def delivery_my_unisoft
    allow_any_instance_of(PreAssignment::CreateDelivery).to receive(:valid_my_unisoft?).and_return(true)
    allow_any_instance_of(User).to receive_message_chain('options.pre_assignment_date_computed?').and_return(false)
    allow(Settings).to receive_message_chain(:first, :notify_errors_to).and_return('test@idocus.com')

    preseizure   = FactoryBot.create :preseizure, user: @user, organization: @organization, report_id: @report.id, piece: @piece

    accounts = Pack::Report::Preseizure::Account.create([
                                                          { type: 1, number: 'A7 AUTO PIECES', preseizure_id: preseizure.id },
                                                          { type: 2, number: 'ABSOLUTE', preseizure_id: preseizure.id },
                                                          { type: 3, number: 'ACMS', preseizure_id: preseizure.id },
                                                        ])
    entries  = Pack::Report::Preseizure::Entry.create([
                                                        { type: 1, number: 'Orange', amount: 1213.48, preseizure_id: preseizure.id, account_id: accounts[0].id },
                                                        { type: 2, number: 'AERO', amount: 1011.23, preseizure_id: preseizure.id, account_id: accounts[1].id },
                                                        { type: 2, number: 'ALLBATTERIES', amount: 202.25, preseizure_id: preseizure.id, account_id: accounts[2].id },
                                                      ])

    PreAssignment::CreateDelivery.new(preseizure, ['my_unisoft']).execute.first
  end

  before(:each) do
    allow(Settings).to receive_message_chain('first.notify_on_ibiza_delivery').and_return('no')
    allow_any_instance_of(Pack::Report::Preseizure).to receive(:journal_name).and_return('AC')
    allow_any_instance_of(Pack::Piece).to receive_message_chain('cloud_content_object.path').and_return("#{Rails.root}/spec/support/files/2019100001.pdf")
    allow(Base64).to receive(:encode64).with(any_args).and_return('JVBERi0xLjQKJeLjz9MKMSAwIG9iaiAKPDwKL0Zvcm1UeXBlIDEKL1N1YnR5\ncGUgL0Zvcm0KL1Jlc291cmNlcyAKPDwKL0ZvbnQgCjw8Ci9GMS4wIDIgMCBS\nCj4+Ci9Qcm9jU2V0IFsvUERGIC9UZXh0IC9JbWFnZUIgL0ltYWdlQyAvSW1h\nZ2VJXQo+PgovVHlwZSAvWE9iamVj==')
  end

  before(:all) do
    DatabaseCleaner.start
    Timecop.freeze(Time.local(2020,11,24))

    @organization = FactoryBot.create :organization, code: 'IDO'
    @user         = FactoryBot.create :user, code: 'IDO%LEAD', organization_id: @organization.id
    @report       = FactoryBot.create :report, user: @user, organization: @organization, name: 'AC0003 AC 202011'
    pack          = FactoryBot.create :pack, owner: @user, organization: @organization , name: (@report.name + ' all')
    @piece        = FactoryBot.create :piece, pack: pack, user: @user, organization: @organization, name: (@report.name + ' 001')
    @piece_2      = FactoryBot.create :piece, pack: pack, user: @user, organization: @organization, name: (@report.name + ' 002')

    AccountBookType.create(user_id: @user.id, name: 'AC', description: '( Achat )', pseudonym: "20")

    mu1 = Software::MyUnisoft.new
    mu1.is_used = true
    mu1.owner   = @organization
    mu1.auto_deliver = 1
    mu1.save

    mu2 = Software::MyUnisoft.new
    mu2.is_used = true
    mu2.owner   = @user
    mu2.encrypted_api_token = "QEVuQwBAEACqDdqsXnsqW6p5pbPq5cr51FEbulJqavwCbJF2jWseBZlEiH7kzx8JxRbumy6IrwwVK+U5rOGIdHBEYoy6OHAek22k2TWaphNtxa/b7erPHNMWw86pf93ITEKevjNVwjLtR4x+Xi1u64rnXfCwi4VMo6d2b3nNWSGNfQc0XmqHvVdBNcy9SUbVoGdNKx4wRnbLjs204JeUzm3OLWputWPyYdo/GsEnyNMn73gCCPFADw=="
    mu2.society_id = 3
    mu2.auto_deliver = 1
    mu2.is_auto_updating_accounting_plan = true
    mu2.save
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  describe "Deliver pre assignment", :data_delivery do
    context "MyUnisoft", :my_unisoft_delivery do
      it "send pre_assignment successfully" do
        delivery = delivery_my_unisoft

        result = VCR.use_cassette('pre_assignment/my_unisoft_delivery_data_building') do
          PreAssignment::Builder::MyUnisoft.new(delivery).run
        end

        allow_any_instance_of(PreAssignmentDelivery).to receive_message_chain('cloud_content_object.path').and_return("#{Rails.root}/spec/support/files/my_unisoft_data.txt")

        result = VCR.use_cassette('pre_assignment/my_unisoft_send_delivery') do
          PreAssignment::Delivery::MyUnisoft.new(delivery.reload).run
        end

        delivery.reload

        expect(delivery.state).to eq 'sent'

        expect(delivery.data_to_deliver).to be nil
        expect(delivery.cloud_content).to be_attached

        expect(delivery.preseizures.size).to eq 1
        expect(delivery.preseizures.first.is_delivered_to?('my_unisoft')).to be true
      end

      it "returns error destination sending" do
        delivery = delivery_my_unisoft

        result = VCR.use_cassette('pre_assignment/my_unisoft_delivery_data_building') do
          PreAssignment::Builder::MyUnisoft.new(delivery).run
        end

        allow_any_instance_of(PreAssignmentDelivery).to receive_message_chain('cloud_content_object.path').and_return("#{Rails.root}/spec/support/files/my_unisoft_data_error.txt")

        result = VCR.use_cassette('pre_assignment/my_unisoft_send_delivery_error') do
          PreAssignment::Delivery::MyUnisoft.new(delivery.reload).run
        end

        delivery.reload
        expect(delivery.state).to eq 'error'
        expect(delivery.data_to_deliver).to be nil
        expect(delivery.error_message).to match /Le compte n'appartient pas/
        expect(delivery.preseizures.first.is_delivered_to?('my_unisoft')).to be false
      end
    end
  end
end