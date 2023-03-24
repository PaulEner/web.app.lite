//= require './events'
//= require './mcf_customer'


jQuery(function() {
  let mcf = new McfCustomer();
  AppListenTo('show_mcf_edition', (e)=>{ mcf.show_mcf_edition(e.detail.url); });
});