//= require './events'

function get_all_selected(obj = 'piece', get_preseizure_ids=false){
  let array_ids = [];
  let type      = (obj == 'operation')? 'operation' : 'document';

  $(`.form-check-input.select-${type}`).each(function(e){
    if($(this).is(':checked')){
      if(get_preseizure_ids && obj == 'piece'){
        let ids = JSON.parse($(this).attr('data-preseizure-ids') || '[]');
        ids.forEach((t)=>{
          if( t && t > 0 ){ array_ids.push(t) }
        });
      }else{
        let id = parseInt($(this).attr('data-id'));
        if(id > 0){ array_ids.push(id); }
      }
    }
  });

  return array_ids;
}

class DocumentsMain{
  constructor(){
    this.applicationJS = new ApplicationJS();
    this.action_locker = false;
    this.page = 1;
    this.ajax_params = {};

    this.export_params = {};
  }

  load_datas(serialize_form=false, append=false){
    if(this.action_locker)
      return false

    if(!append)
      this.page = 1;

    this.action_locker = true;
    let data = [];

    if(serialize_form){
      data.push($('#pack_filter_form').serialize().toString());
      if(!append)
        data.push(`activate_filter=true`);
    }
    else
    {
      let selector = "#pack_filter_form input, #pack_filter_form select, #customer_document_filter, #journal_document_filter, #search_input";
      $(selector).not('.operator').val(''); data.push( `reinit=true` );
    }

    let search_pattern = $('.search-content #search_input').val();

    if(search_pattern && search_pattern != ''){ data.push(`text=${encodeURIComponent(search_pattern)}`); }
    if(this.page > 1){ data.push(`page=${this.page}`) }

    let grid_or_list_view = 'list'
    if($('.box.grid').length > 0 && $('.box.grid').not('.hide').length > 0){
      grid_or_list_view = 'grid'
    }
    data.push(`grid_or_list_view=${grid_or_list_view}`)

    if ($('#customer_document_filter').val()){
      data.push( 'view=' + $('#customer_document_filter').val() )
    }

    if($('#journal_document_filter').val()){
      data.push( 'journal=' + $('#journal_document_filter').val() )
    }

    if($('#badge-filter').val()){
      data.push( 'badge_filter=' + $('#badge-filter').val() )
    }

    this.ajax_params['target'] = (append)? null : '.main-content';
    this.ajax_params['data']   = data.join('&');

    this.applicationJS.sendRequest(this.ajax_params, function(){ $('#more-filter.modal').modal('hide'); })
                       .then((e)=>{
                          if(append){
                            if($(e).find('.no-data-found').length > 0){
                              this.applicationJS.noticeSuccessMessageFrom(null, 'Plus aucun résultat!');
                              this.page = -1;
                            }else{
                              $('.all-results').append($(e).find('.all-results').html());
                            }
                          }

                          this.action_locker = false
                          bind_all_events();
                        })
                       .catch(()=>{ this.action_locker = false; });
  }

  load_next_page(){
    if(this.page < 0) return false;

    this.page = this.page + 1;

    if(this.page > 1)
      this.load_datas(true, true);
  }

  fetch_export_options(elem){
    let tmp_params = { 'ids': [elem.attr('data-id')], 'type': elem.attr('data-type'), 'multi': (elem.attr('data-multi') || false) };
    let params = JSON.parse(JSON.stringify(tmp_params)) || {}; //IMPORTANT: Clone the json object
    let information = "Vous êtes sur le point d'exporter une écriture comptable";

    if(params['multi'] == 'true')
    {
      if(params['type'] == 'special_piece')
      {
        params['ids']  = get_all_selected('piece');
        params['type'] = 'piece';
        information    = `Vous êtes sur le point d'exporter les écritures comptables de ${params['ids'].length} pièce(s)`;

        if(params['ids'].length == 0){
          params['ids']  = tmp_params['ids'];
          params['type'] = 'pack';
          information    = `Vous êtes sur le point d'exporter toutes les écritures comptables du lot`;
          if($('span.filter-info').length > 0)
            information += ' <span class="badge bg-info bold">liées au filtre</span>';
        }
      }
      else
      {
        params['ids'] = get_all_selected('operation');
        params['type'] = 'preseizure';
        information    = `Vous êtes sur le point d'exporter les écritures comptables de ${params['ids'].length} opération(s)`;

        if(params['ids'].length == 0){
          params['ids'] = tmp_params['ids'];
          params['type'] = 'report';
          information    = `Vous êtes sur le point d'exporter toutes les écritures comptables du lot`;
          if($('span.filter-info').length > 0)
            information += ' <span class="badge bg-info bold">liées au filtre</span>';
        }
      }
    }

    let current_uri = window.location.pathname;

    if(current_uri.match(/operations/))
      params['source'] = 'operations';
    else
      params['source'] = 'documents';

    this.export_params = params;

    this.applicationJS.sendRequest({ 'url': '/documents/export_options', 'type': 'POST', 'data': this.export_params, target: null, dataType: 'json' })
                      .then((e)=>{
                        let options = e.options;
                        let html = '';

                        options.forEach((opt)=>{
                          html += `<option value=${opt[1]}>${opt[0]}</options>`
                        });

                        $('#preseizures_export #export_type').html(html);
                        $('#preseizures_export p.information').html(information);

                        $('#preseizures_export').modal('show');
                      });
  }

