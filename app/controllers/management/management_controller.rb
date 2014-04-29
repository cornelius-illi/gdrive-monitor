module Management
  class ManagementController < ApplicationController
    def welcome
    end

    def grant_access
      x = User.new
      x.roles << :researcher
      @researcher = User
        .where(:roles_mask => x.roles_mask)
    end

    def new_researcher
      @resource = User.new
    end

    def create_researcher
      r = researcher_params
      shared_resources = r[:shared_resources].reject { |c| c.blank? }
      r.delete(:shared_resources)
      @resource = User.create(r)

      shared_resources.each do |mr_id|
        mr = MonitoredResource.find(mr_id)
        if mr
          @resource.shared_resources << mr
        end
      end

      if @resource.save
        redirect_to management_grant_access_path, :notice => "Researcher Account for '#{@resource.name}' successfully created!"
      else
        render action: 'new_researcher'
      end
    end

    def delete_researcher
    end

    private
    # Never trust parameters from the scary internet, only allow the white index through.
    def researcher_params
      params.require(:user).permit(:name,:email, :password, :roles, :shared_resources => [])
    end
  end
end
