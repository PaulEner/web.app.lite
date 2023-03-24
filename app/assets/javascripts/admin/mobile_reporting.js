$(window).load(function() {
  $.ajax({
    url: "/admin/mobile_reporting",
    data: { ajax: true, mobile_users_count: true, month: $('#month').val(), year: $('#year').val() },
    type: "GET",
    datatype: 'json',
    success: function(data){
      render_users_chart(data);
    }
  });

  $.ajax({
    url: "/admin/mobile_reporting",
    data: { ajax: true, users_uploader_count: true, month: $('#month').val(), year: $('#year').val() },
    type: "GET",
    datatype: 'json',
    success: function(data){
      render_users_uploader_chart(data);
    }
  });

  $.ajax({
    url: "/admin/mobile_reporting",
    data: { ajax: true, documents_uploaded: true, month: $('#month').val(), year: $('#year').val() },
    type: "GET",
    datatype: 'json',
    success: function(data){
      render_documents_uploaded_chart(data)
    }
  });
});

var render_users_chart = function(data){
  let android_users = data.android_users;
  let ios_users = data.ios_users;

  let users = ios_users + android_users;

  let max_step = android_users;
  let min_step = ios_users;
  if (ios_users > android_users)
    max_step = ios_users
    min_step = android_users

  let graduation_step = Math.ceil(min_step / 2)
  if (graduation_step <= 0){
    graduation_step = Math.ceil(max_step / 4)
  }


  let chartUsers = new Chart($('#chartUsersContainer'), {
    type: 'bar',
    data : {
            labels: ['iOS', 'Android'],
            datasets: [{
                        data: [ios_users, android_users],
                        backgroundColor: ['#F08A42', '#C0D838'],
                        borderColor : ['#FA7010', '#B0A000'],
                        borderWidth: 2
                      }],
          },
    options: {
                layout: { padding:{ top:'10', bottom: '10' } },
                title: { display: true, text: 'Plateforme' },
                tooltips: {
                  callbacks: { 
                    label: function(tooltipItem, data){ 
                      return data.labels[tooltipItem.index] + ': ' + data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index] + ' utilisateurs'
                    }
                  }
                },
                legend: { display: false },
                scales: {
                  yAxes: [{
                            ticks: {
                                suggestedMin: 0,
                                suggestedMax: users,
                                stepSize: graduation_step
                            }
                          }]
                }
              }
  });

  $('#usersCount').html(data.users);
  $('#usersMobileCount').html(data.mobile_users);
  $('#iOSUsersCount').html(data.ios_users);
  $('#androidUsersCount').html(data.android_users);
  $('#usersLoading').remove();
}


var render_users_uploader_chart = function(data){
  let mobile_users = data.mobile_users;
  let users_uploader = data.mobile_users_uploader;

  let users_uploader_percent = 0;
  if (mobile_users > 0){
    users_uploader_percent = ((users_uploader * 100) / mobile_users);
  }

  let chartUploaders = new Chart($('#chartUploaderContainer'), {
    type: 'doughnut',
    data : {
            labels: ['Consultation', 'Téléversement'],
            datasets: [{
                        data: [(100 - users_uploader_percent).toFixed(3), users_uploader_percent.toFixed(3)],
                        backgroundColor: ['#018CCF', '#FF420E'],
                        borderWidth: 5
                      }],
          },
    options: {
                layout: { padding:{ top:'30', bottom: '30' } },
                title: { display: false },
                tooltips: {
                  callbacks: { 
                    label: function(tooltipItem, data){ 
                    return data.labels[tooltipItem.index] + ': ' + data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index] + ' %' }
                  } 
                },
                legend: {
                          position: 'right',
                          onClick: function(){ return false }
                        }
              }
  })

  $('#viewerUsersCount').html(mobile_users - users_uploader);
  $('#uploaderUsersCount').html(users_uploader);
  $('#uploaderLoading').remove();
}

var render_documents_uploaded_chart = function(data){
  let documents = data.documents;
  let mobile_documents = data.mobile_documents;

  let mobile_documents_percent = 0;
  if (documents > 0){
    mobile_documents_percent = ((mobile_documents * 100) / documents);
  }

  let chartDocuments = new Chart($('#chartDocumentsContainer'), {
    type: 'pie',
    data : {
            labels: ['Via iDocus', 'Via App Mobile'],
            datasets: [{
                        data: [(100 - mobile_documents_percent).toFixed(3), mobile_documents_percent.toFixed(3)],
                        backgroundColor: ['#018CCF', '#FF420E'],
                        borderWidth: 0
                      }],
          },
    options: {
                layout: { padding:{ top:'30', bottom: '30' } },
                title: { display: false },
                tooltips: {
                  callbacks: {                      
                    label: function(tooltipItem, data){ 
                    return data.labels[tooltipItem.index] + ': ' + data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index] + ' %'  }
                  }
                },
                legend: {
                          position: 'right',
                          onClick: function(){ return false }
                        }
              }
  });

  $('#uploadedFrameworkDocumentsCount').html(documents - mobile_documents);
  $('#uploadedMobileDocumentsCount').html(mobile_documents);
  $('#documentsLoading').remove();
}