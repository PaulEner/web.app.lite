jQuery(function () {
  $('.package').unbind('click').bind('click', function(e){
    $('.box.result').removeClass('hide');
    let action = $(this).attr('id');
    $.ajax({
      url: "/admin/package_setting/" + action,
      type: "POST",
      data: {organization_code : $("#organization_code").val()},
      success: function(data){
        $('.box.result').html(data)
      }
    });
  });
});