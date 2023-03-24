//= require './main'
//= require './tags'
//= require './uploader'
//= require './preseizures'
//= require './events'

class MyDocumentsPieces extends MyDocumentsMain{
  constructor(){
    super();
  }

  load_packs(serialize_form=false, append=false){
    this.load_collaborator_datas(serialize_form, append);
  }

  load_collaborator_pieces(serialize_form=false, append=false){
    this.load_collaborator_datas(serialize_form);
  }


  delete_piece(elem){
    if(confirm('Voulez vous vraiment supprimer la(les) pièce(s) sélectionnée(s)')){
      let multi = elem.attr('multi') || false;
      let ids   = []

      if(multi == 'true'){
        ids = get_all_selected('piece');
      }
      else{
        ids.push( parseInt(elem.attr('data-id')) );
      }

      if(ids.length > 0){
        let params =  {
                        'url': '/my_documents/delete',
                        'data': { ids: ids },
                        'type': 'POST',
                        'dataType': 'json'
                      }

        this.applicationJS.sendRequest(params).then((e)=>{ this.load_collaborator_pieces(true); });
      }
    }
  }

  restore_piece(id){
     if(confirm('Voulez vous vraiment restaurer cette pièce')){
        let params =  {
                        'url': '/my_documents/restore',
                        'data': { id: id },
                        'type': 'POST',
                        'dataType': 'json'
                      }

        this.applicationJS.sendRequest(params).then((e)=>{ this.load_collaborator_pieces(true); $(".modal").modal('hide');});
    }
  }
}




jQuery(function() {
  let main = new MyDocumentsPieces();

  AppListenTo('documents_load_datas', (e)=>{ main.load_packs(true); });
  AppListenTo('documents_reinit_datas', (e)=>{ main.load_packs(false); });

  AppListenTo('documents_search_text', (e)=>{ main.load_collaborator_pieces(true); });

  AppListenTo('documents_next_page', (e)=>{ main.load_next_page(); });

  AppListenTo('document_customer_filter', (e)=>{ main.load_packs(true); });
  AppListenTo('filter_pack_badge', (e)=>{ main.load_packs(true); });

  AppListenTo('document_collaborator_filter', (e)=>{ main.load_collaborator_pieces(true); });

  AppListenTo('documents_loaded_delete_piece', (e)=>{ main.delete_piece($(e.detail.obj)) });
  AppListenTo('documents_loaded_restore_piece', (e)=>{ main.restore_piece(e.detail.id) });

  AppListenTo('document_reloaded.toggle_piece_detail', (e)=>{
    let obj = e.detail.element;
    let piece_id  = $(obj).attr('datas-piece-id');
    let container = $(`.tr_piece_${piece_id}`);
    
    container.toggle('');

    if( container.find('.preseizures_box').length > 0 ){
      e.set_key('skip_ajax', true);
    }
  });
});