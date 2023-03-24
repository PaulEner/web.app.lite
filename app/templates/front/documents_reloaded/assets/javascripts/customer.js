//= require './events'
//= require './tags'
//= require './uploader'

class DocumentsReloadedCustomer{
  constructor(){
    this.applicationJS   = new ApplicationJS();
    this.edit_tags_modal = $('#tags-edit');

    this.ajax_params =  {
                      'url': '/documents_reloaded',
                      'type': 'GET',
                    }
  }

  load_temp_documents(serialize_form=false, load_customer=false){
    if(this.action_locker)
      return false

    this.action_locker = true;
    let data = [];
    let search_pattern = $('.search-content #search_input').val();

    if(serialize_form){
      data.push($('#pack_filter_form').serialize().toString());

      data.push(`activate_filter=true`);
    }
    else
    {
      search_pattern = '';
      let selector = "#pack_filter_form input, #pack_filter_form select, #customer_document_filter, #journal_document_filter, #search_input";
      $(selector).not('.operator').val(''); data.push( `reinit=true` );
    }

    if(search_pattern && search_pattern != ''){ data.push(`text=${encodeURIComponent(search_pattern)}`); }

    if(this.page > 1){ data.push(`page=${this.page}`) }

    data.push( 'uid=' + $('#customers').val() );

    this.ajax_params['data'] = data.join('&');

    this.applicationJS.sendRequest(this.ajax_params, function(){ $('#more-filter.modal').modal('hide'); })
                       .then((e)=>{
                          if (load_customer){
                            $(".customer-document-content").html($(e).find(".customer-document-content").html());

                            $("#hidden-journal-id").val($('.rubric').first().data('journal-id'));
                            $("#hidden-customer-id").val($('#customers').val());

                            $('select#file_code_customer').val($('#customer_code').val()).trigger("chosen:updated");
                            $('select#file_code_customer').change();
                          }
                          else{
                            $('.box#table_pieces').html($(e).find(".box#table_pieces").html());
                          }

                          $(`.search-content #search_input`).val(search_pattern);

                          if ( $('.filter_active').length > 0 ){
                            $('.filter-info').removeClass('hide');
                          }
                          else{
                            $('.filter-info').addClass('hide');
                          }
                          bind_all_events();
                          this.action_locker = false;
                        })
                       .catch(()=>{ this.action_locker = false; });
  }
}

jQuery(function() {
  let main = new DocumentsReloadedCustomer();

  AppListenTo('journal.before_rubric_addition', (e)=>{
    let customer_id = $('#customers').val();
    let form        = $('#edit-rubric-form');
    let base_uri    = form.attr('base_uri');

    $('#edit-rubric-form').attr('action', `${base_uri.replace('cst_id', customer_id)}`);
  });

  AppListenTo('refresh_customer_view', (e)=>{ setTimeout(()=>{ window.location.reload(true) }, 2000);    });

  AppListenTo('documents_load_datas', (e)=>{ main.load_temp_documents(true); });
  AppListenTo('documents_reinit_datas', (e)=>{ main.load_temp_documents(false); });

  AppListenTo('documents_search_text', (e)=>{ main.load_temp_documents(true); });
  AppListenTo('load_rubric', (e)=>{ main.load_temp_documents(true); });
  AppListenTo('load_customer', (e)=>{ main.load_temp_documents(false, true); });
});