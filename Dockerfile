# ./Dockerfile
FROM ruby:2.7.1 as base

# set some default ENV values for the image
ENV BUNDLE_PATH /bundle
ENV RAILS_LOG_TO_STDOUT 1
ENV RAILS_SERVE_STATIC_FILES 1
ENV EXECJS_RUNTIME Node
# supress warnings until upgrade to rails 6
ENV RUBYOPT '-W0'

# set the app directory var
ENV APP_HOME /home/app
WORKDIR $APP_HOME
ARG NODE_MAJOR_VERSION=14
RUN curl -sL https://deb.nodesource.com/setup_${NODE_MAJOR_VERSION}.x | bash - \
  && apt-get update -qq \
  && apt-get install -y --no-install-recommends \
  build-essential \
  curl \
  default-libmysqlclient-dev \
  dumb-init \
  git \
  libssl-dev \
  libxslt-dev \
  nodejs \
  openssh-client \
  unzip \
  zlib1g-dev \
  default-mysql-client \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean


# install yarn, required by webpacker
ARG YARN_VERSION=1.22.4
RUN npm install -g yarn@${YARN_VERSION}
# install bundler
ARG BUNDLER_VERSION=2.0.2
RUN gem install bundler -v "${BUNDLER_VERSION}"


RUN gem install annotate
RUN gem install bundler


COPY . ./


RUN gem build rails_base

EXPOSE 5555

# use dumb-init as an init system for our process
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

