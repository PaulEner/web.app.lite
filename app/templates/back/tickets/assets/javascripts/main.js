//= require './events'

class AdminTickets {
  constructor(){
    this.applicationJS  = new ApplicationJS;    
    this.ticket_modal   = $('#tickets-modal.modal');    
  }

  load_tickets(id=0){
    let self = this;

    let url = '/admin/tickets/new'

    if (id != 0)
      url = '/admin/tickets/'+ id +'/edit'

    let ajax_params = {
                          url: url,
                          type: 'GET',
                          dataType: 'html',
                        }

    self.applicationJS.sendRequest(ajax_params).then((e)=>{ 
      self.ticket_modal.find('.modal-body').html(e);

      self.ticket_modal.modal('show');
    });

  }

  load_events(){
    let self = this;

    $('.tickets-filter').unbind('click').bind('click',function(e) {
      e.preventDefault();


      // $('.modal#filter-organizations').modal('show');
    });

    $('.tickets-new').unbind('click').bind('click',function(e) {
      e.preventDefault();

      self.load_tickets();
    });


    $('.edit-ticket').unbind('click').bind('click',function(e) {
      e.preventDefault();

      self.load_tickets($(this).data('id'));
    });

    $('#table_tickets td.view-content').mouseover(function() {
      $(this).find('.popover_content_tickets').show();
    })
    .mouseout(function() {
      $(this).find('.popover_content_tickets').hide();
    });
  }

  main() {
    this.load_events();    
  }  
}

jQuery(function() {
  let ticket = new AdminTickets();
  ticket.main();

  bind_globals_events();

  AppListenTo('show_tickets', (e)=>{ if (e.detail.response.success) { window.location.href = e.detail.response.url } });
});