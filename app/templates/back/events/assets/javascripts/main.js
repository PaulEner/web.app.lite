class AdminEvents {
  constructor(){
    this.applicationJS    = new ApplicationJS;    
    this.orders_modal     = $('#filter-orders.modal');    
  }

  show_event(id){
    $('#events .show').html('');

    $.ajax({
      url: '/admin/events/' + id,
      data: '',
      type: "GET",
      success: function(data){
        $('#events .details.focusable').click()
        $('#events .show').html(data)  
      }
    });

  }

  load_events(){
    let self = this;

    $('#events .focusable').unbind('click').bind('click',function(e) {
      e.preventDefault();      

      $('#events .focused').removeClass('focused')
      $(this).addClass('focused')
    });

    $('tbody tr td.do-show').unbind('click').bind('click',function(e) {
      e.preventDefault();      

      let tr = $(this).parent('tr')
      self.show_event(tr.data('id'))
    });

    $('.events-filter').unbind('click').bind('click',function(e) {
      e.preventDefault();      

      self.orders_modal.modal('show');
    });
  }

  main() {
    this.load_events();    
  }
}

jQuery(function() {
  let event = new AdminEvents();
  event.main();

  bind_globals_events();

  AppListenTo('show_events', (e)=>{ if (e.detail.response.success) { window.location.href = e.detail.response.url } });
});