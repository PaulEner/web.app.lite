class PonctualScripts::DeleteSomeOperation < PonctualScripts::PonctualScript
  def self.execute()   
    new().run
  end

  private 

  def execute
    _operations = Operation.where("DATE_FORMAT(created_at,'%Y-%m-%d') = '2022-12-06'").where(api_name: 'cedricom')

    operations = JSON.parse(_operations.to_a.to_json)
    tab_except = []    

    operations.each do |ope|
      next if tab_except.include?ope['id']

      operations.each do |ope_verif|
        if ope['id'] != ope_verif['id'] && ope['date'] == ope_verif['date'] && ope['value_date'] == ope_verif['value_date'] && ope['label'] == ope_verif['label'] && ope['amount'] == ope_verif['amount'] && ope['bank_account_id'] == ope_verif['bank_account_id'] && ope['cedricom_reception_id'] == ope_verif['cedricom_reception_id']

          ope_update = Operation.find ope_verif['id']

          ope_update.bank_account_id = ope['bank_account_id'].to_i * -1

          ope_update.save

          tab_except << ope_verif['id']
        end
      end      
    end
  end
end