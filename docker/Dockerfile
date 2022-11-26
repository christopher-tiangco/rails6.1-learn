ARG RUBY_VERSION=2.7.4

################ Base image used for dev, staging, production ##################
FROM ruby:$RUBY_VERSION-slim as base

ARG BUNDLER_VERSION=2.1.4
ARG NODE_MAJOR=14

# Force container to use UTC timezone
RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime

# Install required packages
# - tzdata downloads the public-domain timezone database
# - poppler-utils (required for notice generation, `pdfunite`) 
# - libicu-dev (required by charlock_holmes gem) 
# - libpq-dev (required by pg gem) 
# - build-essential (required by racc / ffi gems) 
# - git (required by Bundler and the app) 
# - curl (required to get nodeJS) 
# - postgresql-client (required by rails db:setup) 
# - file and imagemagick (required by Paperclip to identify correct file mimetype) 
RUN apt update && \ 
  apt install -y --no-install-recommends \ 
    tzdata \
    poppler-utils \ 
    libicu-dev \ 
    libpq-dev \ 
    git \ 
    build-essential \ 
    curl \ 
    postgresql-client \ 
    file \ 
    imagemagick \ 
    shared-mime-info \ 
    gnupg \ 
    libsqlite3-dev \ 
    chromium chromium-driver \ 
    nodejs && \ 
  apt-get upgrade -y && \ 
  rm -rf /var/lib/apt/lists/* && \ 
  dpkg-reconfigure --frontend noninteractive tzdata

# Install NodeJs and Yarn
RUN curl -sL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash - && \ 
  apt update && apt install -y --no-install-recommends nodejs && \ 
  npm install -g yarn

RUN gem install bundler -v $BUNDLER_VERSION
RUN gem install sass-rails
RUN gem install rails -v 6.1.0


##################### Dev Environment Image #####################

FROM ghcr.io/christopher-tiangco/rails6.1:base as dev_environment

WORKDIR /home/site

RUN useradd --create-home pi

RUN mkdir -p /tmp/rails-base && cd /tmp/rails-base && rails _6.1.0_ new . -d=postgresql --skip-git

COPY Dockerfile /home/pi/Dockerfile
COPY .gitignore /home/pi/.gitignore
COPY development/entrypoint.sh /home/pi/entrypoint.sh
COPY development/database.yml /home/pi/database.yml
COPY development/development.rb /home/pi/development.rb
COPY development/.erb-lint.yml /home/pi/.erb-lint.yml
COPY development/.rubocop.yml /home/pi/.rubocop.yml

RUN chmod +x /home/pi/entrypoint.sh && chown -R pi:pi /usr/local/bundle /home/pi /home/site /tmp/rails-base

ENTRYPOINT ["bash", "-c", "/home/pi/entrypoint.sh"]

USER pi

##################### Build Production Image Dependencies #####################
FROM ghcr.io/christopher-tiangco/rails6.1:base as production_gems_and_assets

WORKDIR /home

ENV GEM_HOME=/usr/local/bundle
ENV BUNDLE_APP_CONFIG=$GEM_HOME
ENV BUNDLE_BIN=/usr/local/bin
ENV RAILS_ENV=production
ENV NODE_ENV=production

COPY ./Gemfile .
COPY ./Gemfile.lock .
COPY ./package.json .
COPY ./yarn.lock .

RUN bundle config set --local without 'development test' \
  && bundle install -j "$(getconf _NPROCESSORS_ONLN)" --retry=3
  
RUN yarn install

COPY . .

RUN --mount=type=secret,id=master_key,dst=/home/config/master.key \ 
  bundle exec rails assets:precompile


##################### Production Image #####################
FROM ruby:$RUBY_VERSION-slim as production

WORKDIR /home

ENV GEM_HOME=/usr/local/bundle
ENV BUNDLE_APP_CONFIG=$GEM_HOME
ENV BUNDLE_BIN=/usr/local/bin
ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=enabled
ENV RAILS_LOG_TO_STDOUT=enabled

# Required for starting puma web server
RUN mkdir -p tmp/pids

# Required shared library for postgresql
RUN apt update && apt install libpq5 -y

# Create the master key passed-in at the build command
RUN --mount=type=secret,id=master_key,dst=/home/config/master.key.tmp \
  cp /home/config/master.key.tmp /home/config/master.key

# Copy prebuilt gems
COPY --from=production_gems_and_assets $GEM_HOME $GEM_HOME

# Copy app code
COPY . .

# Copy prebuilt assets
COPY --from=production_gems_and_assets /home/public/assets /home/public/assets
COPY --from=production_gems_and_assets /home/public/packs /home/public/packs

ENTRYPOINT export RAILS_MASTER_KEY=$(cat /home/config/master.key) \
  && bundle exec puma -C config/puma.rb

USER root
