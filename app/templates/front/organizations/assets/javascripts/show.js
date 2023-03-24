function load_statistic(){
  $.ajax({
    url: '/organizations/'+ $('#organization_id').val() +'/statistic',
    dataType: 'html',
    type: 'GET',
    success: function (data) {
      $('.repartition').html(data)

      load_chart();
    }
  });
}

function load_chart_customer(){
  var stat_customers_labels = JSON.parse($('#stat_customers_labels').val() || '[]') || [];
  var stat_customers_values = JSON.parse($('#stat_customers_values').val() || '[]') || [];

  var chart_dossiers = document.getElementById('chart_dossiers').getContext('2d')

  var mychart_2 = new Chart(chart_dossiers, {type: 'line', data: {
    labels: stat_customers_labels,
    datasets: [{
      data: stat_customers_values,
      fill: false,
      borderColor: '#72AA42',
      backgroundColor: 'rgba(75, 192, 192, 0.2)',
      tension: 0.1
    }]
  }, options: {
     title: {
        display: false,
        fontsize: 17,
        text: 'Evolution du nombre de dossiers',
        align: 'start'
    },
      legend: {
        display: false
      }
  }
  });
}

function load_chart(){
  var organization_options = JSON.parse($('#organization_options').val() || '{}') || {};

  var chart_abonnement = document.getElementById('chart_abonnement').getContext('2d')

  var mychart = new Chart(chart_abonnement, {type: 'pie', data: {
    labels: [
      "iDo'Micro",
      "iDo'Nano",
      "iDo'X",
      "iDo'Classique",
      "Automate",
      "Numérisation"
    ],
    datasets: [{
      label: 'My First Dataset',
      data: [organization_options.micro_package, organization_options.nano_package, organization_options.idox_package, organization_options.basic_package, organization_options.retriever_package],
      backgroundColor: [
        '#72AA42',
        '#C1E637',
        '#C1D837',
        '#445E2B',
        '#555B35',
        '#1A1A1A'
      ]
    }]
  }, options: {
     title: {
        display: false,
        fontsize: 17,
        text: 'Répartition des abonnements',
        align: 'start'
    },
    legend: {
      display: false
    }
  }

  });
}

jQuery(function () {
  load_statistic();
  load_chart_customer();
});