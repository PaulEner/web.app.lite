class RPDocumentsSelection{
  constructor(mainJS){
    this.applicationJS = new ApplicationJS();
    this.main          = mainJS;
  }

  integrate_documents(){
    let document_ids = []
    $('table input.selected_document').each((e, elem)=>{
      if($(elem).is(':checked')){
        document_ids.push($(elem).data('value'));
      }
    });

    let confirm_mess = 'Voulez vous vraiment intégrer le document séléctionné?';
    if(document_ids.length > 1)
      confirm_mess = `Voulez vous vraiment intégrer les ${document_ids.length} documents séléctionnés?`;

    if(confirm(confirm_mess)){
      let ajax_params = {
                          'url': '/retriever/integrate_documents',
                          'data': { document_ids: document_ids },
                          'type': 'POST',
                          'dataType': 'json'
                        };

      this.applicationJS.sendRequest(ajax_params).then((e)=>{ this.main.load_datas('documents-selection'); this.applicationJS.noticeSuccessMessageFrom(null, e.message); });
    }
  }
}