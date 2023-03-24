function bind_all_events(){
  $('.retriever-filter-historic').unbind('click')
  $(".retriever-filter-historic").bind('click',function(e) {
    e.stopPropagation()

    $('#filter-'+ $(".tab-pane.active").attr('id')).modal('show');
  });

  $('select#account_id').unbind('change');
  $('select#account_id').bind('change', function(e){ AppEmit('budgeaApi.user_changed', { user_id: $(this).val() }); AppEmit('retrieved_datas_reload_all') });

  $('.modal button.validate-filter').unbind('click');
  $('#search-form .btn-search').bind('click', function(e){ AppEmit('retrieved_datas_filter', { type: $('#search-type').val() }) });
  $('#search-form .btn-reset').bind('click', function(e){ AppEmit('retrieved_datas_reset_filter', { type: $('#search-type').val() }) });

  $('.modal button.validate-filter').bind('click', function(e){ AppEmit('retrieved_datas_filter', { type: $(this).attr('data-target') }) });

  $('button.reset-filter').unbind('click');
  $('button.reset-filter').bind('click', function(e){ AppEmit('retrieved_datas_reset_filter', { type: $(this).attr('data-target') }) });

  $('.do-showDocument').unbind('click').bind('click', function(e){
    $('#retrieved_document.modal').find('.modal-body iframe#retrieved-document').attr('src', $(this).attr('data-url'));
    $('#retrieved_document.modal').modal('show');
  })

  $('.check-filter-form-view').unbind('click').bind('click', function(e){
    let type = $(this).attr('id').split('-')[0]
    $('#search-type').val(type);

    $('.content-search-form').hide('');
    $('#search-' + type).show('');

    $('.search-title #search-action').text($(this).data('bs-title').toLowerCase())
  })

  $('.show-calendar').unbind('click').bind('click',function(e) {
    e.stopPropagation();
    $('#'+$(this).attr('data-ref')).click();
  });

}

jQuery(function() {
  bind_all_events();
});