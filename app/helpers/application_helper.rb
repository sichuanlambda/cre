module ApplicationHelper
  def rating_color_class(score)
    case score
    when 80..100 then "very-friendly"
    when 60..79 then "friendly"
    when 40..59 then "moderate"
    when 20..39 then "less-friendly"
    else "needs-improvement"
    end
  end

  def platform_color(platform)
    case platform.to_s
    when 'twitter' then 'blue-400'
    when 'linkedin' then 'blue-600'
    when 'facebook' then 'blue-800'
    else 'gray-600'
    end
  end
end
