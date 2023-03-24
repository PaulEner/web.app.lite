class AdminOrders {
  constructor(){
    this.applicationJS    = new ApplicationJS;    
    this.orders_modal     = $('#filter-orders.modal');    
  }

  load_events(){
    let self = this;

    $('.filter-orders').unbind('click').bind('click',function(e) {
      e.preventDefault();      

      self.orders_modal.modal('show');
    }); 
  }

  main() {    
    this.load_events();    
  }  
}

jQuery(function() {
  let orders = new AdminOrders();
  orders.main();

  bind_globals_events();

  AppListenTo('show_deliverie', (e)=>{ if (e.detail.response.success) { window.location.href = e.detail.response.url } });
});