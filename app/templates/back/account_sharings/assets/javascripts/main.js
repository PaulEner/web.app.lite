class AdminAccountSharing {
  constructor(){
    this.account_sharing_filter_modal  = $('#filter-account-sharing');
  }

  load_events(){
    let self = this;

    $('.filter-account-sharing').unbind('click').bind('click',function(e) {
      e.preventDefault();

      self.account_sharing_filter_modal.modal('show');
    });

  }

}

jQuery(function() {
  let account = new AdminAccountSharing();

  account.load_events();
  AppListenTo('window.application_auto_rebind', (e)=>{  account.load_events(); });

});

