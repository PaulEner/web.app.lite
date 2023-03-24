//= require './journal'

function bind_vat_accounts_events(){
  $('select.vat_accounts_label').on('change', function(e){
    let parent = $(this).parents('div.form-group.account_book_type_vat_accounts')
    let value  = $(this).val()

    if(value == -1)
      parent.find('div.tva_rate > input').attr('disabled', 'disabled')
    else
      parent.find('div.tva_rate > input').removeAttr('disabled')
  });
}

function searchable_option_copy_journals_list() {
  let checked_count = 0;

  $('select#copy-journals-into-customer').removeClass('form-control');
  $('select#copy-journals-into-customer').asMultiSelect({
    'noneText': 'Selectionner un/des journaux',
    'allText': 'Tous séléctionnés',
    events: {
      onChange: function(sol, changedElements) {
        changedElements['0'].checked ? checked_count ++ : checked_count --;
        (checked_count > 0) ? $('.copy_account_book_type_btn').removeAttr('disabled') : $('.copy_account_book_type_btn').attr('disabled', 'disabled');
      },
    }
  });
}


jQuery(function () {
  let journal = new Journal();
  journal.main();

  AppListenTo('window.application_auto_rebind', (e)=>{
    bind_vat_accounts_events();
    searchable_option_copy_journals_list();
  });

  AppListenTo('compta_analytic.edit_journal_compta', (e)=>{
    let elem = e.detail.obj;
    let journal_id = $(elem).data('journal-id');
    let customer_id = $(elem).data('customer-id');
    let code = $(elem).data('code');

    journal.edit_analytics(journal_id, customer_id, code);
  });

  AppListenTo('compta_analytics.validate_analysis', (e)=>{ journal.update_analytics(e.detail.data) });

  AppListenTo('journal.select_external_journal', (e)=>{
    let elem = e.detail.obj;
    let c_value = elem.val();

    $('input#account_book_type_pseudonym').val(c_value);
  });

  AppListenTo('window.change-per-page.journales', (e)=>{ journal.load_journals(e.detail.name, 1, e.detail.per_page); });
  AppListenTo('window.change-page.journales', (e)=>{ journal.load_journals(e.detail.name, e.detail.page); });
});