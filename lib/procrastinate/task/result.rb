
# A single value result, like from a normal method call. Return an instance of
# this from your task#result method to enable result handling. 
#
class Procrastinate::Task::Result
  # Gets passed all messages sent by the child process for this task.
  #
  def incoming_message(obj)
    p [:incoming_message, obj]
    @value = obj
  end

  def value
    @value
  end
end