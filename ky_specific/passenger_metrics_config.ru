class Application
    def call(env)
      status  = 200
      headers = { "Content-Type" => "text/plain; version=0.0.4", "Cache-Control" => "no-cache" }
  
      output = `/usr/local/bundle/gems/passenger-5.3.7/bin/passenger-status`
      passenger_queue = output.scan(/Requests in queue: [0-9]*/)[0].strip.split(": ")[1].to_i
      passenger_workers = output.scan(/PID/).length
      metrics_string = "passenger_requests_queue #{passenger_queue.to_s}\npassenger_workers #{passenger_workers.to_s}"
  
      body    = ["# this is served from rack server\n#{metrics_string}"]
  
      [status, headers, body]
    end
  end
  
run Application.new