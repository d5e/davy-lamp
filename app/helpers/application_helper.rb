# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def forms_selection(title, form, field, options)
    render :partial => 'forms/selection', :locals => {:selection => {
      :title => title,
      :form => form.object_name,
      :field => field,
      :options => options},
      :f => form }
  end

end
