# Dockerfile for Railway deployment
FROM ruby:3.4.3-slim

# Install system dependencies
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    default-libmysqlclient-dev \
    libvips-dev \
    imagemagick \
    ffmpeg \
    libyaml-dev \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy dependency files first for better caching
COPY .ruby-version .ruby-version
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

COPY package.json package-lock.json ./
RUN npm install

# Copy the rest of the application
COPY . .

# Precompile assets (provide dummy env vars for build)
RUN RAILS_ENV=production \
    SECRET_KEY_BASE=dummy \
    DEVISE_SECRET_KEY=dummy \
    DATABASE_NAME=dummy \
    DATABASE_HOST=localhost \
    DATABASE_PORT=3306 \
    DATABASE_USERNAME=dummy \
    DATABASE_PASSWORD=dummy \
    REDIS_HOST=localhost:6379 \
    REDIS_URL=redis://localhost:6379 \
    SIDEKIQ_REDIS_HOST=localhost:6379 \
    RPUSH_REDIS_HOST=localhost:6379 \
    RACK_ATTACK_REDIS_HOST=localhost:6379 \
    MONGODB_URL=mongodb://localhost:27017/gumroad \
    MEMCACHE_SERVERS=localhost:11211 \
    ELASTICSEARCH_HOST=http://localhost:9200 \
    REVISION=build \
    bundle exec rails assets:precompile

# Expose port
EXPOSE 3000

# Start command
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
