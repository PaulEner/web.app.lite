//=require './events'

class BoxDocument{
  constructor(){
    this.applicationJS = new ApplicationJS;
  }

  select_ibizabox_documents(url){
    this.applicationJS.sendRequest({ 'url': url }).then((element)=>{
      $('#select_ibizabox_documents').html($(element).find('.ibizabox_documents').html());

      bind_ibizabox_documents_events();
    }).catch((error)=> { 
      console.error(error);
    });
  }
}

jQuery(function() {
  let box_document = new BoxDocument();

  let load_select = false

  if ($('#select_ibizabox_documents').length > 0 && !load_select){
    const url = $('#select_ibizabox_documents').attr('link');
    box_document.select_ibizabox_documents(url);
    load_select = true
  }
})