class SortableDom{
  constructor(name, nodes){
    this.name             = name;

    this.container        = $(`#${name}_sortable`);
    this.input_preview    = $(`input.${name}_preview`);
    this.separator        = $(`#${name}_separator`);
    this.validation       = $(`#${name}_validation`);
    this.default          = JSON.parse( $(`input#current_${name}`).val() || '{}' );
    this.target_value     = $(`#${name}_hidden`);
    this.target_separator = $(`#${name}_separator_hidden`);
    this.elements         = [];
    this.nodes            = nodes;

    this.separator.on('change.sortable_dom', (e)=>{ this.set_preview(); });
    this.validation.on('click.sortable_dom', (e)=>{ this.set_values(); })
  }

  init(){
    this.init_form();

    this.bind_sorting();
    this.bind_clickable();
    this.reset_position();
  }

  init_form(){
    if(this.default && JSON.stringify(this.default) != '{}'){
      let parsed_node = JSON.parse(JSON.stringify( this.nodes.sort((a, b)=>{ return a.position - b.position }) ));

      parsed_node.forEach((p)=>{
        let node   = p.name;
        let c_node = null;

        if(parseInt(this.default[node]['is_used']) == 1)
        {
          $(`.${this.name}_sortable_child.${node}`).addClass('active');
          this.nodes.find((n)=>{ return n.name == node }).position = parseInt(this.default[node]['position'] || "1");
        }
      });

      let html = '';
      let c_nodes = this.nodes.sort((a, b)=>{ return a.position - b.position })

      c_nodes.forEach((el)=>{
        html += $(`.${this.name}_sortable_child.${el.name}`)[0].outerHTML;
      });

      this.container.html(html);
    }
  }

  reset_position(){
    let self = this;
    let index = 0;
    this.elements  = [];
    this.container.find('span.position').remove();

    $(`.${this.name}_sortable_child.active`).each(function(e){
      index += 1;
      self.elements.push({ name: $(this).data('name'), ex: $(this).data('ex') });
      $(this).append(`<span class="badge bg-success position semibold">${index}</span>`);
    });

    this.set_preview();
    this.set_values();
  }

  bind_sorting(){
    let self = this;

    this.container.sortable({
      items: `.${self.name}_sortable_child.active`,
      draggable: `.${self.name}_sortable_child.active`,
      start: function(event, ui) {
        $(`.${self.name}_sortable_child.clickable`).unbind('click.sort');
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
      $(`.${this.name}_sortable_child.clickable`).unbind('click.sort')
                                                  .bind('click.sort', function(e){
                                                    $(this).hasClass('active') ? $(this).removeClass('active') : $(this).addClass('active');
                                                    self.reset_position();
                                                  })
    }, 300);
  }

  set_preview(){
    let separator = this.separator.val();
    let result    = this.elements.map((el)=>{ return el.ex }).join(separator);

    this.input_preview.val(`${result}`);
  }

  set_values(){
    this.target_separator.val( this.separator.val() );

    let result = {};
    this.nodes.forEach((n)=>{
      let node = n.name;

      result[node] = { position: 1 };
      if( this.elements.find((el)=>{ return el.name == node }) ){
        result[node]['is_used'] = 1;
        result[node]['position'] = this.elements.findIndex((el)=>{ return el.name == node }) + 1
      }
    });

    this.target_value.val( JSON.stringify(result) );
  }
}