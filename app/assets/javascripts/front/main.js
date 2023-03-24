//= require '../application'
//= require '../dynamic_events'
//= require '../dynamic_hide_menu'

function init_menu_animation(){
  let to_animate = GetCache('menu_animation');

  //special menu animation : keep it here
  $('nav.navbar.main_menu').unbind('click.animation').bind('click.animation', function(){ SetCache('menu_animation', 'yes', 1); })

  if(to_animate != 'no'){
    let organization_lefter = $('.organizations .lefter');
    organization_lefter.find('ul li.direct_links').addClass('hide');
    $('.navbar.main_menu').addClass('showMenu');
    $('footer.main_footer').addClass('showFooter');

    if(organization_lefter.length > 0){
      let duration = 500;
      organization_lefter.find('ul li.direct_links').each(function(e){
        duration = duration + 150
        setTimeout((f)=>{
          $(this).addClass('derivationLeft');
          $(this).removeClass('hide');
        }, duration);
      });
    }

    SetCache('menu_animation', 'no', 60);
  }
}

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
  /************************************************************************************/ 
  /******* IMPORTANT : USE ONLY UNBIND AND BIND FORMAT EVENTS IN THIS METHODS *********/
  /************************************************************************************/
  /* Notice flash */
    $('span.close_error').unbind('click').bind('click', function(e){ $('.notice-internal-error').fadeOut('fast'); });

  /* SORTABLE */
    $('.as_idocus_sortable').unbind('click').bind('click', function(e){
      e.preventDefault();
      let url    = $(this).attr('href');
      let target = $(this).parents('table:first').attr('id');
      let app    = new ApplicationJS();

      let ajax_params = {
                          url: url,
                          type: 'GET',
                          dataType: 'html',
                          target: `#${target}`
                        };

      if(target == '' || target == undefined || target == null){
        console.error('The sortable link doesn t have a valid target (table id is missing ...)');
      }
      else{
        if(url != '' && url != '#' && url != undefined && url != null)
          app.sendRequest(ajax_params,'', bind_all_events);
      }
    });

  /* AS USER */
    $('a.as_user').unbind('click').bind('click', function(e){
      e.preventDefault();

      $('.as-user-with-overlay').show();    
      setTimeout(function(){$('.as-user-notification').slideDown('fast');}, 100);
    });

    $('.close_as_user_modal').unbind('click').bind('click', function(e){
      e.preventDefault();

      $('.as-user-notification').slideUp('fast');  
      setTimeout(function(){$('.as-user-with-overlay').hide();}, 300);
    });
  /* AS USER */

  $('button.add-rule').unbind('click').bind('click',function(e) {
    e.stopPropagation();

    if ($(this).find('.sub_rule_menu').hasClass('hide')){
      $(this).find('.sub_rule_menu').removeClass('hide')
    }
    else {
      $(this).find('.sub_rule_menu').addClass('hide')
    }    
  });

  let popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
  let popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
    return new bootstrap.Popover(popoverTriggerEl)
  });

  let tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
  let tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl)
  })


  AppEmit('window.application_auto_rebind');
}

function check_flash_messages(){
  let app = new ApplicationJS();
  app.noticeAllMessageFrom(document);
}

jQuery(function () {
  calculate_footer_marginer();

  init_menu_animation();

  bind_globals_events();

  ApplicationJS.set_checkbox_radio();

  check_flash_messages();

  /** Custom hide alert messages error **/
  AppListenTo('close_alert_errors', (e)=>{ $('.notice.notice-internal-error').slideUp('fast'); });

  /** Calculate footer marginer height **/
  $(window).resize(function(e){
    calculate_footer_marginer();
  })

  /* SCROLLING TO THE BOTTOM */
  scrool_on_top();
});