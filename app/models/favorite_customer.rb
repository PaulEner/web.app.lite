class FavoriteCustomer < ApplicationRecord
  serialize :customer_ids, Array

  belongs_to :user

  def self.get_infos_of(customer_id)
    customer = User.where(id: customer_id).first
    result = OpenStruct.new()

    if customer
      result = OpenStruct.new({ id: customer.id, code: customer.code , name: customer.info, message: '', active: customer.still_active? })

      result.last_pack = customer.packs.order(updated_at: :desc).first

      result.all_temp_docs_size    = customer.temp_documents.count
      result.temp_docs_error_size  = customer.temp_documents.where(state: 'unreadable').count
      result.temp_docs_error_size += customer.archive_document_corrupted.where(state: 'rejected').count

      result.all_retrievers_size  = 0
      result.retriever_error_size = 0

      if customer.is_package?(:bank_active)
        result.retriever_option_active = true
        result.all_retrievers_size     = customer.retrievers.count
        result.retriever_error_size    = customer.retrievers.where(state: 'error').count
      end

      result.all_preseizures_size        = Pack::Report::Preseizure.unscoped.where(user_id: customer.id).count
      result.duplicated_preseizures_size = Pack::Report::Preseizure.unscoped.blocked_duplicates.joins(:organization, :piece, :user).where(user_id: customer.id, is_blocked_for_duplication: true).count

      result.failed_delivery = Pack::Report::Preseizure.not_deleted.failed_delivery.recent.where(user_id: customer.id).count

      all_anomaly_percent     = result.all_temp_docs_size + result.all_retrievers_size + result.all_preseizures_size
      current_anomaly_percent = result.temp_docs_error_size + result.retriever_error_size + result.duplicated_preseizures_size

      calculated_anomaly_percent = (all_anomaly_percent > 0)? ((current_anomaly_percent * 100) / all_anomaly_percent).ceil : 0

      if calculated_anomaly_percent < 40
        result.anomaly_state = 'good'
      elsif calculated_anomaly_percent >= 30 && calculated_anomaly_percent <= 70
        result.anomaly_state  = 'medium'
      else
        result.anomaly_state  = 'critical'
      end

      result.document_state = 'good'
      result.document_state = result.anomaly_state if customer.still_active?
      result.document_state = 'medium'             if !customer.still_active? && result.anomaly_state == 'critical'
    end

    result
  end
end