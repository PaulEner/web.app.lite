# -*- encoding : UTF-8 -*-

module CustomerHelper
  def popover_content(package, title="Abonnement actuel")
    contents  = content_tag :h6, title, class: 'popover-title text-center semibold p-2'
    contents += content_tag :hr, '', class: 'm-1'

    count_price = 0

    if package
      %w(name preassignment mail bank scan).each do |column|
        next if BillingMod::Configuration.options_of(package.name)[column.to_sym] == 'strict'
        next if column == 'preassignment' && package.preassignment_active

        _column = column != 'name' ? column.to_s +  '_active' : column

        if package.send("#{_column}".to_sym) || column == 'preassignment'
          column = 'ido_retriever' if column == 'bank'
          column = 'ido_digitize'  if column == 'scan'
          column = package.name    if column == 'name'

          content      = ''
          content_span = ''

          price = BillingMod::Configuration.price_of(column.to_sym).to_i

          if (column == 'preassignment' && !package.preassignment_active)
            count_price -= price.to_i
            price = "-" + price.to_s + '€'
          else
            count_price += price.to_i
            price = price.to_s + '€'
          end

          content_span  += content_tag :span, BillingMod::Configuration.human_name_of(column), class: 'semibold float-start'
          content_span  += content_tag :span, price, class: 'semibold float-end'
          content       += content_tag :div, content_span.html_safe, class: 'clearfix'

          if BillingMod::Configuration.label_of(column).present?
            label = BillingMod::Configuration.label_of(column)

            label = 'Remise pré-affectation' if column == 'preassignment' && !package.preassignment_active

            content += content_tag :i, label, class: 'clearfix float-start'
          end

          contents += content_tag :div, content.html_safe, class: 'clearfix'
        end
      end
    end

    contents  += content_tag :hr, '', class: 'm-1'
    span_total = content_tag :span, count_price.to_s + '€', class: 'semibold p-1'
    contents  += content_tag :div, span_total.html_safe, class: 'clearfix text-end'

    content_tag :div, contents.html_safe, class: 'w-100'  
  end
end