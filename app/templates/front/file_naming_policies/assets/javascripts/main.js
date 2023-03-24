class NamingPolicy{
  constructor(){
    this.container       = $('#sortable_parent');
    this.input_preview   = $('input.preview');
    this.elements        = [];


    // IMPORTANT: position represent the default position of the node element
    this.nodes           = [
                            { name: 'code', position: 100 },
                            { name: 'company', position: 101 },
                            { name: 'journal', position: 102 },
                            { name: 'period', position: 103 },
                            { name: 'piece_number', position: 104 },
                            { name: 'third_party', position: 105 },
                            { name: 'invoice_number', position: 106},
                            { name: 'invoice_date', position: 107}
                          ];
  }

  init(){
    this.init_form();

    this.bind_sorting();
    this.bind_clickable();
    this.reset_position();
  }

  init_form(){
    let policy = JSON.parse($('input#current_policy_name').val() || '{}');

    if(policy.id > 0){
      $('#scope').val( policy.scope ).change();
      $('#element-separator').val( policy.separator ).change();

      let parsed_node = JSON.parse(JSON.stringify( this.nodes.sort((a, b)=>{ return a.position - b.position }) ));
      parsed_node.forEach((p)=>{
        let node   = p.name;
        let c_node = null;

        if(policy.first_user_identifier == node)
        {
          $(`.sortable_child.${node}`).addClass('active');
          this.nodes.find((n)=>{ return n.name == node }).position = policy.first_user_identifier_position;
        }
        else if(policy.second_user_identifier == node)
        {
          $(`.sortable_child.${node}`).addClass('active');
          this.nodes.find((n)=>{ return n.name == node }).position = policy.second_user_identifier_position;
        }
        else if(policy[`is_${node}_used`] == true)
        {
          $(`.sortable_child.${node}`).addClass('active');
          this.nodes.find((n)=>{ return n.name == node }).position = policy[`${node}_position`];
        }
      });

      let html = '';
      this.nodes.sort((a, b)=>{ return a.position - b.position }).forEach((el)=>{
        html += $(`.sortable_child.${el.name}`)[0].outerHTML;
      });

      this.container.html(html);
    }
  }

  reset_position(){
    let self = this;
    let index = 0;
    this.elements  = [];
    $('span.position').remove();

    this.container.find('.sortable_child.active').each(function(e){
      index += 1;
      self.elements.push({ name: $(this).data('name'), ex: $(this).data('ex') });
      $(this).append(`<span class="badge bg-success position semibold">${index}</span>`);
    });

    this.set_preview();
  }

  bind_sorting(){
    let self = this;
    $('#sortable_parent').sortable({
      items: ".sortable_child.active",
      draggable: ".sortable_child.active",
      start: function(event, ui) {
        $('.sortable_child.clickable').unbind('click.sort');
      },
      stop: function(event, ui) {
        self.bind_clickable();
        self.reset_position();
      }
    });
  }

  bind_clickable(elem){
    let self = this;
    window.setTimeout(()=>{
      $('.sortable_child.clickable').unbind('click.sort')
                                    .bind('click.sort', function(e){
                                      $(this).hasClass('active') ? $(this).removeClass('active') : $(this).addClass('active');
                                      self.reset_position();
                                    })
    }, 300);
  }

  set_preview(){
    let separator = $('#element-separator').val();
    let result    = this.elements.map((el)=>{ return el.ex }).join(separator);
    if(result)
      this.input_preview.val(`${result}.pdf`);
  }

  get_parameter(e){
    let data = { 'file_naming_policy': {} };

    data['file_naming_policy']['scope']     = $('#scope').val();
    data['file_naming_policy']['separator'] = $('#element-separator').val();

    data['file_naming_policy']['first_user_identifier'] = '';
    data['file_naming_policy']['first_user_identifier_position'] = 1;
    data['file_naming_policy']['second_user_identifier'] = '';
    data['file_naming_policy']['second_user_identifier_position'] = 1;

    this.nodes.forEach((el)=>{
      if(el.name != 'code' && el.name != 'company'){
        data['file_naming_policy'][`is_${el.name}_used`] = false;
        data['file_naming_policy'][`${el.name}_position`] = 1;
      }
    });

    this.elements.forEach((el, index)=>{
      if(el.name == 'code' || el.name == 'company')
      {
        if(data['file_naming_policy']['first_user_identifier'] == '')
        {
          data['file_naming_policy']['first_user_identifier']          = el.name
          data['file_naming_policy']['first_user_identifier_position'] = index + 1;
        }
        else
        {
          data['file_naming_policy']['second_user_identifier']          = el.name
          data['file_naming_policy']['second_user_identifier_position'] = index + 1;
        }
      }
      else
      {
        data['file_naming_policy'][`is_${el.name}_used`]  = true;
        data['file_naming_policy'][`${el.name}_position`] = index + 1;
      }
    });

    e.set_key('datas', data);
  }
}

jQuery(function() {
  let main = new NamingPolicy();

  main.init();

  $('#element-separator').on('change', function(e){ main.set_preview(); });
  AppListenTo('create_policy_parameter', (e)=>{ main.get_parameter(e); });
});