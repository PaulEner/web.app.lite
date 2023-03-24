function bind_account_sharings_organization_events(){
  $('#account_sharings .btn.share_account_btn').unbind('click').bind('click', function(e){ AppEmit('account_sharings_add_account'); });

  $('#guest_collaborators .edit_contact').unbind('click').bind('click', function(e){ AppEmit('account_sharings_edit_contact', { id: $(this).data('id') }); });

  $('.modal#account-sharing button.validate').unbind('click').bind('click', function(e){ AppEmit('account_sharings_validate_sharing'); });

  $('.account_sharings_filter').unbind('click').bind('click',function(e) {
    e.stopPropagation();

    $('#filter_'+ $(".tab-pane.active").attr('id')).modal('show');
  });
}

jQuery(function() {
  AppListenTo('window.application_auto_rebind', (e)=>{ bind_account_sharings_organization_events() });
});