function bind_globals_events() {
  elements_initializer();
  iDocus_ajax_links();
  iDocus_pagination();

  $('.create-organization').unbind('click').bind('click',function(e) {
    e.preventDefault();

    AppEmit('create_organization');
  });

  $('.organization-filter').unbind('click').bind('click',function(e) {
    e.preventDefault();

    $("#filter-organizations.modal").modal('show');
  });

  $('.create-group-organization').unbind('click').bind('click',function(e) {
    e.preventDefault();

    AppEmit('create_group_organization');
  });

  $('.edit-group-organization').unbind('click').bind('click',function(e) {
    e.preventDefault();

    AppEmit('edit_group_organization', { id: $(this).attr('id')});
  });
}