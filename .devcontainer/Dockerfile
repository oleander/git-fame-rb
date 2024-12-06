FROM mcr.microsoft.com/devcontainers/ruby:3.3

WORKDIR /workspace

ENV BUNDLE_PATH=/cache/bundle

RUN apt-get update && \
    apt-get install -y cmake git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN git config --global --add safe.directory *
RUN gem install solargraph bundler:2.5.22 gem-release

COPY Gemfile Gemfile.lock git_fame.gemspec ./
COPY lib/git_fame/version.rb ./lib/git_fame/version.rb

RUN bundle install --jobs 4 --retry 3
