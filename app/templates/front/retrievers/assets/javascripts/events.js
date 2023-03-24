function bind_all_events(){
  $('.retriever_actions .delete_connection').unbind('click');
  $('.retriever_actions .delete_connection').bind('click', function(e){
    AppEmit('budgeaApi.user_changed', { user_id: $(this).attr('data-user-id') }).then((e)=>{
      setTimeout((f)=>{ AppEmit('retriever_delete_connection', { id: $(this).data('id') }); }, 2000);
    });
  });

  $('.retriever_actions .trigger_connection').unbind('click');
  $('.retriever_actions .trigger_connection').bind('click', function(e){
    AppEmit('budgeaApi.user_changed', { user_id: $(this).attr('data-user-id') }).then((e)=>{
      setTimeout((f)=>{ AppEmit('retriever_trigger_connection', { id: $(this).data('id') }); }, 2000);
    });
  });

  $('.retriever_actions .edit_connection').unbind('click');
  $('.retriever_actions .edit_connection').bind('click', function(e){    
    if($(this).data('banking-provider') == 'budgea'){
      AppEmit('budgeaApi.user_changed', { user_id: $(this).attr('data-user-id') }).then((e)=>{
        setTimeout((f)=>{ AppEmit('retriever_edit_connection', { retriever: $(this).data('retriever') }); }, 2000);
      });
    }
    else{
      AppEmit('retriever_specific_setup', { banking_provider: 'internal', retriever_id: $(this).data('retriever')['id'] });
    }
  });


  $('.action.sub-menu-bank-param').unbind('click');
  $(".action.sub-menu-bank-param").bind('click',function(e) {
    e.stopPropagation();

    if ($(this).find('.sub_menu').hasClass('hide')){
      $(this).find('.sub_menu').removeClass('hide');
    }
    else {
      $(this).find('.sub_menu').addClass('hide');
    }
  });

  $('.create-manual-bank-account').unbind('click');
  $(".create-manual-bank-account").bind('click',function(e) {
    e.stopPropagation()

    $('#create-bank-account').modal('show');
  });

  $('.retriever-filter-others').unbind('click');
  $(".retriever-filter-others").bind('click',function(e) {
    e.stopPropagation()

    $('#filter-'+ $(".tab-pane.active").attr('id')).modal('show');
  });

  $('.retriever-filter').unbind('click');
  $(".retriever-filter").bind('click',function(e) {
    e.stopPropagation()

    $('#filter-retriever').modal('show');
  });

  $('.add-retriever').unbind('click');
  $(".add-retriever").bind('click',function(e) {
    e.stopPropagation();
    AppEmit('retriever_edit_connection', { retriever: null });
  });

  $('.add-bridge-retriever').unbind('click');
  $(".add-bridge-retriever").bind('click',function(e) {
    e.stopPropagation();
    AppEmit('retriever_specific_setup', { banking_provider: 'bridge' });
  });

  $('.add-internal-retriever').unbind('click');
  $(".add-internal-retriever").bind('click',function(e) {
    e.stopPropagation();
    AppEmit('retriever_specific_setup', { banking_provider: 'internal' });
  });

  $('.modal#add-internal-retriever button.validate').unbind('click');
  $('.modal#add-internal-retriever button.validate').bind('click', function(e){
    e.stopPropagation();
    AppEmit('retriever_specific_setup_validate', { banking_provider: 'internal' });
  });


  $('.sub-menu-bank-param li.edit').unbind('click');
  $(".sub-menu-bank-param li.edit").bind('click',function(e) {
    e.stopPropagation()

    $('#edit-bank-account').modal('show');
  });

  $('span.chevron-show').unbind('click');
  $('span.chevron-show').bind('click',function(e) {
    e.stopPropagation();
    var id = $(this).attr('id');
    
    if ($(this).children().hasClass('rotate')){      
      $(this).children().removeClass('rotate').addClass('rotate-reset');
      $('.more-'+id).hide('');
    }
    else{
      $(this).children().removeClass('rotate-reset').addClass('rotate');
      $('.more-'+id).show('');
    }    
  });

  $('.list-retriever').unbind('click');
  $(".list-retriever").bind('click',function(e) {
    AppEmit('retrievers_list');
  });

  $('ul.retriever-index li a').unbind('click');
  $('ul.retriever-index li a').bind('click', function(e){
    e.preventDefault();
    AppEmit('retrievers_list_filter', { pattern: $(this).data('index') });
  });

  $('#connectors-list #export_connectors').unbind('click');
  $('#connectors-list #export_connectors').bind('click', function(e){
    e.preventDefault();
    AppEmit('retrievers_list_export');
  });

  $('select#account_id').unbind('change');
  $('select#account_id').bind('change', function(e){ AppEmit('budgeaApi.user_changed', { user_id: $(this).val() }); AppEmit('retriever_reload_all'); });

  $('#filter-retriever #filter_button').unbind('click');
  $('#filter-retriever #filter_button').bind('click', function(e){ $('#filter-retriever').modal('hide'); AppEmit('retriever_reload_all') });

  $('#filter-retriever #filter_cancel').unbind('click');
  $('#filter-retriever #filter_cancel').bind('click', function(e){ $('#filter-retriever').modal('hide'); $('#filter-retriever #search_name').val(''); $('#filter-retriever #search_state').val(''); AppEmit('retriever_reload_all') })

  $('#add-retriever .step1 #choose-selector').unbind('change');
  $('#add-retriever .step1 #choose-selector').bind('change', function(e){
    AppEmit('add_retriever_search_connector');
  });

  $('#add-retriever .step1 #connector-search-name').unbind('keyup');
  $('#add-retriever .step1 #connector-search-name').bind('keyup', function(e){
    AppEmit('add_retriever_search_connector');
  });

  $('#add-retriever .step1 select#connectors-list').unbind('change');
  $('#add-retriever .step1 select#connectors-list').bind('change', function(e){
    AppEmit('add_retriever_connector_selection');
  });

  $('#add-retriever button.primary').unbind('click');
  $('#add-retriever button.primary').bind('click', function(e){
    AppEmit('add_retriever_primary_action');
  });

  $('#add-retriever button.secondary').unbind('click');
  $('#add-retriever button.secondary').bind('click', function(e){
    AppEmit('add_retriever_secondary_action');
  });

  $(".more-result").unbind('click').bind('click', function(e){ $(this).hide('fast'); AppEmit('documents_next_page'); })
}

jQuery(function() {
  AppListenTo('window.application_auto_rebind', (e)=>{ bind_all_events() });

    /* SCROLLING TO THE BOTTOM */
  var end_reached = true;
  $('.body_content').scroll(function() {
    let content_h  = $('.body_content').outerHeight();
    let content    = document.getElementsByClassName("body_content")[0];
    let c_position = content.scrollHeight - content.scrollTop

    const show_hide_more_result = (action)=>{
      if(action == 'show'){
        $('.more-result').show('fast');
      }else{
        // $('.more_result_button').hide('slow');
        $('.more-result').hide('fast');
      }
    }

    if( c_position >= (content_h + 75) ){
      end_reached = false
      show_hide_more_result('hide');
    }else if(!end_reached){
      end_reached = true;
      show_hide_more_result('show');
    }
  });
});