FROM mcr.microsoft.com/devcontainers/ruby:4.0

WORKDIR /workspace

ENV BUNDLE_PATH=/cache/bundle

# cmake builds libgit2 for the rugged gem
RUN apt-get update && \
    apt-get install -y cmake git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN git config --global --add safe.directory '*'

COPY Gemfile Gemfile.lock git_fame.gemspec ./
COPY lib/git_fame/version.rb ./lib/git_fame/version.rb

RUN bundle install --jobs 4 --retry 3
