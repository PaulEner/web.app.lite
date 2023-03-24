class BillingMod::Configuration
  PREMIUM = {
              CEN:  { price: 1500, customers_limit: 0, unit_price: 10 },
              GMBA: { price: 1500, customers_limit: 0, unit_price: 10 },
            }

  LISTS = {
            ido_premium: {
              human_name: "iDo'Premium",
              description: "Vous permet de transférer vos pièces sans limite (quotas) de téléversement.",
              hint: "Facture à 3.000€ HT pour les $$X premiers dossiers, au delà des $$X dossiers : 10€ ht/dossier",
              label: 'Téléchargement + Pré-saisie comptable',
              price: 0,
              commitment: 0,
              cummulative_excess: false,
              data_flows: { max: 0, duration: 'month', excess_price: 0 },
              options: { upload: 'strict', bank: 'strict', scan: 'strict', mail: 'optional', digitize: 'strict', preassignment: 'strict'}
            },
            ido_classic: {
              human_name: "iDo'Classique",
              description: "Vous permet de transférer jusqu'à 100 pièces/mois, mutualisation des quotas au niveau du cabinet.",
              hint: "Au-delà du quota cabinet cumulé, calcul du dépassement simplifié : 0,25€ ht/facture",
              label: 'Téléchargement + Pré-saisie comptable',
              price: 20,
              commitment: 0,
              cummulative_excess: true,
              data_flows: { max: 100, duration: 'month', excess_price: 0.25 },
              options: { upload: 'strict', bank: 'optional', scan: 'strict', mail: 'optional', digitize: 'optional', preassignment: 'optional'}
            },
            ido_micro: {
              human_name: "iDo'Micro",
              description: "Vous permet de transférer jusqu'à 100 pièces/an et de bénéficier des automates de récupérations bancaires pour un engagement de 12 mois.",
              hint: "Au-delà de 100 factures, calcul du dépassement simplifié : 0,25€ ht/facture",
              label: 'Téléchargement + Pré-saisie comptable + Engagement 12 mois',
              price: 10,
              commitment: 12,
              cummulative_excess: false,
              data_flows: { max: 100, duration: 'annual', excess_price: 0.25 },
              options: { upload: 'strict', bank: 'strict', scan: 'strict', mail: 'optional', digitize: 'optional', preassignment: 'strict'}
            },
            ido_micro_plus: {
              human_name: "iDo'Micro",
              description: "Vous permet de transférer jusqu'à 20 pièces/mois pour un engagement de 12 mois.",
              hint: "Au-delà de 20 factures, calcul du dépassement simplifié : 0,3€ ht/facture",
              label: 'Téléchargement + Pré-saisie comptable + Engagement 12 mois',
              price: 10,
              commitment: 12,
              cummulative_excess: true,
              data_flows: { max: 20, duration: 'month', excess_price: 0.3 },
              options: { upload: 'strict', bank: 'optional', scan: 'strict', mail: 'optional', digitize: 'optional', preassignment: 'strict'}
            },
            ido_nano: {
              human_name: "iDo'Nano",
              description: "Vous permet de transférer jusqu'à 100 pièces/an pour un engagement de 12 mois.",
              hint: "Au-delà de 100 factures, calcul du dépassement simplifié : 0,25€ ht/facture",
              label: 'Téléchargement + Pré-saisie comptable + Engagement 12 mois',
              price: 5,
              commitment: 12,
              cummulative_excess: false,
              data_flows: { max: 100, duration: 'annual', excess_price: 0.25 },
              options: { upload: 'strict', bank: 'optional', scan: 'strict', mail: 'optional', digitize: 'optional', preassignment: 'strict'}
            },
            ido_mini: {
              human_name: "iDo'Mini",
              description: "Vous permet de transférer jusqu'à 300 pièces/trimèstre, mutualisation des quotas au niveau du cabinet.",
              hint: "Au-delà du quota cabinet cumulé, calcul du dépassement simplifié : 0,25€ ht/facture",
              label: 'Téléchargement + Pré-saisie comptable + Engagement 12 mois',
              price: 10,
              commitment: 12,
              data_flows: { max: 100, duration: 'month', excess_price: 0.25 },
              options: { upload: 'strict', bank: 'none', scan: 'strict', mail: 'none', preassignment: 'optional'}
            },            
            ido_x: {
              human_name: "iDo'X",
              description: "Vous permet de convertir les pièces venues de jefacture.com (Factur-X) en écritures comptables !",
              hint: "Attention, les autres modes d’import de documents (email, upload, appli mobile…) ne sont pas disponibles, seuls les fichiers venant de jefacture.com sont autorisés.",
              label: 'Factur-X + Pré-saisie comptable',
              price: 5,
              commitment: 0,
              cummulative_excess: false,
              data_flows: { max: 0, duration: 'month', excess_price: 0.25 },
              options: { upload: 'none', bank: 'optional', scan: 'none', mail: 'none', digitize: 'none', preassignment: 'strict' }
            },            
            ido_retriever: {
              human_name: "Automate",
              description: "Vous permet de bénéficier des automates de récupération bancaires",
              hint: "",
              label: 'Automate, récupération bancaire',
              price: 5,
              commitment: 0,
              cummulative_excess: false,
              data_flows: { max: 0, duration: 'month', excess_price: 0.25 },
              options: { upload: 'none', bank: 'strict', scan: 'none', mail: 'none', digitize: 'optional', preassignment: 'strict'}
            },
            ido_digitize: {
              human_name: "Numérisation",
              description: "Vous permet de générer vos kit d'envoi de numérisation gratuitement (0 €)",
              hint: "",
              label: 'Numérisation de document',
              price: 0,
              commitment: 0,
              cummulative_excess: false,
              data_flows: { max: 0, duration: 'month', excess_price: 0.25 },
              options: { upload: 'none', bank: 'none', scan: 'strict', mail: 'none', digitize: 'strict', preassignment: 'strict'}
            },
            preassignment: {
              human_name: "Pré-affectation",
              price: 9, 
              label: 'Pré-saisie comptable active', 
            },
            mail: {
              human_name: "Courrier",
              price: 10, 
              label: 'Envoi par courrier A/R', 
            },
            bank_excess: { price: 2 },
            journal_excess: { price: 1 },
            reduced_retriever: { price: 3 },
          }.freeze

  class << self
    def human_name_of(package)
      BillingMod::Configuration::LISTS[package.to_sym][:human_name]
    end

    def label_of(package)
      BillingMod::Configuration::LISTS[package.to_sym][:label]
    end

    def options_of(package)
      BillingMod::Configuration::LISTS[package.to_sym][:options]
    end

    def price_of(package, user=nil)
      package = :reduced_retriever if package.to_s == 'ido_retriever' && CustomUtils.reduced_retriever_price?(user.try(:organization).try(:code)) #We have an exception of ido_retriever price

      BillingMod::Configuration::LISTS[package.to_sym][:price]
    end

    def flow_limit_of(package)
      BillingMod::Configuration::LISTS[package.to_sym][:data_flows][:max]
    end

    def excess_price_of(package)
      BillingMod::Configuration::LISTS[package.to_sym][:data_flows][:excess_price]
    end

    def excess_duration_of(package)
      BillingMod::Configuration::LISTS[package.to_sym][:data_flows][:duration]
    end

    def commitment_duration_of(package)
      BillingMod::Configuration::LISTS[package.to_sym][:commitment]
    end

    def discount_price(package, count, version=1)
      prices = {
                  '1' =>  [
                              { limit: (0..75), package_price: 0, retriever_price: 0 },
                              { limit: (76..150), package_price: -1, retriever_price: 0 },
                              { limit: (151..250), package_price: -1.5, retriever_price: -0.5 },
                              { limit: (251..350), package_price: -2, retriever_price: -0.75 },
                              { limit: (351..500), package_price: -3, retriever_price: -1 },
                              { limit: (501..Float::INFINITY), package_price: -4, retriever_price: -1.25 }
                          ],
                  '2' =>  [
                            { limit: (0..250), package_price: 0, retriever_price: 0 },
                            { limit: (251..Float::INFINITY), package_price: -10, retriever_price: 0 }
                          ],
                  '3' =>  [
                            { limit: (0..50), package_price: -1, retriever_price: 0 },
                            { limit: (51..150), package_price: -1.5, retriever_price: -0.5 },
                            { limit: (151..200), package_price: -2, retriever_price: -0.75 },
                            { limit: (201..250), package_price: -2.5, retriever_price: -1 },
                            { limit: (251..350), package_price: -3, retriever_price: -1.25 },
                            { limit: (351..500), package_price: -4, retriever_price: -1.50 },
                            { limit: (501..Float::INFINITY), package_price: -5, retriever_price: -2 }
                          ],
                         
               }

      _price = 0
      _found = false

      prices[version.to_s].each do |node|
        next if _found

        if ['ido_retriever', 'bank_option'].include?(package.to_s)
          _price = node[:retriever_price]  if node[:limit].include?(count)
        else
          _price = node[:package_price] if node[:limit].include?(count)
        end

        _found = true if _price < 0
      end

      _price
    end

    def premium_price_of(organization_code)
      BillingMod::Configuration::PREMIUM[organization_code.to_sym][:price]
    end

    def premium_customers_limit_of(organization_code)
      BillingMod::Configuration::PREMIUM[organization_code.to_sym].try(:[], :customers_limit).to_i
    end

    def premium_unit_customer_price_of(organization_code)
      BillingMod::Configuration::PREMIUM[organization_code.to_sym].try(:[], :unit_price).to_f
    end
  end
end