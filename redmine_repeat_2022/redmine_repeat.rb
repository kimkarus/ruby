def repeat_issue(context)
  repeat = 0
  context[:issue].custom_values.each do |custom_value|
    if custom_value.custom_field.name == "repeat" || custom_value.custom_field.name == "Повторить через (дни)" then
      repeat = custom_value.value.to_i
    end
  end
  if (repeat > 0) then
    copy = context[:issue].copy()
    if copy.due_date? then
      if copy.start_date? then
        copy.start_date = copy.due_date + repeat
      end
      copy.due_date = nil
      #if copy.due_date? then
      #  copy.due_date = copy.due_date + repeat
      #end
    else
      copy.start_date = Time.now
      copy.start_date = copy.start_date + repeat
    end
    copy.done_ratio = 0
    copy.status_id = 1
    copy.parent_issue_id = context[:issue].parent_issue_id
    copy.save()
  end
end

module RedmineRepeat
  class Hooks < Redmine::Hook::ViewListener
    def controller_issues_new_after_save(context) #after for check changes
      if context[:issue]
	if context[:issue].status.is_closed? then
          repeat_issue(context)
	end
	if context[:issue].done_ratio >= 100 and context[:issue].status.is_closed? then
	  repeat_issue(context)
	end
      end
    end

    def controller_issues_edit_before_save(context) #before for check changes
      if context[:issue] then
        @issue = Issue.find context[:issue].id
	unless @issue.status.id == context[:issue].status.id then # STATUS HAS CHANGES
          if context[:issue].status.is_closed? then
            repeat_issue(context)
          end
        end
	unless @issue.done_ratio == context[:issue].done_ratio then #PROGRESS HAS CHANGES
	  if context[:issue].done_ratio >= 100 then
            repeat_issue(context)
          end
	end
      end
    end
    alias_method :controller_issues_bulk_edit_before_save, :controller_issues_edit_before_save
  end
end
