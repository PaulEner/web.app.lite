//= require './events'
//= require './tags'
//= require './uploader'

class MyDocumentsCustomer{
  constructor(){
    this.applicationJS   = new ApplicationJS();
    this.edit_tags_modal = $('#tags-edit');

    this.ajax_params =  {
                      'url': '/my_documents',
                      'type': 'GET',
                    }
  }

  load_pieces(serialize_form=false, load_rubric=false, load_customer=false, all=false){
    if(this.action_locker)
      return false

    this.action_locker = true;
    let data       = [];
    let journal_id = $('#hidden-journal-id').val();
    let advanced_search    = $('#form_' + journal_id);
    let form_serialization = '';

    if(serialize_form || load_rubric){
      $('#hidden-journal-id').val('');
      data.push($('#customer_filter_form').serialize().toString());
    }
    else
    {
      let selector   = "#customer_filter_form input, #search_input";
      $(selector).not('.operator').val('');      
    }

    if(this.page > 1){ data.push(`page=${this.page}`) }

    data.push( 'uid=' + btoa($('#customers').val()) );

    if (!all && !load_customer )
      data.push( 'journal_id=' + journal_id );

    this.ajax_params['data'] = data.join('&');

    this.applicationJS.sendRequest(this.ajax_params, function(){ $('#more-filter.modal').modal('hide'); })
                       .then((e)=>{
                          $('#table_pieces').html($(e).find("#table_pieces").html());

                          if(serialize_form && $('.rubric.trigge span.link_principal.active').length == 0)
                          {
                            $('#customer-result').addClass('hide');
                            setTimeout((e)=>{ $('.rubric.trigge:first').click(); }, 500);
                          }
                          else
                          {
                            $('#customer-result').removeClass('hide');
                          }

                          $('select#l_journal').val(journal_id).trigger("chosen:updated");
                          bind_all_events();
                          clean_url();

                          this.action_locker = false;
                        })
                       .catch(()=>{ this.action_locker = false; });
  }

  download_document(piece_ids){
    let url_download = window.location.href + `/download_selected_zip/${piece_ids.join('_')}`

    window.location.replace(url_download);
  }
}

function clean_url(){
  let url         = window.location.href
  let new_history = url.split('?')[0]
  new_history     = new_history.split('#')[0]

  history.pushState({}, "", new_history);
}

jQuery(function() {
  let main = new MyDocumentsCustomer();

  clean_url();

  AppListenTo('journal.before_rubric_addition', (e)=>{
    let customer_id = $('#customers').val();
    let form        = $('#edit-rubric-form');
    let base_uri    = form.attr('base_uri');

    $('#edit-rubric-form').attr('action', `${base_uri.replace('cst_id', customer_id)}`);
  });

  AppListenTo('refresh_customer_view', (e)=>{ setTimeout(()=>{ window.location.reload(true) }, 2000);    });

  AppListenTo('documents_load_datas', (e)=>{ main.load_pieces(true); });
  AppListenTo('documents_reinit_datas', (e)=>{ main.load_pieces(false); });
  AppListenTo('load_all_documents', (e)=>{ main.load_pieces(false, false, false, true); });

  AppListenTo('documents_search_text', (e)=>{ main.load_pieces(true); });
  AppListenTo('load_rubric', (e)=>{ main.load_pieces(false, true); });
  AppListenTo('load_customer', (e)=>{ main.load_pieces(false, false ,true); });
  AppListenTo('download_piece_zip', (e)=>{ main.download_document(e.detail.ids) });
});