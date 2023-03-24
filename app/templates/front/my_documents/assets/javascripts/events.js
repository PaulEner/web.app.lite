function get_all_selected(obj = 'piece', get_preseizure_ids=false){
  let array_ids = [];
  let type      = (obj == 'operation')? 'operation' : 'document';

  $(`.form-check-input.select-${type}`).each(function(e){
    if($(this).is(':checked')){
      if(get_preseizure_ids && obj == 'piece'){
        let ids = JSON.parse($(this).attr('data-preseizure-ids') || '[]');
        ids.forEach((t)=>{
          if( t && t > 0 ){ array_ids.push(t) }
        });
      }else{
        let id = parseInt($(this).attr('data-id'));
        if(id > 0){ array_ids.push(id); }
      }
    }
  });

  return array_ids;
}

function bind_all_events(){
  $('#delivery-date.daterange, #invoice-date.daterange').val('');

  $('.date-edit-third-party').asDateRange({ defaultBlank: true, singleDatePicker: true, locale: { format: 'DD/MM/YYYY' }});

  $('#customer_document_filter').asMultiSelect({
    "texts" : { "searchplaceholder": "Choix dossiers", "noItemsAvailable": 'Aucun dossier trouvé'},
    "resultsContainer": '.result-sol',
    "maxHeight": "300px",
    "noneText": "Choix dossier",
  });

  $('#journal_document_filter').asMultiSelect({
    "noneText": "Choix journaux",
  });

  $('#period_document_filter').asMultiSelect({
    "noneText": "Choix",
  });

  $('.popup-info-rubric').mouseover(function(e) {
    $('.info-rubric-content').removeClass('hide') 
  }).mouseout(function(e) {
    $('.info-rubric-content').addClass('hide') 
  });


  $('input.input-tag').on('beforeItemAdd', function(event) {
    event.stopPropagation();
    AppEmit('new_update_tags', { piece_id: $(this).data('id'), tags: event.item, type: "piece" });
  });

  $('input.input-tag').on('beforeItemRemove', function(event) {
    event.stopPropagation();
    AppEmit('new_update_tags', { piece_id: $(this).data('id'), tags: '-' + event.item, type: "piece" });
  });

  $('input.input-tag').tagsinput('refresh');

  $('#add-document.modal .btn-close.upload').unbind('click').bind('click',function(e) {
    e.stopPropagation();

    if ($('.template-upload.fade.in').length > 0 ){
      $('#add-document.modal .info').show('');

      setTimeout(function(){ $('#add-document.modal .info').hide(''); }, 5000);
    }else{
      $('#add-document.modal').modal('hide');
    }
  });

  $('#customer_document_filter').unbind('change.mix_journal').bind('change.mix_journal', function(e){
    if ($('.user_and_journals').length > 0){
      let lists = JSON.parse( $('.user_and_journals').val() );
    }
    let current_code = $(this).val();

    if(current_code !== null && current_code !== undefined && current_code.length > 0){
      $('#journal_document_filter option').addClass('hide');
      $('#journal_document_filter').parent().find('.multi-select-container .multi-select-menuitem').addClass('hide');
      current_code.forEach((code)=>{
        let found_result = lists.find((e)=>{ return e.user == code })
        if(found_result){
          found_result.journals.forEach((journal)=>{ 
            $(`#journal_document_filter option[value=${journal}]`).removeClass('hide');
            $('#journal_document_filter').parent().find(`.multi-select-container .multi-select-menuitem input[value=${journal}]`).parent().removeClass('hide');
          });
        }
      })
    }else{
      $('#journal_document_filter option').removeClass('hide');
      $('#journal_document_filter').parent().find('.multi-select-container .multi-select-menuitem').removeClass('hide');
    }
  });

  $('#customers').unbind('change.mix_customer').bind('change.mix_customer', function(e){
    $('#hidden-customer-id').val($(this).val());

    window.location.href = window.location.href.split('?')[0] + "?uid=" + btoa($(this).val());
  });

  $('#customers').chosen({
    search_contains: true,
    no_results_text: 'Aucun résultat correspondant à'
  });

  setTimeout(()=>{ $('.hide_on_load').removeClass('hide'); $('#customer_document_filter').change() }, 1000); //TODO: find a better way to change the user selector

  $('.more-filter').unbind('click').bind('click',function(e) {
    e.stopPropagation();
    $('#more-filter').modal('show');
  });

  $('.show-calendar').unbind('click').bind('click',function(e) {
    e.stopPropagation();    
    $('#'+$(this).attr('data-ref')).click();
  });

  $('.select-all').unbind('click').bind('click',function(e) {
    e.stopPropagation();
    if($(this).is(':checked')){
      $(this).attr('title', 'Désélectionner toutes les pièces')
      $('.select-document, .select-operation').prop('checked', true);
      $('.select-document, .select-operation').closest('.box').addClass('selected');
      $('.piece-detail-container').addClass('selected');
      $('.action-selected').removeClass('hide');
      $('.grid .stamp-content').addClass('selected');      
    }
    else{
      $(this).attr('title', 'Sélectionner toutes les pièces')
      $('.select-document, .select-operation').prop('checked', false);
      $('.select-document, .select-operation').closest('.box').removeClass('selected');
      $('.action-selected').addClass('hide');
      $('.grid .stamp-content').removeClass('selected');
      $('.piece-detail-container').removeClass('selected');
    }    
  });


  $('.select-document, .select-operation').unbind('click').bind('click',function(e) {
    e.stopPropagation();
    var piece_id = $(this).attr('data-id');

    if($(this).is(':checked')){
      $(this).closest('.box').addClass('selected');
      $('.tr_piece_' + piece_id).addClass('selected');
      $('.grid .stamp-content#document_grid_' + piece_id).addClass('selected');
    }else{
      if ($('.select-all').is(':checked')) { $('.select-all').prop('checked', false); }
      $('.select-all').attr('title', 'Sélectionner toutes les pièces');
      $(this).closest('.box').removeClass('selected');
      $('.tr_piece_' + piece_id).removeClass('selected');
      $('.grid .stamp-content#document_grid_' + piece_id).removeClass('selected');
    }

    if ($('.box.list.selected').length == $('.box.list').length)
      $('.select-all').prop('checked', true);

    if ($('.box.list.selected').length < 1) {
      $('.action-selected').addClass('hide');
    }else{
      $('.action-selected').removeClass('hide');
    }
  });

  $('li.direct_links .rubric').unbind('click').bind('click',function(e) {
    e.preventDefault();

    $('li.direct_links .rubric .link_principal').removeClass('active');
    $(this).find('.link_principal').addClass('active');
    $('#hidden-journal-id').val($(this).data('id'));

    AppEmit('load_rubric');
  });

  
  $('.btn-all-documents').unbind('click').bind('click',function(e) {
    e.preventDefault();

    AppEmit('load_all_documents');
  });

  $('.more-filter').unbind('click').bind('click',function(e) {
    e.stopPropagation();
    $('#more-filter').modal('show');
  });
  
  $('.filter-customer-journal').unbind('click').bind('click', function(e){ AppEmit('document_customer_filter'); });

  $('.download_piece_zip').unbind('click').bind('click', function(e){ 
    let ids = get_all_selected($(this).data('type'), true)

    if (ids.length > 20){
      $('.modal#alert-info').modal('show');
    }
    else{
      AppEmit('download_piece_zip', { ids: ids });
    }    
  });

  $('.to-filter').unbind('click').bind('click', function(e){ $('#badge-filter').val($(this).attr('id')); AppEmit('filter_pack_badge'); });

  $('.grid .stamp-content').unbind('dblclick').bind('dblclick',function(e) {
    e.stopPropagation();
    AppEmit('documents_show_preseizures_details', {'obj': this});
  });

  $('.add-document').unbind('click').bind('click',function(e) {
    e.stopPropagation();
    $('#add-document').modal("show");    
  });

  $('.add-rubric').unbind('click').bind('click',function(e) {
    e.stopPropagation();
    $(this).hide('');

    $('li.input-add-rubric').show('');
  });

  $('.cancel-add-rubric').unbind('click').bind('click',function(e) {
    e.stopPropagation();
    $('.add-rubric').show('');

    $('li.input-add-rubric').hide();
  });

  $('span.edit-third-party').unbind('click').bind('click',function(e) {
    e.stopPropagation();

    $('.content-tp').hide();
    
    if ($(this).hasClass('name'))
      $(this).closest('label.third').find('.third-party-name').show('');
    else if ($(this).hasClass('date'))
      $(this).closest('label.third').find('.third-party-date').show('');
  });

  $('.valid-third-party').unbind('click').bind('click',function(e) {
    e.stopPropagation();
    e.preventDefault();

    let type  = $(this).data('type');
    let value = $(this).closest('.third-party-'+type).find('input').val();
    let id    = $(this).data('preseizure-id');

    if (type != "" && value != ""){
      AppEmit('edit_third_party', { 'type': type, 'value': value, 'id': id });
    }
    else{
      $('.content-tp').hide();
    }
  });

  $('.content-tp input').unbind('change keyup').bind('change keyup',function(e) {
    e.preventDefault();

    let self = $(this);

    if (self.val() != ''){
      self.closest('.content-tp').find('.valid-third-party').removeClass('hide');
      self.closest('.content-tp').find('.cancel-third-party').addClass('hide');
    }
    else{      
      $('.date-edit-third-party').data('daterangepicker').hide();
      $('.date-edit-third-party').val('');

      self.closest('.content-tp').find('.cancel-third-party').removeClass('hide');
      self.closest('.content-tp').find('.valid-third-party').addClass('hide');
    }
  });

  $('.cancel-third-party').unbind('click.cancel-third-party').bind('click.cancel-third-party',function(e) {
    e.stopPropagation();
    e.preventDefault();    

    $('.content-tp input').val('');
    $('.content-tp').hide();
  });



  $('#more-filter .modal-footer .btn-add, #customer_filter_form .btn-search').unbind('click').bind('click', function(){ $('#more-filter').modal('hide'); AppEmit('documents_load_datas'); });
  $('.btn-reinit').unbind('click').bind('click', function(){ $('#more-filter').modal('hide'); AppEmit('documents_reinit_datas'); });

  //prevent form submition
  $('.search-content #search_input').unbind('keydown').bind('keydown', function(e){ if(e.key == 'Enter'){ e.preventDefault(); return false; } });
  $('.search-content #search_input').unbind('keypress').bind('keypress', function(e){ if(e.key == 'Enter'){ e.preventDefault(); return false; } });
  $('.search-content #search_input').unbind('keyup').bind('keyup', function(e){ if(e.key == 'Enter'){ e.preventDefault(); return false; } });
  $('.search-content #search_input').unbind('keyup.search').bind('keyup.search', function(e){ if(e.key == 'Enter'){ AppEmit('documents_search_text'); } });

  $('.search-content .glass svg').unbind('click').bind('click', function(e){ AppEmit('documents_search_text'); });

  $('.download_pack_archive').unbind('click').bind('click', function(){ AppEmit('download_pack_archive', {'obj': this}); });
  $('.download_pack_bundle').unbind('click').bind('click', function(){ AppEmit('download_pack_bundle', {'obj': this}); });

  $('.preseizures_export').unbind('click').bind('click',function(e) { AppEmit('documents_export_preseizures', {'obj': this}) });

  $('.update_tags').unbind('click').bind('click', function(e){ e.preventDefault(); AppEmit('documents_update_tags', {'obj': this}); });

  $('.edit_compta_analysis').unbind('click').bind('click', function(){ AppEmit('documents_edit_analysis', { 'code': $(this).data('code'), is_used: $(this).data('is-used') }); });

  $('.delete_piece').unbind('click').bind('click', function(){ AppEmit('documents_loaded_delete_piece', {'obj': this}); });
  $(".restore").unbind('click').bind('click', function(e){ e.stopPropagation(); AppEmit('documents_loaded_restore_piece', { id: $(this).attr('data-piece-id') }); });

  $('.edit_preseizures').unbind('click').bind('click', function(){ AppEmit('documents_edit_preseizures', {'obj': this}); });
  $('.edit_selected_preseizures').unbind('click').bind('click', function(){
    let ids = get_all_selected($(this).data('type'), true);
    AppEmit('documents_edit_multiple_preseizures', { 'ids': ids.join(',') });
  });

  $('.deliver_preseizures').unbind('click').bind('click', function(){ AppEmit('documents_deliver_preseizures', {'obj': this}); });

  $('table.entries .content_amount').unbind('click').bind('click', function(){ AppEmit('documents_edit_entry_amount', {'obj': this}); });
  $('table.entries .content_account').unbind('click').bind('click', function(){ AppEmit('documents_edit_entry_account', {'obj': this}); });

  $('table.entries td.entry').mouseover(function(){ $(this).find('.content_amount span.debit_or_credit').show(); }).mouseout(function(){ $(this).find('.content_amount span.debit_or_credit').hide(); });
  $('table.entries .debit_or_credit').unbind('click').bind('click', function(){ AppEmit('documents_change_entry_type', {'obj': this}); });

  $(".zoom.pdf-viewer, #table_pieces td.show-detail").unbind('click').bind('click', function(){ 
    var url = $(this).attr('data-content-url');

    //needed to avoid showing the last document before loading the next one
    let iframe = $("#PdfViewerDialog .modal-body .view-content iframe.src-piece");
    $("#PdfViewerDialog .modal-body .view-content span.loading").removeClass('hide');
    iframe.addClass('hide');

    iframe.attr("src", url);
    $("#PdfViewerDialog").modal('show');

    iframe[0].onload = ()=>{ 
      $("#PdfViewerDialog .modal-body .view-content span.loading").addClass('hide')
      iframe.removeClass('hide');
    }
  });

  $('.content-list-pieces-deleted li.get-pieces-deleted').unbind('click').bind('click', function(e){
    $("#DeletedPiece .modal-body .view-content").html($(this).data('content'));

    $("#DeletedPiece button.restore").attr("data-piece-id", $(this).attr('id'));

    $("#DeletedPiece button.previous").attr("data-content", $(this).prev().attr('data-content') || '');
    $("#DeletedPiece button.previous").attr("id", $(this).prev().attr('id') || '');

    $("#DeletedPiece button.next").attr("data-content", $(this).next().attr('data-content') || '');
    $("#DeletedPiece button.next").attr("id", $(this).next().attr('id') || '');

    $("#DeletedPiece").modal('show');
  });

  $('#DeletedPiece button.previous, #DeletedPiece button.next').unbind('click').bind('click', function(e){
    if ($(this).attr('id')){
      $("#DeletedPiece .modal-body .view-content").html($(this).attr('data-content'));
      $("#DeletedPiece button.restore").attr("data-piece-id", $(this).attr('id'));

      let prev_content = ($(".content-list-pieces-deleted li#"+$(this).attr('id') ).prev().attr('data-content')) || '';
      let next_content = ($(".content-list-pieces-deleted li#"+$(this).attr('id') ).next().attr('data-content')) || '';

      let prev_id      = ($(".content-list-pieces-deleted li#"+$(this).attr('id')).prev().attr('id')) || '';
      let next_id      = ($(".content-list-pieces-deleted li#"+$(this).attr('id')).next().attr('id')) || '';

      $("#DeletedPiece button.previous").attr("data-content", prev_content);
      $("#DeletedPiece button.previous").attr("id", prev_id);

      $("#DeletedPiece button.next").attr("data-content", next_content);
      $("#DeletedPiece button.next").attr("id", next_id);
    }
  });

  $('.temp-document-view .image_piece, #TempDocument button.previous, #TempDocument button.next').unbind('click').bind('click', function(e){
    if ($(this).attr("data-index") > 0 && $(this).attr('data-content') != ""){
      let _index_prev = parseInt($(this).attr('data-index')) - 1;
      let _index_next = parseInt($(this).attr('data-index')) + 1;

      $("#TempDocument .modal-body .view-content").html($(this).attr('data-content'));

      let _class_for_each = $(this).data('each-class');

      let prev_content = $(_class_for_each + "#each_"+_index_prev).data('content') || '';
      let next_content = $(_class_for_each + "#each_"+_index_next).data('content') || '';

      $("#TempDocument button.previous").attr("data-content", prev_content);
      $("#TempDocument button.previous").attr("data-index", _index_prev);
      $("#TempDocument button.previous").attr("data-each-class", _class_for_each);

      $("#TempDocument button.next").attr("data-content", next_content);
      $("#TempDocument button.next").attr("data-index", _index_next);
      $("#TempDocument button.next").attr("data-each-class", _class_for_each);

      if (!$(this).hasClass('previous') && !$(this).hasClass('next')){
        $("#TempDocument").modal('show');
      }
    }
  });

  $('.show-list-document').mouseover(function() { $(".temp-document-view").show(); }).mouseout(function() { $(".temp-document-view").hide(); });

  $('.btn.add-entry').unbind('click').bind('click', function(e){
    $(this).closest('.content-table').find('.entries tbody').append($('template').html())
    $(this).parent('.btn-add-content').find('.add-entry').addClass('hide');
    $(this).parent('.btn-add-content').find('.action-add-content').removeClass('hide');

    $('.btn.add-entry').prop('disabled', true);

    bind_all_events();
  })

  $('.action-add-content.text-end #valid-entry').unbind('click').bind('click', function(e){
    AppEmit('new_entry', { elt: $(this).closest('.content-table').find('.entries tbody .new-entrie-content'), preseizure_id: $(this).closest('.preseizure-content-list').data('preseizure-id') });

    $('.btn.add-entry').prop('disabled', false);
  })

  $('.action-add-content.text-end #cancel-entry').unbind('click').bind('click', function(e){
    $(this).closest('.content-table').find('.entries tbody tr:last').remove();
    $(this).closest('.btn-add-content').find('.add-entry').removeClass('hide');
    $(this).closest('.btn-add-content').find('.action-add-content').addClass('hide');

    $('.btn.add-entry').prop('disabled', false);
  });


  $('.popup-info-tag').mouseover(function(e) {
    if ($(this).hasClass('second'))
    {
      $('.info-tag-content-second').removeClass('hide')
    }
    else{
      $('.info-tag-content').removeClass('hide')
    }

  }).mouseout(function(e) {
    if ($(this).hasClass('second'))
    {
      $('.info-tag-content-second').addClass('hide')
    }
    else{
      $('.info-tag-content').addClass('hide')
    } 
  });


  $('.entry .remove').unbind('click').bind('click', function(e){
    let tr = $(this).closest('tr');
    if (confirm('Voulez-vous vraiment supprimer cette ligne ? ')){
      let preseizure_id = $(this).closest('.preseizure-content-list').data('preseizure-id');
      let account_id    = tr.find('input.account_id_hidden').val();
      let entry_id      = tr.find('input.entry_id_hidden').val();

      AppEmit('remove_entry', { preseizure_id: preseizure_id, account_id: account_id, entry_id: entry_id });
    }
  });

  $('#collaborator_document_filter').asMultiSelect({
    "texts" : { "searchplaceholder": "Choix dossiers", "noItemsAvailable": 'Aucun dossier trouvé'},
    "resultsContainer": '.result-sol-customer',
    "maxHeight": "500px",
    "noneText": "Choix dossier",
    "showSelectAll": false
  });

  $('#collaborator_journal_document_filter').asMultiSelect({
    "texts" : { "searchplaceholder": "Choix journaux", "noItemsAvailable": 'Aucun journal trouvé'},
    "resultsContainer": '.result-sol-journal',
    "maxHeight": "500px",
    "noneText": "Choix journaux",
    "showSelectAll": false
  });

  $('#collaborator_period_document_filter').asMultiSelect({
    "texts" : { "searchplaceholder": "Choix périodes", "noItemsAvailable": 'Aucune période trouvée'},
    "resultsContainer": '.result-sol-period',
    "maxHeight": "500px",
    "noneText": "Choix périodes",
    "showSelectAll": false
  });

  $('#collaborator_document_filter').unbind('change.mix_journal').bind('change.mix_journal', function(e){
    let lists = [];
    if ($('.user_and_journals').length > 0){
      lists = JSON.parse( $('.user_and_journals').val() );
    }
    let current_code = $(this).val();

    if(current_code !== null && current_code !== undefined && current_code.length > 0){
      if( current_code.length == 1 )
      {
        var opt_text = $('#collaborator_document_filter').find(`option[value="${current_code[0]}"]`).text();
        var code     = opt_text.split(' ')[0].trim()
        $('select#file_code').val(code).trigger("chosen:updated");
        $('select#file_code').change();
      }

      $('#collaborator_journal_document_filter option').addClass('hide');
      $('#collaborator_journal_document_filter').parent().find('.multi-select-container .multi-select-menuitem').addClass('hide');
      current_code.forEach((code)=>{
        let found_result = lists.find((e)=>{ return e.user == code })
        if(found_result){
          found_result.journals.forEach((journal)=>{ 
            $(`#collaborator_journal_document_filter option[value=${journal}]`).removeClass('hide');
            $('#collaborator_journal_document_filter').parent().find(`.multi-select-container .multi-select-menuitem input[value=${journal}]`).parent().removeClass('hide');
          });
        }
      })
    }else{
      $('#collaborator_journal_document_filter option').removeClass('hide');
      $('#collaborator_journal_document_filter').parent().find('.multi-select-container .multi-select-menuitem').removeClass('hide');
    }
  });

  setTimeout(()=>{ $('.hide_on_load').removeClass('hide'); $('#collaborator_document_filter').change() }, 1000); //TODO: find a better way to change the user selector

  $('#document-filter').unbind('click').bind('click', function(e){ AppEmit('document_collaborator_filter'); });
}

jQuery(function() {
  AppListenTo('window.application_auto_rebind', (e)=>{
    bind_all_events();
  });
});