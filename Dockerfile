FROM ruby:2.5-alpine
RUN apk update && apk add nodejs build-base libxml2-dev libxslt-dev postgresql postgresql-dev sqlite sqlite-dev busybox-suid curl bash linux-headers
 


# Install dependencies in order to be able to build passenger
RUN apk add curl-dev pcre-dev
RUN gem install passenger -v "5.3.7"
RUN passenger-config install-standalone-runtime --auto

# Configure the main working directory. This is the base 
# directory used in any further RUN, COPY, and ENTRYPOINT 
# commands.
RUN mkdir -p /app 
WORKDIR /app


# Copy the Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v '1.16.3' && bundle install --without development test --jobs 20 --retry 5

# Copy the main application.
COPY . ./

RUN chmod +x ky_specific/start_webserver_script.sh

# Expose port 5000 to the Docker host, so we can access it 
# from the outside. This is the same as the one set with
# `deis config:set PORT 5000`
EXPOSE 5000

# The main command to run when the container starts. Also 
# tell the Rails dev server to bind to all interfaces by 
# default.
#CMD bundle exec sidekiq -C config/sidekiq.yml -e development & bundle exec rails server -b 0.0.0.0 -p 5000 -e development  
CMD ls
