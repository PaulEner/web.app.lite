function bind_globals_events() {
  elements_initializer();
  iDocus_ajax_links();
  iDocus_pagination();

  $('.new-subscription').unbind('click').bind('click',function(e) {
    e.preventDefault();

    AppEmit('create_subscription_option');
  });

  $('.edit-subscription-option').unbind('click').bind('click',function(e) {
    e.preventDefault();

    AppEmit('edit_subscription_option', { id: $(this).data('id') });
  });
}