function apply_searchable_option(target) {
  if (target === 'collaborators') {
    $('#select-collaborator-role').removeClass('form-control');
    $('#select-organization-group-list').removeClass('form-control');
    $('#select-collaborator-role').asMultiSelect();
    $('#select-organization-group-list').asMultiSelect();
  }

  else if (target === 'groups') {
    $('#select-collaborators-list').removeClass('form-control');
    $('#select-customers-collaborators-list').removeClass('form-control');
    $('#select-collaborators-list').asMultiSelect();
    $('#select-customers-collaborators-list').asMultiSelect();
  }
}

function bind_collaborator_events(){
  if ($('#information.active.show').length > 0) { apply_searchable_option('collaborators'); }

  $('.new_edit').unbind('click').bind('click', function(e) {
    e.stopPropagation();

    let target      = '';
    let action_name = '';
    let id          = 0;

    if ($(this).hasClass('collaborator')) { target = 'collaborators'; }
    else if ($(this).hasClass('group')) { target = 'groups'; }

    if ($(this).hasClass('create')) { action_name = 'new'; }
    else if ($(this).hasClass('edit')) {
      id          = $(this).parent().attr('id').split('-')[1];
      action_name = 'edit';
    }

    AppEmit('new_edit', { target: target, action_name: action_name, id: id });
  });


  $('.create_update').unbind('click').bind('click', function(e) {
    e.stopPropagation();

    const form = $('form.create_update_form');

    AppEmit('create_update', { url: form.attr('action'), data: form.serialize()});
  })


  $('.search-content .search_input_text').unbind('keyup.apply_searchable').bind('keyup.apply_searchable', function(e){
    e.stopPropagation();

    let name = $(this).attr('name');
    let type = 'members';

    if (name === 'group_contains[text]') {
      type = 'groups';
    }

    if(e.key == 'Enter'){ 
      AppEmit('search_text', { type: type });
    } 
  });
  $('.search-content .input-group-text').unbind('click').bind('click', function(e){
    e.preventDefault();

    let type = 'members';

    if ($(this).hasClass('group-search')) {
      type = 'groups';
    }

    AppEmit('search_text', { type: type }); 
  });

  $('.more-filter').unbind('click').bind('click',function(e) {
    e.stopPropagation();

    if ($(this).hasClass('group_filter')) { $('#search_group_filter').modal('show'); }
    else if ($(this).hasClass('member_filter')) { $('#search_collaborator_filter').modal('show'); }
  });

  $('.search_filter').unbind('click').bind('click', function(e) {
    e.stopPropagation();

    let current_form = 'member_f'

    if ($(this).hasClass('group_f')) {
      current_form = 'group_f';
    }

    const form = $(`form.${current_form}.search_contains_filter`);

    AppEmit('search_contains_filter', { url: form.attr('action'), data: form.serialize()});
  });

  $('.collaborator_rights').unbind('click').bind('click', function(e) {
    e.stopPropagation();

    AppEmit('show_collaborator_rights_edit', { url: $(this).attr('link') });
  });

  $('.collaborator_file_storages').unbind('click').bind('click', function(e) {
    e.stopPropagation();

    AppEmit('show_collaborator_file_storages_edit', { url: $(this).attr('link') });
  });

  $('.destroy_group').unbind('click').bind('click', function(e) {
    /*e.preventDefault();*/
    e.stopPropagation();

    const text = $(this).attr('text');
    const url  = $(this).attr('link');

    if (confirm(text)) {
      AppEmit('destroy_group', { url: url });
    }
    else { return false; }
  });

  $('.show_details_group').unbind('click').bind('click', function(e) {
    e.stopPropagation();
    e.preventDefault();

    const url = $(this).attr('href');

    AppEmit('show_details_group', { url: url });
  });
}

jQuery(function() {
  AppListenTo('window.application_auto_rebind', (e)=>{ bind_collaborator_events(); })
});