jQuery(function () {
  $(".principal li span.link_principal, .principal .slave li span.link_slave").unbind('click.lefter').bind('click.lefter',function(e) {
    $('.principal li span.link_principal, .principal li span.link_slave').removeClass('active');
    $(this).addClass('active');
    if ($(this).parent().data('href') == "parametres"){
      $(this).parent().find('.chevron').toggle();
      $(this).parent().find('ul').slideToggle();
      $('.principal li span.link_slave').removeClass('active');
      $(this).addClass('active');
    }
    else{
      $(".organizations .content").html('');
      if ($(this).hasClass('link_slave')){
        $('.parameters').addClass('active');
      }
    }
  });


  /* SPECIAL HEADER CUSTOMER LINKS */
    $('a.head_customer_link').unbind('click.head_customer').bind('click.head_customer', function(e){
      e.preventDefault();

      if( $(this).hasClass('active') )
        return false

      let url    = $(this).attr('href');
      let app    = new ApplicationJS();

      $('a.head_customer_link').removeClass('active');
      $(this).addClass('active');

      let ajax_params = {
                          url: url,
                          type: 'GET',
                          dataType: 'html',
                          target: '.customer_content'
                        };

      if(url != '' && url != '#' && url != undefined && url != null)
          app.sendRequest(ajax_params).then((e)=>{
            window.history.replaceState({}, '', url);
          });
    });
});