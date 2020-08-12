module KyMetrics
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    
    def index
      restrict_web_access = false
      metrics = {
        "sidekiq" => { "total_workers" => 0, "total_threads" => 0, "busy_threads" => 0, "busy_percentage" => 0.0},
        "altsidekiq" => { "total_workers" => 0, "total_threads" => 0, "busy_threads" => 0, "busy_percentage" => 0.0}
      }   
        
      metrics_string = ""
      metrics.keys.each do |process_name|
        ps = Sidekiq::ProcessSet.new
        metrics[process_name]["total_workers"] = ps.map { |host| 1 if host["identity"].split("-")[-3]==process_name}.map { |item| item.to_i }.sum
        metrics[process_name]["total_threads"] = ps.map { |host| host['concurrency'].to_i if host["identity"].split("-")[-3]==process_name }.map { |item| item.to_i }.sum 
        metrics[process_name]["busy_threads"] = ps.map { |host| host['busy'].to_i if host["identity"].split("-")[-3]==process_name }.map { |item| item.to_i}.sum 
        metrics[process_name]["busy_percentage"] = (100.0 * (metrics[process_name]["busy_threads"].to_f / [metrics[process_name]["total_threads"], 1].max.to_f)).to_i   
        #puts "Process name = #{process_name} | Busy Threads = #{metrics[process_name]["busy_threads"]} | Total Threads = #{metrics[process_name]["total_threads"]} | Busy Percentage = #{metrics[process_name]["busy_percentage"]}%"
        metrics_string += "#{process_name}_total_workers #{metrics[process_name]["total_workers"]}\n#{process_name}_total_threads #{metrics[process_name]["total_threads"]}\n#{process_name}_busy_threads #{metrics[process_name]["busy_threads"]}\n#{process_name}_busy_percentage #{metrics[process_name]["busy_percentage"]}\n"
      end
      
      is_prometheus_request = (request.headers.key?("HTTP_X_PROMETHEUS_SCRAPE_TIMEOUT_SECONDS") == true) && (request.headers.key?("HTTP_X_FORWARDED_FOR") == false)
      
      response.set_header("Content-Type", "text/plain; version=0.0.4")
      response.set_header("Cache-Control", "no-cache") 
        
      if ( restrict_web_access && is_prometheus_request  )
        render plain: metrics_string
      elsif ( restrict_web_access && !is_prometheus_request )
        render plain: "Not authorized to view this Page", :status => :unauthorized
      else
        render plain: metrics_string
      end
        
     
      
    end
      
      
      
  end
end
 