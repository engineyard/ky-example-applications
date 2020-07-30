# Custom Metrics for Passenger

This is a demo application that displays how the `custom metrics` for HPA can be used when it comes to web traffic. Specifically, the application is using `passenger` webserver, but it could be used as an example in other cases too.

## Setup

### Configuration

The application will use just SQLite. Since no communication is needed for our backend (no information shared among the webserver e.g. users etc), SQLite will do just fine. This means that the only configuration we should provide is the one regarding the Horizontal Pod Autoscaling (HPA):

```
KY_AUTOSCALING_web_ENABLED                  true
KY_AUTOSCALING_web_MAX_REPLICAS             20
KY_AUTOSCALING_web_METRIC_NAME              passenger_workers
KY_AUTOSCALING_web_METRIC_QUERY             avg(passenger_workers{service="<your_application_name>"})
KY_AUTOSCALING_web_METRIC_TYPE              Prometheus
KY_AUTOSCALING_web_MIN_REPLICAS             3
KY_AUTOSCALING_web_TARGET_TYPE              Value
KY_AUTOSCALING_web_TARGET_VALUE             4
```


## How it works

The application exposes the following routes:

* `/` : the default rails route
* `/add-requests-in-queue` : a route that will just make the request sleep for a random number of seconds. 

The route `/add-requests-in-queue` tries to simulate a request that takes too much time to complete. Having a number of such simultaneusly requests will end up choking the passenger web server. 

In order to avoid requests queueing, we need to enable HPA with `custom metrics` so that more web pods will be started once a specific metric reaches a limit. In our case we have used the metric `passenger_workers` that is the number of passenger workers reported via `passenger-status`. Specifically we use the **average** number of `passenger_workers` reported across all our web pods.

One issue with the above approach is that the `custom metrics` is just a route in our application. Prometheus will scrape that route in order to obtain the desired metric and then signal the HPA to take action. In cases of high traffic spikes the requests to the `/metric` will be also queued, leading to no scaling.

In order to avoid that case we have modified the nginx template that passenger uses adding a route to `/metrics` on the nginx level. This route is served **not** by our application but by a minimal rack application. The rack application will just call the `passenger-status` command, scrape its output and display the metrics in order for Prometheus to read them. This way, even if passenger is queueing the requests, we can be assured that the `/metrics` route will be served and that HPA will scale the web pods accordingly.

## How to see it in action

Deploy the application and using a v5 stack instance issue the following command in order to create heavy traffic:

```
ab -n 10000 -c 300 http://<your_application_name>.kontaineryard.io/add-requests-in-queue
```

By visiting the URL http://<your_application_name>.kontaineryard.io/metrics you will see the passenger workers and queue. Even if there are requests queued up, the `/metrics` request is served due to it being processed not by passenger but from the rack application. By issuing `eyk ps:list` you may see the web pods scaling.

