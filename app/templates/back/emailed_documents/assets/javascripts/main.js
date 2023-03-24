class AdminEmailedDocument {
  constructor(){
    this.applicationJS      = new ApplicationJS;    
    this.emailed_doc_modal  = $('#filter-emailed-document.modal');
    this.emailed_doc_error_list_modal  = $('#email_errors_list.modal');
  }

  load_events(){
    let self = this;

    $('.filter-emailed-document').unbind('click').bind('click',function(e) {
      e.preventDefault();      

      self.emailed_doc_modal.modal('show');
    });

    $('.list-errors').unbind('click').bind('click',function(e) {
      e.preventDefault();      

      self.load_errors($(this).data('id'));
    });
  }

  load_errors(id){
    let self = this

    let url = '/admin/emailed_documents/' + id + '/show_errors'


    let ajax_params = {
      url: url,
      type: 'GET',
      dataType: 'html',
    }

    self.applicationJS.sendRequest(ajax_params).then((e)=>{
      self.emailed_doc_error_list_modal.find('.modal-body').html(e);

      self.emailed_doc_error_list_modal.modal('show');
    });
  } 
}

jQuery(function() {
  let emailed_doc = new AdminEmailedDocument();
  emailed_doc.load_events();

 AppListenTo('window.application_auto_rebind', (e)=>{  emailed_doc.load_events(); });
});