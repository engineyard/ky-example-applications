class PagesController < ApplicationController 
  
  def metrics
      p ENV['DYNO']
      p ENV['HOSTNAME']
      response.set_header("Content-Type", "text/plain; version=0.0.4")
      response.set_header("Cache-Control", "no-cache")
      low_threshold = 4
      high_threshold = 10
      ps = Sidekiq::ProcessSet.new
      total_threads = ps.map { |host| host['concurrency'].to_i }.sum 
      busy_threads = ps.map { |host| host['busy'].to_i }.sum 
      busy_percentage = (100.0 * (busy_threads.to_f / [total_threads, 1].max.to_f)).to_i
      scale_up = case 
        when busy_percentage >= high_threshold
          2
        when busy_percentage <= low_threshold
          1
        else
          0
      end
      puts "High threshold = #{high_threshold} | Low threshold = #{low_threshold}"
      puts "#{busy_threads}/#{total_threads} (#{busy_percentage}%) busy, scale #{scale_up}"
      
      metrics_string = ""
      
      
      render plain: "total_threads #{total_threads}\nbusy_threads #{busy_threads}\nbusy_percentage #{busy_percentage}\nscale_up #{scale_up}"
  end
    




end