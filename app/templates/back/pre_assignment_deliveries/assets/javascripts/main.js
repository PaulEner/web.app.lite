class AdminDelivery {
  constructor(){
    this.applicationJS    = new ApplicationJS;    
    this.deliverie_modal  = $('#filter-deliverie.modal');    
  }

  load_events(){
    let self = this;

    $('.filter-deliveries').unbind('click').bind('click',function(e) {
      e.preventDefault();      

      self.deliverie_modal.modal('show');
    }); 
  }

  main() {
    this.load_events();    
  }  
}

jQuery(function() {
  let deliverie = new AdminDelivery();
  deliverie.main();

  bind_globals_events();

  AppListenTo('show_deliverie', (e)=>{ if (e.detail.response.success) { window.location.href = e.detail.response.url } });
});