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

  # GET monitored_resource/1/resources/1
  def show
    redirect_to monitored_resource_path(@monitored_resource), :alert => 'Resource does not exist!' if @resource.blank?
  end

  def show_threshold
    respond_to do |format|
      format.html {  }
      format.json {
        cat = Array.new
        (1..27).each do |x|
          cat << (x*10).to_s
        end

        result_set = {
          :categories => cat,
          :data => scatter_distances(270)
        }

        render json: result_set
      }
    end
  end

  def calculate_time_distance_to_previous
    resources = Resource.find_with_several_revisions
    resources.each do |resource|
      id = resource.has_key?('id') ? resource['id'].to_i : nil
      if id
        revisions = Revision
          .where(:resource_id => id)
          .where(:distance_to_previous => nil)
        revisions.each do |revision|
          revision.calculate_time_distance_to_previous
        end
      end
    end

    redirect_to show_threshold_path
  end

  def calculate_optimal_threshold
    respond_to do |format|
      format.html {  }
      format.json {
        distances_to_previous_revisions = Hash.new
        (3..30).each do |var|
          seconds = (var*60)
          minutes = (seconds/60).to_s
          upper_limit = seconds+60
          distances_to_previous_revisions[minutes] = Array.new
          query = 'SELECT rr.id, rr.distance_to_previous AS dist FROM collaborations cc
            INNER JOIN  (
              SELECT c.collaboration_id AS sid, MIN(c.modified_date) AS modd
              FROM collaborations c WHERE c.threshold=? GROUP BY c.collaboration_id
            ) xx  ON cc.collaboration_id = xx.sid AND cc.modified_date = xx.modd
            JOIN revisions rr ON cc.revision_id=rr.id
            WHERE cc.threshold=? AND rr.distance_to_previous < ? AND rr.distance_to_previous != 0;'

          query_with_params = ActiveRecord::Base.send(:sanitize_sql_array, [query, seconds, seconds, upper_limit])
          results = ActiveRecord::Base.connection.exec_query(query_with_params)

          results.each do |collaboration|
              distances_to_previous_revisions[minutes] << collaboration['dist']-seconds
          end
        end

        result_set = Hash.new
        result_set['categories'] = distances_to_previous_revisions.keys
        result_set['data'] = Array.new
        result_set['occurences'] = Array.new

        distances_to_previous_revisions.values.each do |values|

          values.sort!
          result_set['occurences'] << values.length

          set = Array.new

          # lower adjacent
          set << values.min

          # lower hinge (25th percentile)
          up_hinge_rank = 0.25 * (values.length)
          ir_rank = up_hinge_rank.to_i

          up_hinge_fraction = up_hinge_rank - up_hinge_rank.to_i

          if up_hinge_fraction.eql? 0.0
            set << values[ir_rank]
          else
            if (ir_rank+1) >= values.length
              set << values[ir_rank]
            else
              interpolation = (up_hinge_fraction * (values[ir_rank+1] - values[ir_rank])) + values[ir_rank]
              set << interpolation
            end
          end

          # Median (50th percentile)
          up_hinge_rank = 0.50 * (values.length)
          ir_rank = up_hinge_rank.to_i
          up_hinge_fraction = up_hinge_rank - up_hinge_rank.to_i
          if up_hinge_fraction.eql? 0.0
            set << values[ir_rank]
          else
            if (ir_rank+1) >= values.length
              set << values[ir_rank]
            else
              interpolation = (up_hinge_fraction * (values[ir_rank+1] - values[ir_rank])) + values[ir_rank]
              set << interpolation
            end
          end

          # upper hinge (75th percentile)
          up_hinge_rank = 0.75 * (values.length)
          ir_rank = up_hinge_rank.to_i
          up_hinge_fraction = up_hinge_rank - up_hinge_rank.to_i
          if up_hinge_fraction.eql? 0.0
            set << values[ir_rank]
          else
            if (ir_rank+1) >= values.length
              set << values[ir_rank]
            else
              interpolation_75 = (up_hinge_fraction * (values[ir_rank+1] - values[ir_rank])) + values[ir_rank]
              set << interpolation_75
            end
          end

          # upper adjacent
          set << values.max

          result_set['data'] << set
        end

        render json: result_set
      }
    end



  end

  def merged_revisions
    @master = Revision.find(params[:rev_id])
    @revisions = Revision
    .joins('JOIN collaborations ON revisions.id=collaborations.revision_id')
    .where('revisions.resource_id=?', @master.resource_id)
    .where('collaborations.collaboration_id=?', @master.id)
    .where('collaborations.threshold=?', Collaboration::STANDARD_COLLABORATION_THRESHOLD)
    .order('modified_date DESC')

    respond_to do |format|
      format.html { render :layout => !request.xhr? }
    end
  end

  # def refresh_revisions
  #   @resource.retrieve_revisions(current_user.token)
  #   redirect_to monitored_resource_resource_url(@monitored_resource, @resource), :notice => "Revisions are being refreshed!"
  # end

  # def download_revisions
  #   @resource.download_revisions(current_user.token)
  #   redirect_to monitored_resource_resource_url(@monitored_resource, @resource), :notice => "Revisions are being downloaded!"
  # end
  #
  # def calculate_diffs
  #   @resource.calculate_revision_diffs
  #   redirect_to monitored_resource_resource_url(@monitored_resource, @resource), :notice => "Revision Diffs have been calculated"
  # end

  # @todo: deprecated ... now done on monitored_resource-level for all google_resources
  # def merge_revisions
  #   # delete old merges
  #   #Revision.where(:resource_id => @resource.id).update_all('revision_id = NULL')
  #
  #   # then create new merges
  #   @resource.merge_consecutive_revisions
  #   redirect_to monitored_resource_resource_url(@monitored_resource, @resource), :notice => "Weak Revisions have been merged!"
  # end

  # @todo: deprecated ... now done on monitored_resource-level for all google_resources
  # def find_collaborations
  #   # delete old merges
  #   #Revision.where(:resource_id => @resource.id).update_all('collaboration_id = NULL')
  #
  #   @resource.find_collaborations
  #   redirect_to monitored_resource_resource_url(@monitored_resource, @resource), :notice => "Collaborations have been created!"
  # end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_resource
    @monitored_resource = MonitoredResource.find(params[:monitored_resource_id])

    # Authorize object permission - @todo: better way to solve this via cancan?
    unless @monitored_resource.nil?
      shared = current_user.shared_resources.map {|r| r.id }
      @monitored_resource = nil unless ((@monitored_resource.user_id == current_user.id) || shared.include?(@monitored_resource.id))
    end

    @resource = Resource.where(
        :id =>params[:id],
        :monitored_resource_id => params[:monitored_resource_id]
    ).first
  end

  def scatter_distances(limit=900)
    limit_query = limit
    distances = Array.new

    #query = "SELECT distance_to_previous FROM revisions WHERE distance_to_previous IS NOT NULL AND distance_to_previous < #{limit_query}"
    #dist = ActiveRecord::Base.connection.exec_query(query)
    #distances << scatter_distances_for(dist, 'Distances All', COLORS[0] )

    query_google = "SELECT distance_to_previous FROM revisions JOIN resources ON revisions.resource_id = resources.id
      WHERE resources.mime_type IN ('#{ Resource::GOOGLE_FILE_TYPES.join("','") }') AND distance_to_previous IS NOT NULL AND distance_to_previous < #{limit_query}"
    dist_google = ActiveRecord::Base.connection.exec_query(query_google)
    distances << scatter_distances_for(dist_google, 'Google file types', COLORS[0] )

    query_non_google = "SELECT distance_to_previous FROM revisions JOIN resources ON revisions.resource_id = resources.id
      WHERE resources.mime_type NOT IN ('#{ Resource::GOOGLE_FILE_TYPES.join("','") }') AND distance_to_previous IS NOT NULL AND distance_to_previous < #{limit_query}"
    dist_non_google = ActiveRecord::Base.connection.exec_query(query_non_google)
    distances << scatter_distances_for(dist_non_google, 'other file types', COLORS[1] )

    #MonitoredResource.all.each_with_index do |mr, index|
    #  query_team = 'SELECT distance_to_previous FROM revisions JOIN resources ON revisions.resource_id = resources.id
    #        WHERE resources.monitored_resource_id=' + mr.id.to_s + ' AND distance_to_previous IS NOT NULL AND distance_to_previous < 901'
    #  dist_team = ActiveRecord::Base.connection.exec_query(query_team)
    #  distances << scatter_distances_for(dist_team, mr.title, COLORS[index+1] )
    #end

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

    set_array = Array.new
    distances_all_values.sort.each do |tupel|
      set_array << tupel[1]
    end

    distances_all[:data] = set_array
    return distances_all
  end

  def scatter_aritmetic_means
    results = Array.new

    data_all = Hash.new
    (1..60).each do |avg_base|
      seconds = (avg_base*60)+1
      query = 'SELECT AVG(distance_to_previous) AS avg FROM revisions WHERE distance_to_previous IS NOT NULL AND distance_to_previous < ' + seconds.to_s
      dist = ActiveRecord::Base.connection.exec_query(query)
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
        dist = ActiveRecord::Base.connection.exec_query(query)
        data[avg_base] = dist[0]['avg'].round(2)
      end

      results[index+1][:data] = data.to_a
    end

    return results
  end

  def scatter_percentage
    results = Array.new

    query_sum = 'SELECT COUNT(revisions.id) as count FROM revisions WHERE distance_to_previous IS NOT NULL'
    res_sum = ActiveRecord::Base.connection.exec_query(query_sum)
    sum = res_sum[0]['count']

    data_all = Hash.new
    (1..60).each do |avg_base|
      seconds = (avg_base*60)+1
      query = 'SELECT COUNT(revisions.id) AS number FROM revisions WHERE distance_to_previous IS NOT NULL AND distance_to_previous < ' + seconds.to_s
      dist = ActiveRecord::Base.connection.exec_query(query)
      data_all[avg_base] = (dist[0]['number'].to_f/sum).round(2)
    end
    results[0] = {:name => 'All', :color => COLORS[0], :data => data_all.to_a }

    MonitoredResource.all.each_with_index do |mr,index|
      results[index+1] = {:name => mr.title, :color => COLORS[index+1],  }

      query_team = 'SELECT COUNT(revisions.id) as count FROM revisions
        JOIN resources ON revisions.resource_id=resources.id
        WHERE resources.monitored_resource_id='+ mr.id.to_s + ' AND distance_to_previous IS NOT NULL'
      res_sum_team = ActiveRecord::Base.connection.exec_query(query_team)
      sum_team = res_sum_team[0]['count']

      data = Hash.new
      (1..60).each do |avg_base|
        seconds = (avg_base*60)+1
        query = 'SELECT COUNT(revisions.id) AS number FROM revisions JOIN resources ON revisions.resource_id = resources.id
          WHERE resources.monitored_resource_id=' + mr.id.to_s + ' AND distance_to_previous IS NOT NULL AND distance_to_previous < ' + seconds.to_s
        dist = ActiveRecord::Base.connection.exec_query(query)
        data[avg_base] = (dist[0]['number'].to_f/sum_team).round(2)
      end

      results[index+1][:data] = data.to_a
    end

    return results
  end
end
