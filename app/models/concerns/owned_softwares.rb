module OwnedSoftwares
  extend ActiveSupport::Concern

  included do
    has_one :acd, as: :owner, dependent: :destroy, class_name: 'Software::Acd'
    has_one :ibiza, as: :owner, dependent: :destroy, class_name: 'Software::Ibiza'
    has_one :coala, as: :owner, dependent: :destroy, class_name: 'Software::Coala'
    has_one :exact_online, as: :owner, dependent: :destroy, class_name: 'Software::ExactOnline'
    has_one :quadratus, as: :owner, dependent: :destroy, class_name: 'Software::Quadratus'
    has_one :fec_agiris, as: :owner, dependent: :destroy, class_name: 'Software::FecAgiris'
    has_one :fec_acd, as: :owner, dependent: :destroy, class_name: 'Software::FecAcd'
    has_one :cegid, as: :owner, dependent: :destroy, class_name: 'Software::Cegid'
    has_one :csv_descriptor, as: :owner, autosave: true, dependent: :destroy, class_name: 'Software::CsvDescriptor'
    has_one :my_unisoft, as: :owner, dependent: :destroy, class_name: 'Software::MyUnisoft'
    has_one :sage_gec, as: :owner, dependent: :destroy, class_name: 'Software::SageGec'
    has_one :cogilog, as: :owner, dependent: :destroy, class_name: 'Software::Cogilog'
    has_one :ciel, as: :owner, dependent: :destroy, class_name: 'Software::Ciel'
  end
end