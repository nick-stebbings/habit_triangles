module List

  def get_task_list(list_idx)
    session[:lists][list_idx][:todos]
  end

  def list_completed?(list_idx)
    tasks = get_task_list(list_idx)
    tasks.all? { |task| task[:completed] } && tasks.size > 0
  end  

  def incomplete_tasks(list_idx)
    get_task_list(list_idx).reject { |task| task[:completed] }
  end

  def incomplete_tasks_string(list_idx)
    "#{incomplete_tasks(list_idx).size}/#{list_size(list_idx)}"
  end

  def list_size(list_idx)
    get_task_list(list_idx).size
  end

  def sort_lists(list)
    completed = 
    {  false: [],
        true: []
    }
    list.each_index do |idx|
      list_completed?(idx) ? completed[:true].push(idx) : completed[:false].push(idx) 
    end

    completed.each do |_, arr|
      list.each_with_index do |list, idx|
        yield(list, idx) if arr.include?(idx)
      end
    end
  end

  # Sort Todos on a list by "completed". 
  def sort_todos(list)
    complete, incomplete = list.partition{ |task| task[:completed] }

    incomplete.each{ |task| yield(task, list.index(task)) }
    complete.each{ |task| yield(task, list.index(task)) }
  end

  # Return an error message if the name is invalid, otherwise return nil.
  def error_for_list_name(name)
    if !(1..100).cover? name.size   
      "The list name must be between 1 and 100 characters"
    elsif session[:lists].any? {|list| list[:name] == name }
      "The list name must be unique."
    end
  end

  # Return an error message if the Todo is invalid, otherwise return nil.
  def error_for_todo(text)
    if !(1..100).cover? text.size   
      "The task must be between 1 and 100 characters"
    end
  end
end