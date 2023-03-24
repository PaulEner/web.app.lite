//= require './main'
//= require './tags'
//= require './preseizures'

class MyDocumentsDetails extends MyDocumentsMain{
  constructor(){
    super();

    this.pack_id = $('#current_pack').attr('data-id');
    this.ajax_params =  {
                          'url': `/my_documents/${this.pack_id}`,
                          'type': 'GET',
                        }
  }

  load_pieces(serialize_form=false, append=false){
    this.load_datas(serialize_form, append);
  }

  delete_piece(elem){
    if(confirm('Voulez vous vraiment supprimer cette(ces) pièce(s)')){
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

        this.applicationJS.sendRequest(params).then((e)=>{ this.load_pieces(true); });
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

        this.applicationJS.sendRequest(params).then((e)=>{ this.load_pieces(true); $(".modal").modal('hide');});
    }
  }

  edit_analysis(code, is_used=false){
    let selected_pieces = get_all_selected('piece');
    let id = ''
    if(selected_pieces.length == 1)
      id = selected_pieces[0]

    if(is_used){
      $('#comptaAnalysisEdition.modal').modal('show');
      AppEmit('compta_analytics.main_loading', { code: code, pattern: id, type: 'piece', is_used: true });
    }
  }

  update_analytics(data={}){
    let params =  {
                    url: '/my_documents/pieces/update_analytics',
                    type: 'POST',
                    data: { analysis: data, pieces_ids: get_all_selected('piece') },
                    dataType: 'json'
                  }

    this.applicationJS.sendRequest(params).then((e)=>{ this.load_pieces(true); });
  }

  show_preseizures_modal(elem){
    let preseizure_id = elem.attr('data-preseizure-id');
    if(preseizure_id){
      let params =  {
                      'url': `/my_documents/preseizures/${preseizure_id}`,
                      'data': { view: 'by_type' },
                      'dataType': 'html'
                    }

      this.applicationJS.sendRequest(params).then((e)=>{
        $('#view-document-content .modal-body').html($(e).find('.preseizures_box').html());
        $('#view-document-content .modal-body .for-dismiss-modal').html($('.dismiss-modal').clone().removeClass('hide').html());
        $('#view-document-content').modal('show');
        bind_all_events();
      });
    }
  }
}

jQuery(function() {
  let main = new MyDocumentsDetails();

  AppListenTo('documents_show_preseizures_details', (e)=>{ main.show_preseizures_modal($(e.detail.obj)) });

  AppListenTo('documents_load_datas', (e)=>{ console.log('button'); main.load_pieces(true) });
  AppListenTo('documents_reinit_datas', (e)=>{ main.load_pieces(false) });

  AppListenTo('documents_delete_piece', (e)=>{ main.delete_piece($(e.detail.obj)) });
  AppListenTo('documents_restore_piece', (e)=>{ main.restore_piece(e.detail.id) });

  AppListenTo('documents_edit_analysis', (e)=>{ main.edit_analysis(e.detail.code, e.detail.is_used) });

  AppListenTo('documents_search_text', (e)=>{ console.log('key'); main.load_pieces(true); });

  AppListenTo('compta_analytics.validate_analysis', (e)=>{ main.update_analytics(e.detail.data) });

  AppListenTo('documents_next_page', (e)=>{ main.load_next_page(); });
});