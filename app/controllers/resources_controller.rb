require 'json'

class ResourcesController < ApplicationController
  before_filter :refresh_token!, only: [:refresh_revisions, :download_revisions]
  before_action :set_resource, only: [:show, :refresh_revisions, :download_revisions,
                                      :calculate_diffs, :merge_revisions, :find_collaborations, :merged_revisions]

  COLORS = [
      'rgba(119, 152, 191, .5)',
      'rgba(223, 83, 83, .5)',
      'rgba(30, 152, 30, .5)',
      'rgba(255, 165, 0, .5)',
      'rgba(83, 83, 83, .5)',
  ]

  # GET /resources/1
  def show
    # do nothing
  end

  def show_threshold
    respond_to do |format|
      format.html {  }
      format.json {
        reportid = params[:resultid].to_i

        case reportid
          when 0
            distances = scatter_distances
            result_set = {
              :title => 'frequency vs. distance',
              :x_title => 'distances in seconds',
              :y_title => 'frequency', :data => distances
            }
          when 1
            aritmetic_means = scatter_aritmetic_means
            result_set = {
              :title => 'arithmetic mean vs. maximum distance',
              :x_title => 'maximum distance between revisions in seconds',
              :y_title => 'frequency', :data => aritmetic_means}
          when 2
            percentages = scatter_percentage
            result_set = {
                :title => 'accumulated percentage of revisions',
                :x_title => 'maximum distance between revisions in seconds',
                :y_title => 'percentage', :data => percentages}

          else
            result_set = {}
        end

        render json: result_set
      }
    end
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

  def scatter_distances
    query = 'SELECT distance_to_previous FROM revisions WHERE distance_to_previous IS NOT NULL AND distance_to_previous < 901'
    dist = ActiveRecord::Base.connection.execute(query)

    distances = Array.new
    distances << scatter_distances_for(dist, 'Distances All', COLORS[0] )

    MonitoredResource.all.each_with_index do |mr, index|
      query_team = 'SELECT distance_to_previous FROM revisions JOIN resources ON revisions.resource_id = resources.id
            WHERE resources.monitored_resource_id=' + mr.id.to_s + ' AND distance_to_previous IS NOT NULL AND distance_to_previous < 901'
      dist_team = ActiveRecord::Base.connection.execute(query_team)
      distances << scatter_distances_for(dist_team, mr.title, COLORS[index+1] )
    end

    return distances
  end

  def scatter_distances_for(dist, name, color)
    distances_all = {
        :name => name,
        :color => color,
    }

    distances_all_values = Hash.new

    dist.each do |d|
      key = ((d['distance_to_previous'].to_i/10)+1)*10
      if distances_all_values.has_key? key
        distances_all_values[ key ] += 1
      else
        distances_all_values[ key ] = 1
      end
    end

    distances_all[:data] = distances_all_values.to_a
    return distances_all
  end

  def scatter_aritmetic_means
    results = Array.new

    data_all = Hash.new
    (1..60).each do |avg_base|
      seconds = (avg_base*60)+1
      query = 'SELECT AVG(distance_to_previous) AS avg FROM revisions WHERE distance_to_previous IS NOT NULL AND distance_to_previous < ' + seconds.to_s
      dist = ActiveRecord::Base.connection.execute(query)
      data_all[avg_base] = dist[0]['avg'].round(2)
    end
    results[0] = {:name => 'All', :color => COLORS[0], :data => data_all.to_a }

    MonitoredResource.all.each_with_index do |mr,index|
      results[index+1] = {:name => mr.title, :color => COLORS[index+1],  }
      data = Hash.new
      (1..60).each do |avg_base|
        seconds = (avg_base*60)+1
        query = 'SELECT AVG(distance_to_previous) AS avg FROM revisions JOIN resources ON revisions.resource_id = resources.id
          WHERE resources.monitored_resource_id=' + mr.id.to_s + ' AND distance_to_previous IS NOT NULL AND distance_to_previous < ' + seconds.to_s
        dist = ActiveRecord::Base.connection.execute(query)
        data[avg_base] = dist[0]['avg'].round(2)
      end

      results[index+1][:data] = data.to_a
    end

    return results
  end

  def scatter_percentage
    results = Array.new

    query_sum = 'SELECT COUNT(revisions.id) as count FROM revisions WHERE distance_to_previous IS NOT NULL'
    res_sum = ActiveRecord::Base.connection.execute(query_sum)
    sum = res_sum[0]['count']

    data_all = Hash.new
    (1..60).each do |avg_base|
      seconds = (avg_base*60)+1
      query = 'SELECT COUNT(revisions.id) AS number FROM revisions WHERE distance_to_previous IS NOT NULL AND distance_to_previous < ' + seconds.to_s
      dist = ActiveRecord::Base.connection.execute(query)
      data_all[avg_base] = (dist[0]['number'].to_f/sum).round(2)
    end
    results[0] = {:name => 'All', :color => COLORS[0], :data => data_all.to_a }

    MonitoredResource.all.each_with_index do |mr,index|
      results[index+1] = {:name => mr.title, :color => COLORS[index+1],  }

      query_team = 'SELECT COUNT(revisions.id) as count FROM revisions
        JOIN resources ON revisions.resource_id=resources.id
        WHERE resources.monitored_resource_id='+ mr.id.to_s + ' AND distance_to_previous IS NOT NULL'
      res_sum_team = ActiveRecord::Base.connection.execute(query_team)
      sum_team = res_sum_team[0]['count']

      data = Hash.new
      (1..60).each do |avg_base|
        seconds = (avg_base*60)+1
        query = 'SELECT COUNT(revisions.id) AS number FROM revisions JOIN resources ON revisions.resource_id = resources.id
          WHERE resources.monitored_resource_id=' + mr.id.to_s + ' AND distance_to_previous IS NOT NULL AND distance_to_previous < ' + seconds.to_s
        dist = ActiveRecord::Base.connection.execute(query)
        data[avg_base] = (dist[0]['number'].to_f/sum_team).round(2)
      end

      results[index+1][:data] = data.to_a
    end

    return results
  end
end
