require 'json'

class ResourcesController < ApplicationController
  before_filter :refresh_token!, only: [:refresh_revisions, :download_revisions]
  before_action :set_resource, only: [:show, :refresh_revisions, :download_revisions,
                                      :calculate_diffs, :merge_revisions, :find_collaborations, :merged_revisions]

  # GET /resources/1
  def show
    # do nothing
  end

  def show_threshold
    query = 'SELECT distance_to_previous FROM revisions WHERE distance_to_previous IS NOT NULL AND distance_to_previous < 901'
    dist = ActiveRecord::Base.connection.execute(query)

    @distances = Hash.new
    dist.each do |d|
      key = ((d['distance_to_previous'].to_i/10)+1)*10

      if @distances.has_key? key
        @distances[ key ][0] += 1
      else
        @distances[ key ]  = Array.new
        @distances[ key ][0] = 1
        @distances[ key ][1] = 0
        @distances[ key ][2] = 0
        @distances[ key ][3] = 0
      end
    end

    [1,2,4].each_with_index do |monitored_resource_id, index|
      query_team = 'SELECT distance_to_previous FROM revisions JOIN resources ON revisions.resource_id = resources.id
        WHERE resources.monitored_resource_id=' + monitored_resource_id.to_s + ' AND distance_to_previous IS NOT NULL AND distance_to_previous < 901'
      dist_team = ActiveRecord::Base.connection.execute(query_team)

      dist_team.each do |d|
        key = ((d['distance_to_previous'].to_i/10)+1)*10

        unless @distances[ key ][index+1].blank?
          @distances[ key ][index+1] += 1
        end
      end
    end


    @distances_json = @distances.to_a.map {|elem| elem.flatten }
    @distances_json.insert(0,['occurence','all teams', 'siemens', 'lapeyre', 'bayer'])
    @distances_json = @distances_json.to_json

    avg_array = Array.new
    avg_array << ['arithmetic mean','overall mean', 'siemens', 'lapeyre', 'bayer']

    number_array = Array.new
    number_array << ['revision count','overall count', 'siemens', 'lapeyre', 'bayer']

    query_sum = 'SELECT COUNT(revisions.id) as count FROM revisions WHERE distance_to_previous IS NOT NULL'
    res_sum = ActiveRecord::Base.connection.execute(query_sum)
    sum = res_sum[0]['count']

    query_sum_siemens = 'SELECT COUNT(revisions.id) as count FROM revisions JOIN resources ON revisions.resource_id=resources.id WHERE resources.monitored_resource_id=1 AND distance_to_previous IS NOT NULL'
    res_sum_siemens = ActiveRecord::Base.connection.execute(query_sum_siemens)
    sum_siemens = res_sum_siemens[0]['count']

    query_sum_lapeyre = 'SELECT COUNT(revisions.id) as count FROM revisions JOIN resources ON revisions.resource_id=resources.id WHERE resources.monitored_resource_id=2 AND distance_to_previous IS NOT NULL'
    res_sum_lapeyre = ActiveRecord::Base.connection.execute(query_sum_lapeyre)
    sum_lapeyre = res_sum_lapeyre[0]['count']

    query_sum_bayer = 'SELECT COUNT(revisions.id) as count FROM revisions JOIN resources ON revisions.resource_id=resources.id WHERE resources.monitored_resource_id=4 AND distance_to_previous IS NOT NULL'
    res_sum_bayer = ActiveRecord::Base.connection.execute(query_sum_bayer)
    sum_bayer = res_sum_bayer[0]['count']

    (1..60).each do |avg_base|
      seconds = (avg_base*60)+1
      query = 'SELECT COUNT(revisions.id) AS number, AVG(distance_to_previous) AS avg FROM revisions WHERE distance_to_previous IS NOT NULL AND distance_to_previous < ' + seconds.to_s
      dist = ActiveRecord::Base.connection.execute(query)

      query_siemens = 'SELECT COUNT(revisions.id) AS number, AVG(distance_to_previous) AS avg FROM revisions JOIN resources ON revisions.resource_id = resources.id
        WHERE resources.monitored_resource_id=1 AND distance_to_previous IS NOT NULL AND distance_to_previous < ' + seconds.to_s
      dist_siemens = ActiveRecord::Base.connection.execute(query_siemens)

      query_lapeyre = 'SELECT COUNT(revisions.id) AS number, AVG(distance_to_previous) AS avg FROM revisions JOIN resources ON revisions.resource_id = resources.id
        WHERE resources.monitored_resource_id=2 AND distance_to_previous IS NOT NULL AND distance_to_previous < ' + seconds.to_s
      dist_lapeyre = ActiveRecord::Base.connection.execute(query_lapeyre)

      query_bayer = 'SELECT COUNT(revisions.id) AS number, AVG(distance_to_previous) AS avg FROM revisions JOIN resources ON revisions.resource_id = resources.id
        WHERE resources.monitored_resource_id=4 AND distance_to_previous IS NOT NULL AND distance_to_previous < ' + seconds.to_s
      dist_bayer = ActiveRecord::Base.connection.execute(query_bayer)

      avg_array << [ (avg_base*60), dist[0]['avg'].round(2), dist_siemens[0]['avg'].round(2), dist_lapeyre[0]['avg'].round(2), dist_bayer[0]['avg'].round(2) ]

      number_array << [ (avg_base*60), (dist[0]['number'].to_f/sum).round(2), (dist_siemens[0]['number'].to_f/sum_siemens).round(2), (dist_lapeyre[0]['number'].to_f/sum_lapeyre).round(2), (dist_bayer[0]['number'].to_f/sum_bayer).round(2) ]
    end

    @averages_json = avg_array.to_json

    @percentages_json = number_array.to_json
  end

  def calculate_threshold
    resources = Resource.find_with_several_revisions
    resources.each do |resource|
      id = resource.has_key?('id') ? resource['id'].to_i : nil
      if id
        revisions = Revision.where(:resource_id => id)
        revisions.each do |revision|
          revision.calculate_time_distance_to_previous
        end
      end
    end

    redirect_to show_threshold_path
  end

  def refresh_revisions
    @resource.retrieve_revisions(current_user.token)
    redirect_to monitored_resource_resource_url(@monitored_resource, @resource), :notice => "Revisions are being refreshed!"
  end

  def download_revisions
    @resource.download_revisions(current_user.token)
    redirect_to monitored_resource_resource_url(@monitored_resource, @resource), :notice => "Revisions are being downloaded!"
  end

  def calculate_diffs
    @resource.calculate_revision_diffs
    redirect_to monitored_resource_resource_url(@monitored_resource, @resource), :notice => "Revision Diffs have been calculated"
  end

  def merge_revisions
    # delete old merges
    Revision.where(:resource_id => @resource.id).update_all('revision_id = NULL')

    # then create new merges
    @resource.merge_consecutive_revisions
    redirect_to monitored_resource_resource_url(@monitored_resource, @resource), :notice => "Weak Revisions have been merged!"
  end

  def find_collaborations
    # delete old merges
    Revision.where(:resource_id => @resource.id).update_all('collaboration_id = NULL')

    @resource.find_collaborations
    redirect_to monitored_resource_resource_url(@monitored_resource, @resource), :notice => "Collaborations have been created!"
  end

  def merged_revisions
    @master = Revision.find(params[:rev_id])
    @revisions = Revision
      .where('resource_id=? AND (collaboration_id=? OR revision_id = ?)',
             @resource.id, params[:rev_id], params[:rev_id] )
      .order('modified_date DESC')

    respond_to do |format|
      format.html { render :layout => !request.xhr? }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_resource
    @monitored_resource = MonitoredResource.find(params[:monitored_resource_id])
    @resource = Resource.find(params[:id])
  end
end
