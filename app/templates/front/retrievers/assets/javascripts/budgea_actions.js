function load_all_actions(budgeaApi, applicationJS){
  $('.scarequire_decoupled_button').unbind('click').bind('click', function(e) {
    e.preventDefault();
    var self;
    var finalize = ()=>{
      applicationJS.sendRequest({ url: '/retrievers', type: 'GET', target: '.retrievers-list' }).then((e)=>{
        applicationJS.noticeSuccessMessageFrom(null, 'Configuration automate terminée.');
      });
    }

    self = $(this);
    if (confirm("Voulez vous vraiment lancer la synchronisation de cet automate ? La synchronisation peut prendre un moment ...")) {
      var data, id;
      id = self.attr('data-id');
      $('.state_field_' + id).text("Procedure d'authentification en cours...");
      data = '';

      if (self.attr('id') === 'decoupled') {
        data = {
          resume: true
        };
      }
      
      AppEmit('budgeaApi.user_changed', { user_id: self.attr('data-user-id') }).then((e)=>{
        setTimeout((f)=>{
          budgeaApi.refresh_connection(id, data).then(function() {
            finalize();
          }, function() {
            finalize();
          });
        }, 2000)
      });
    }
  });

  $('.webauth_button').unbind('click').bind('click', function(e) {
    var id, user_id, id_connection, self, options;
    e.preventDefault();
    self = $(this);
    if (confirm("Voulez-vous vraiement lancer la procédure d'authentification ? La synchronisation peut prendre un moment ...")) {
      id = self.attr('data-id');
      user_id = self.attr('data-user-id');

      $('#loading_' + id).removeClass('hide');
      self.attr("disabled", true);
      id_connection = $('#ido_connector_id_' + id).val() || 0;
      if (id_connection !== 0) {
        options = {
                    'ido_capabilities': $(`#ido_capabilities_${id}`).val(),
                    'ido_connector_id': $(`#ido_connector_id_${id}`).val(),
                    'ido_custom_name': $(`#ido_custom_name_${id}`).val(),
                    'ido_connector_name': $(`#ido_connector_name_${id}`).val(),
                  }

        AppEmit('budgeaApi.user_changed', { user_id: user_id }).then((e)=>{
          setTimeout((f)=>{ budgeaApi.webauth(user_id, id_connection, false, options); }, 2000);
        });
      }
    }
  });
}

jQuery(function() {
  var _budgeaApi     = new BudgeaApi();
  var _applicationJS = new ApplicationJS();

  AppListenTo('window.application_auto_rebind', (e)=>{ load_all_actions(_budgeaApi, _applicationJS) }); 
})