  launch_export(){
    let params = this.export_params;
    params['format']       = $('#preseizures_export #export_type').val();
    params['is_operations'] = VARIABLES.get('is_from_operation_page');

    let str_params = JSON.stringify(params);

    window.location.href = `/documents/export_preseizures/${btoa(str_params)}`;
  }

  download_pack_archive(pack_id){
    window.location.href = `/documents/download_archive/${pack_id}`;
  }

  download_pack_bundle(pack_id){
    window.location.href = `/documents/download_bundle/${pack_id}`
  }

  deliver_preseizures(elem){
    let tmp_params = { 'ids': [elem.attr('data-id')], 'type': elem.attr('data-type'), 'multi': elem.attr('data-multi') };
    let params = JSON.parse(JSON.stringify(tmp_params)) || {}; //IMPORTANT: Clone the json object
    let information = 'Voulez vous vraiment livrer cette écriture comptable';

    if(params['multi'] == 'true')
    {
      if(params['type'] == 'special_piece')
      {
        params['ids']  = get_all_selected('piece');
        params['type'] = 'piece';
        information    = `Voulez vous vraiment livrer les écritures comptables non livrées de ${params['ids'].length} pièce(s)?`;

        if(params['ids'].length == 0){
          params['ids']  = tmp_params['ids'];
          params['type'] = 'pack';
          information    = `Voulez vous vraiment livrer les écritures comptables non livrées du lot?`;
          if($('span.filter-info').length > 0)
            information += ' (Liées au filtre)';
        }
      }
      else
      {
        params['ids'] = get_all_selected('operation');
        params['type'] = 'preseizure';
        information    = `Voulez vous vraiment livrer les écritures comptables non livrées de ${params['ids'].length} opération(s)?`;

        if(params['ids'].length == 0){
          params['ids']  = tmp_params['ids'];
          params['type'] = 'report';
          information    = `Voulez vous vraiment livrer les écritures comptables non livrées du lot?`;
          if($('span.filter-info').length > 0)
            information += ' (Liées au filtre)';
        }
      }
    }

    params['is_operations'] = VARIABLES.get('is_from_operation_page');

    let ajax_params =  {
                          'url': '/documents/deliver_preseizures',
                          'type': 'POST',
                          'data': params,
                          'dataType': 'json'
                        }

    if(confirm(information))
      this.applicationJS.sendRequest(ajax_params).then((e)=>{ this.applicationJS.noticeSuccessMessageFrom(null, `${e.size} livraison(s) en cours ...`); });
  }

}

jQuery(function() {
  let main = new DocumentsMain();

  AppListenTo('download_pack_archive', (e)=>{ main.download_pack_archive($(e.detail.obj).attr('data-id')); });
  AppListenTo('download_pack_bundle', (e)=>{ main.download_pack_bundle($(e.detail.obj).attr('data-id')); });

  AppListenTo('documents_deliver_preseizures', (e)=>{ main.deliver_preseizures($(e.detail.obj)); });

  AppListenTo('documents_export_preseizures', (e)=>{ main.fetch_export_options($(e.detail.obj)); });
  $('#preseizures_export.modal #export_button').unbind('click').bind('click', function(){ main.launch_export(); });
});