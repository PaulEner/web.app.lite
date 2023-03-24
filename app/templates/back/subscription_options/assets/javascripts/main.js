//= require './events'

class AdminSubscriptionOptions{
  constructor(){
    this.applicationJS                    = new ApplicationJS;    
    this.create_subscription_option_modal = $('#create-new-subscription-option.modal');    
  }
  main() {    
    bind_globals_events();
  }

  subscription_option(id=-1){
    let self = this;

    let url = `/admin/subscription_options/new`;

    if (id > 0){
      url = '/admin/subscription_options/'+ id +'/edit';
    }

    let ajax_params = {
                      url: url,
                      type: 'GET',
                      dataType: 'html',
                    }

    this.applicationJS.sendRequest(ajax_params).then((e)=>{ 
      self.create_subscription_option_modal.find('.modal-body').html(e);

      self.create_subscription_option_modal.modal('show');
      ApplicationJS.set_checkbox_radio(this);
    });
  }
}

jQuery(function() {
  let sub_option = new AdminSubscriptionOptions();
  sub_option.main();  

  AppListenTo('show_subscription_option', (e)=>{ if (e.detail.response.json_flash.success) { window.location.href = e.detail.response.url } });
  AppListenTo('create_subscription_option', (e)=>{ sub_option.subscription_option(); });
  AppListenTo('edit_subscription_option', (e)=>{ sub_option.subscription_option(e.detail.id); });
});