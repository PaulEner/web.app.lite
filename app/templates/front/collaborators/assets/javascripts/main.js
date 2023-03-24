//= require './events'

class Main{
  constructor () {
    this.applicationJS   = new ApplicationJS;
    this.member_modal    = $('#add_edit_collaborator.modal');
    this.group_modal     = $('#add_edit_group');
    this.group_show_details_modal = $('#show_group_details');
    this.member_filter_modal = $('#search_collaborator_filter');
    this.group_filter_modal = $('#search_group_filter');
    this.organization_id = $('input:hidden[name="organization_id"]').val();
    this.action_locker   = false;
  }


  show_modal(target, params){
    if (target === 'collaborators') {
      this.applicationJS.sendRequest(params).then((element)=>{
        this.member_modal.find('.modal-body').html($(element).find('.form_content').html());
        this.member_modal.find('.modal-title').html($(element).find('.form_content').attr('text'));
        apply_searchable_option('collaborators');
        this.member_modal.modal('show');
      });
    }
    else if (target === 'groups') {
      this.applicationJS.sendRequest(params).then((element)=>{
        this.group_modal.find('.modal-body').html($(element).find('.form_content').html());
        this.group_modal.find('.modal-title').html($(element).find('.form_content').attr('text'));
        apply_searchable_option('groups')
        this.group_modal.modal('show');

        ApplicationJS.set_checkbox_radio();
      });
    }
  }

  new_edit(target, action_name, id=0){
    if (id === 0) {
      let params =  { 'url': `/organizations/${this.organization_id}/${target}/${action_name}` };

      this.show_modal(target, params);
      $('.modal-footer .create_update').text('Ajouter');
    }
    else{
      let params =  { 'url': `/organizations/${this.organization_id}/${target}/${id}/${action_name}` };

      this.show_modal(target, params);
      $('.modal-footer .create_update').text('Éditer');
    }
  }

  create_update(url, data){
    this.applicationJS.sendRequest({
      'url': url,
      'data': data,
      'type': 'POST',
      'dataType': 'html',
    }).then((response)=>{
      if (url.indexOf("groups") >= 0) {
        $('.page-content .box-group-content').html($(response).find('.page-content .box-group-content').html());
        this.group_modal.modal('hide');
      }
    }).catch((response)=>{
      if (url.indexOf("groups") >= 0) { this.group_modal.modal('hide'); }
    });
  }


  load_data(search_pattern=false, type='members', page=1, per_page=0){
    if(this.action_locker) { return false; }

    this.action_locker = true;
    let params = [];

    let search_text = '';
    let params_name = 'group_contains[text]';

    if (type === 'members') {
      type = 'collaborators';
      params_name = 'user_contains[text]';
    }

    if (search_pattern) {
      search_text = $(`.search-content input[name='${params_name}'].search_input_text`).val();
      if(search_text && search_text != ''){ params.push(`${params_name}=${encodeURIComponent(search_text)}`); }
    }

    params.push(`page=${page}`);

    if (per_page > 0) { params.push(`per_page=${ per_page }`); }

    let ajax_params =   {
                          'url': `/organizations/${this.organization_id}/${type}?${params.join('&')}`,
                          'dataType': 'html',
                          'target': ''
                        };

    this.applicationJS.sendRequest(ajax_params)
    .then((response)=>{
      if (type === 'collaborators') {
        $('.page-content .collaborators-content').html($(response).find('.page-content .collaborators-content').html());
      }
      else if (type === 'groups') {
        $('.page-content .box-group-content').html($(response).find('.page-content').html());
      }

      $(`.search-content input[name='${params_name}'].search_input_text`).val(search_text);

      this.action_locker = false;
    })
    .catch(()=>{ this.action_locker = false; });
  }


  search_contains_filter(url, data){
    this.applicationJS.sendRequest({
      'url': url,
      'data': data,
      'type': 'GET',
      'dataType': 'html',
    }).then((response)=>{
      if (url.indexOf("collaborators") >= 0) {
        $('.page-content .collaborators-content').html($(response).find('.page-content .collaborators-content').html());
        this.member_filter_modal.modal('hide');
      }
      else if (url.indexOf("groups") >= 0) {
        $('.page-content .box-group-content').html($(response).find('.page-content').html());
        this.group_filter_modal.modal('hide');
      }
    }).catch((response)=>{
      this.member_filter_modal.modal('hide');
      this.group_filter_modal.modal('hide');
    });
  }


