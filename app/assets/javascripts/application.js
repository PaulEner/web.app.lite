//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require popper
//= require bootstrap
//= require chart.min
//= require jquery.qtip.min
//= require help
//= require jquery.tokeninput.min
//= require jquery.livequery.min
//= require jquery_nested_form
//= require file-uploader/vendor/jquery.ui.widget
//= require file-uploader/fileupload-tpl
//= require file-uploader/fileupload-load-image
//= require file-uploader/fileupload-canvas-to-blob
//= require file-uploader/fileupload-blueimp-gallery
//= require file-uploader/jquery.iframe-transport
//= require file-uploader/jquery.fileupload
//= require file-uploader/jquery.fileupload-process
//= require file-uploader/jquery.fileupload-image
//= require file-uploader/jquery.fileupload-validate
//= require file-uploader/jquery.fileupload-ui
//= require file-uploader/cors/jquery.xdr-transport
//= require file-uploader/main
//= require shift_selectable
//= require searchable-option-list
//= require chosen.jquery
//= require bootstrap-filestyle.min
//= require bootstrap-datepicker/core
//= require retractable
//= require jquery.multi-select
//= require moment
//= require daterangepicker
//= require custom_popover
//= require app_listener
//= require bootstrap-tagsinput

/********** GLOBAL VARIABLES ********/
  var GLOBAL = {}
  var VARIABLES = {}
  var VARS = {}

  VARIABLES.set = (var_name, value) => {
    VARS[var_name] = value;
  }

  VARIABLES.get = (var_name) => {
    return VARS[var_name];
  }


/*********** JQuery mixing *********************/
  $.fn.asDateRange = function(option={}){
    $.each(this, function(e){
      let el = $(this);

      if( !el.hasClass('mixed-to-date-range') ){
        let initial_value = el.val();
        let is_deleted    = false;

        el.daterangepicker(option);
        el.addClass('mixed-to-date-range');

        if( el.hasClass('notblank') ){
          //daterangepicker set an automatic date
        }
        else{
          if(option.defaultBlank && option.defaultBlank == true){
            if(initial_value == undefined || initial_value == '' || initial_value == null)
              el.val('');

            el.unbind('keyup.custom_keyup_date').bind('keyup.custom_keyup_date', function(e){
              if(el.val() == '' || el.val() == undefined || el.val() == null)
                is_deleted = true;
              else
                is_deleted = false;
            });

            el.unbind('blur.custom_blur_date').bind('blur.custom_blur_date', function(e){
              if(is_deleted){
                el.val('');
                is_deleted = false;
              };
            });
          }
        }
      }
    });
  }

  $.fn.asMultiSelect = function(options={}){
    $.each(this, function(e){
      let el = $(this);
      if( !el.hasClass('mixed-to-multi') ){
        el.searchableOptionList(options);
        el.addClass('mixed-to-multi');
      }
    });
  }


  $.fn.asChosenList = function(options={}){
    if( !this.hasClass('mixed-to-chosen') ){
      this.chosen(options);
      this.addClass('mixed-to-chosen');
    }
  }

  $.fn.serializeObject = function(strict=false){
    var o = {};
    var a = this.serializeArray();

    try{
      $.each(a, function(){
        const inject = (obj, name)=>{
          if(name.match(/\[\](.+)/))
          {
            if(strict && this.value)
              obj[name] = this.value;
            else if(!strict)
              obj[name] = this.value;
          }
          else if(name.match(/\[\]$/)){
            let obj_index = name.replace(/\[\]/g, '');

            if(this.value != undefined && this.value != '' && this.value != null){
              try{
                obj[obj_index].push(this.value);
              }catch(e){
                obj[obj_index] = [this.value];
              }
            }
          }
          else
          {
            let splited = name.split('[');
            let c_name  = splited[0].replace(']', '');

            if(splited.length > 1)
            {
              if(obj[c_name] == undefined || obj[c_name] == null)
                obj[c_name] = {};

              splited.shift();
              inject(obj[c_name], splited.join('['));
            }
            else
            {
              if(strict && this.value)
                obj[c_name] = this.value;
              else if(!strict)
                obj[c_name] = this.value;
            }
          }
        }

        inject(o, this.name);
      });
    }catch(err){
      console.error(err);
    }

    return o;
  };


  $.fn.readOnlyAdmin = function(options={}){
    if( this.hasClass('readonly-trigger')){
      let is_super_admin = VARIABLES.get('is_super_admin');
      let full_access    = VARIABLES.get('full_access')

      if (is_super_admin == 'false' || full_access == 'false')
      {
        $('.readonly-container').empty();
        $('.readonly-link-container a').attr("href", '#')
        $('.readonly-link-container input').prop( "disabled", true );
      }
    }
  }


