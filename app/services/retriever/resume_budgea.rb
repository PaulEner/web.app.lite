# -*- encoding : UTF-8 -*-
class Retriever::ResumeBudgea
  def execute
    retrievers = Retriever.where("updated_at < ?", 30.minutes.ago)

    @infos = []

    retrievers.each do |retriever|
      access_token = retriever.user.try(:budgea_account).try(:access_token)

      next unless retriever.user.still_active? && access_token.present? && retriever.budgea_id.present?

      initial_message = retriever.error_message

      begin
        result = retriever.resume_me

        sleep(3)

        final_message = retriever.reload.error_message

        @infos << info(retriever, initial_message, final_message, result.try(:[], :from)) if final_message != initial_message
      rescue => e
        @infos << info(retriever, initial_message, e.to_s)
      end
    end
  end

  private

  def info(retriever, initial_message, final_message, updated_by=nil)
    {
      retriever_id: retriever.id,
      budgea_id: retriever.budgea_id,
      user_code: retriever.user.code,
      state: retriever.state,
      budgea_state: retriever.budgea_state,
      initial_message: initial_message,
      final_message: final_message,
      budgea_error_message: retriever.budgea_error_message,
      service_name: retriever.service_name,
      updated_by: updated_by,
      created_at: retriever.created_at,
      updated_at: retriever.updated_at
    }
  end
end
