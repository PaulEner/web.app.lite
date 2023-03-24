function bind_all_events(){
  $('ul.nav.nav-tabs li.nav-item').unbind('click.filter').bind('click.filter', function(e){
    if( $(this).hasClass('no-filter') )
      $('.filter_button').addClass('hide');
    else
      $('.filter_button').removeClass('hide')
  })

  $('.piece-errors-filter').unbind('click').bind('click',function(e) {
    e.stopPropagation();

    $('#filter-'+ $(".tab-pane.active").attr('id')).modal('show');
  });


  $(`.check-all-piece-ignored`).unbind('change').bind('change', function(e){
    let target_selector = $('.checkbox');

    if($(this).hasClass('ignored')){ target_selector = $('.check-piece-ignored.checkbox'); }
    else if($(this).hasClass('duplicated')){ target_selector = $('.check-piece-duplicated'); }

    if ($(this).is(':checked')){ target_selector.prop('checked', true); }
    else{ target_selector.prop('checked', false); }
  });

  $('#account_id').unbind('change').bind('change', function(e){ AppEmit('account_filter'); });

  $('.modal#filter-ignored-pre-assignment button.validate').unbind('click').bind('click', (e)=>{ AppEmit('pieces_errors_filter_page', { target: 'ignored-pre-assignment', action: 'validate'}); });
  $('.modal#filter-duplicated-pre-assignment button.validate').unbind('click').bind('click', (e)=>{ AppEmit('pieces_errors_filter_page', { target: 'duplicated-pre-assignment', action: 'validate'}); });

  $('.modal#filter-ignored-pre-assignment button.cancel').unbind('click').bind('click', (e)=>{ AppEmit('pieces_errors_filter_page', { target: 'ignored-pre-assignment', action: 'reset'}); });
  $('.modal#filter-duplicated-pre-assignment button.cancel').unbind('click').bind('click', (e)=>{ AppEmit('pieces_errors_filter_page', { target: 'duplicated-pre-assignment', action: 'reset'}); });

  $('#resend-to-pre-assignment').unbind('click').bind('click', function(e){ AppEmit('pieces_errors_update_ignored_pieces', { type: 'force_pre_assignment' }) });
  $('#confirm-ignorance').unbind('click').bind('click', function(e){ AppEmit('pieces_errors_update_ignored_pieces', { type: 'confirm_ignorance' }) });

  $('#unlock-preseizures').unbind('click').bind('click', function(e){ AppEmit('pieces_errors_update_duplicated_preseizures', { type: 'unlock_preseizures' }) });
  $('#confirm-duplication').unbind('click').bind('click', function(e){ AppEmit('pieces_errors_update_duplicated_preseizures', { type: 'confirm_duplication' }) });

 /* $('.custom_popover').custom_popover();*/

  const piece_modal = '#show_ignored_pieces.modal';
  let show_piece_modal = $(piece_modal);
  const tbl_ignored_pieces = '#tbl_ignored_pieces';
  let checkbox_checker_nav = $(`${piece_modal} #navigation .checkbox_checker`);

  const check_checker = function(piece_index) {
    let checker = $(`${tbl_ignored_pieces} .check-piece-ignored.checker_piece_${piece_index}`);
    if (checker.length > 0){
      checkbox_checker_nav.removeClass('hide');
      if (checker.is(':checked')){
        checkbox_checker_nav.prop('checked', true);
      }
      else{
        checkbox_checker_nav.prop('checked', false);
      }
    }
    else{
      checkbox_checker_nav.addClass('hide');
    }
  };

  const load_modal = function(element, show=false){
    show_piece_modal.find('h5.name').html(element.data('piece-name'));
    show_piece_modal.find('iframe.piece').attr('src', element.data('piece-url'));

    if (show) { show_piece_modal.modal('show'); }
  }

  let piece_index = 0;

  $('a.do-showPieces').unbind('click').bind('click', function(e){
    e.preventDefault();

    if ($(this).hasClass('ignored_piece')) {
      piece_index += 1;

      load_modal($(this), true);
    }

    else if ($(this).hasClass('duplicated_piece')) {
      let duplicated_piece = $('#show_duplicated_pieces.modal');
      duplicated_piece.find('iframe.duplicate').attr('src', $(this).data('duplicate-url'));
      duplicated_piece.find('iframe.original').attr('src', $(this).data('original-url'));
      duplicated_piece.modal('show');
    }

  });

  $(`${piece_modal} #navigation a.left`).unbind('click').bind('click', function(e){
    e.preventDefault();

    if(piece_index > 0){
      piece_index -= 1;
      check_checker(piece_index);
      load_modal($(`${tbl_ignored_pieces} .piece_${piece_index}`))
    }
  });

  $(`${piece_modal} #navigation a.right`).unbind('click').bind('click', function(e){
    e.preventDefault();

    if (piece_index < ($(`${tbl_ignored_pieces} a.do-showPieces`).length - 1)){
      piece_index += 1;
      check_checker(piece_index);
      load_modal($(`${tbl_ignored_pieces} .piece_${piece_index}`));
    }
  });

  checkbox_checker_nav.unbind('change').bind('change', function(e){
    if ($(this).is(':checked')){
      $(`${tbl_ignored_pieces} .checker_piece_${piece_index}`).prop('checked', true);
    }
    else{
      $(`${tbl_ignored_pieces} .checker_piece_${piece_index}`).prop('checked', false);
    }
  });
}

jQuery(function() {
  bind_all_events();
});