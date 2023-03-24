# -*- encoding : UTF-8 -*-
class DataVerificator::UnlockedTable < DataVerificator::DataVerificator
  def execute
    message = []
    model_name.each do |mod|
      line_locked = mod.where.not(locked_at: nil).where("DATE_FORMAT(locked_at, '%Y%m%d') <= #{1.days.ago.strftime('%Y%m%d')}")
      next if line_locked.empty?

      line_locked.each { |line| line.locked_at = nil; line.save }

      message << "Table: #{mod.table_name}, Unlocked: #{line_locked.size}, id: #{line_locked.collect(&:id)}"
    end

    {
      title: "Unlocked Table - #{message.size} Tables lock unlocked",
      message: message.join("; ")
    }
  end

  private

  def model_name
    [Pack, Order, Period, TempPack, UserOptions, User]
  end
end