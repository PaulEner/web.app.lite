//= require './main'

class DocumentsOperations extends DocumentsMain{
  constructor(){
    super();

    this.ajax_params =  {
                          'url': '/operations',
                          'type': 'GET',
                        }
  }

  load_reports(serialize_form=false, append=false){
    this.load_datas(serialize_form, append);
  }
}

jQuery(function() {
  let main = new DocumentsOperations();

  AppListenTo('documents_load_datas', (e)=>{ main.load_reports(true) });
  AppListenTo('documents_reinit_datas', (e)=>{ main.load_reports(false) });

  AppListenTo('documents_search_text', (e)=>{ main.load_reports(true); });

  AppListenTo('documents_next_page', (e)=>{ main.load_next_page(); });

  AppListenTo('document_customer_filter', (e)=>{ main.load_reports(true); });
});