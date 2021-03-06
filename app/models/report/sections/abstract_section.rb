class Report::Sections::AbstractSection

  TYPE = 'SECTION'

  def initialize(name=nil)
    @name = name
    @metrics = Array.new
    @data = Hash.new

    initialize_section
  end

  def initialize_section
    raise NotImplementedError.new("Subclass responsibility")
  end

  def calculate_for(monitored_resource, monitored_periods)
    @metrics.each do |metric|
      @data[metric.title] = Hash.new
      monitored_periods.each do |period|
        @data[metric.title][period.id] = metric.calculate_for(monitored_resource, period, @data)
      end
    end
  end

  def to_h
    return flatten_data
  end

  def flatten_data
    flatted_section = Hash.new
    flatted_section[:name] = @name
    flatted_section[:type] = TYPE

    flatted_section[:values] = Array.new

    @data.each do |metric_name,values_hash|
      metric = Hash.new
      metric[:name] = metric_name

      # @todo: calculate_for on metrics should be class method and return a hash instead of just the value
      unless metric_name[0,1].eql? "("
        metric[:type] = 'METRIC'
      else
        metric[:type] = 'PERMISSION'
      end
      metric[:values] = values_hash.values

      flatted_section[:values] << metric
    end

    return flatted_section
  end
end