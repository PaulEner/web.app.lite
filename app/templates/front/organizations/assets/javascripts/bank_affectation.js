jQuery(function () {
  $('.check-bank-rule').unbind('click')
  $(".check-bank-rule").bind('click',function(e) {
      e.stopPropagation();

      if ($('label.container input:checked').length > 0){
        $('#export-rule').removeClass('btn-light-secondary').addClass('btn-light');
        $('#delete-rule').removeClass('btn-light-secondary').addClass('btn-danger');
      }
      else{
        $('#export-rule').removeClass('btn-light').addClass('btn-light-secondary');
        $('#delete-rule').removeClass('btn-danger').addClass('btn-light-secondary');
      }
  });

  $('.check-all-bank-rule').unbind('click')
  $(".check-all-bank-rule").bind('click',function(e) {
    e.stopPropagation();

    if ($(this).is(':checked')){
      $('#export-rule').removeClass('btn-light-secondary').addClass('btn-light');
      $('#delete-rule').removeClass('btn-light-secondary').addClass('btn-danger');
      $(".check-bank-rule").prop('checked', true);
    }
    else{
      $('#export-rule').removeClass('btn-light').addClass('btn-light-secondary');
      $('#delete-rule').removeClass('btn-danger').addClass('btn-light-secondary');
      $(".check-bank-rule").prop('checked', false);
    }
  });


  $('.add-rule button').unbind('click')
  $(".add-rule button").bind('click',function(e) {
      e.stopPropagation();      

      if ($(this).parent().find('div.sub_rule_menu').length > 0){
        $(this).parent().find('div.sub_rule_menu').remove()
      }
      else {
        $(this).parent().append($('.sub_rule_append').html());

        $(this).parent('div').find('li.add').unbind('click')
        $(this).parent('div').find('li.add').bind('click',function(e) {
          e.stopPropagation();      

          $('#apply-to').multiSelect({
            "noneText": "Choisir le type d'opération"
          });

          $('#add-new-rule #affect-to').multiSelect({
            "noneText": "Choisir une affectation"
          });

          $('#rule-type').multiSelect({
            "noneText": "Choisir le type de règle"
          });

          $('#customers-list').multiSelect({
            "noneText": "Séléctionnez les clients affectés par la règle"
          });          

          $('#add-new-rule').modal('show');

          $('#affect-to').unbind('change');
          $("#affect-to").bind('change',function(e) {
            e.stopPropagation();

            if ($(this).val() == 'customer'){
              $('.customers-list').removeClass('hide');
            }
            else{
              $('.customers-list').addClass('hide');
            }
          });

        });

        $(this).parent('div').find('li.download').unbind('click')
        $(this).parent('div').find('li.download').bind('click',function(e) {
          e.stopPropagation();

          $('#import-rule #affect-to').multiSelect({
            "noneText": "Choisir une affectation"
          });

          $('#import-rule').modal('show');
        });
      }
  });
});