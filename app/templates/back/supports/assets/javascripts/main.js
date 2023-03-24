function bind_all_events(){
  $('#get_retriever').unbind('click').bind('click', function(e){
    let action = "get_retriever";
    let type   = "POST";
    let datas  = { user_code: $('input.user_code').val() };

    AppEmit('get_retriever', { 'action': action, "type": type, "datas": datas });
  });

  $('.resume_me').unbind('click').bind('click', function(e){
    let action = "resume_me";
    let type   = "POST";
    let datas  = { retriever_id: $(this).data('retriever-id') };

    if (confirm('Voulez-vous vraiment efféctuer cette action ? ')){
      AppEmit('resume_me', { 'action': action, "type": type, "datas": datas });
    }
  });

  $('.toggle').unbind('click').bind('click', function(e){
    let action = $(this).data('action');

    $('.box .result.' + action).toggle('');
  });

  $('.view_bank_accounts').unbind('click').bind('click', function(e){
    let retriever_id = $(this).data('retriever-id');
    let title        = $(this).data('title');
    let action       = "get_bank_accounts";
    let type         = "POST";
    let datas        = { retriever_id: retriever_id };

    AppEmit('get_bank_accounts', {'action': action, "type": type, "datas": datas, "title": title });
  });

  $('#get_operations').unbind('click').bind('click', function(e){
    let action = "get_operations";
    let type   = "GET";
    let datas  = $("form#operation-filter").serializeObject();
    
    AppEmit('get_operations', { 'action': action, "type": type, "datas": datas });
  });

  $('#get_pieces').unbind('click').bind('click', function(e){
    $('.check-action').hide();
    let action = "get_pieces";
    let type   = "GET";
    let datas  = { piece_name: $('input.piece_name').val(), pack_piece_name: $('input.pack_piece_name').val(), preseizure_date: $('input.preseizure_date').val()};

    if ($('input.piece_name').val() != "" || $('input.pack_piece_name').val() != "" || $('input.preseizure_date').val() != "" ){
      AppEmit('get_pieces', { 'action': action, "type": type, "datas": datas });
    }    
  });

  $('#get_preseizures').unbind('click').bind('click', function(e){
    $('.check-action').hide();
    let action = "get_preseizures";
    let type   = "GET";
    let datas  = $("form#piece-filter").serializeObject();
    
    AppEmit('get_preseizures', { 'action': action, "type": type, "datas": datas });
  });

  $('#generate_mail').unbind('click').bind('click', function(e){
    let action = "generate_mail";
    let type   = "GET";
    let datas  = $("form#users-filter").serializeObject();

    AppEmit('generate_mail', { 'action': action, "type": type, "datas": datas });
  });

  
  $('#get_flux_bridge').unbind('click').bind('click', function(e){
    let action = "get_flux_bridge";
    let type   = "GET";
    let datas  = $("form#bridge-filter").serializeObject();

    AppEmit('get_flux_bridge', { 'action': action, "type": type, "datas": datas });
  });
  
  $('#get_ba_free').unbind('click').bind('click', function(e){
    let action = "get_ba_free";
    let type   = "GET";
    let datas  = $("form#bridge-filter").serializeObject();

    AppEmit('get_ba_free', { 'action': action, "type": type, "datas": datas });
  });
  
  $('#get_transaction_free').unbind('click').bind('click', function(e){
    let action = "get_transaction_free";
    let type   = "GET";
    let datas  = $("form#bridge-filter").serializeObject();

    AppEmit('get_transaction_free', { 'action': action, "type": type, "datas": datas });
  });

  $('#get_temp_document').unbind('click').bind('click', function(e){
    let action = "get_temp_document";
    let type   = "GET";
    let datas  = $("form#temp_document-filter").serializeObject();

    AppEmit('get_temp_document', { 'action': action, "type": type, "datas": datas });
  });
  
  $('#set_delivery_external').unbind('click').bind('click', function(e){
    let action = "set_delivery_external";
    let type   = "POST";
    let datas  = $("form#external-filter").serializeObject();

    AppEmit('set_delivery_external', { 'action': action, "type": type, "datas": datas });
  });

  $('.switch').unbind('click').bind('click', function(e){
    let action = "switch";
    let type   = "POST";
    let datas  = { user_code: $('input.user_code').val(), to: $(this).data('action') };

    if (confirm('Voulez-vous vraiment efféctuer cette action ? ')){
      AppEmit('switch', { 'action': action, "type": type, "datas": datas });
    }
  });

  $('.check-all').bind('click', function(e){
    let checked  = $(this).is(':checked');
    let to_check = $(this).data('action');

    $('.check-' + to_check).prop('checked', checked);

    if (checked){
      $("#"+ to_check +"-check-action").show();
    }
    else{
      $("#"+ to_check +"-check-action").hide();
    }
  });

  $('.check').bind('click', function(e){
    let checked = $(this).is(':checked');
    let to_check = $(this).data('action');

    if ($('.check-'+ to_check +':checked').length > 0){
      $("#"+ to_check +"-check-action").show();
    }
    else{
      $("#"+ to_check +"-check-action").hide();
    }
  });
  
  $('.resend_operation').unbind('click').bind('click', function(e){
    let action = "resend_operation";
    let type   = "POST";
    let datas  = { ids: [$(this).data('operation-id')], to: $(this).data('action') };

    if (confirm('Voulez-vous vraiment efféctuer cette action ? ')){
      AppEmit('resend_operation', { 'action': action, "type": type, "datas": datas });
    }
  });

  $('#operation-check-action').unbind('click').bind('click', function(e){
    let ids    = []
    $('.check-operation:checked').each(function(){ ids.push($(this).val()) })
    let action = "resend_operation";
    let type   = "POST";
    let datas  = { ids: ids };

    if (confirm('Voulez-vous vraiment efféctuer cette action ? ')){
      AppEmit('resend_operation', { 'action': action, "type": type, "datas": datas });
    }
  });

  $('.resend_to_preassignment').unbind('click').bind('click', function(e){
    let action = "resend_to_preassignment";
    let type   = "POST";
    let datas  = { ids: [$(this).data('piece-id')], to: $(this).data('action') };

    if (confirm('Voulez-vous vraiment efféctuer cette action ? ')){
      AppEmit('resend_to_preassignment', { 'action': action, "type": type, "datas": datas });
    }
  });

  $('#piece-check-action').unbind('click').bind('click', function(e){
    let ids    = []
    $('.check-piece:checked').each(function(){ ids.push($(this).val()) })
    let action = "resend_to_preassignment";
    let type   = "POST";
    let datas  = { ids: ids };

    if (confirm('Voulez-vous vraiment efféctuer cette action ? ')){
      AppEmit('resend_to_preassignment', { 'action': action, "type": type, "datas": datas });
    }
  });

  $('#preseizure-check-action').unbind('click').bind('click', function(e){
    let ids    = []
    $('.check-preseizure:checked').each(function(){ ids.push($(this).val()) })
    let action = "resend_delivery";
    let type   = "POST";
    let datas  = { ids: ids };

    if (confirm('Voulez-vous vraiment efféctuer cette action ? ')){
      AppEmit('resend_delivery', { 'action': action, "type": type, "datas": datas });
    }
  });

  $('#temp_document-check-action').unbind('click').bind('click', function(e){
    let ids    = []
    $('.check-temp_document:checked').each(function(){ ids.push($(this).val()) })
    let action = "destroy_temp_document";
    let type   = "POST";
    let datas  = { ids: ids };

    if (confirm('Voulez-vous vraiment efféctuer cette action ? ')){
      AppEmit('destroy_temp_document', { 'action': action, "type": type, "datas": datas });
    }
  });

  $('.destroy_temp_document').unbind('click').bind('click', function(e){
    let action = "destroy_temp_document";
    let type   = "POST";
    let datas  = { ids: [$(this).data('temp-document-id')], to: $(this).data('action') };

    if (confirm('Voulez-vous vraiment efféctuer cette action ? ')){
      AppEmit('destroy_temp_document', { 'action': action, "type": type, "datas": datas });
    }
  });
  
  $('.delete_fingerprint_temp_document').unbind('click').bind('click', function(e){
    let action = "delete_fingerprint_temp_document";
    let type   = "POST";
    let datas  = { ids: [$(this).data('temp-document-id')], to: $(this).data('action') };

    if (confirm('Voulez-vous vraiment efféctuer cette action ? ')){
      AppEmit('delete_fingerprint_temp_document', { 'action': action, "type": type, "datas": datas });
    }
  });

  
  $('#generate_password').unbind('click').bind('click', function(e){
    let action = "generate_password";
    let type   = "POST";
    let datas  = { code_client: $('.user_code_password').val(), to: $(this).data('action') };

    if (confirm('Voulez-vous vraiment efféctuer cette action ? ')){
      AppEmit('generate_password', { 'action': action, "type": type, "datas": datas });
    }
  });
}

