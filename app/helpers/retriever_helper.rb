# frozen_string_literal: true

module RetrieverHelper
  def retriever_dyn_attrs(retriever)
    hsh = {}
    5.times do |i|
      param_name = "param#{i + 1}"
      data = retriever.send(param_name)
      next unless data

      data = data.dup # data is frozen due to encryption so we use a duplicate
      data['error'] = retriever.errors[param_name].first
      data['value'] = nil if data['type'] == 'password'
      hsh[param_name] = data
    end
    hsh.to_json
  end

  def state_of(retriever)
    states =  {
                '': '-',
                'ready': 'OK',
                'configuring': 'Synchronisation en cours',
                'destroying': 'Suppression en cours',
                'waiting_selection': 'Sélection de documents',
                'waiting_additionnal_info': "En attente de l'utilisateur",
                'error': 'Erreur',
                'unavailable': 'Indisponible'
              }

    states[retriever.state.to_sym]
  end

  def badge_type_of(retriever)
    if ['ready', 'configuring', 'waiting_selection', 'waiting_additionnal_info'].include? retriever.state
      'success'
    else
      'danger'
    end
  end

  def customers_active
    if @user.organization.specific_mission
      accounts.map { |u| [u, u.id] } || []
    else
      accounts.active.map { |u| [u, u.id] } || []
    end
  end

  def retriever_customers
    accounts.active.select do |customer|
      customer.my_package.try(:bank_active)
    end.map{ |u| [u, u.id] } || []
  end

  def retrievers_of(account)
    account.retrievers.map do |retriever|
      name = (retriever.name != retriever.service_name)? "#{retriever.name}(#{retriever.service_name})" : retriever.name
      [ name, retriever.budgea_id ] if retriever.budgea_id.present?
    end.compact || []
  end

  # def link_retriever_options(account)
  #   { class: account.try(:id)? '' : 'disabled', title: account.try(:id)? '' : 'Sélectionnez un dossier pour pouvoir poursuivre' }
  # end

  def retriever_journals_of(account)
    account.account_book_types.map do |journal|
      [ journal.name, journal.id ]
    end || []
  end

  def parse_options_with(values=nil)
    options = CustomUtils.arrStr_to_array(values)

    options.map do |opt|
      [opt[:label], opt[:value]]
    end || []
  end
end
