module ResourcesHelper

  SVG_HEIGHT = 120
  SVG_PADDING = 10
  SVG_TEXT_LINE_PADDING = 5
  SVG_SIZE_RECT = 12

  def svg_timeline(resource)
    all_revisions = resource.revisions # to calculate whole time-span
    activities = resource.revisions.activities

    # fist date in timeline, last in order
    reference_date = all_revisions.last.modified_date
    span_in_minutes = (all_revisions.first.modified_date - reference_date).to_i/60

    # when only one revision
    span_in_minutes = 1 if span_in_minutes == 0
    pix_per_minute = ((920.to_f/span_in_minutes) < 0.5) ? 0.5 : (920.to_f/span_in_minutes)

    # svg properties
    width_line = ((920.to_f/span_in_minutes) < 0.5) ? (0.5*span_in_minutes).to_i : 920
    width_image = width_line + (2 * SVG_PADDING) + 60 # 2x10 for paddings, + 60 for caption of last revision

    # rendering

    svg_contents = Array.new
    svg_contents << svg_line(width_line)
    sessions = Array.new # group around each to define standards (font-family, size)

    activities.reverse.each_with_index do |activity, index|
      x_rev_rect = ((activity.modified_date - reference_date).to_i/60 * pix_per_minute).to_i + SVG_PADDING

      if activity.revisions.blank?
        sessions << svg_rect_single_revision(x_rev_rect, activity, (index%2 == 0), true )
      else
        sessions << svg_rect_multiple_revisions(x_rev_rect, (index%2 == 0), activity,
                                                reference_date, pix_per_minute, resource.monitored_resource_id )
      end

    end

    svg_contents << content_tag(:g, sessions.join().html_safe, 'font-family' => 'Verdana', 'font-size' => 8 )
    return content_tag(:svg, svg_contents.join().html_safe, :width => width_image, :height => SVG_HEIGHT, :xmlns => "http://www.w3.org/2000/svg")
  end

  def svg_timeline_no_aggregation(resource)
    all_revisions = resource.revisions # to calculate whole time-span

    # fist date in timeline, last in order
    reference_date = all_revisions.last.modified_date
    span_in_minutes = (all_revisions.first.modified_date - reference_date).to_i/60

    # when only one revision
    span_in_minutes = 1 if span_in_minutes == 0
    pix_per_minute = ((920.to_f/span_in_minutes) < 0.5) ? 0.5 : (920.to_f/span_in_minutes)

    # svg properties
    width_line = ((920.to_f/span_in_minutes) < 0.5) ? (0.5*span_in_minutes).to_i : 920
    width_image = width_line + (2 * SVG_PADDING) + 60 # 2x10 for paddings, + 60 for caption of last revision

    # rendering

    svg_contents = Array.new
    svg_contents << svg_line(width_line)
    actions = Array.new # group around each to define standards (font-family, size)

    all_revisions.reverse.each_with_index do |action, index|
      x_rev_rect = ((action.modified_date - reference_date).to_i/60 * pix_per_minute).to_i + SVG_PADDING
      actions << svg_rect_single_revision(x_rev_rect, action, (index%2 == 0), false )
    end

    svg_contents << content_tag(:g, actions.join().html_safe, 'font-family' => 'Verdana', 'font-size' => 8 )
    return content_tag(:svg, svg_contents.join().html_safe, :width => width_image, :height => SVG_HEIGHT, :xmlns => "http://www.w3.org/2000/svg")
  end

  private
  def svg_line(width_line)
    tag(:line,
        :x1 => SVG_PADDING,
        :x2 => (width_line + SVG_PADDING),
        :y1 => SVG_HEIGHT/2,
        :y2 => SVG_HEIGHT/2,
        'stroke-width' => 1,
        :stroke => 'rgb(0,0,0)'
    )
  end

  def svg_revision_caption(x_value, even, revision, multiple=false, first_date=nil)
    if even
      y_caption_start = multiple ? (SVG_HEIGHT/2) - 60 : (SVG_HEIGHT/2) - 50
      y_anchor_line_end = (SVG_HEIGHT/2) - 45
    else
      y_caption_start = (SVG_HEIGHT/2 + 20)
      y_anchor_line_end = (SVG_HEIGHT/2) + 50
    end

    elements = Array.new
    elements << tag(:line,
                    :x1 => x_value,
                    :x2 => x_value,
                    :y1 => (SVG_HEIGHT/2),
                    :y2 => y_anchor_line_end,
                    'stroke-width' => 1,
                    :stroke => "rgb(180,180,180)"
    )

    tspans = [
        content_tag(:tspan, revision.modified_date.to_date.to_s,
                    :x => x_value + SVG_TEXT_LINE_PADDING,
                    :dy => '1.2em',
        ),
        content_tag(:tspan, revision.modified_date.strftime("%H:%M"),
                    :x => x_value + SVG_TEXT_LINE_PADDING,
                    :dy => '1.2em',
        ),
    ]

    if multiple
      tspans << content_tag(:tspan, time_difference(first_date,revision.modified_date),
              :x => x_value + SVG_TEXT_LINE_PADDING,
              :dy => '1.2em',
          )
    end

    tspans << content_tag(:tspan, "P: " + revision.revisions_permissions_id_list,
        :x => x_value + SVG_TEXT_LINE_PADDING,
        :dy => '1.2em'
    )

    elements << content_tag(:text, tspans.join().html_safe, :x => x_value + SVG_TEXT_LINE_PADDING, :y => y_caption_start )
    return elements
  end

  def svg_rect_single_revision(x_value, revision, even=true, captions=true)
    elements = Array.new

    if captions
      elements << svg_revision_caption(x_value, even, revision)
      elements.flatten! # caption elements as new array, but on same level

      # the revision mark on the timeline
      elements << tag(:rect,
                      :width => SVG_SIZE_RECT,
                      :height => SVG_SIZE_RECT,
                      :x => x_value - SVG_SIZE_RECT/2,
                      :y => (SVG_HEIGHT/2)- (SVG_SIZE_RECT/2),
                      :style => 'fill:rgba(119, 152, 191, .9)',
                      :transform => "rotate(45 #{x_value} 60)"
      )
    else
      # the revision mark on the timeline
      elements << tag(:rect,
                      :width => SVG_SIZE_RECT,
                      :height => SVG_SIZE_RECT,
                      :x => x_value - SVG_SIZE_RECT/2,
                      :y => (SVG_HEIGHT/2)- (SVG_SIZE_RECT/2),
                      :style => 'fill:rgba(119, 152, 191, .3)',
                      :transform => "rotate(45 #{x_value} 60)"
      )
    end



    return elements
  end

  def svg_rect_multiple_revisions(x_value_end, even=true, activity, reference_date, pix_per_minute, mr_id)
    stroke_width = activity.revisions.blank? ? 0 : 2
    stroke = rect_stroke_color(activity, mr_id)
    first_date = activity.first_revision_in_session.modified_date

    x_value_start = ((first_date - reference_date).to_i/60 * pix_per_minute).to_i + SVG_PADDING
    width = x_value_end-x_value_start + 10 # overlap (same as when rotated)

    elements = Array.new
    elements << svg_revision_caption(x_value_end, even, activity, true, first_date)
    elements.flatten! # caption elements as new array, but on same level

    elements << tag(:rect,
      :width => width,
      :height => SVG_SIZE_RECT,
      :x => x_value_start - (SVG_SIZE_RECT/2),
      :y => (SVG_HEIGHT/2) - (SVG_SIZE_RECT/2),
      :style => "fill:rgba(119, 152, 191, .9);stroke-width:#{stroke_width};stroke:#{stroke}"
    )

    return elements
  end

  def rect_stroke_color(activity, mr_id)
    stroke_color = activity.team_collaboration? ? 'rgb(51,204,51)' : 'rgb(0,0,0)'
    activity.collaboration_is_global? ? 'rgb(239,0,0)' : stroke_color
  end
end