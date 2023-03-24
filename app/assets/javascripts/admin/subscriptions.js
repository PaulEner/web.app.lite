var loadAccounts = function(type, renderer){
  $.ajax({
    url: "/admin/subscriptions/accounts",
    data: { type: type },
    type: "POST",
    success: function(data){
      renderer.find(".modal-body").html(data);
    },
    error: function(data){
      renderer.find(".modal-body").html("<p>Erreur lors du chargement des données, veuillez réessayer plus tard</p>");        
    }
  });
}

jQuery(function () {
  // $('span.popover_active').popover({trigger: 'hover'})
  
  $('a.do-showAccounts').unbind('click').bind('click', function(e){
    e.preventDefault();    

    $accountsDialog = $('#showAccounts');
    $accountsDialog.find('h3').text($(this).attr('title'));
    $accountsDialog.find(".modal-body").html("<span class='loading'>Chargment en cours ...</span>");
    $accountsDialog.modal('show');
    loadAccounts($(this).attr('type'), $accountsDialog);
  });
});


$(window).scroll(function(e){
  topWindow = $(window).scrollTop();

  offset = $('#subscriptions #statistic_table').offset();
  table_position_top = offset.top - topWindow;

  if (table_position_top > 45)
    $('#subscriptions #detachable_header').fadeOut('fast');
  else
    $('#subscriptions #detachable_header').slideDown('fast');
})