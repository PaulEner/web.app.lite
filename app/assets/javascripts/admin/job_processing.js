var launch_real_sequences = function(){
  data = window.location.search.substring(1,window.location.search.length);
  $.ajax({
    url: 'job_processing/real_time_event',
    data: data,
    type: "GET",
    success: function(data){
      $("#job_processing .retractable .col-md-12 .box").html(data);
      event_job_processing();
    }
  });
}

var event_job_processing = function(){
  // # $('.kill_action').click (e) ->
  // #   if job_processing_real_time
  // #     if confirm('Veuillez arrêter le temps réel avant de faire cette action')
  // #       window.clearInterval(job_processing_real_time)
  // #       window.location.reload()

  // #   if confirm('Voulez vous vraiment arrêter cette tâche ?')
  // #     id = $(this).attr('id')
  // #     $.ajax
  // #       url: 'job_processing/kill_job_softly',
  // #       data: { id:id },
  // #       dataType: 'json'

  // #       $("tr#tr_"+id).hide()
  
  $('#real_temp').unbind('click').bind('click', function(e){
    if $('#flag_temp_start_stop').val() == '0';
      $('#flag_temp_start_stop').val(1);
      $(this).removeClass('btn-success').addClass('btn-danger').text('Arrêter');
      window.job_processing_real_time = window.setInterval(launch_real_sequences, 3000);
    else
      window.clearInterval(window.job_processing_real_time);
      window.location.reload();
  }
}

jQuery(function () {
  window.job_processing_real_time = '';
  event_job_processing();
}