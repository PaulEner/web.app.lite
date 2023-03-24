function apply_searchable_option_list(target) {
  if (target=== 'select_customers') {
    $('select#select-customers-paper-set-order').removeClass('form-control');
    $('select#select-customers-paper-set-order').asMultiSelect({
      'searchplaceholder': 'Selectionner / Rechercher un dossier client à qui envoyer un kit courrier',
      'noneText': 'Selectionner un/des journaux',
      'allText': 'Tous séléctionnés'
    });
  }
}


function bind_all_events_order(){
  $('.select.order_paper_set_casing_count i.help-block').addClass('hide');

  if ($('#order form, form#new_edit_order_customer').length > 0){
    AppEmit('update_casing_counts');
    AppEmit('update_price');

    $('select').unbind('change').bind('change', function(e) {
      if ($(this).attr('id') === 'order_paper_set_start_date' || $(this).attr('id') === 'order_paper_set_end_date' ) {
        AppEmit('update_casing_counts');
      }

      else if ($(this).attr('id') === 'order_paper_set_casing_count') {
        AppEmit('check_casing_size_and_count');
      }

      AppEmit('update_price');
    });

    $('.copy_address').unbind('click').bind('click', function(e) {
      e.stopPropagation();

      $('#order_paper_return_address_attributes_company').val($('#order_address_attributes_company').val());
      $('#order_paper_return_address_attributes_last_name').val($('#order_address_attributes_last_name').val());
      $('#order_paper_return_address_attributes_first_name').val($('#order_address_attributes_first_name').val());
      $('#order_paper_return_address_attributes_address_1').val($('#order_address_attributes_address_1').val());
      $('#order_paper_return_address_attributes_address_2').val($('#order_address_attributes_address_2').val());
      $('#order_paper_return_address_attributes_city').val($('#order_address_attributes_city').val());
      $('#order_paper_return_address_attributes_zip').val($('#order_address_attributes_zip').val());
    });
  }


  $('.new_edit_order_url').unbind('click').bind('click', function(e) {
    e.stopPropagation();

    const url = $(this).attr('link');

    AppEmit('new_edit_order_view', { url: url });
  });

  ApplicationJS.set_checkbox_radio();
}

jQuery(function() {
  bind_all_events_order();
});