  show_collaborator_rights_edit(url){
    // let ajax_params =   {
    //                       'url': url,
    //                       'dataType': 'html',
    //                       'target': ''
    //                     };

    // this.applicationJS.sendRequest(ajax_params)
    // .then((element)=>{
    //   this.action_locker = false;
    //   $('#authorization').html($(element).find('#collaborator_rights').html());
    //   $('#authorization .cancel_collaborator_rights').remove();
    //   bind_collaborator_events();
    //   ApplicationJS.set_checkbox_radio();
    // })
    // .catch(()=>{ this.action_locker = false; });
  }

  show_collaborator_file_storages_edit(url){
    // let ajax_params =   {
    //                       'url': url,
    //                       'dataType': 'html',
    //                       'target': ''
    //                     };

    // this.applicationJS.sendRequest(ajax_params)
    // .then((element)=>{
    //   this.action_locker = false;
    //   $('#file_storages').html($(element).find('#file_storage_authorizations').html());
    //   $('#file_storages .cancel_collaborator_file_storages').remove();
    //   bind_collaborator_events();
    //   ApplicationJS.set_checkbox_radio();
    // })
    // .catch(()=>{ this.action_locker = false; });
  }

  destroy_group(url){
    let is_deleted = false

    if (!is_deleted) {
      let ajax_params =   {
                          'url': url,
                          'type': 'DELETE',
                          'dataType': 'html',
                        };

      this.applicationJS.sendRequest(ajax_params)
      .then((element)=>{
        this.action_locker = false;
        $('.page-content .box-group-content').html($(element).find('.page-content').html());
        is_deleted = true

        ApplicationJS.set_checkbox_radio();
      })
      .catch(()=>{ this.action_locker = false; });
    }
  }

  show_details_group(url){
    let is_already_open = false

    if (!is_already_open) {
      let ajax_params =   {
                          'url': url,
                          'type': 'GET',
                          'dataType': 'html',
                        };

      this.applicationJS.sendRequest(ajax_params)
      .then((element)=>{
        this.action_locker = false;
        this.group_show_details_modal.find('.modal-body').html($(element).find('.group-modal-body').html());
        this.group_show_details_modal.find('.modal-title').html($(element).find('.group-modal-title').html());

        this.group_show_details_modal.modal('show');
        is_already_open = true
        ApplicationJS.set_checkbox_radio();
      })
      .catch(()=>{ this.action_locker = false; });
    }
  }
}


jQuery(function() {
  let main = new Main();

  let is_rigths_executed = false;
  if ($('#authorization.active.show').length > 0 && !is_rigths_executed) {
    main.show_collaborator_rights_edit($('.collaborator_rights.active').attr('link'));
    is_rigths_executed = true;
  }

  let is_file_storages_executed = false;
  if ($('#file_storages.active.show').length > 0 && !is_file_storages_executed) {
    main.show_collaborator_file_storages_edit($('.collaborator_file_storages.active').attr('link'));
    is_file_storages_executed = true;
  }

  AppListenTo('new_edit', (e)=>{ main.new_edit(e.detail.target, e.detail.action_name, e.detail.id); });
  AppListenTo('create_update', (e)=>{ main.create_update(e.detail.url, e.detail.data); });

  AppListenTo('search_text', (e)=>{ main.load_data(true, e.detail.type); });
  AppListenTo('search_contains_filter', (e)=>{ main.search_contains_filter(e.detail.url, e.detail.data); });

  AppListenTo('show_collaborator_rights_edit', (e)=>{ main.show_collaborator_rights_edit(e.detail.url); });
  AppListenTo('show_collaborator_file_storages_edit', (e)=>{ main.show_collaborator_file_storages_edit(e.detail.url); });

  AppListenTo('destroy_group', (e)=>{ main.destroy_group(e.detail.url); });

  AppListenTo('show_details_group', (e)=>{ main.show_details_group(e.detail.url); });
  
  AppListenTo('window.change-per-page.members', (e)=>{ main.load_data(true, e.detail.name, 1, e.detail.per_page); });
  AppListenTo('window.change-page.members', (e)=>{ main.load_data(true, e.detail.name, e.detail.page); });
});