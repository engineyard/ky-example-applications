# Engine Yard Kontainers example application: multi pod application with autoscaling

A Rails application created to test sidekiq workers, cron jobs and database migrations on KY.

# Introduction

A real KontainerYard application will consist of multiple processes each one having its own pod/s. Some processes are "special" like `cronenberg` and `migration`, while others like `sidekiq` are not. 

### cronenberg
The `cronenberg` process is a pod that will execute our cron jobs. It basically uses the [cronenberg](https://github.com/ess/cronenberg) binary with the jobs defined under `ky-specific/cronenberg/cron-jobs.yml`. Once the pod is up it will just run the jobs, like the standard cron does.

### migration
The `migration` process (the entry named `migration` in Procfile) is a little bit more complicated. The goal is to run the `db:migrate` command during deployments _before_ any other process starts. It aims to work like the one in EYCloud: the migration is executed _before_ the passenger/unicorn restart, so that the database schema will be there when the newly deployed code is executed. Like all commands in KontainerYard, the `db:migrate` should be executed in a pod. So, during a deployment the pod named `migration` will be started first, execute the "commands" and then (if successful) the rest of the pods will be started (e.g. `web`, `sidekiq`, `cronenberg`). In our example the "commands" is the script `ky-specific/migration/db-migrate.sh`. This shell script will actually invoke the command `db:migrate` and based on the result it will touch a file named `/tmp/migration-ready` within the pod.

As we have seen in the EYCloud deployments, if a `db:migrate` fails then the deployment is rolled back. We can achieve the same in KontainerYard via using the [readiness probe](https://docs.teamhephy.com/applications/managing-app-configuration/#custom-health-checks). The `readiness probe` is just an http or exec check in order to verify if a pod is in running. As mentioned above, the file `/tmp/migration-ready` will be created _once_ the migrations have finished successfully. If they fail for any reason then the file won't be created, thus the pod will be determined as failed, an exception will be thrown in the deis-controller side and the deployment will be rolled back.

The above show that a carefully chosen `readiness probe` is the key in order handle long running migrations. We have used successfully the following:

```
deis config set DEIS_DEPLOY_TIMEOUT=600 --app=<app_name>

deis healthchecks:set readiness exec stat /tmp/migration-ready --type=migration --initial-delay=10 --period-seconds=10 --success-threshold=1 --failure-threshold=60 --app=<app_name>

```
You may check for the details of the setting [DEIS_DEPLOY_TIMEOUT](https://docs.teamhephy.com/applications/deploying-apps/#tuning-application-settings)

### web
The web process will consist of one or more pods that will run the web server (in our case Puma).

### sidekiq
The web process will consist of one or more pods that will run the sidekiq workers.

# Autoscaling
In KontainerYard the notion of Autoscaling means different things according to the context. We have the following contexts:

* cluster
* pods
* custom

### cluster Autoscaling

This is a k8s component that controls the number of instances in the cluster. All the pods will run on the cluster's worker nodes (EC2 instances). When we start up more pods than the current cluster's capacity the  cluster autoscaler will signal AWS to add more nodes (instances). If the pods number drops, the cluster autoscaler will signal AWS to remove some nodes.


### pod Autoscaling

The pod Autoscaling in the KontainerYard is actually the [hephy's HPA](https://docs.teamhephy.com/applications/managing-app-processes/#autoscale). This can be set via the `deis autoscale` command. The pod Autoscaling is based on cpu/memory usage rules. 

### custom Autoscaling
This is a KontainerYard feature. The custom Autoscaling context refers to pods. We can set custom rules in order to decide the scaling of the pods. We start by exposing a `/metrics` route that outputs the needed metrics (e.g. sidekiq workers and queue size). Prometheus will scrape the `/metrics` route of the application and decide on if the pods need scaling or not. Setting the appropriate configuration is more complicated compared to `deis autoscale`, but gives more control.

Although the `/metrics` route could be part of the application, in this example we have decided to create a [mountable rails engine](https://guides.rubyonrails.org/engines.html). This means that we can separate the KontainerYard only components. In this example, the directory `ky_metrics` is the one holding the mountable rails engine that exposes the `/metrics` route. In order to show the great flexibility of the application, we have added the needed "hooks" in the `Dockerfile`. These "hooks" will actually modify the `Gemfile` and `config/routes.rb` in order to include the `ky_metrics` in `Gemfile` and expose `/metrics` in `config/routes.rb`. While we could simply make it part of the application in the first place, this option shows how the `Dockerfile` can be used in order to customize the deployment and also the application itself.  

In our example the `/metrics` route will expose the following information:

```
      metrics = {
        "sidekiq" => { "total_workers" => 0, "total_threads" => 0, "busy_threads" => 0, "busy_percentage" => 0.0},
        "altsidekiq" => { "total_workers" => 0, "total_threads" => 0, "busy_threads" => 0, "busy_percentage" => 0.0}
      }   
```
This means that we are able to create some business rules for the scaling to be based upon (e.g. scale the sidekiq pods when the `busy_percentage` is more than 70%). Since sidekiq shares all the information in redis, these metrics can be easily computed.

In order to set the custom Autoscaling we need to configure the application like:

```
KY_AUTOSCALING_sidekiq_ENABLED              true
KY_AUTOSCALING_sidekiq_MAX_REPLICAS         8
KY_AUTOSCALING_sidekiq_METRIC_NAME          sidekiq_busy_percentage
KY_AUTOSCALING_sidekiq_METRIC_QUERY         sidekiq_busy_percentage
KY_AUTOSCALING_sidekiq_METRIC_TYPE          Prometheus
KY_AUTOSCALING_sidekiq_MIN_REPLICAS         1
KY_AUTOSCALING_sidekiq_TARGET_TYPE          Value
KY_AUTOSCALING_sidekiq_TARGET_VALUE         75
```

