//= require '../application'
//= require '../dynamic_events'

function bind_globals_events(){
  AppParseVars();
  custom_dynamic_animation();
  custom_dynamic_height();
  elements_initializer();
  iDocus_event_emiter();
  iDocus_ajax_links();
  iDocus_dynamic_modals();
  iDocus_pagination();
  iDocus_sortable();

  AppEmit('window.application_auto_rebind');

  $('button.add-rule').unbind('click').bind('click',function(e) {
    e.stopPropagation();

    if ($(this).find('.sub_rule_menu').hasClass('hide')){
      $(this).find('.sub_rule_menu').removeClass('hide')
    }
    else {
      $(this).find('.sub_rule_menu').addClass('hide')
    }    
  });
}

jQuery(function () {
  bind_globals_events();

  calculate_footer_marginer();
  scrool_on_top();

  $('.back-notice-flush a.close').unbind('click').bind('click', function(e){
    let alerts = $('.back-notice-flush .alert');
    alerts.remove();
  });
});
