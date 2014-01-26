class WelcomeController < ApplicationController
  def index
    redirect_to monitored_resources_path if current_user
  end
end
