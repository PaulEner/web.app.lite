class AdminScanningProviders {
  constructor(){
    this.applicationJS      = new ApplicationJS;    
    this.news_modal         = $('#scanning_providers-modal.modal');
  }

  load_asp(id=0, read_only=false){
    let self = this;

    let url = '/admin/scanning_providers/new'

    if (id != 0)
      url = '/admin/scanning_providers/'+ id +'/edit'

    if (read_only)
      url = '/admin/scanning_providers/'+ id

    let ajax_params = {
                        url: url,
                        type: 'GET',
                        dataType: 'html',
                      }

    self.applicationJS.sendRequest(ajax_params).then((e)=>{
      self.news_modal.find('.modal-body').html(e);

      self.news_modal.modal('show');
    });
  }

  load_events(){
    let self = this;

    $('#scanning_provider_customer_tokens').tokenInput("/admin/users/search_by_code.json?full_info=true", {
	    theme: "facebook",
	    searchDelay: 500,
	    minChars: 2,
	    preventDuplicates: true,
	    prePopulate: $('#scanning_provider_customer_tokens').data('pre'),
	    hintText: "Tapez un code utilisateur à rechercher",
	    noResultsText: "Aucun résultat",
	    searchingText: "Recherche en cours..."
		});

    $('.new-asp').unbind('click').bind('click',function(e) {
      e.preventDefault();

      self.load_asp();
    });

    $('.edit-asp').unbind('click').bind('click',function(e) {
      e.preventDefault();

      self.load_asp($(this).data('id'));
    });
  }

  main() {
    this.load_events();
  }
}

jQuery(function() {
  let asp = new AdminScanningProviders();
  asp.main();

  bind_globals_events();
});
