function bind_all_events(){
  $('select#account_id').unbind('change');
  $('select#account_id').bind('change', function(e){ AppEmit('budgeaApi.user_changed', { user_id: $(this).val() }); AppEmit('retriever_parameters_reload_all') });

  $('.action.sub-menu-bank-param').unbind('click');
  $(".action.sub-menu-bank-param").bind('click',function(e) {
    e.stopPropagation();

    if ($(this).find('.sub_menu').hasClass('hide')){
      $(this).find('.sub_menu').removeClass('hide')
    }
    else {
      $(this).find('.sub_menu').addClass('hide')
    }
  });

  $('.create-manual-bank-account').unbind('click')
  $(".create-manual-bank-account").bind('click',function(e) {
    AppEmit('retriever_bank_edition', { id: 0 });
  });

  $('.retriever-filter-others').unbind('click')
  $(".retriever-filter-others").bind('click',function(e) {
    e.stopPropagation()

    $('#filter-'+ $(".tab-pane.active").attr('id')).modal('show');
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

  $('#retriever_selector').unbind('change');
  $('#retriever_selector').bind('change', function(e){ AppEmit('retriever_change_retriever_selection', { budgea_id: $(this).val() }); });

  $('.tab-pane#banks-selection .validate_banks_selection').unbind('click');
  $('.tab-pane#banks-selection .validate_banks_selection').bind('click', function(e){ AppEmit('retriever_validate_retriever_selection'); });

  $('table.banks_params_list tbody td .action .activation').unbind('click').bind('click', function(e){
    AppEmit('retriever_bank_activation', { id: $(this).data('id'), type: $(this).data('type') });
  });

  $('table.banks_params_list tbody td .action .edit').unbind('click').bind('click', function(e){
    AppEmit('retriever_bank_edition', { id: $(this).data('id') });
  });

  $('#integrate_documents').unbind('click').bind('click', (e)=>{ AppEmit('retriever_integrate_documents'); });

  $('.modal#filter-banks-selection button.validate').unbind('click').bind('click', (e)=>{ AppEmit('retriever_parameters_filter_page', { target: 'banks-selection', action: 'validate'}); });
  $('.modal#filter-documents-selection button.validate').unbind('click').bind('click', (e)=>{ AppEmit('retriever_parameters_filter_page', { target: 'documents-selection', action: 'validate'}); });
  $('.modal#filter-banks-params button.validate').unbind('click').bind('click', (e)=>{ AppEmit('retriever_parameters_filter_page', { target: 'banks-params', action: 'validate'}); });

  $('.modal#filter-banks-selection button.cancel').unbind('click').bind('click', (e)=>{ AppEmit('retriever_parameters_filter_page', { target: 'banks-selection', action: 'reset'}); });
  $('.modal#filter-documents-selection button.cancel').unbind('click').bind('click', (e)=>{ AppEmit('retriever_parameters_filter_page', { target: 'documents-selection', action: 'reset'}); });
  $('.modal#filter-banks-params button.cancel').unbind('click').bind('click', (e)=>{ AppEmit('retriever_parameters_filter_page', { target: 'banks-params', action: 'reset'}); });

  $('li.navigation_links').unbind('click.need_filter').bind('click.need_filter', function(e){
    if($(this).hasClass('no-filter')){
      $('button.filter-banks').addClass('hide');
    }else{
      $('button.filter-banks').removeClass('hide');
    }
  });

  $('.check-all-bank-account').unbind('click').bind('click', function(e){
    $('input.selected_document').prop('checked', $('.check-all-bank-account').is(':checked') );
  });

  $('input.selected_document').unbind('click').bind('click', function(e){
    $('.check-all-bank-account').prop('checked', false);
  });

  $('.do-showDocument').unbind('click').bind('click', function(e){
    $('#retrieved_document.modal').find('.modal-body iframe#retrieved-document').attr('src', $(this).attr('data-url'));
    $('#retrieved_document.modal').modal('show');
  });
}

jQuery(function() {
  AppListenTo('window.application_auto_rebind', (e)=>{  bind_all_events(); })
});