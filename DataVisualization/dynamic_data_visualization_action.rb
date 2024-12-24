require 'gruff'

# Description: Sublayer::Action responsible for creating dynamic charts and graphs from data sets.
# This action can produce visualizations that adjust based on AI model insights or real-time data monitoring.
#
# It is initialized with data and options for the type of chart, and it returns a file path to the generated graph image.
#
# Example usage: When you need real-time visual feedback on data trends or results from AI analyses.

class DynamicDataVisualizationAction < Sublayer::Actions::Base
  def initialize(data:, chart_type: 'line', title: 'Data Visualization', file_path: 'chart.png', **options)
    @data = data
    @chart_type = chart_type
    @title = title
    @file_path = file_path
    @options = options
  end

  def call
    begin
      generate_chart
      Sublayer.configuration.logger.log(:info, "Chart generated successfully: #{@file_path}")
      @file_path
    rescue StandardError => e
      error_message = "Error generating chart: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def generate_chart
    g = case @chart_type
        when 'line'
          Gruff::Line.new
        when 'bar'
          Gruff::Bar.new
        when 'pie'
          Gruff::Pie.new
        else
          raise ArgumentError, "Unsupported chart type: #{@chart_type}"
        end

    g.title = @title
    @data.each do |label, values|
      g.data(label, values)
    end

    apply_options(g)
    g.write(@file_path)
  end

  def apply_options(chart)
    @options.each do |key, value|
      if chart.respond_to?("#{key}=")
        chart.send("
#{key}=", value)
      end
    end
  end
end
