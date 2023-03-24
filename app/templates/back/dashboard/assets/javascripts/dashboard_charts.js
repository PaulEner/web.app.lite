class DashboardCharts{
  clear_chart(name){
    $(`#${name}`).replaceWith(`<canvas id="${name}"></canvas>`);
  }

  flow_chart(data = {}, id='chart_flux_document'){
    this.clear_chart(id)
    let chart_flux_document = $('#'+id)[0].getContext('2d');
    let mychart_2 = new Chart(chart_flux_document,
      {
        type: 'bar',
        data: {
          labels: data['header'],
          datasets: [
            {
              label: data['info'],              
              data: data['value'],
              backgroundColor: data['bg_color'],
              borderColor: data['border_color'],
              borderWidth: 1
            }
          ]
        },
        options: {
          legend: { display: false },
          title: {
            display: false
          }
        }
    });
  }

  mixed_chart(data = {}, id='document_delivery'){
    this.clear_chart(id)

    let mixed_chart = $('#'+ id)[0].getContext('2d');

    let mychart = new Chart(mixed_chart,
      {
        type: 'line',
        data: {
          labels: data['x_name'],
          datasets: [{
            label: data['legend_1'],
            data: data['value_1'],
            fill: false,
            borderColor: data['border_color_1'],
            tension: 0.1
          },
          {
            label: data['legend_2'],
            data: data['value_2'],
            fill: false,
            borderColor: data['border_color_2'],
            tension: 0.1
          }]
        }
      });
    }

  mixed_chart_bo(data = {}){
    this.clear_chart('bank_operation')

    let mixed_chart = $('#bank_operation')[0].getContext('2d');
    let mychart = new Chart(mixed_chart,
      {
        type: 'line',
        data: {
          labels: data['x_name'],
          datasets: [{
            label: data['legend_1'],
            data: data['value_1'],
            fill: false,
            borderColor: data['border_color_1'],
            tension: 0.1
          },
          {
            label: data['legend_2'],
            data: data['value_2'],
            fill: false,
            borderColor: data['border_color_2'],
            tension: 0.1
        },
          {
            label: data['legend_3'],
            data: data['value_3'],
            fill: false,
            borderColor: data['border_color_3'],
            tension: 0.1
        }]
      }
    });
  }    
}