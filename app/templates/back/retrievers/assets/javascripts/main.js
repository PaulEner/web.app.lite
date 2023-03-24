class AdminRetriever {
  constructor(){
    this.retriever_filter_modal  = $('#filter-retriever');
  }

  load_events(){
    let self = this;

    $('.retrievers-filter').unbind('click').bind('click',function(e) {
      e.preventDefault();      

      self.retriever_filter_modal.modal('show');
    });

  }

}

jQuery(function() {
  let retriever = new AdminRetriever();
  
  retriever.load_events();
  AppListenTo('window.application_auto_rebind', (e)=>{  retriever.load_events(); });
});

