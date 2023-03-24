class AdminDematbox {
  constructor(){
    this.dematbox_modal  = $('#filter-demat-file.modal');
  }

  load_events(){
    let self = this;

    $('.filter-dematbox').unbind('click').bind('click',function(e) {
      e.preventDefault();      

      self.dematbox_modal.modal('show');
    }); 
  }
 
}

jQuery(function() {
  let dematbox = new AdminDematbox();

  dematbox.load_events();
  AppListenTo('window.application_auto_rebind', (e)=>{  dematbox.load_events(); });
});