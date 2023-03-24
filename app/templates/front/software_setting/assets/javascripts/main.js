//=require './events'

class SoftwareSetting {
  constructor(){
    this.applicationJS = new ApplicationJS();
  }

  edit_csv_descriptor(id){
    let ajax_params =   {
                          url: `/organizations/${id}/csv_descriptor/format_setting`,
                          type: 'GET',
                          dataType: 'HTML',
                          target: '#csv_descriptors.edit',
                          target_dest: '#edit_csv_descriptor_format'
                        }
    this.applicationJS.sendRequest(ajax_params).then((e)=>{ $('.modal#csv_descriptor_modal').modal('show'); });
  }

  load_csv_descriptor(user_id, organization_id){
    let ajax_params = {
                        url: `/organizations/${organization_id}/csv_descriptor/${user_id}/format_setting`,
                        type: 'GET',
                        dataType: 'HTML',
                        target: '#csv_descriptors.edit',
                        target_dest: '#edit_csv_descriptor_format'
                      };

    this.applicationJS.sendRequest(ajax_params).then((e)=>{ $('.modal#csv_descriptor_modal').modal('show'); });
  }

}


jQuery(function() {
  var main = new SoftwareSetting();

  AppListenTo('csv_descriptor_open_edition', (e)=>{ main.edit_csv_descriptor(e.detail.id) });

  AppListenTo('csv_descriptor_edit_customer_format', (e)=>{ main.load_csv_descriptor(e.detail.id, e.detail.organization_id) });
});