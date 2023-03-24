var render_pids = function(){
  var result = [];
  var text = $('textarea#content').val().split("\n");

  $.map( text, function( value, i ) {
    var _txt = value.replace(/  +/g, ' ').split(' ');

    if (_txt[1] == 'deploy' && _txt[11] == 'Passenger' && _txt[12] == 'AppPreloader:' ){
      var pids = value.split("deploy")[0];
      result.push('kill -9 ' + pids);
    }
  });

  $('.box.result').html(result.join("<br/>"));
}

jQuery(function () {
  $('.convert').unbind('click').bind('click', function(e){
    render_pids();
  });
});