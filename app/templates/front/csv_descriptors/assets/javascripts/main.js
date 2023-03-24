var activate_csv_field_action, activate_csv_global_action, field_separator_state, initialize_csv_editor, update_directive_input;

update_directive_input = function(type, element) {
  if (type === 'date' || type === 'deadline_date' || type === 'period_date') {
    element.parents('li').find('#text_format').hide();
    element.parents('li').find('#text_format').attr('disabled', 'disabled');
    element.parents('li').find('.number-input').hide();
    element.parents('li').find('.number-input #number-input').attr('disabled', 'disabled');
    element.parents('li').find('#select_format').show();
    return element.parents('li').find('#select_format').removeAttr('disabled');
  } else if (type === 'client_code' || type === 'journal' || type === 'pseudonym' || type === 'original_piece_number' || type === 'operation_label' || type === 'piece' || type === 'lettering' || type === 'remark' || type === 'third_party') {
    element.parents('li').find('#text_format').hide();
    element.parents('li').find('#text_format').attr('disabled', 'disabled');
    element.parents('li').find('#select_format').hide();
    element.parents('li').find('#select_format').attr('disabled', 'disabled');
    element.parents('li').find('.number-input').show();
    return element.parents('li').find('.number-input #number-input').removeAttr('disabled');
  } else if (type === 'other') {
    element.parents('li').find('#select_format').hide();
    element.parents('li').find('#select_format').attr('disabled', 'disabled');
    element.parents('li').find('.number-input').hide();
    element.parents('li').find('.number-input #number-input').attr('disabled', 'disabled');
    element.parents('li').find('#text_format').show();
    return element.parents('li').find('#text_format').removeAttr('disabled');
  } else {
    element.parents('li').find('.number-input').hide();
    element.parents('li').find('.number-input #number-input').attr('disabled', 'disabled');
    element.parents('li').find('#select_format').hide();
    element.parents('li').find('#select_format').attr('disabled', 'disabled');
    element.parents('li').find('#text_format').hide();
    return element.parents('li').find('#text_format').attr('disabled', 'disabled');
  }
};

initialize_csv_editor = function() {
  return $('#csv_descriptors.edit #select_directive option:selected').each(function(index, e) {
    var type;
    type = $(e).attr('value');
    return update_directive_input(type, $(this));
  });
};

activate_csv_field_action = function() {
  $('#csv_descriptors.edit .remove_field').unbind('click');
  $('#csv_descriptors.edit .remove_field').bind('click', function() {
    $(this).parents('li').remove();
    return false;
  });
  $('#csv_descriptors.edit #select_directive').unbind('change');
  $('#csv_descriptors.edit #select_directive').bind('change', function() {
    var type;
    $(this).children('option[selected="selected"]').removeAttr('selected');
    $(this).children('option:selected').attr('selected', 'selected');
    type = $(this).children('option:selected').attr('value');
    return update_directive_input(type, $(this));
  });
  $('.number-input input[data-toggle="tooltip"]').tooltip();
  $('.number-input #step-button').unbind('click');
  $('.number-input input[type=number]').keypress(function(evt) {
    return evt.preventDefault();
  });
  $('.number-input .step-up').on('click', function(e) {
    e.preventDefault();
    this.parentNode.querySelector('input[type=number]').stepUp(1);
    return false;
  });
  $('.number-input .step-down').on('click', function(e) {
    e.preventDefault();
    this.parentNode.querySelector('input[type=number]').stepDown(1);
    return false;
  });
  return field_separator_state();
};

activate_csv_global_action = function() {
  $('#csv_descriptors.edit .add_field').click(function(e) {
    e.preventDefault();
    var fields;
    $('#csv_descriptors.edit .template li.field').clone().appendTo('#csv_descriptors.edit .list');
    fields = $('#csv_descriptors.edit .list li.field').last().find('#select_directive option').first();
    fields.attr('selected', 'selected');
    activate_csv_field_action();
    return false;
  });
  $('#csv_descriptors.edit .remove_all_fields').click(function(e) {
    e.preventDefault();
    var is_confirmed;
    is_confirmed = confirm('Etes-vous sûr ?');
    if (is_confirmed) {
      $('#csv_descriptors.edit .list').html('');
    }
    return false;
  });
  return $('#csv_descriptors.edit .add_all_fields').click(function(e) {
    e.preventDefault();
    var escape_option, is_confirmed, options;
    is_confirmed = confirm('Etes-vous sûr ?');
    if (is_confirmed) {
      options = $('#csv_descriptors.edit .template li.field #select_directive option');
      escape_option = [];
      $('#csv_descriptors.edit .list li.field').each(function(index, element) {
        if ($(this).find('#select_directive option[selected="selected"]').val() !== void 0) {
          return escape_option.push($(this).find('#select_directive option[selected="selected"]').val());
        }
      });
      if (escape_option.length === 0 && $('#csv_descriptors.edit .list li.field').length > 0) {
        $('#csv_descriptors.edit .list').html('');
      }
      return options.each(function(index, element) {
        var fields, new_fields;
        if (escape_option.indexOf(element.value) === -1) {
          new_fields = $('#csv_descriptors.edit .template li.field').clone().appendTo('#csv_descriptors.edit .list');
          fields = $('#csv_descriptors.edit .list li.field').last().find('#select_directive option[value="' + element.value + '"]');
          fields.attr('selected', 'selected');
          activate_csv_field_action();
          return update_directive_input(element.value, fields);
        }
      });
    }
  });
};

field_separator_state = function() {
  $('input[type="checkbox"]#field-separator-state').unbind('click');
  return $('input[type="checkbox"]#field-separator-state').on('click', function() {
    var $this;
    $this = $(this);
    if ($this.val() === '|separator') {
      return $this.val('|space');
    } else {
      return $this.val('|separator');
    }
  });
};


jQuery(function() {
  if ($('#csv_descriptors.edit').length > 0) {
    $('#csv_descriptors.edit .list').sortable();
    initialize_csv_editor();
    activate_csv_global_action();
    activate_csv_field_action();


    AppListenTo('csv_descriptor_update_format', (e)=>{ 
      var directive, last_element;
      directive = [];

      $('#csv_descriptors.edit .list li').each(function(index, element) {
        var field, li, part;
        li = $(this);
        field = li.find('option:selected').val();
        if (field === 'date' || field === 'deadline_date' || field === 'period_date') {
          part = field + '-' + li.find('#select_format').val();
        } else if (field === 'client_code' || field === 'journal' || field === 'pseudonym' || field === 'original_piece_number' || field === 'operation_label' || field === 'piece' || field === 'lettering' || field === 'remark' || field === 'third_party') {
          part = field + '-' + li.find('.number-input #number-input').val();
        } else if (field === 'other') {
          part = field + '-' + li.find('#text_format').val();
        } else {
          part = field;
        }
        part += li.find('input[type="checkbox"]#field-separator-state').val();
        return directive.push(part);
      });
      last_element = directive.slice(-1)[0];
      last_element = last_element.split("|")[0];

      directive.splice(-1, 1, last_element);

      $('#software_csv_descriptor_directive').val(directive.join('|'));

      return true;
    });
  }
});