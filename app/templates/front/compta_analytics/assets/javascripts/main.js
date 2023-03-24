class DocumentsAnalytics{
  constructor(){
    this.analytics = null;
    this.defaults  = null;
  }

  form_target(){
    return '#compta_analytic_form_modal'
  }

  bind_events(){
    $('.analytic_name').on('change', (e)=>{ this.handle_analysis_change($(e.currentTarget)); });
    $('.analytic_ventilation').on('change', (e)=>{ this.handle_analysis_ventilation($(e.currentTarget)); });
    $('.analytic_select').on('change', (e)=>{ this.handle_analysis_select($(e.currentTarget)); });
    $('.analytic_group .section_map').unbind('click').bind('click', (e)=>{ this.toogle_section_group($(e.currentTarget)); });
  }

  clear_analytics(){
    $('.analytic_box').addClass('hide');

    $('.analytic_select').html('');
    $('.analytic_select').val('').change();
    $('.analytic_ventilation').val(0).change();
  }

  load_analytics(code, pattern, type, is_used){
    let me = this;
    this.clear_analytics();

    if(is_used)
    { 
      $('.journal_hint').addClass('hide');
      if(type == 'journal')
        $('.journal_hint').removeClass('hide');
      $.ajax({
        url: '/compta_analytics/analytics',
        data: { code: code, pattern: pattern, type: type },
        dataType: 'json',
        type: 'POST',
        beforeSend: function(){
          me.bind_events();
          $('#analytic .fields, .no_compta_analysis, .help-block').hide();
          AppLoading('show');
        },
        success: function(data){
          me.analytics = data['analytics'];

          if(me.analytics != undefined && me.analytics != null && me.analytics.length > 0)
          {
            let analytic_options = '<option selected value>Sélectionnez une analyse</option>'
            me.analytics.forEach((e, i)=>{
              analytic_options = analytic_options + "<option value='" + me.analytics[i]['name'] + "'>" + me.analytics[i]['name'] + "</option>";
            });
            $('.analytic_name').html(analytic_options);

            $('#analytic .fields, .help-block').show();
            me.set_default_analytics(data['defaults']);
            AppEmit('compta_analytics.after_load', { type: 'success', with_default:  (data['defaults'] != undefined && data['defaults'] != null && data['defaults'] != '') });
          }
          else
          {
            $('.no_compta_analysis').show();
            $('.help-block').hide();
            AppEmit('compta_analytics.after_load', { type: 'error', message: 'no_analytics' });
          }

          me.bind_events();

          AppLoading('hide');
        },
        error: function(data){
          AppLoading('hide');
          $('#analytic .fields, .help-block').hide();
          $('.no_compta_analysis').show();

          AppEmit('compta_analytics.after_load', { type: 'error', message: data });
        }
      });
    }
    else
    {
      $('#analytic .fields, .help-block').hide();
      $('.no_compta_analysis').show();

      AppEmit('compta_analytics.after_load', { type: 'error', message: 'not_used' });
    }
  }

  set_default_analytics(defaults){
    this.defaults = defaults

    if(defaults != undefined && defaults != null && defaults != '')
    {
      for(var i=1; i <= 3; i++)
      {
        let j = 0;
        let a_name        = defaults[`a${i}_name`];
        let a_references  = defaults[`a${i}_references`];
        if(a_name != undefined && a_name != null && a_name != '')
          $(`#h_analytic_${i}_name`).val(a_name).change();

        if(a_references != undefined && a_references != null && a_references != '')
          j = 0
          a_references.forEach((ref)=>{
            j += 1
            $(`#h_analytic_${i}${j}_ventilation`).val(ref['ventilation'] || 0).change();

            for(var t=1; t<=3; t++)
            {
              let a_axis = ref[`axis${t}`];
              if(a_axis != undefined && a_axis != null && a_axis != '')
              {
                $(`#h_analytic_${i}${j}_axis${t}`).val(a_axis).change();
                $(`#section_group_${i}${j}`).removeClass('hide');
              }
            }
          });
      }

      $('.default_values').remove();
    }
  }

  get_analytics_resume(){
    let html =  '<div class="analytic_resume"><div class="analytic_title">Analyse en cours :</div>';
    let axis_option_name = '';
    let target = this.form_target();

    for(var i=1; i<=3; i++){
      let axis_value = $(`${target} .analytic_${i}_name`).val();
      if(axis_value != '' && axis_value != undefined && axis_value != null){
        axis_option_name = $(`#analytic_fields #h_analytic_${i}_name option[value='${axis_value}']`).text();
        html += `<div class='analytic_groups clearfix'><div class='analytic_axis_name'>${axis_option_name}</div>`;

        for(var j=1; j<=3; j++){
          let ventilation_value = $(`${target} .analytic_${i}${j}_ventilation`).val();
          let section_names = [];
          for(var t=1; t<=3; t++){
            let sect_value = $(`${target} .analytic_${i}${j}_axis${t}`).val();
            if(sect_value != undefined && sect_value != '' && sect_value != null)
              section_names.push( $(`#analytic_fields #h_analytic_${i}${j}_axis${t} option[value='${sect_value}']`).text() );
          }
          if(section_names.length > 0){
            html += `<div class='analytic_section_group clearfix'><div class='analytic_section_name float-left'>- ${section_names.join(", ")}&nbsp;:&nbsp;</div><div class='analytic_section_ventilation float-left'>${ventilation_value}%</div></div>`
          }
        }
        html += '</div>'
      }
    }

    if(axis_option_name == '')
      html = ''
    else
      html += '</div>'

    return html
  }

  toogle_section_group(elem){
    let number = elem.data('group-number');

    if( $(`#analytic_parent_box${number}`).is(":visible") )
      $(`#analytic_parent_box${number}`).slideUp('fast');
    else
      $(`#analytic_parent_box${number}`).slideDown('fast');
  }

  handle_analysis_change(current_analytic){
    let target = this.form_target();
    let number = current_analytic.data('analytic-number');
    let value  = current_analytic.val() || '';

    $('#analytic_'+number+'_group .analytic_axis').html('');
    $('#analytic_'+number+'_group .analytic_ventilation').val(0).change();
    $('#analytic_'+number+'_group .analytic_box').addClass('hide');
    $('#analytic_'+number+'_group .analytic_axis_group').addClass('hide');

    $(`${target} .analytic_hidden_group_${number} .hidden_analytic_axis`).val('');

    if(this.analytics != undefined && this.analytics != null && value != ''){
      $(`#analytic_${number}_group .analytic_box`).removeClass('hide');

      const by_analytic_id = (element)=>{
        return element['name'] == value 
      };

      let analytic = this.analytics.find(by_analytic_id, current_analytic);

      let references = null;
      if(this.defaults != undefined && this.defaults != null && this.defaults != '')
        references = this.defaults["a${number}_references"];

      for(var i=1; i<=3; i++){
        for(var j=1; j<=3; j++){
          let num               = `${number}${j}`;
          let axis_name         = `axis${i}`;
          let axis              = $('#h_analytic_'+num+'_'+axis_name);
          let axis_group        = $('#analytic_'+num+'_'+axis_name+'-group');
          let label_axis_group  = $('#analytic_'+num+'_'+axis_name+'-group label');
          let hidden_axis       = $(`${target} .analytic_${num}_${axis_name}`);

          if(analytic[axis_name] != undefined && analytic[axis_name] != null){
            let sections = analytic[axis_name]['sections'];
            let selected = '';
            let a_axis = '';

            if(references != undefined && references != null && references != '')
              a_axis = references[j-1]["axis${i}"];
            
            if(a_axis != undefined && a_axis != null && a_axis != '')
              selected = 'selected';
            let axis_options = `<option ${selected} value>Sélectionnez une section</option>`;

            sections.forEach((section)=>{
              selected = '';
              if(a_axis == section['code'])
                selected = 'selected';
              axis_options = axis_options + "<option ${selected} value='" + section['code'] + "'>" + section['description'] + "</option>";
            });
            axis.html(axis_options);
            label_axis_group.html(`Axe: <i style='font-weight: normal'>${analytic[axis_name]['name']}</i>`);
            axis_group.removeClass('hide');

            // axis.chosen({ search_contains: true, allow_single_deselect: true, no_results_text: 'Aucun résultat correspondant à' })
            // axis.trigger('chosen:updated')

            hidden_axis.val(axis.val())
          }
        }
      }

      $(`#analytic_${number}_group .analytic_box`).addClass('hide');
      $(`#analytic_${number}_group #analytic_parent_box${number}`).removeClass('hide');
    }
  }

  handle_analysis_ventilation(elem){
    let number    = elem.data('ventilation-number');
    let target    = this.form_target();
    let ss_target = elem.data('target');

    $(target + ' .' + ss_target).val( elem.val() );

    let total_ventilation = 0;
    $(`.analytic_ventilation_group_${number}`).each((e, self)=>{ total_ventilation += parseFloat($(self).val()) });
    $(`#total_ventilation_${number}`).html(` Total Ventilation: ${total_ventilation}%`);

    if(total_ventilation == 100)
      $(`#total_ventilation_${number}`).addClass('green')
    else
      $(`#total_ventilation_${number}`).removeClass('green')
  }

  handle_analysis_select(elem){
    let target    =  this.form_target();
    let ss_target = elem.data('target');
    $(target + ' .' + ss_target).val( elem.val() );
  }
}


jQuery(function() {
  let main = new DocumentsAnalytics();

  $('document').livequery(function(){ main.bind_events(); });

  $('#comptaAnalysisEdition .btn#validate_analysis').unbind('click').bind('click', function(){ 
    let data = $('#comptaAnalysisEdition form#compta_analytic_form_modal').serializeObject();
    AppEmit('compta_analytics.validate_analysis', { data: data });
  });

  $('.modal#comptaAnalysisEdition').on('hide.bs.modal', function(e){
    let data = $('#comptaAnalysisEdition form#compta_analytic_form_modal').serializeObject();
    AppEmit('compta_analytics.hide_modal', { data: data, resume: main.get_analytics_resume() });
  });

  AppListenTo('compta_analytics.main_loading', (e)=>{ main.load_analytics(e.detail.code, e.detail.pattern, e.detail.type, e.detail.is_used); });
});