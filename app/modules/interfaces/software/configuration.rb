module Interfaces::Software::Configuration
  #SOFTWARES = ['acd', 'ibiza', 'exact_online', 'my_unisoft', 'coala', 'sage_gec', 'quadratus', 'cegid', 'fec_agiris', 'fec_acd', 'csv_descriptor', 'cogilog', 'ciel']
  API_SOFTWARES = ['ibiza', 'exact_online', 'my_unisoft', 'sage_gec', 'acd']
  NON_API_SOFTWARES = ['coala', 'quadratus', 'cegid', 'fec_agiris', 'fec_acd', 'csv_descriptor', 'cogilog', 'ciel']
  SOFTWARES = API_SOFTWARES + NON_API_SOFTWARES
  SOFTWARES_HUMAN_NAME = { acd: 'ACD', ibiza: 'iBiza', exact_online: 'Exact Online', my_unisoft: 'My Unisoft', coala: 'Coala', sage_gec: 'Sage GEC - Privé', quadratus: 'Quadratus', cegid: 'Cegid', fec_agiris: 'Agiris', fec_acd: 'FEC ACD', csv_descriptor: 'CSV', cogilog: 'Cogilog', ciel: 'Ciel' }
  TABLE_NAME_WITH_SOFTWARES_USING_API = ['software_ibizas', 'software_exact_online', 'software_my_unisofts', 'software_sage_gec', 'software_acd']
  SOFTWARES_OBJECTS = [::Software::Ibiza, ::Software::ExactOnline, ::Software::Cegid, ::Software::Coala, ::Software::SageGec, ::Software::FecAgiris, ::Software::FecAcd, ::Software::Quadratus, ::Software::CsvDescriptor, ::Software::MyUnisoft, ::Software::Cogilog, ::Software::Ciel]

  def self.softwares
    {
      ibiza:          Software::Ibiza,
      exact_online:   Software::ExactOnline,
      cegid:          Software::Cegid,
      coala:          Software::Coala,
      sage_gec:       Software::SageGec,
      fec_agiris:     Software::FecAgiris,
      acd:            Software::Acd,
      fec_acd:        Software::FecAcd,
      quadratus:      Software::Quadratus,
      csv_descriptor: Software::CsvDescriptor,
      my_unisoft:     Software::MyUnisoft,
      cogilog:        Software::Cogilog,
      ciel:           Software::Ciel,
    }
  end

  def self.h_softwares
    {
      ibiza:          'ibiza',
      exact_online:   'exact_online',
      my_unisoft:     'my_unisoft',
      coala:          'coala',
      sage_gec:       'sage_gec',
      quadratus:      'quadratus',
      cegid:          'cegid',
      fec_agiris:     'fec_agiris',
      acd:            'acd',
      fec_acd:        'fec_acd',
      csv_descriptor: 'csv_descriptor',
      cogilog:        'cogilog',
      ciel:           'ciel',
    }.with_indifferent_access
  end

  def self.human_format
    {
      ibiza:          "iBiza",
      exact_online:   "Exact Online",
      my_unisoft:     "My Unisoft",
      coala:          "Coala",
      sage_gec:       "Sage GEC - Privé",
      quadratus:      "Quadratus",
      cegid:          "Cegid",
      fec_agiris:     "Fec Agiris",
      acd:            'acd',
      fec_acd:        "Fec ACD",
      csv_descriptor: "Autre(format d'export .csv)",
      cogilog:        "Cogilog",
      ciel:           "Ciel",
    }.with_indifferent_access
  end

  def self.softwares_table_name
    {
      ibiza:          'software_ibizas',
      exact_online:   'software_exact_online',
      my_unisoft:     'software_my_unisofts',
      coala:          'software_coalas',
      sage_gec:       'software_sage_gec',
      quadratus:      'software_quadratus',
      cegid:          'software_cegids',
      fec_agiris:     'software_fec_agiris',
      acd:            'software_acd',
      fec_acd:        'software_fec_acds',
      csv_descriptor: 'software_csv_descriptors',
      cogilog:        'software_cogilog',
      ciel:           'software_ciel',
    }.with_indifferent_access
  end

  def self.software_object_name
    {
      'Software::Ibiza'         => 'ibiza',
      'Software::ExactOnline'   => 'exact_online',
      'Software::Cegid'         => 'cegid',
      'Software::Coala'         => 'coala',
      'Software::SageGec'       => 'sage_gec',
      'Software::FecAgiris'     => 'fec_agiris',
      'Software::Acd'           => 'acd',
      'Software::FecAcd'        => 'fec_acd',
      'Software::Quadratus'     => 'quadratus',
      'Software::CsvDescriptor' => 'csv_descriptor',
      'Software::MyUnisoft'     => 'my_unisoft',
      'Software::Cogilog'       => 'cogilog',
      'Software::Ciel'          => 'ciel',
    }
  end

  def auto_deliver?
    return false if self.owner.is_a?(User) && auto_deliver === false
    return true  if self.owner.is_a?(User) && auto_deliver === true

    (self.owner.is_a?(User) && auto_deliver == -1) ? self.owner.organization.auto_deliver?(self) : (auto_deliver == 1)
  end

  def used?
    if self.is_a?(Software::Ibiza)
      if owner_type == 'User'
        is_used
      else
        is_used && ( access_token.present? || access_token_2.present? )
      end
    else
      is_used
    end
  end
end