/******************* GLOBAL FUNCTIONS *********************/
  AppDecode64 = (str_64) =>{
    try{
      //This is a workarround for decoding utf-8 encoded string from base64
      //WARNING: escape IS DEPRECATED: MAY NOT WORK ON CERTAIN BROWSER
      return decodeURIComponent( escape( atob(str_64) ) )
    }catch(e){
      return atob(str_64)
    }
  }

  AppParseVars = ()=>{
    $('span.js_var_setter').each(function(e){
      let name  = $(this).attr('id').replace('js_var_', '').trim();
      let value = $(this).text().trim();

      VARIABLES.set(name, AppDecode64(value));
    });
  }

  // Type must be 'show' or 'hide'
  AppLoading = (type='show') => {
    if(type == 'show'){
      $('div.loading_box').addClass('force');
      $('div.loading_box').removeClass('hide');
    }
    else{
      $('div.loading_box').removeClass('force');
      $('div.loading_box').addClass('hide');
    }
  }

  SetCache = (name, value, lifeTime) => {
    localStorage[name] = JSON.stringify({ dataSet: value, timeSet: new Date().getTime(), lifeTime: (lifeTime || 30) }) //lifeTime in minutes
  }

  GetCache = (name) => {
    if(localStorage[name] == undefined || localStorage[name] == '' || localStorage[name] == null){
      console.log('init')
      return ''
    }else{
      let dataCache = JSON.parse(localStorage[name])
      let dataSet = dataCache.dataSet
      let lifeTime = dataCache.lifeTime
      let timeSet = dataCache.timeSet

      if( (dataSet == undefined || dataSet == '' || dataSet == null) || (lifeTime == undefined || lifeTime == '' || lifeTime == null) ){
        return ''
      }else{
        let endTime = new Date().getTime()
        let timeDiff = ((endTime - timeSet) / 1000) / 60 //timeDiff in minutes

        if(timeDiff >= lifeTime){
          console.log('reset')
          return ''
        }else{
          console.log('cache')
          return dataSet
        }
      }
    }
  }


/************************ MAIN CLASS ********************************/
class ApplicationJS {
  constructor(){
    AppParseVars();
    // console.log( "Controller: " + VARIABLES.get('controller_path') );
    console.log( "Env: " + VARIABLES.get('rails_env') );
  }

  noticeAllMessageFrom(page=null){
    this.noticeSuccessMessageFrom(page);
    this.noticeErrorMessageFrom(page);
  }

  noticeSuccessMessageFrom(page=null, message = null){
    var html = message;
    var is_present = "";
    if(message)
    {
      is_present = 'true';
    }
    else if(page)
    {
      html = $(page).find('.notice-internal-success').html();
      is_present = $(page).find('.notice-internal-success .msg_present');
    }

    if(is_present.length > 0){
      $('#idocus_notifications_messages .notice-internal-success').html(html);

      $('#idocus_notifications_messages .notice-internal-success').slideDown('fast');
      setTimeout(function(){$('.notice-internal-success').fadeOut('');}, 5000);
    }
  }

  noticeErrorMessageFrom(page=null, message=null , danger=false){
    var html = message;
    var is_present = "";

    var used_alert = '#idocus_notifications_messages .notice-internal-error .alert.alert-warning';
    var not_used_alert = '#idocus_notifications_messages .notice-internal-error .alert.alert-danger';

    if(danger){
      used_alert = '#idocus_notifications_messages .notice-internal-error .alert.alert-danger';
      not_used_alert = '#idocus_notifications_messages .notice-internal-error .alert.alert-warning';
    }

    if(message)
    {
      is_present = 'true';
    }
    else if(page)
    {
      html = $(page).find(`${used_alert} .message-alert`).html();
      is_present = $(page).find(`${used_alert} .msg_present`);
    }

    if(html == '' || html == undefined || html == null)
      html = "Une erreur inattendue s'est produite. Veuillez réessayer ultérieurement";

    if(is_present.length > 0){
      $(not_used_alert).addClass('hide');
      $(used_alert).removeClass('hide');

      if(VARIABLES.get('rails_env') != 'production' || !danger)
        $(`${used_alert} .message-alert`).html(html);

      $('#idocus_notifications_messages .notice-internal-error').slideDown('fast');
      setTimeout(function(){ $('#idocus_notifications_messages .notice-internal-error').slideUp('fast'); }, 30000);
    }
  }

