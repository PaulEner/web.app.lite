//= require './events'

class AdminOrganization {
  constructor(){
    this.applicationJS                   = new ApplicationJS;    
    this.create_organization_modal       = $('#create-new-organizations.modal');
    this.create_group_organization_modal = $('#create-new-group.modal');
  }

  create_or_edit_organization(){
    let self = this;

    let ajax_params = {
                      url: `/admin/organizations/new`,
                      type: 'GET',
                      dataType: 'html',
                    }

    this.applicationJS.sendRequest(ajax_params).then((e)=>{ 
      self.create_organization_modal.find('.modal-body').html(e);

      self.create_organization_modal.modal('show');
      ApplicationJS.set_checkbox_radio(this);
    });
  }

  create_group_organization(id=-1){
    let self = this;

    let url = '/admin/organizations/groups/new';

    if (id != -1){
      url = '/admin/organizations/groups/'+id+'/edit';
    }
    let ajax_params = {
                      url: url,
                      type: 'GET',
                      dataType: 'html',
                    }

    this.applicationJS.sendRequest(ajax_params).then((e)=>{ 
      self.create_group_organization_modal.find('.modal-body').html(e);

      self.create_group_organization_modal.modal('show');
      ApplicationJS.set_checkbox_radio(this);
    });
  }

  main() {
    let self = this;

    bind_globals_events();
    ApplicationJS.set_checkbox_radio(this);
  }  
}

// <<<<<<< HEAD
// $(document).ready(function() {
//   var resources = [
//     'ocr_needed_temp_packs',
//     'bundle_needed_temp_packs',
//     'processing_temp_packs',
//     'currently_being_delivered_packs',
//     'failed_packs_delivery',
//     'blocked_pre_assignments',
//     'awaiting_pre_assignments',
//     'reports_delivery',
//     'failed_reports_delivery',
//     'awaiting_supplier_recognition',
//     'awaiting_adr'
//   ];

//   load_resources(resources);

//   var interval_id = setInterval(function(){ load_resources(resources); }, 30000);
// });
// =======
jQuery(function() {
  let organization = new AdminOrganization();
  organization.main();

  bind_globals_events();

  AppListenTo('show_organization', (e)=>{ if (e.detail.response.json_flash.success) { window.location.href = e.detail.response.url } });
  AppListenTo('create_organization', (e)=>{ organization.create_or_edit_organization(); });
  AppListenTo('edit_group_organization', (e)=>{ organization.create_or_edit_organization(); });
  AppListenTo('create_group_organization', (e)=>{ organization.create_group_organization(); });
  AppListenTo('edit_group_organization', (e)=>{ organization.create_group_organization(e.detail.id); });
});