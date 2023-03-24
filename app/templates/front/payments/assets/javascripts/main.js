//=require './events'

class Organization {
  constructor () {
    this.applicationJS      = new ApplicationJS();
    this.organization_id    = $('#organization_id').val();
    this.add_new_rule_modal = $('#add-new-rule.modal');
    this.action_locker      = false;
  }

  valid_slimpay_form() {
    const self = this;
    var datas = $('#slimpay_checkout_form').serialize().split('&');
    var errors = [];

    datas.forEach(function(d) {
      var param = d.split('=');
      if (param[0] === 'first_name' && !param[1]) {
        errors.push('Prénom est vide');
      }
      if (param[0] === 'last_name' && !param[1]) {
        errors.push('Nom est vide');
      }
      if (param[0] === 'email' && !param[1]) {
        errors.push('Email est vide');
      }
      if (param[0] === 'address' && !param[1]) {
        errors.push('Adresse est vide');
      }
      if (param[0] === 'city' && !param[1]) {
        errors.push('Ville est vide');
      }
      if (param[0] === 'postal_code' && !param[1]) {
        errors.push('Code postal est vide');
      }
      if (param[0] === 'country' && !param[1]) {
        errors.push('Pays est vide');
      }
    });

    if (errors.length > 0) {
      self.set_slimpay_alert('<ul>' + errors.map(function(e){
        return '<li>' + e + '</li>';
      }).join('') + '</ul>', 'alert-danger');
      return false;
    } else {
      return true;
    }
  }

  set_slimpay_alert(message, type) {
    $('#slimpay_checkout_form #alert').removeClass('hide');
    $('#slimpay_checkout_form #alert').html('<div class="span12 alert ' + type + '">' + message + '</div>');
    window.location.href = '#slimpay_checkout_form';
  }


  reset_slimpay_form() {
    $('#slimpay_checkout_form #alert').addClass('hide');
    $('#slimpay_checkout_form #alert').html('');

    $('#slimpay_checkout #step2_section').html('');

    $('#slimpay_checkout #step1_buttons').removeClass('hide');
    $('#slimpay_checkout #step1_section').removeClass('hide');
    $('#slimpay_checkout #step2_section').addClass('hide');

    $('#slimpay_checkout #step_loader').addClass('hide');

    $('#slimpay_checkout_form input, #slimpay_checkout_form select').each(function(e) {
      $(this).removeAttr('disabled');
    });
  }


  prepare_payment_slimpay(url, data){
    const self = this;
    if (self.valid_slimpay_form()) {
      this.applicationJS.sendRequest({
          'url': url,
          'data': data,
          'type': 'POST',
          'dataType': 'json',
        }).then((response)=>{
          load_slimpay_step();
          if (response.success) {
            $('#slimpay_checkout #step1_section').addClass('hide');
            $('#slimpay_checkout #step2_section').removeClass('hide');
            $('#slimpay_checkout #step1_buttons').addClass('hide');
            if (response.frame_64) {
              var frame = atob(response.frame_64);
              $('#slimpay_checkout #step2_section').html('<div id="checkout_frame_loader" class="feedback active"><span style="margin-left: 40px">Chargement en cours ...</span></div>');
              $('#slimpay_checkout #step2_section').append(frame);
              setTimeout(function() {
                $('#slimpay_checkout #step2_section #checkout_frame_loader').remove();
              }, 4000);
            } else if (response.redirect_uri) {
              window.location.href = response.redirect_uri;
            } else {
              self.set_slimpay_alert('Aucune redirection définie', 'alert-danger');
            }
          } else {
            console.error(response.message);
            self.set_slimpay_alert(response.message, 'alert-danger');
          }
      }).catch((response)=>{
        load_slimpay_step();
        console.error(response);
        self.set_slimpay_alert('Internal serveur error', 'alert-danger');
      });
    }
  }


  confirm_payment_slimpay(url){
    const self = this;
    this.applicationJS.sendRequest({
      'url': url,
      'type': 'POST',
      'dataType': 'json',
    }).then((response)=>{
      $('#payments #payment_configuration_checker').addClass('hide');
      if (response.success) {
        if (response.debit_mandate['transactionStatus'] === 'success') {
          $('#payments td#debit_state').html('<span class="badge badge-success fs-origin">OK</span>');
        } else if (response.debit_mandate['transactionStatus'] === 'started') {
          $('#payments td#debit_state').html('<span class="badge badge-warning fs-origin">En attente utilisateur ...</span>');
        } else {
          $('#payments td#debit_state').html('<span class="badge badge-secondary fs-origin">Non configuré</span>');
          self.reset_slimpay_form();
        }
        $('#payments td#debit_bic').html(response.debit_mandate.bic);
        $('#payments td#debit_name').html(response.debit_mandate.title + ' ' + response.debit_mandate.firstName + ' ' + response.debit_mandate.lastName);
        $('#payments td#debit_email').html(response.debit_mandate.email);
      }
    }).catch((response)=>{
      $('#payments #payment_configuration_checker').addClass('hide');
      $('#payments td#debit_state').html("<span class='badge badge-danger fs-origin'>Une erreur inattendue s'est produite, Veuillez réessayer ultérieurement.</span>");
    });
  }
}

jQuery(function () {

  let organization = new Organization();
  

  AppListenTo('prepare_payment_slimpay', (e)=>{ organization.prepare_payment_slimpay(e.detail.url, e.detail.data); });
  AppListenTo('confirm_payment_slimpay', (e)=>{ organization.confirm_payment_slimpay(e.detail.url); });
});