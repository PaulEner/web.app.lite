## Array method overwriter AND booster
class Array
  def extract!
    dup.tap { delete_if &Proc.new } - self
  end
end