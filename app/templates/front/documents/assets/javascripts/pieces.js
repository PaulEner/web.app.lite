//= require './main'
//= require './tags'
//= require './uploader'

class DocumentsPieces extends DocumentsMain{
  constructor(){
    super();

    this.ajax_params =  {
                          'url': '/documents',
                          'type': 'GET',
                        }
  }

  load_packs(serialize_form=false, append=false){
    this.load_datas(serialize_form, append);
  }

  delete_pack_pieces(pack_id){
    let params =  {
                    url: '/documents/delete',
                    type: 'POST',
                    data: { pack_id: pack_id },
                    dataType: 'json'
                  }
    if (confirm('Voulez-vous vraiment supprimer toutes les pièces ? ')){
      this.applicationJS.sendRequest(params).then((e)=>{ this.load_datas(true); });
    }
  }
}

jQuery(function() {
  let main = new DocumentsPieces();

  AppListenTo('documents_load_datas', (e)=>{ main.load_packs(true); });
  AppListenTo('documents_reinit_datas', (e)=>{ main.load_packs(false); });

  AppListenTo('documents_search_text', (e)=>{ main.load_packs(true); });

  AppListenTo('documents_next_page', (e)=>{ main.load_next_page(); });

  AppListenTo('document_customer_filter', (e)=>{ main.load_packs(true); });
  AppListenTo('filter_pack_badge', (e)=>{ main.load_packs(true); });

  AppListenTo('delete_all_pieces', (e)=>{ main.delete_pack_pieces(e.detail.pack_id)});
});