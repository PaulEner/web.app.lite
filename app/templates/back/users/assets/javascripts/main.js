//= require './events'

class AdminUsers {
  constructor(){
    this.applicationJS                   = new ApplicationJS;    
    this.create_organization_modal       = $('#create-new-organizations.modal');    
  }
  main() {
  }  
}

jQuery(function() {
  bind_globals_events();  
});