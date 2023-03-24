function is_manual_paper_set_order_applied() {
  const manual_paper_set_order = $('#paper_set_specific_prices');
  return manual_paper_set_order.length > 0 && manual_paper_set_order.attr("data-manual") === 'true';
}


function confirm_manual_paper_set_order(){
  if (is_manual_paper_set_order_applied()){
    $('.valid-manual-paper-set-order').unbind('click').bind('click', function(e) {
      e.preventDefault();
      if (confirm("Vous êtes sur le point de commander un kit sans passer par courrier. Etes-vous sûr ?")){
        $('#valid-manual-paper-set-order').submit();
      }
    });
  }
}


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


function bind_all_events_paper_set_orders(){
  apply_searchable_option_list('select_customers');
  $('.select_for_orders').unbind('click').bind('click', function(e) {      
    e.stopPropagation();

    AppEmit('select_for_orders');
    apply_searchable_option_list('select_customers');

    $('#select_for_orders').modal('show');
  });


  $('.select.order_paper_set_casing_count i.help-block').addClass('hide');


  $('.open_new_edit').unbind('click.new_edit').bind('click.new_edit', function(e) {
    e.preventDefault();

    AppEmit('add_or_edit_paper_set_order', { url: $(this).find('a').attr('href')} );

    $('#add-new-paper-set-order').modal('show');
  });


  $('.valid-paper-set-order').unbind('click').bind('click', function(e) {
    e.stopPropagation();

    /*$('#order_multiple_paper_set').submit();*/

    let form = $('form#order_multiple_paper_set');
    let url = form.attr('action');

    AppEmit('order_multiple_paper_set', { url: url, data: form.serialize() });

    $('#select_for_orders').modal('hide');
    $('#create_order_multiple').modal('show');
  });

  if ($('form.paper_set_order_form').length > 0){
    AppEmit('update_casing_counts').then(e=>{
      AppEmit('update_price');
    });

    $('select').unbind('change.update_price').bind('change.update_price', function(e) {
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

    confirm_manual_paper_set_order();
  }

  if ($('#paper_set_orders.select_to_order').length > 0){
    $('#master_checkbox').unbind('change').bind('change', function(e) {
      if ($(this).is(':checked')){
        $('.checkbox').attr('checked', true);
      }
      else{
        $('.checkbox').attr('checked', false);
      }
    });
  }

  if ($('.order_multiple form, form.order_multiple_form').length > 0){
    AppEmit('update_table_casing_counts', { index: -1}).then(e=>{
      AppEmit('update_table_price');
    });

    $('select').unbind('change.update_table_price').bind('change.update_table_price', function(e) { AppEmit('update_table_price'); });
    $('.date_order').unbind('change').bind('change', function(e) {
      const index = $(this).attr("data-index");
      AppEmit('update_table_casing_counts', { index: index}).then((e)=>{
        AppEmit('update_table_price');
      });
    });

    confirm_manual_paper_set_order();
  }

  $('.add-paper-set-order, .create-paper-set-order-multiple').unbind('click').bind('click', function(e) {
    e.stopPropagation();
    AppLoading('show');
    $('#valid-manual-paper-set-order.paper_set_order_form, #default.paper_set_order_form').submit();
  });

  $('.edit-file-sending-kits').unbind('click').bind('click', function(e) {
    e.preventDefault();

    const url = $(this).attr('link');

    AppEmit('edit_file_sending_kits_view', { url: url});
  });

  $('.validate_file_sending_kits_edit').unbind('click').bind('click', function(e) {
    e.stopPropagation();
    $('form#edit_file_sending_kit_form').submit();
  });

  $('.open_paper_set_order_filter').unbind('click').bind('click', function(e) {
    e.stopPropagation();

    $('#paper_set_order_filter.modal').modal('show');
  });

  ApplicationJS.set_checkbox_radio();
}

jQuery(function() {
  AppListenTo('window.application_auto_rebind', (e)=>{ bind_all_events_paper_set_orders() });
});