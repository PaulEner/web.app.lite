# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe Transaction::AccountNumberFinder do
  describe '#execute' do
    before(:all) do
      @organization = create(:organization)
      @user = create(:user)
      @organization.customers << @user
      @operation = OpenStruct.new({ label: 'Prlv Google $10.00', amount: 10 })
      @accounting_plan = [
        ['GOOGLE', '0GOO'],
        ['SLIMPAY', '0SLIM'],
        ['FIDUCEO', '0FID'],
        ['IBIZA /NS', '0IBI'],
        ['CA', '0CA'],
        ['CARTE', '0CAR']
      ]
    end

    context 'without rules and without accounting plan', :first do
      it 'returns 0TEMP' do
        allow_any_instance_of(Transaction::AccountNumberFinder).to receive(:accounting_plan).and_return([])

        result = Transaction::AccountNumberFinder.new(@user, '0TEMP').execute(@operation)

        expect(result).to eq('0TEMP')
      end
    end

    context 'with accounting plan', :second do
      it 'returns 0GOO' do
        allow_any_instance_of(Transaction::AccountNumberFinder).to receive(:accounting_plan).and_return(@accounting_plan)

        result = Transaction::AccountNumberFinder.new(@user, '0TEMP').execute(@operation)

        expect(result).to eq('0GOO')
      end

      it 'returns 0SLIM' do
        allow_any_instance_of(Transaction::AccountNumberFinder).to receive(:accounting_plan).and_return(@accounting_plan)
        @operation.label = 'Prlv Slimpay Janvier 2015'
        @operation.amount = -100
        allow(@operation).to receive('credit?').and_return(true)

        result = Transaction::AccountNumberFinder.new(@user, '0TEMP').execute(@operation)

        expect(result).to eq('0SLIM')
      end

      it 'returns 0CAR based on scores' do
        allow_any_instance_of(Transaction::AccountNumberFinder).to receive(:accounting_plan).and_return(@accounting_plan)
        @operation.label = 'paiement par carte €20.00'
        @operation.amount = -20
        allow(@operation).to receive('credit?').and_return(true)

        result = Transaction::AccountNumberFinder.new(@user, '0TEMP').execute(@operation)

        expect(result).to eq('0CAR')
      end

      it 'returns 0TEMP based on scores' do
        allow_any_instance_of(Transaction::AccountNumberFinder).to receive(:accounting_plan).and_return(@accounting_plan)
        @operation.label = 'Prlv Caisse-epargne Janvier 2015'
        @operation.amount = -20
        allow(@operation).to receive('credit?').and_return(true)

        result = Transaction::AccountNumberFinder.new(@user, '0TEMP').execute(@operation)

        expect(result).to eq('0TEMP')
      end
    end

    context 'with match rules' do
      before(:all) do
        @rule = AccountNumberRule.new
        @rule.organization = @organization
        @rule.name = 'Orange'
        @rule.affect = 'organization'
        @rule.rule_type = 'match'
        @rule.rule_target = 'both'
        @rule.content = '"ORANGE"'
        @rule.priority = 0
        @rule.third_party_account = '0ORA'
        @rule.save
      end

      after(:all) do
        @rule.destroy
      end

      it 'returns 0ORA on "both" target rules' do
        allow_any_instance_of(Transaction::AccountNumberFinder).to receive(:accounting_plan).and_return([])
        @operation.label = 'Prlv Orange Janvier 2015'
        @operation.amount = -200
        allow(@operation).to receive('credit?').and_return(true)

        result = Transaction::AccountNumberFinder.new(@user, '0TEMP').execute(@operation)

        expect(result).to eq('0ORA')
      end

      it 'returns 0TEMP on "debit" target rules and "credit" operation' do
        allow_any_instance_of(Transaction::AccountNumberFinder).to receive(:accounting_plan).and_return([])

        @rule.rule_target = 'debit'
        @rule.save

        @operation.label = 'Prlv Orange Janvier 2015'
        @operation.amount = -200
        allow(@operation).to receive('credit?').and_return(true)

        result = Transaction::AccountNumberFinder.new(@user, '0TEMP').execute(@operation)

        expect(result).to eq('0TEMP')
      end

      it 'returns 0ORA on "credit" target rules and "credit" operation' do
        allow_any_instance_of(Transaction::AccountNumberFinder).to receive(:accounting_plan).and_return([])

        @rule.rule_target = 'credit'
        @rule.save

        @operation.label = 'Prlv Orange Janvier 2015'
        @operation.amount = -200
        allow(@operation).to receive('credit?').and_return(true)

        result = Transaction::AccountNumberFinder.new(@user, '0TEMP').execute(@operation)

        expect(result).to eq('0ORA')
      end

      it 'returns prior matched rule', :priority do
        allow_any_instance_of(Transaction::AccountNumberFinder).to receive(:accounting_plan).and_return([])

        rule1 = AccountNumberRule.new
        rule1.organization = @organization
        rule1.name = 'Priority 1'
        rule1.affect = 'organization'
        rule1.rule_type = 'match'
        rule1.rule_target = 'both'
        rule1.content = "*DISTRIBU*"
        rule1.priority = 1
        rule1.third_party_account = 'distribu'
        rule1.save


        rule2 = AccountNumberRule.new
        rule2.organization = @organization
        rule2.name = 'Priority 2'
        rule2.affect = 'organization'
        rule2.rule_type = 'match'
        rule2.rule_target = 'both'
        rule2.content = "*CARTE X*"
        rule2.priority = 2
        rule2.third_party_account = 'carteX'
        rule2.save

        @operation.label = 'CARTE X2978 04/11 RUEM DISTRIBU'
        @operation.amount = -200
        @operation.save
        allow(@operation).to receive('credit?').and_return(true)

        result = Transaction::AccountNumberFinder.new(@user, '0TEMP').execute(@operation)

        rule1.priority = 2
        rule1.save

        rule2.priority = 1
        rule2.save

        result2 = Transaction::AccountNumberFinder.new(@user.reload, '0TEMP').execute(@operation)

        expect(result).to eq('distribu')
        expect(result2).to eq('carteX')
      end

      it 'returns prior matched rule with 3 rules', :priority2 do
        allow_any_instance_of(Transaction::AccountNumberFinder).to receive(:accounting_plan).and_return([])

        rule1 = AccountNumberRule.new
        rule1.organization = @organization
        rule1.name = 'Priority 1'
        rule1.affect = 'organization'
        rule1.rule_type = 'match'
        rule1.rule_target = 'both'
        rule1.content = "*RUEM DISTRIBU*"
        rule1.priority = 1
        rule1.third_party_account = 'distribu'
        rule1.save

        rule2 = AccountNumberRule.new
        rule2.organization = @organization
        rule2.name = 'Priority 2'
        rule2.affect = 'organization'
        rule2.rule_type = 'match'
        rule2.rule_target = 'both'
        rule2.content = "*CARTE X*"
        rule2.priority = 2
        rule2.third_party_account = 'carteX'
        rule2.save

        rule3 = AccountNumberRule.new
        rule3.organization = @organization
        rule3.name = 'Priority 3'
        rule3.affect = 'organization'
        rule3.rule_type = 'match'
        rule3.rule_target = 'both'
        rule3.content = "*RUEM*"
        rule3.priority = 1
        rule3.third_party_account = 'ruem'
        rule3.save

        @operation.label = 'CARTE X2978 04/11 RUEM DISTRIBU'
        @operation.amount = -200
        @operation.save
        allow(@operation).to receive('credit?').and_return(true)

        result = Transaction::AccountNumberFinder.new(@user, '0TEMP').execute(@operation)

        rule1.priority = 2
        rule1.save

        rule2.priority = 1
        rule2.save

        rule3.priority = 0
        rule3.save

        result2 = Transaction::AccountNumberFinder.new(@user.reload, '0TEMP').execute(@operation)

        expect(result).to eq('distribu')
        expect(result2).to eq('ruem')
      end
    end

    context 'with truncate rules' do
      before(:all) do
        @rule = AccountNumberRule.new
        @rule.organization = @organization
        @rule.name = '/NS'
        @rule.affect = 'organization'
        @rule.rule_type = 'truncate'
        @rule.rule_target = 'both'
        @rule.content = '/NS'
        @rule.priority = 0
        @rule.save
      end

      after(:all) do
        @rule.destroy
      end

      it 'returns 0IBI on "both" target rules' do
        allow_any_instance_of(Transaction::AccountNumberFinder).to receive(:accounting_plan).and_return(@accounting_plan)
        @operation.label = 'Prlv iBiza $150.0'
        @operation.amount = -150
        allow(@operation).to receive('credit?').and_return(true)

        result = Transaction::AccountNumberFinder.new(@user, '0TEMP').execute(@operation)

        expect(result).to eq('0IBI')
      end

      it 'returns 0TEMP on "credit" target rules and "debit" operation' do
        allow_any_instance_of(Transaction::AccountNumberFinder).to receive(:accounting_plan).and_return(@accounting_plan)

        @rule.rule_target = 'credit'
        @rule.save

        @operation.label = 'Prlv iBiza $150.0'
        @operation.amount = 150
        allow(@operation).to receive('debit?').and_return(true)

        result = Transaction::AccountNumberFinder.new(@user, '0TEMP').execute(@operation)

        expect(result).to eq('0TEMP')
      end

      it 'returns 0IBI on "debit" target rules and "debit" operation' do
        allow_any_instance_of(Transaction::AccountNumberFinder).to receive(:accounting_plan).and_return(@accounting_plan)

        @rule.rule_target = 'debit'
        @rule.save

        @operation.label = 'Prlv iBiza $150.0'
        @operation.amount = 150
        allow(@operation).to receive('debit?').and_return(true)

        result = Transaction::AccountNumberFinder.new(@user, '0TEMP').execute(@operation)

        expect(result).to eq('0IBI')
      end
    end

    context 'with match rules and with accounting plan' do
      before(:all) do
        @rule = AccountNumberRule.new
        @rule.organization = @organization
        @rule.name = 'Google'
        @rule.affect = 'organization'
        @rule.rule_type = 'match'
        @rule.rule_target = 'both'
        @rule.content = 'Google'
        @rule.priority = 0
        @rule.third_party_account = '0GOG'
        @rule.save

        @accounting_plan_base = AccountingPlan.new
        @accounting_plan_base.last_checked_at = Time.now
        @accounting_plan_base.is_updating = false
        @accounting_plan_base.user = @user
        @accounting_plan_base.save

        @ac_items1 = AccountingPlanItem.new
        @ac_items1.third_party_account = '0CUST'
        @ac_items1.third_party_name = 'TEST CUST'
        @ac_items1.kind = 'customer'
        @ac_items1.accounting_plan_itemable_type = 'AccountingPlan'
        @ac_items1.accounting_plan_itemable_id = @accounting_plan_base.id
        @ac_items1.save

        @ac_items2 = AccountingPlanItem.new
        @ac_items2.third_party_account = '0PROV'
        @ac_items2.third_party_name = 'TEST PROV'
        @ac_items2.kind = 'provider'
        @ac_items2.accounting_plan_itemable_type = 'AccountingPlan'
        @ac_items2.accounting_plan_itemable_id = @accounting_plan_base.id
        @ac_items2.save
      end

      after(:all) do
        @rule.destroy
      end

      it 'returns providers only on operation\'s negative amount' do
        @operation.label = 'TEST PROV $10.00'
        @operation.amount = -10
        allow(@operation).to receive('credit?').and_return(true)

        result = Transaction::AccountNumberFinder.new(@user, '0TEMP').execute(@operation)

        expect(result).to eq('0PROV')
      end

      it 'returns customers only on operation\'s positive amount' do
        @operation.label = 'TEST CUST $10.00'
        @operation.amount = 10
        allow(@operation).to receive('debit?').and_return(true)

        result = Transaction::AccountNumberFinder.new(@user, '0TEMP').execute(@operation)

        expect(result).to eq('0CUST')
      end

      it 'returns temp account if accounting_plan is skiped and rules not found' do
        @operation.label = 'TEST PROV $10.00'
        @operation.amount = -10
        allow(@operation).to receive('credit?').and_return(true)

        options = UserOptions.new
        options.user = @user
        options.skip_accounting_plan_finder = true
        options.save

        result = Transaction::AccountNumberFinder.new(@user.reload, '0TEMP').execute(@operation)

        options.skip_accounting_plan_finder = false
        options.save
        @user.reload

        expect(result).to eq('0TEMP')
      end

      it 'returns temp_account even providers is found but operation\'s amount is positive' do
        @operation.label = 'TEST PROV $10.00'
        @operation.amount = 10
        allow(@operation).to receive('debit?').and_return(true)

        result = Transaction::AccountNumberFinder.new(@user, '0TEMP').execute(@operation)

        expect(result).to eq('0TEMP')
      end

      it 'returns 0GOG based on rules' do
        allow_any_instance_of(Transaction::AccountNumberFinder).to receive(:accounting_plan).and_return(@accounting_plan)
        @operation.label = 'Prlv Google $10.00'
        @operation.amount = 10
        allow(@operation).to receive('debit?').and_return(true)

        result = Transaction::AccountNumberFinder.new(@user, '0TEMP').execute(@operation)

        expect(result).to eq('0GOG')
      end

      it 'returns 0GOO based on accounting plan if rules is a "credit" and operation is a "debit"' do
        allow_any_instance_of(Transaction::AccountNumberFinder).to receive(:accounting_plan).and_return(@accounting_plan)

        @rule.rule_target = 'credit'
        @rule.save

        @operation.label = 'Prlv Google $10.00'
        @operation.amount = 10
        allow(@operation).to receive('debit?').and_return(true)

        result = Transaction::AccountNumberFinder.new(@user, '0TEMP').execute(@operation)

        expect(result).to eq('0GOO')
      end

      it 'returns 0TEMP, if founded rule is not in accounting plan for ibiza users' do
        allow_any_instance_of(User).to receive_message_chain('accounting_plan.customers.where').and_return([])
        allow_any_instance_of(User).to receive('uses?').with(:ibiza).and_return(true)
        allow_any_instance_of(Transaction::AccountNumberFinder).to receive(:accounting_plan).and_return(@accounting_plan)

        @operation.label = 'Prlv Google $10.00'
        @operation.amount = 10
        allow(@operation).to receive('debit?').and_return(true)
        allow(Transaction::AccountNumberFinder).to receive(:find_with_rules).and_return(nil)
        allow(Transaction::AccountNumberFinder).to receive(:find_with_accounting_plan).and_return(nil)

        result = Transaction::AccountNumberFinder.new(@user, '0TEMP').execute(@operation)

        expect(result).to eq('0TEMP')
      end
    end

    context 'with *.* content rules', :star_star  do
      before(:all) do
        @rule = AccountNumberRule.new
        @rule.organization = @organization
        @rule.name = 'Star star'
        @rule.affect = 'organization'
        @rule.rule_type = 'match'
        @rule.rule_target = 'both'
        @rule.content = '*.*'
        @rule.priority = 0
        @rule.third_party_account = '0ORA'
        @rule.save
      end

      after(:all) do
        @rule.destroy
      end

      it '*.* match' do
        @operation.label = 'Akamir bladenu'
        @operation.amount = -10
        allow(@operation).to receive('credit?').and_return(true)
        allow_any_instance_of(Transaction::AccountNumberFinder).to receive(:accounting_plan).and_return([])

        result = Transaction::AccountNumberFinder.new(@user).execute(@operation)

        expect(result).to eq('0ORA')
      end

      it '*.* allow the highest scores' do
        @rule_2 = AccountNumberRule.new
        @rule_2.organization = @organization
        @rule_2.name = 'Star star van'
        @rule_2.affect = 'organization'
        @rule_2.rule_type = 'match'
        @rule_2.rule_target = 'both'
        @rule_2.content = '*Test star*'
        @rule_2.priority = 0
        @rule_2.third_party_account = 'TR0E'
        @rule_2.save

        @operation.label = 'TEST STAR academi club zain'
        @operation.amount = 10
        allow(@operation).to receive('credit?').and_return(true)
        allow_any_instance_of(Transaction::AccountNumberFinder).to receive(:accounting_plan).and_return([])

        result = Transaction::AccountNumberFinder.new(@user).execute(@operation)

        expect(result).to eq('TR0E')
      end

      it 'with the same scores, get the high priority' do
        @user.organization.account_number_rules.global.last.destroy

        @rule.priority = 2
        @rule.save

        @rule_2 = AccountNumberRule.new
        @rule_2.organization = @organization
        @rule_2.name = 'Star star van damme'
        @rule_2.affect = 'organization'
        @rule_2.rule_type = 'match'
        @rule_2.rule_target = 'both'
        @rule_2.content = '*Test*'
        @rule_2.priority = 0
        @rule_2.third_party_account = 'M0R3'
        @rule_2.save

        @operation.label = 'TEST STAR'
        @operation.amount = 10
        allow(@operation).to receive('credit?').and_return(true)
        allow_any_instance_of(Transaction::AccountNumberFinder).to receive(:accounting_plan).and_return([])

        result = Transaction::AccountNumberFinder.new(@user).execute(@operation)

        expect(result).to eq('M0R3')
      end
    end
  end
end
