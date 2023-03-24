//= require './events'

class DocumentsReloadedTags{
  constructor(){
    this.applicationJS = new ApplicationJS;
    this.tags_modal    = $('#tags.modal');

    this.ids = []
    this.type = 'pack'
  }

  show_tags(elem){
    let multi = elem.attr('multi') || false;
    let s_id  = 0;

    if(multi == 'true'){
      this.ids = get_all_selected('piece');
      this.type = 'piece';
    }else{
      s_id = elem.attr('data-id')
      this.ids = [s_id];
      this.type = elem.attr('data-type');
    }

    let params =  {
                    'url': '/documents_reloaded/get/tags',
                    'data': { type: this.type, id: s_id },
                    'dataType': 'html'
                  }

    this.applicationJS.sendRequest(params).then((e)=>{
      this.tags_modal.find('.modal-body').html(e);
      this.tags_modal.modal('show');
    });
  }

  update_tags(elem){
    let new_tags = this.tags_modal.find('.tag_reloaded_content #selectionsTags').val();

    let user_id = $('select#customers').val();

    let params =  {
                    'url': '/documents_reloaded/tags/update',
                    'type': 'POST',
                    'data': { type: this.type, ids: this.ids, tags: new_tags, user_id: user_id },
                    'dataType': 'json'
                  }

    this.applicationJS.sendRequest(params).then((e)=>{ window.location.replace(window.location.href);
    this.applicationJS.noticeSuccessMessageFrom(null, e.message);  });

    this.tags_modal.modal('hide');
  }

  delete_tag(elem){
    let parent = elem.parent();
    let d_value = parent.find('.tag_value').val();
    let input = this.tags_modal.find('#selectionsTags');
    let c_value = input.val();

    c_value += `#-${d_value} `;
    input.val(c_value);

    parent.removeClass('d-inline')
    parent.addClass('hide');
  }
}

jQuery(function() {
  let main = new DocumentsReloadedTags();

  AppListenTo('documents_update_tags', (e)=>{ main.show_tags($(e.detail.obj)); });

  $('#tags.modal #add_tags').unbind('click').bind('click', function(e){ main.update_tags() });

  $('#tags.modal').on('show.bs.modal', function(e){
    $('#tags.modal .delete_tag').unbind('click').bind('click', function(e){ main.delete_tag($(this)); });
  });
});