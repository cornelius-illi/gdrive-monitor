class Report::Chapters::AbstractChapter

  TYPE = 'CHAPTER'

  def initialize(name=nil)
    @name = name
    @sections = Array.new

    initialize_chapter
  end

  def calculate_for(monitored_resource, monitored_periods)
    @sections.each do |section|
      section.calculate_for(monitored_resource, monitored_periods)
    end
  end

  def initialize_chapter
    raise NotImplementedError.new("Subclass responsibility")
  end

  def to_h
    result = Hash.new
    result[:name] = @name
    result[:type] = TYPE
    result[:values] = Array.new
    @sections.each do |section|
      result[:values] << section.to_h
    end

    result
  end
end