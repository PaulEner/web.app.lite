function bind_globals_events() {
  elements_initializer();
  iDocus_ajax_links();
  iDocus_pagination();

  $('.user-filter').unbind('click').bind('click',function(e) {
    e.preventDefault();

    $('.modal#filter-organizations').modal('show');
  });
}