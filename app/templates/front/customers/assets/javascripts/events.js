function bind_customer_events() {
  $('.close_customer, .reopen_customer').unbind('click').bind('click',function(e) {
    e.preventDefault();

    let target = 'close';

    if ($(this).hasClass('reopen_customer')) { target = 'reopen'; }

    const url = $(this).attr('href');

    AppEmit('close_or_reopen_confirm_view', { url: url, target: target });
  });

  $('.close_or_reopen_confirm').unbind('click').bind('click', function(e) {
    e.preventDefault();
    e.stopPropagation();

    let form_data = {};
    let url = '';
    let attr = $(this).attr('link');

    if ($(this).hasClass('close')) {
      const form = $('form#account_close_confirm');
      form_data = form.serialize();
      url = form.attr('action');
    }
    else if (typeof attr !== 'undefined' && attr !== false)
    {
      url = attr;
    }

    AppEmit('close_or_reopen_confirm', { url: url, data: form_data });
  });


  $('input.required_field').unbind('keypress.customer_form_field input.customer_form_field')
  .bind('keypress.customer_form_field input.customer_form_field', function(e) {
    AppEmit('validate_first_slide_form');
  });

  $('.search-content #search_input')
  .unbind('keyup').bind('keyup', function(e){
    e.stopPropagation();

    if(e.key == 'Enter'){
      AppEmit('search_text');
    } 
  });

  $('.search-content .input-group-text')
  .unbind('click').bind('click', function(e){
    e.preventDefault();
    AppEmit('search_text');
  });


  $('form.subscription_option_form .valid_subscription_edit').unbind('click').bind('click', function(e){
    e.preventDefault();

    AppLoading('show');

    $('form.subscription_option_form').find('.clonable_fields').remove();
    $('form.subscription_option_form').submit();
  });

  $('.td-popover').mouseover(function() {
    $(this).find('.popover_content_customer').show();
  })
  .mouseout(function() {
    $(this).find('.popover_content_customer').hide();
  });
}


jQuery(function() {
  AppListenTo('window.application_auto_rebind', (e)=>{ bind_customer_events(); }) ;
});