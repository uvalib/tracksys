FROM alpine:3.11

# Add necessary packages
RUN apk --update add bash tzdata ruby ruby-dev build-base nodejs sqlite-dev zlib-dev libxml2-dev libxslt-dev libffi-dev ca-certificates git imagemagick file mysql-dev

# Create the run user and group
RUN addgroup --gid 18570 sse && adduser --uid 1984 docker -G sse -D

# set the timezone appropriatly
ENV TZ=UTC
RUN cp /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Add necessary gems
RUN gem install bundler -v 1.17.3 --no-document # && gem install io-console --no-document

# Specify home 
ENV APP_HOME /tracksys
WORKDIR $APP_HOME

# Copy the Gemfile into the image and install the gems
ADD Gemfile Gemfile.lock ./
RUN bundle install --jobs=4 --without=["development" "test"] --no-cache

# install the app and bundle
COPY . $APP_HOME

# asset prevompile
RUN rake assets:precompile

# Update permissions
RUN chown -R docker $APP_HOME && chgrp -R sse $APP_HOME

# define port and startup script
EXPOSE 8080
CMD script/entry.sh

# move in the profile
COPY package/container_bash_profile /home/docker/.profile

# Ensure permissions are correct
RUN chown docker:sse /home/docker/.profile $APP_HOME/script/entry.sh && chmod 755 /home/docker/.profile $APP_HOME/script/entry.sh

# Add the build tag
#ARG BUILD_TAG
#RUN test -n "$BUILD_TAG" && touch $APP_HOME/buildtag.build-$BUILD_TAG || touch $APP_HOME/buildtag.build-0

# Specify the user
#USER docker

