var reset = function(type){
  $('.box.result').removeClass('hide');

    $.ajax({
      url: "/admin/reset/" + type,
      type: "GET",
      datatype: 'html',
      success: function(data){
        $('.box.result').html(data)
      }
    });
}

jQuery(function () {
  $('.reset').unbind('click').bind('click', function(e){
    reset($(this).attr('id'));
  });
});