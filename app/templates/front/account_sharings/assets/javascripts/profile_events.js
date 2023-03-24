function bind_account_sharings_profile_events(){
  $('.modal#account-sharing-new button.validate').unbind('click').bind('click', function(e){ AppEmit('account_sharings_new'); });
  $('.modal#account-sharing-new-request button.validate').unbind('click').bind('click', function(e){ AppEmit('account_sharings_new_request'); });
}

jQuery(function() {
  AppListenTo('window.application_auto_rebind', (e)=>{ bind_account_sharings_profile_events() }); 
});