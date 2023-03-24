module AccountNumberRulesHelper
  def set_popover_content
    contents = content_tag :span, '- recherche: station 2015 match avec libellé: Prélèvement station 2015 001', class: 'semibold'
    contents += content_tag :br, ''
    contents += content_tag :span, '- recherche: station 2015 ne match pas avec libellé : Prélèvement station janvier 2015 001', class: 'semibold'
    contents += content_tag :br, ''
    contents += content_tag :span, '- recherche: station 2015 ne match pas avec libellé : Prélèvement préstation 2015 001', class: 'semibold'
    contents += content_tag :br, ''
    contents += content_tag :span, '- recherche: station*2015 match avec libellé: Prélèvement station janvier 2015 001', class: 'semibold'
    contents += content_tag :br, ''
    contents += content_tag :span, '- recherche: *station*2015 match avec libellé: Prélèvement préstation janvier 2015 001', class: 'semibold'
    contents += content_tag :br, ''
    contents += content_tag :span, '- recherche: *station*2015 ne match pas avec libellé: Prélèvement préstation janvier 2015001', class: 'semibold'
    contents += content_tag :br, ''
    contents += content_tag :span, '- recherche: *station*2015* match avec libellé: Prélèvement préstation janvier 2015001', class: 'semibold'
    contents += content_tag :br, ''
    contents += content_tag :span, '- recherche: *.* match avec toutes les caractères', class: 'semibold'

    content_tag :div, contents.html_safe, class: 'w-100'
  end
end