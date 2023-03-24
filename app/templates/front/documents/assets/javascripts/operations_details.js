//= require './main'
//= require './preseizures'

class DocumentsOperationsDetails extends DocumentsMain{
  constructor(){
    super();

    this.report_id = $('#current_report').attr('data-id');
    this.ajax_params =  {
                          'url': `/operations/${this.report_id}`,
                          'type': 'GET',
                        }
  }

  load_operations(serialize_form=false, append=false){
    this.load_datas(serialize_form, append);
  }
}

jQuery(function() {
  let main = new DocumentsOperationsDetails();

  AppListenTo('documents_load_datas', (e)=>{ main.load_operations(true) });
  AppListenTo('documents_reinit_datas', (e)=>{ main.load_operations(false) });

  AppListenTo('documents_search_text', (e)=>{ main.load_operations(true); });

  AppListenTo('documents_next_page', (e)=>{ main.load_next_page(); });
});