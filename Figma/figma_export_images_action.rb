require 'httparty'

# Description: Sublayer::Action responsible for exporting images from Figma.
# This action integrates with the Figma API to automate exporting of design assets.
#
# It is initialized with a file_key, node_ids, and format. Optionally, you can provide output directory.
# It returns the link to the exported images.
#
# Example usage: When you want to export assets from Figma based on AI-generated design specifications or automatically update
# development resources in a versioned workflow.

class FigmaExportImagesAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(file_key:, node_ids:, format: 'png', output_dir: './')
    @file_key = file_key
    @node_ids = node_ids
    @format = format
    @output_dir = output_dir
    @personal_access_token = ENV['FIGMA_ACCESS_TOKEN']
  end

  def call
    export_images
  rescue HTTParty::Error => e
    error_message = "HTTP error during Figma image export: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error exporting images from Figma: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def export_images
    url = "https://api.figma.com/v1/images/#{@file_key}?ids=#{@node_ids}&format=#{@format}"
    headers = {
      "Authorization" => "Bearer #{@personal_access_token}"
    }

    response = self.class.get(url, headers: headers)

    if response.success?
      image_urls = response.parsed_response['images']
      Sublayer.configuration.logger.log(:info, "Images exported successfully from Figma")
      save_images(image_urls)
      image_urls
    else
      error_message = "Failed to export images: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  def save_images(image_urls)
    image_urls.each do |node_id, url|
      begin
        download_image(node_id, url)
      rescue StandardError => e
        Sublayer.configuration.logger.log(:error, "Failed to save image for node \\#{node_id}: #{e.message}")
      end
    end
  end

  def download_image(node_id, url)
    response = HTTParty.get(url)
    raise StandardError, "Failed to download image: HTTP #{response.code}" unless response.success?
    
    File.open(File.join(@output_dir, "#{node_id}.#{@format}"), 'wb') do |file|
      file.write(response.body)
    end
  end
end
