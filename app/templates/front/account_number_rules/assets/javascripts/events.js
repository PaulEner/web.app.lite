function bind_all_events_account_number_rules(){
  function multi_select_for(target= 'add-modal') {
    if (target === 'add-modal') {
      /*$('select#customers-list').asMultiSelect({
        'noneText': 'Selectionner un/des clients affectés par la règle',
        'allText': 'Tous séléctionnés'
      });

      $('select#groups-list').asMultiSelect({
        'noneText': 'Selectionner un/des groupe(s) affectés par la règle',
        'allText': 'Tous séléctionnés'
      });*/


      $('select#customers-list').searchableOptionList({
        'noneText': 'Selectionner un/des clients affectés par la règle',
        'allText': 'Tous séléctionnés',
        'maxHeight': '300px'
      });

      $('select#groups-list').searchableOptionList({
        'noneText': 'Selectionner un/des groupe(s) affectés par la règle',
        'allText': 'Tous séléctionnés',
        'maxHeight': '300px'
      });
    }

    if (target === 'download-modal') {
      $('select#affect-rule-to').asMultiSelect({
        'noneText': 'Selectionner un/des affectations',
        'allText': 'Tous séléctionnés',
        'maxHeight': '300px'
      });
    }

  }


  function show_affect_to(current_value) {
    if (current_value === 'user'){
      $('.head_affect_to').removeClass('hide');
      $('.customers-list').removeClass('hide');
      $('.groups-list').removeClass('hide');
    }
    else{
      $('.head_affect_to').addClass('hide');
      $('.customers-list').addClass('hide');
      $('.groups-list').addClass('hide');
    }
  }


  function set_third_party_account(selected_rule_type_value) {
    if (selected_rule_type_value === 'truncate'){
      $('.third_party_account-section').addClass('hide');
    }
    else{
      $('.third_party_account-section').removeClass('hide');
    }
  }


  $('.check-bank-rule').unbind('click').bind('click',function(e) {
    e.stopPropagation();

    if ($('.check-bank-rule:checked').length > 0){
      $('#export-rule').removeClass('btn-light-secondary').addClass('btn-light').removeAttr('disabled');
      $('#delete-rule').removeClass('btn-light-secondary').addClass('btn-danger').removeAttr('disabled');
    }
    else{
      $('#export-rule').removeClass('btn-light').addClass('btn-light-secondary').attr('disabled', 'disabled');
      $('#delete-rule').removeClass('btn-danger').addClass('btn-light-secondary').attr('disabled', 'disabled');
    }
  });

  $('.check-all-bank-rule').unbind('click').bind('click',function(e) {
    e.stopPropagation();

    if ($(this).is(':checked')){
      $('#export-rule').removeClass('btn-light-secondary').addClass('btn-light').removeAttr('disabled');
      $('#delete-rule').removeClass('btn-light-secondary').addClass('btn-danger').removeAttr('disabled');
      $(".check-bank-rule").prop('checked', true);
    }
    else{
      $('#export-rule').removeClass('btn-light').addClass('btn-light-secondary').attr('disabled', 'disabled');
      $('#delete-rule').removeClass('btn-danger').addClass('btn-light-secondary').attr('disabled', 'disabled');
      $(".check-bank-rule").prop('checked', false);
    }
  });

  multi_select_for('add-modal');
  $('.create_or_update_account_number_rules')
  .unbind('click').bind('click',function(e) {
    if ($(this).hasClass('new')) { e.stopPropagation(); }
    else if ($(this).hasClass('duplicate') || $(this).hasClass('edit')) { e.preventDefault();}

    const url = $(this).attr('href');

    AppEmit('create_or_update_account_number_rules', { url: url });
  });

  $('.required_field')
  .unbind('keypress.account_number_rules keyup.account_number_rules keydown.account_number_rules input.account_number_rules change.account_number_rules')
  .bind('keypress.account_number_rules keyup.account_number_rules keydown.account_number_rules input.account_number_rules change.account_number_rules', function(e) {
    AppEmit('validate_account_number_rule_fields');
  });

  const rule_type_selector = $('select#rule-type');
  set_third_party_account(rule_type_selector.val());
  $(rule_type_selector)
  .unbind('change').bind('change', function(e) {
    e.stopPropagation();

    set_third_party_account($(this).val());
  });

  show_affect_to($('select#affect-to').val());
  $('select#affect-to, select#affect-rule-to').unbind('change').bind('change',function(e) {
    e.stopPropagation();

    show_affect_to($(this).val());
  });

  $('.sub_rule_menu li.download')
  .unbind('click').bind('click',function(e) {
    e.stopPropagation();

    show_affect_to($('select#affect-rule-to').val());

    $('#import-rule').modal('show');
  });

  $('#export-rule').unbind('click').bind('click',function(e) {
    if ($('.check-all-bank-rule').is(':checked')){
      e.preventDefault();

      $('#confirm-export.modal').modal('show');
    }
  });

  $('#confirm-export.modal .validate-export-rule').unbind('click').bind('click',function(e) {
    e.preventDefault();

    $('#export_type_submit').val($('input[name="export_type"]:checked').val());

    $('form#form_export_or_destroy').submit();

    $('#confirm-export.modal').modal('hide');

    $('.check-all-bank-rule, .check-bank-rule').prop('checked', false);

    $('.btn-action-rule').prop('disabled', true);
  });

  
  multi_select_for('filter-modal');
  $('.more-filter').unbind('click').bind('click',function(e) {
    e.stopPropagation(); 

    multi_select_for('filter-modal');

    $('#filter-rule').modal('show');
  });

  $('.action.sub-menu-bank-affectation')
  .unbind('click').bind('click',function(e) {
    e.stopPropagation();

    $('.sub_menu').not(this).each(function(){
      $(this).addClass('hide');
    });

    $(this).parent().find('.sub_menu').removeClass('hide');
  });


  $('.skip_accounting_plan').unbind('click').bind('click', function(e) {
    e.stopPropagation();
    e.preventDefault();

    $('#skipAccountingPlan').modal('show');
  });

  $('#skipAccountingPlan #skipAccountingPlanButton')
  .unbind('click').bind('click', function(e) {
    e.stopPropagation();

    const accounts = $('#skipAccountingPlan #account_list').val();
    const account_validation = $('#skipAccountingPlan #account_validation').val();
    const url = $('#skipAccountingPlan #skipAccountingPlanForm').attr('action');

    AppEmit('skip_accounting_plan', { url: url, account_list: accounts, account_validation: account_validation });
  })

  $('.search-content #search_input').unbind('keyup').bind('keyup', function(e){ if(e.key == 'Enter'){ /*e.keyCode == 13*/ AppEmit('account_number_rule_contains_search_text'); } });
  $('.bank-affectation #basic-addon1').unbind('click').bind('click', function(e){ AppEmit('account_number_rule_contains_search_text'); });

  $('span.customize_tooltip').mouseover(function() {
    $(this).find('.account_number_rules_popover_content').show();
  })
  .mouseout(function() {
    $(this).find('.account_number_rules_popover_content').hide();
  });

  ApplicationJS.set_checkbox_radio();
}

jQuery(function() {
  AppListenTo('window.application_auto_rebind', (e)=>{ bind_all_events_account_number_rules() });
});