  sendRequest(params={}, beforeUpdateContent=function(e){}, afterUpdateContent=function(e){}){
    var self = this

    console.log(params.url);
    return new Promise((success, error) => {
      $.ajax({
        url: params.url,
        type: params.type || 'GET',
        data: params.data,
        contentType: params.contentType || 'application/x-www-form-urlencoded; charset=UTF-8',
        dataType: params.dataType || 'html',
        beforeSend: function(){
          if(params.no_loading !== true){
            if( !($('div.loading_box').hasClass('force')) )
              $('div.loading_box').removeClass('hide');
          }
        },
        success: function(result) {
          if (beforeUpdateContent) { beforeUpdateContent(); }

          let target      = params.target || null;
          let destination = params.target_dest || target || null;
          if(target)
          {
            let source_html = '';
            try{
              source_html = $(result).find(target)[0].outerHTML;
            }catch(e){
              let found = false;

              try{
                if(/^[.]/.test(target)){
                  if( $(result).hasClass(target.replace('.', '')) ){ found = true; source_html = $(result)[0].outerHTML; }
                }else if( /^[#]/.test(target) ){
                  if( $(result).attr('id') == target.replace('#', '') ){ found = true; source_html = $(result)[0].outerHTML; }
                }
              }
              catch(err){
                console.log(err);
              }

              // if(!found){
              //   window.setTimeout((el)=>{ window.location.reload(); }, 1000);
              // }
            }

            if(params.mode == 'append'){
              $(destination).append( source_html );
            }
            else if(params.mode == 'prepend'){
              $(destination).prepend( source_html );
            }
            else{
              if(target == destination)
                $(destination).replaceWith( source_html );
              else
                $(destination).html( source_html );
            }
          }

          if (afterUpdateContent) { afterUpdateContent(); }

          try{
            self.noticeAllMessageFrom(result);
          }catch(e){}

          try{
            if(result.json_flash.success){
              self.noticeSuccessMessageFrom(null, result.json_flash.success)
            }
          }catch(e){}

          try{
            if(result.json_flash.error){
              $('#idocus_notifications_messages .notice-internal-error .error_title').text('Attention');
              self.noticeErrorMessageFrom(null, result.json_flash.error)
            }
          }catch(e){}


          if(success)
            success(result);

          window.setTimeout((e)=>{ 
            if(params.no_loading !== true){
              if( !($('div.loading_box').hasClass('force')) )
                $('div.loading_box').addClass('hide');
            }
            bind_globals_events();
          }, 1000);
        },
        error: function(result){
          self.noticeErrorMessageFrom(null, result.responseText, true);

          if(success)
            success(result);

          window.setTimeout((e)=>{ 
            $('div.loading_box').addClass('hide');
            bind_globals_events();
          }, 1000);
        }
      });
    });
  }

  static launch_async(idocus_params={}){
    return new Promise((success, error)=>{
      let appJS           = new ApplicationJS();
      let url             = idocus_params['url'];
      let confirm_message = idocus_params['confirm'];
      let skip_ajax       = idocus_params['skip_ajax'] || false;

      if( !skip_ajax && url && url != '#' )
      {
        let type        = idocus_params['method'] || 'GET';
        let ajax_params = {
                            url: url,
                            type: type,
                          }
        //parsing content-type
          if(idocus_params['content_type']){
            ajax_params['contentType'] = idocus_params['content_type']
          }

        //parsing HTML parameter
          ajax_params['dataType'] = 'json';
          if(idocus_params['html'] && idocus_params['html']['target']){
            ajax_params['dataType'] = 'html';
            ajax_params['target']      = idocus_params['html']['target'];
            ajax_params['target_dest'] = idocus_params['html']['target_dest'] || ajax_params['target'];
            ajax_params['mode']        = idocus_params['html']['mode'];
          }

        //parsing form and datas parmeter
          let form_data = {};
          if(idocus_params['form'] && idocus_params['form']['id'])
          {
            let form      = $(`form#${idocus_params['form']['id']}`);

            if(form)
            {
              if(idocus_params['form']['linear'] === true)
              {
                form_data = form.serialize();
              }
              else
              {
                if(ajax_params['dataType'] == 'json')
                  form_data = form.serializeObject(); //serialize as json
                else
                  form_data = form.serialize(); //serialize as url params
              }

              if(idocus_params['form']['dump_action'] === true){
                ajax_params['url'] = form.attr('action');

                if(form.attr('method'))
                  ajax_params['type'] = form.attr('method');
              }

              // Validate the from
              if(idocus_params['form']['validate'] !== false){
                let errors = [];
                form.find("input,textarea,select").filter('[required]:visible').each(function(e){
                  if($(this).val() == undefined || $(this).val() == null || $(this).val().trim() == ''){
                    $(this).parents().each((a, parent)=>{
                      if( $(parent).hasClass('form-group') ){
                        let label = $(parent).find('label').text();
                        errors.push( `<strong>${ label || $(this).attr('name') }</strong>: est vide.` );
                        return false; //break
                      }
                    });
                  }
                });

                if(errors.length > 0){
                  appJS.noticeErrorMessageFrom(null, '<ul class="errors_list"><li class="error_element">' + errors.join('</li><li class="error_element">') + '</li></ul>');
                  error();
                  return false;
                }
              }
            }
          }

          if(idocus_params['datas'] && ajax_params['dataType'] == 'json'){
            let new_datas = {}

            try{
              new_datas = JSON.parse(idocus_params['datas']) || {};
            }catch(e){
              new_datas = idocus_params['datas'] || {};
            }

            if(typeof(form_data) === 'object')
              form_data = Object.assign( form_data, new_datas );
          }

          if(form_data){ ajax_params['data'] = form_data; }

        appJS.sendRequest(ajax_params)
              .then(e => {
                //Handling modal param
                if( idocus_params['modal'] && idocus_params['modal']['id'] )
                {
                  let modal_name = idocus_params['modal']['id']
                  if(modal_name == '#')
                    modal_name = 'general_idocus_main_modal';

                  let modal            = $(`.modal#${modal_name}`);
                  let close_on_success = (idocus_params['modal']['close_after_success'] === false)? false : true
                  let close_on_error   = idocus_params['modal']['close_after_error'] || false

                  if(e.json_flash){
                    if( close_on_success && e.json_flash.success ){ modal.modal('hide'); }
                    else if( close_on_error && e.json_flash.error ){ modal.modal('hide'); }
                  }else{
                    if( close_on_success ){ modal.modal('hide'); }
                    else if( close_on_error ){ modal.modal('hide'); }
                  }
                }

                //handle redirect_to param
                if( idocus_params['redirect_to'] && idocus_params['redirect_to']['url'] ){
                  ApplicationJS.launch_async( idocus_params['redirect_to'] ).then((e)=>{ success(e); }).catch(err=>{ error(err); });
                }
                else
                {
                  success(e);
                }
              })
              .catch(err => {
                //Handling modal param
                if( idocus_params['modal'] && idocus_params['modal']['id'] )
                {
                  let modal_name = idocus_params['modal']['id']
                  if(modal_name == '#')
                    modal_name = 'general_idocus_main_modal';

                  let modal          = $(`.modal#${modal_name}`);
                  let close_on_error = idocus_params['modal']['close_after_error'] || false
                  if( close_on_error ){ modal.modal('hide'); }
                }

                success(err)
              });
      }
      else
      {
        if(skip_ajax)
          console.log("Ajax skipped");
        else
          console.log('Url not defined ... No request launched');

        success();
      }
    });
  }

  static set_checkbox_radio(that = null){
    let class_list = [];

    $('.input_switch').change(function() {
      class_list = $(this).attr('class').split(/\s+/);

      if ($(this).is(':checked')){
        $(this).attr('checked', true);

        if (class_list.indexOf("input_check_field") > -1 || class_list.indexOf("check-software") > -1) { $(this).closest('.form-check.form-switch').find('label.label_check_field').text('Oui'); }
        else { $(this).parent().find('label').text('Oui'); }

        if ((class_list.indexOf("check-software") > -1) || (class_list.indexOf("filter-customer") > -1)) { $(this).attr('value', 1); }
        else { $(this).attr('value', true); }

        if (class_list.indexOf("option_checkbox") > -1) { $(this).addClass('active_option'); }

      }
      else {
        $(this).attr('checked', false);

        if (class_list.indexOf("input_check_field") > -1 || class_list.indexOf("check-software") > -1) { $(this).closest('.form-check.form-switch').find('label.label_check_field').text('Non'); }
        else { $(this).parent().find('label').text('Non'); }

        if ((class_list.indexOf("check-software") > -1) || (class_list.indexOf("filter-customer") > -1)) { $(this).attr('value', 0); }
        else { $(this).attr('value', false); }

        if (class_list.indexOf("option_checkbox") > -1) { $(this).removeClass('active_option'); }
      }
    });

    if ($('.input_switch:checked').length > 0) {
      const selected = $('.input_switch:checked');

      $.each(selected, function() {
        class_list = $(this).attr('class').split(/\s+/);
        let element = $(this);

        if (class_list.indexOf("input_check_field") > -1 || class_list.indexOf("check-software") > -1) {
          element = $('.input_check_field.input_switch:checked, .check-software.input_switch:checked');
          element.closest('.form-check.form-switch').find('label.label_check_field').text('Oui');
        }
        else {
          element.parent().find('label').text('Oui');
        }
      });
    }
  }
}

jQuery(function () { AppParseVars() });