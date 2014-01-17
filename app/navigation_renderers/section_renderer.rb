class SectionRenderer < SimpleNavigation::Renderer::Base
  def render(item_container)
    list_content = item_container.items.inject([]) do |list, item|
      if item.key == :hr
        list << content_tag(:hr, '')
      else
        li_options = item.html_options.reject {|k, v| k == :link}
        li_content = tag_for(item)
        if include_sub_navigation?(item)
          li_content << render_sub_navigation_for(item)
        end
        h5 = content_tag(:h5, li_content, li_options )
        list << content_tag(:section, h5)
      end
    end.join
    if skip_if_empty? && item_container.empty?
      ''
    else
      content_tag(:nav, list_content, {:id => item_container.dom_id, :class => item_container.dom_class})
    end
  end
end