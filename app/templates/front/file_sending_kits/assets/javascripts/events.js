
function applied_manual_paper_set_order(){
  let elements = $('tbody#fsk_paper_set_orders tr');
  if (elements.length > 0) {
    let total_price = 0
    elements.each(function(index, element){
      let period = 1;
      let price = 0;
      let period_duration = parseInt($(element).find('#fsk_order_period_duration').val());
      let ms_day = 1000*60*60*24*28;
      let start_date = new Date($(element).find('#fsk_orders_paper_set_start_date').val());
      let end_date   = new Date($(element).find('#fsk_orders_paper_set_end_date').val());

      if(start_date <= end_date){
        let count = Math.floor(Math.abs(end_date - start_date) / ms_day) + period_duration;
        period = (count / period_duration) - 1;

        let manual_paper_set_order  = $(element).find('#fsk_manual_paper_set_order');
        if(manual_paper_set_order.length > 0 && manual_paper_set_order.val() == 'true'){
          paper_set_folder_count = parseInt($(element).find("#fsk_order_paper_set_folder_count").val());
          price = paper_set_folder_count * (period + 1);
        }

        // $(element).find('#fsk_order_paper_set_price').html(price + ",00€")
        $(element).find('#fsk_order_paper_set_price').html("0,00€");
        $(element).find('span.error_info').html('');
      }
      else
      {
        price = 0;
        $(element).find('span.error_info').html('<span class="alert alert-danger">Interval de date invalide</span>');
      }

      if ($(element).find('input.fsk_user_checked').is(':checked')){
        total_price += price;
      }
    });

    // $('.fsk_total_price').html(total_price + ",00€ HT")
    $('.fsk_total_price').html("0,00€ HT")
  }

  if ($('form.fsk_paper_set_orders').length > 0){
    $("#fsk_all_users_checked").unbind('click').bind('click', function(e) {
      $('input:checkbox.fsk_user_checked').not(this).prop('checked', this.checked);
      check_generation_button();
    });
  }

  check_generation_button();
}


function check_generation_button(){
  $('#generate-manual-paper-set-order').prop('disabled', 'disabled');
  $('input:checkbox.fsk_user_checked').each(function(e){
    if( $(this).is(':checked') ){
      $('#generate-manual-paper-set-order').removeAttr('disabled');
    }
  });
}

function generate_manual_paper_set_order(){
  $("#generate-manual-paper-set-order").unbind('click').bind('click', function(e) {
    e.preventDefault();

    let form = $('form.fsk_paper_set_orders');
    let organization_id = $('#fsk_manual_paper_set_order').data('id');
    let url = `/organizations/${organization_id}/file_sending_kit/generate`;

    $('#download-manual-paper-set-order .download-manual-paper-set-order-folder-pdf').hide();
    $('#download-manual-paper-set-order .pending-generation').removeClass('hide');
    $(".canceling-manual-order").attr('disabled','disabled');
    $("#generate-manual-paper-set-order").attr('disabled', 'disabled');

    AppEmit('generate_manual_paper_set_order', { url: url, data: form.serialize() });
  });
}


function file_sending_kits_main_events() {
  $('select').unbind('change').bind('change', function() {
    applied_manual_paper_set_order();
  });


  if ($('.file_sending_kits_select').length > 0) {
    $('.form-footer-content').removeClass('hide');
  }

  $('input.fsk_user_checked').unbind('click').bind('click', function() {
    applied_manual_paper_set_order();
  });

  $('.select_for_orders').unbind('click').bind('click', function(e) {
    e.stopPropagation();

    const url = $(this).attr('link');

    AppEmit('select_for_orders', { url: url });
  });


  $('.edit-file-sending-kits').unbind('click').bind('click', function(e) {
    e.preventDefault();

    const url = $(this).attr('link');

    AppEmit('edit_file_sending_kits_view', { url: url});
  });

  $('.validate_file_sending_kits_edit').unbind('click').bind('click', function(e) {
    e.stopPropagation();
    AppLoading('show');
    $('form#edit_file_sending_kit_form').submit();
  });

  applied_manual_paper_set_order();

  generate_manual_paper_set_order();

  ApplicationJS.set_checkbox_radio();
}


jQuery(function () {
  file_sending_kits_main_events();
});