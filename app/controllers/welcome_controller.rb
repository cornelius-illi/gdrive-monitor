class WelcomeController < ApplicationController
  def index
    redirect_to monitored_resources_path if current_user
  end

  def mime_types
    @mime_count = Hash.new

    mime_types = Resource.select(:mime_type).uniq
    mime_types.each do |r|
      @mime_count[r.mime_type] = Resource.where(:mime_type => r.mime_type).count
    end

    @mime_count.sort_by {|_key, value| value}
  end
end