class AdminSupports {
  constructor(){
    this.applicationJS        = new ApplicationJS;    
    this.bank_utilities_modal = $('#bank_utlities.modal');   
  }

  supports(action, type, datas, modal_title=""){
    let self = this;

    action = action.selector;
    type   = type.selector;
    datas  = datas[0];

    $('.result').addClass('hide');
    $('.box .result.' + action).removeClass('hide');    

    self.ajax_params =  {
                          url: "/admin/supports/" + action,
                          type: type,
                          datatype: 'html',
                          data: datas,
                        }

    self.applicationJS.sendRequest(self.ajax_params)
                       .then((data)=>{
                          if (modal_title != ""){
                            $('#bank_utlities.modal').find('.modal-title').html(modal_title);

                            $('#bank_utlities.modal').find('.modal-body').html(data);

                            $('#bank_utlities.modal').modal('show');
                          }
                          else{
                            $('.box .result.' + action).html(data).show('');
                          }

                          bind_all_events();
                        })
                       .catch((e)=>{ console.log(e); });
  }
}

jQuery(function() {
  let abu = new AdminSupports();

  bind_all_events();

  AppListenTo('get_retriever', (e)=>{ abu.supports( $(e.detail.action), $(e.detail.type), $(e.detail.datas) ); });
  AppListenTo('resume_me', (e)=>{ abu.supports( $(e.detail.action), $(e.detail.type), $(e.detail.datas) ); });
  AppListenTo('get_bank_accounts', (e)=>{ abu.supports( $(e.detail.action), $(e.detail.type), $(e.detail.datas), $(e.detail.title) ); });
  AppListenTo('get_operations', (e)=>{ abu.supports( $(e.detail.action), $(e.detail.type), $(e.detail.datas) ); });
  AppListenTo('switch', (e)=>{ abu.supports( $(e.detail.action), $(e.detail.type), $(e.detail.datas) ); });
  AppListenTo('resend_operation', (e)=>{ abu.supports( $(e.detail.action), $(e.detail.type), $(e.detail.datas) ); });
  AppListenTo('get_pieces', (e)=>{ abu.supports( $(e.detail.action), $(e.detail.type), $(e.detail.datas) ); });
  AppListenTo('get_preseizures', (e)=>{ abu.supports( $(e.detail.action), $(e.detail.type), $(e.detail.datas) ); });
  AppListenTo('get_bank_accounts_bridge', (e)=>{ abu.supports( $(e.detail.action), $(e.detail.type), $(e.detail.datas) ); });
  AppListenTo('resend_to_preassignment', (e)=>{ abu.supports( $(e.detail.action), $(e.detail.type), $(e.detail.datas) ); });
  AppListenTo('resend_delivery', (e)=>{ abu.supports( $(e.detail.action), $(e.detail.type), $(e.detail.datas) ); });
  AppListenTo('get_flux_bridge', (e)=>{ abu.supports( $(e.detail.action), $(e.detail.type), $(e.detail.datas) ); });
  AppListenTo('get_ba_free', (e)=>{ abu.supports( $(e.detail.action), $(e.detail.type), $(e.detail.datas) ); });
  AppListenTo('get_transaction_free', (e)=>{ abu.supports( $(e.detail.action), $(e.detail.type), $(e.detail.datas) ); });
  AppListenTo('get_temp_document', (e)=>{ abu.supports( $(e.detail.action), $(e.detail.type), $(e.detail.datas) ); });
  AppListenTo('destroy_temp_document', (e)=>{ abu.supports( $(e.detail.action), $(e.detail.type), $(e.detail.datas) ); });
  AppListenTo('delete_fingerprint_temp_document', (e)=>{ abu.supports( $(e.detail.action), $(e.detail.type), $(e.detail.datas) ); });
  AppListenTo('set_delivery_external', (e)=>{ abu.supports( $(e.detail.action), $(e.detail.type), $(e.detail.datas) ); });
  AppListenTo('generate_password', (e)=>{ abu.supports( $(e.detail.action), $(e.detail.type), $(e.detail.datas) ); });
  AppListenTo('generate_mail', (e)=>{ abu.supports( $(e.detail.action), $(e.detail.type), $(e.detail.datas) ); });
});