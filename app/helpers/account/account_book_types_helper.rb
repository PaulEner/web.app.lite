module Account::AccountBookTypesHelper
  def account_book_type_entry_type_for_select(organization, customer)
    options = if organization.specific_mission
      [
        [t('simple_form.labels.account_book_type.entry_type_5'),5]
      ]
    elsif !customer || (customer && customer.my_package.try(:preassignment_active))
      [
        [t('simple_form.labels.account_book_type.entry_type_0'),0],
        [t('simple_form.labels.account_book_type.entry_type_2'),2],
        [t('simple_form.labels.account_book_type.entry_type_3'),3]
      ]
    else
      [
        [t('simple_form.labels.account_book_type.entry_type_0'),0]
      ]
    end

    if !organization.specific_mission
      if !customer || ( customer && customer.my_package.try(:bank_active) )
        options << [t('simple_form.labels.account_book_type.entry_type_4'),4]
      end

      if !customer || ( customer && customer.my_package.try(:preassignment_active) )
        options << [t('simple_form.labels.account_book_type.entry_type_1'),1]
      end
    end

    options
  end
end