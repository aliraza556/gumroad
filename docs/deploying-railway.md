# Deploying Gumroad to Railway

This guide provides step-by-step instructions for deploying Gumroad to [Railway](https://railway.app/). Railway offers a modern deployment experience with built-in support for databases and services, making it an excellent choice for deploying full-stack Rails applications.

## Table of contents

- [Prerequisites](#prerequisites)
- [Video walkthrough](#video-walkthrough)
- [Quick start (step-by-step)](#quick-start-step-by-step)
- [Detailed setup](#detailed-setup)
  - [Step 1: Create a Railway project](#step-1-create-a-railway-project)
  - [Step 2: Add services](#step-2-add-services)
  - [Step 3: Configure environment variables](#step-3-configure-environment-variables)
  - [Step 4: Deploy the application](#step-4-deploy-the-application)
  - [Step 5: Post-deployment setup](#step-5-post-deployment-setup)
- [Using railway.json configuration](#using-railwayjson-configuration)
- [Scaling](#scaling)
- [Troubleshooting](#troubleshooting)
- [Cost estimation](#cost-estimation)

---

## Prerequisites

Before you begin, ensure you have:

- A [Railway account](https://railway.app/) (GitHub account recommended for easy deployment)
- [Railway CLI](https://docs.railway.app/develop/cli) installed (optional but recommended)
- [Git](https://git-scm.com/) installed
- The Gumroad repository forked/cloned to your GitHub account

Install Railway CLI:

```bash
# macOS
brew install railway

# npm (all platforms)
npm install -g @railway/cli

# Shell script
curl -fsSL https://railway.app/install.sh | sh
```

## Video walkthrough

<!-- TODO: Add video demonstration link -->
> A video walkthrough of this deployment process is available [here](#).

---

## Quick start (step-by-step)

This is a complete step-by-step guide for deploying Gumroad to Railway. Follow each step in order.

### Step 1: Login to Railway CLI

```bash
railway login
```

This opens a browser window. Authorize the CLI to access your Railway account.

### Step 2: Create a new Railway project

```bash
railway init
```

- Select "Empty Project" when prompted
- Enter a project name (e.g., "gumroad")

### Step 3: Link your GitHub repository

1. Go to [Railway Dashboard](https://railway.app/dashboard)
2. Click on your newly created project
3. Click **"New"** → **"GitHub Repo"**
4. Select your forked Gumroad repository
5. Select the branch to deploy (e.g., `main` or your feature branch)

### Step 4: Add MySQL Database

1. In your Railway project, click **"New"**
2. Select **"Database"** → **"MySQL"**
3. Wait for MySQL to provision (about 30 seconds)

### Step 5: Add Redis

1. Click **"New"** → **"Database"** → **"Redis"**
2. Wait for Redis to provision

### Step 6: Add MongoDB

1. Click **"New"** → **"Database"** → **"MongoDB"**
2. Wait for MongoDB to provision

### Step 7: Add Memcached (via Docker)

1. Click **"New"** → **"Docker Image"**
2. Enter: `memcached:alpine`
3. Click **"Deploy"**
4. After deployment, go to **Settings** → **Networking**
5. Add a private network alias: `memcached`

### Step 8: Add Elasticsearch (via Docker)

1. Click **"New"** → **"Docker Image"**
2. Enter: `docker.elastic.co/elasticsearch/elasticsearch:7.17.0`
3. Add these environment variables to the Elasticsearch service:
   - `discovery.type` = `single-node`
   - `ES_JAVA_OPTS` = `-Xms512m -Xmx512m`
   - `xpack.security.enabled` = `false`
4. Click **"Deploy"**
5. After deployment, go to **Settings** → **Networking**
6. Add a private network alias: `elasticsearch`

### Step 9: Configure environment variables

Click on your **Gumroad web service** → **Variables** tab.

Add these variables (click "New Variable" for each):

**Rails Core:**
```
RAILS_ENV=production
RACK_ENV=production
RAILS_LOG_TO_STDOUT=enabled
RAILS_SERVE_STATIC_FILES=enabled
```

**Secret Keys (generate with `rails secret` locally):**
```
SECRET_KEY_BASE=<your-generated-secret>
DEVISE_SECRET_KEY=<your-generated-secret>
```

**Database (use Railway's variable references):**
```
DATABASE_HOST=${{MySQL.MYSQLHOST}}
DATABASE_PORT=${{MySQL.MYSQLPORT}}
DATABASE_NAME=${{MySQL.MYSQLDATABASE}}
DATABASE_USERNAME=${{MySQL.MYSQLUSER}}
DATABASE_PASSWORD=${{MySQL.MYSQLPASSWORD}}
```

**Redis:**
```
REDIS_HOST=${{Redis.REDIS_URL}}
SIDEKIQ_REDIS_HOST=${{Redis.REDIS_URL}}
RPUSH_REDIS_HOST=${{Redis.REDIS_URL}}
RACK_ATTACK_REDIS_HOST=${{Redis.REDIS_URL}}
```

**MongoDB (note: host:port format only, no protocol):**
```
MONGO_DATABASE_URL=${{MongoDB.MONGOHOST}}:${{MongoDB.MONGOPORT}}
MONGO_DATABASE_NAME=${{MongoDB.MONGO_INITDB_DATABASE}}
MONGO_DATABASE_USERNAME=${{MongoDB.MONGOUSER}}
MONGO_DATABASE_PASSWORD=${{MongoDB.MONGOPASSWORD}}
```

**Memcached:**
```
MEMCACHE_SERVERS=memcached:11211
```

**Elasticsearch:**
```
ELASTICSEARCH_HOST=http://elasticsearch:9200
```

**Application:**
```
REVISION=${{RAILWAY_GIT_COMMIT_SHA}}
DOMAIN=<your-railway-domain>.up.railway.app
PROTOCOL=https
```

### Step 10: Configure healthcheck

1. Click on your Gumroad web service
2. Go to **Settings** → **Healthcheck**
3. Set **Path** to `/healthcheck`
4. Set **Timeout** to `300` seconds

### Step 11: Deploy

Push your changes to GitHub, and Railway will automatically deploy:

```bash
git add .
git commit -m "Configure for Railway deployment"
git push origin main
```

Or trigger a manual deploy from the Railway dashboard by clicking **"Deploy"**.

### Step 12: Run database migrations

After the deployment succeeds:

```bash
railway link  # Link to your project if not already
railway run bundle exec rails db:migrate
railway run bundle exec rails db:seed
```

### Step 13: Generate a public domain

1. Click on your Gumroad web service
2. Go to **Settings** → **Networking**
3. Click **"Generate Domain"**
4. Copy the generated URL (e.g., `gumroad-production.up.railway.app`)
5. Update the `DOMAIN` environment variable with this value

### Step 14: Verify deployment

1. Visit your generated domain
2. Check the `/healthcheck` endpoint returns OK
3. Test basic functionality

## CLI Quick reference

For experienced users, here's a condensed CLI workflow:

```bash
# Login and create project
railway login
railway init

# Add services via dashboard (easier) or CLI
railway add --database mysql
railway add --database redis
railway add --database mongo

# Link and set core variables
railway link
railway variables set RAILS_ENV=production
railway variables set RACK_ENV=production
railway variables set RAILS_LOG_TO_STDOUT=enabled
railway variables set RAILS_SERVE_STATIC_FILES=enabled

# Deploy from GitHub (recommended) or CLI
railway up

# Run migrations after deploy
railway run bundle exec rails db:migrate
```

> **Note:** For complete setup, follow the [Quick start (step-by-step)](#quick-start-step-by-step) guide above.

## Detailed setup

### Step 1: Create a Railway project

#### Option A: Web dashboard (recommended for beginners)

1. Go to [Railway Dashboard](https://railway.app/dashboard)
2. Click "New Project"
3. Select "Deploy from GitHub repo"
4. Authorize Railway to access your GitHub account
5. Select the Gumroad repository
6. Railway will auto-detect the Rails application

#### Option B: Railway CLI

```bash
# Login to Railway
railway login

# Initialize project in your repository directory
cd /path/to/gumroad
railway init

# This creates a new project and links it to the current directory
```

### Step 2: Add services

Railway makes it easy to add databases and services. Add each service from the dashboard or CLI.

#### MySQL Database

**Via Dashboard:**
1. In your project, click "New"
2. Select "Database" → "MySQL"
3. Railway provisions a MySQL instance automatically

**Via CLI:**
```bash
railway add --database mysql
```

Railway automatically sets the `MYSQL_URL` environment variable.

#### Redis

**Via Dashboard:**
1. Click "New" → "Database" → "Redis"

**Via CLI:**
```bash
railway add --database redis
```

Railway automatically sets the `REDIS_URL` environment variable.

#### MongoDB

**Via Dashboard:**
1. Click "New" → "Database" → "MongoDB"

**Via CLI:**
```bash
railway add --database mongo
```

Railway automatically sets the `MONGO_URL` environment variable.

#### Elasticsearch

Railway doesn't have a native Elasticsearch plugin. Use one of these options:

**Option 1: Elastic Cloud (recommended)**
1. Create an account at [Elastic Cloud](https://cloud.elastic.co/)
2. Create a deployment
3. Copy the Elasticsearch endpoint URL
4. Set it as an environment variable in Railway

**Option 2: Self-hosted on Railway**
1. Click "New" → "Docker Image"
2. Enter: `docker.elastic.co/elasticsearch/elasticsearch:7.17.0`
3. Add environment variable: `discovery.type=single-node`
4. Add environment variable: `ES_JAVA_OPTS=-Xms512m -Xmx512m`

### Step 3: Configure environment variables

Click on your web service in the Railway dashboard, then go to the "Variables" tab.

#### Database configuration

Railway automatically creates connection URLs. You need to parse them for Gumroad's expected format:

```bash
# Via CLI, set these variables:

# Parse MySQL URL components (Railway provides MYSQL_URL)
railway variables set DATABASE_HOST='${{MySQL.MYSQLHOST}}'
railway variables set DATABASE_PORT='${{MySQL.MYSQLPORT}}'
railway variables set DATABASE_NAME='${{MySQL.MYSQLDATABASE}}'
railway variables set DATABASE_USERNAME='${{MySQL.MYSQLUSER}}'
railway variables set DATABASE_PASSWORD='${{MySQL.MYSQLPASSWORD}}'

# Redis configuration (Railway provides REDIS_URL)
railway variables set REDIS_HOST='${{Redis.REDIS_URL}}'
railway variables set SIDEKIQ_REDIS_HOST='${{Redis.REDIS_URL}}'
railway variables set RPUSH_REDIS_HOST='${{Redis.REDIS_URL}}'
railway variables set RACK_ATTACK_REDIS_HOST='${{Redis.REDIS_URL}}'

# MongoDB configuration (host:port format, no protocol)
railway variables set MONGO_DATABASE_URL='${{MongoDB.MONGOHOST}}:${{MongoDB.MONGOPORT}}'
railway variables set MONGO_DATABASE_NAME='${{MongoDB.MONGO_INITDB_DATABASE}}'
railway variables set MONGO_DATABASE_USERNAME='${{MongoDB.MONGOUSER}}'
railway variables set MONGO_DATABASE_PASSWORD='${{MongoDB.MONGOPASSWORD}}'
```

#### Rails configuration

```bash
railway variables set RAILS_ENV=production
railway variables set RACK_ENV=production
railway variables set RAILS_LOG_TO_STDOUT=enabled
railway variables set RAILS_SERVE_STATIC_FILES=enabled
railway variables set RAILS_MAX_THREADS=5
railway variables set PUMA_WORKER_PROCESSES=2
railway variables set USE_DB_WORKER_REPLICAS=false
railway variables set SKIP_NATIVE_MYSQL_RECONNECT=true

# Generate secret keys (run locally and paste the values)
# rails secret
railway variables set SECRET_KEY_BASE=your_generated_secret
railway variables set DEVISE_SECRET_KEY=your_generated_devise_secret

# Memcached and Elasticsearch
railway variables set MEMCACHE_SERVERS=memcached:11211
railway variables set ELASTICSEARCH_HOST=http://elasticsearch:9200

# Application metadata
railway variables set REVISION='${{RAILWAY_GIT_COMMIT_SHA}}'
railway variables set DOMAIN=your-app.up.railway.app
railway variables set PROTOCOL=https
```

#### External services

Configure external services as needed:

```bash
# AWS S3 (for file storage)
railway variables set AWS_ACCESS_KEY_ID=your_key
railway variables set AWS_SECRET_ACCESS_KEY=your_secret
railway variables set AWS_DEFAULT_REGION=us-east-1

# Stripe (for payments)
railway variables set STRIPE_API_KEY=your_stripe_secret_key
railway variables set STRIPE_PUBLIC_KEY_PROD=your_stripe_public_key

# Email service
railway variables set RESEND_DEFAULT_API_KEY=your_resend_key

# Elasticsearch
railway variables set ELASTICSEARCH_HOST=your_elasticsearch_url
```

### Step 4: Deploy the application

#### Configure the build and start commands

In the Railway dashboard, click on your service and go to "Settings":

**Build Command:**
```bash
bundle install && npm install && bundle exec rails assets:precompile
```

**Start Command:**
```bash
bundle exec puma -C config/puma.rb
```

#### Add Sidekiq worker service

1. In your project, click "New" → "GitHub Repo"
2. Select the same repository
3. In the service settings, set:
   - **Start Command:** `bundle exec sidekiq -q critical -q default -q low -q mongo`
4. Name this service "worker"

#### Build configuration (Dockerfile vs Nixpacks)

**Recommended: Use Dockerfile (default)**

Gumroad includes a Dockerfile that handles all the required build steps automatically. Railway will detect and use it.

**Alternative: Nixpacks**

If you prefer Nixpacks, create a `nixpacks.toml` file, but note that you'll need to add custom build commands:

```toml
[phases.setup]
nixPkgs = [
    "nodejs-20_x",
    "ruby_3_4",
    "imagemagick",
    "ffmpeg",
    "vips",
    "wkhtmltopdf"
]

[phases.install]
cmds = [
    "bundle install",
    "npm install"
]

[phases.build]
cmds = [
    "bundle exec rails js:export",
    "node lib/findIcons.js",
    "bundle exec rails assets:precompile"
]

[start]
cmd = "bundle exec puma -C config/puma.rb"
```

> **Note:** Nixpacks requires all environment variables to be set. The Dockerfile approach is simpler because it uses dummy values during build.

#### Deploy

**Via GitHub (automatic):**
- Push to your connected branch, and Railway auto-deploys

**Via CLI:**
```bash
railway up
```

#### Run database migrations

After the first deployment:

```bash
railway run rails db:migrate
railway run rails db:seed
```

### Step 5: Post-deployment setup

#### Reindex Elasticsearch

```bash
railway run rails console
```

In the console:

```ruby
DevTools.delete_all_indices_and_reindex_all
```

#### Verify the deployment

1. Go to the Railway dashboard
2. Click on your web service
3. Click "Settings" → "Networking" → "Generate Domain"
4. Visit the generated URL

---

## Using railway.json configuration

For reproducible deployments, create a `railway.json` file in your project root:

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile"
  },
  "deploy": {
    "startCommand": "bundle exec puma -C config/puma.rb",
    "healthcheckPath": "/healthcheck",
    "healthcheckTimeout": 300,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

> **Important:** Gumroad uses a custom Dockerfile that generates required files (routes, icons) before asset precompilation. The Dockerfile builder is recommended over Nixpacks.

---

## Scaling

Railway uses a usage-based pricing model. Scale by adjusting resources:

### Vertical scaling

In the service settings, adjust:
- **Memory:** Increase from 512MB to 8GB as needed
- **vCPU:** Increase compute resources

### Horizontal scaling (multiple instances)

Railway supports horizontal scaling via replicas:

1. Go to your service settings
2. Under "Deploy" → "Replicas", increase the count

### Worker scaling

For the Sidekiq worker:
- Create additional worker services for different queue priorities
- Or scale the existing worker service horizontally

---

## Troubleshooting

### Common issues

#### Build fails with "KeyError: key not found"

This means a required environment variable is missing during the build. The Dockerfile uses dummy values for build-time, but if you see this error, check that the Dockerfile includes all required variables:

- `SECRET_KEY_BASE`
- `DEVISE_SECRET_KEY`
- `DATABASE_*` variables
- `REDIS_HOST`, `SIDEKIQ_REDIS_HOST`, `RPUSH_REDIS_HOST`, `RACK_ATTACK_REDIS_HOST`
- `MONGO_DATABASE_URL`, `MONGO_DATABASE_NAME`, `MONGO_DATABASE_USERNAME`, `MONGO_DATABASE_PASSWORD`
- `MEMCACHE_SERVERS`
- `ELASTICSEARCH_HOST`
- `REVISION`

#### Build fails with "Module not found: $app/utils/routes"

The JS routes file needs to be generated before webpack compilation. Ensure your Dockerfile runs:

```dockerfile
RUN RAILS_ENV=production ... bundle exec rails js:export
```

#### Build fails with "Can't find stylesheet icon_names"

The icon names SCSS file needs to be generated. Ensure your Dockerfile runs:

```dockerfile
RUN node lib/findIcons.js
```

#### Build fails with "Cannot find name 'IconName'"

Same as above - run `node lib/findIcons.js` in the Dockerfile.

#### MongoDB connection error with "Host should not contain protocol"

The `MONGO_DATABASE_URL` should be in `host:port` format, NOT a full MongoDB URI:

```bash
# WRONG
MONGO_DATABASE_URL=mongodb://localhost:27017/gumroad

# CORRECT
MONGO_DATABASE_URL=localhost:27017
```

#### Healthcheck failure

1. Ensure the healthcheck path is set to `/healthcheck` (not `/up`)
2. Verify all required services (MySQL, Redis, MongoDB) are running
3. Check that all environment variables are configured correctly
4. View logs to see the actual error:

```bash
railway logs
```

#### Build fails with missing system dependencies

If using Nixpacks instead of Dockerfile, update your `nixpacks.toml`:

```toml
[phases.setup]
nixPkgs = ["nodejs-20_x", "ruby_3_4", "imagemagick", "ffmpeg", "vips"]
aptPkgs = ["pdftk"]
```

#### Database connection errors

1. Verify the database service is running
2. Check that variable references are correct:

```bash
railway variables
```

3. Test the connection:

```bash
railway run bundle exec rails db:version
```

#### Asset compilation failures

Clear the cache and redeploy:

```bash
railway run rm -rf public/assets tmp/cache
railway up --force
```

#### Sidekiq not processing jobs

1. Verify the worker service is running in the dashboard
2. Check worker logs:

```bash
railway logs --service worker
```

3. Ensure Redis is connected:

```bash
railway run bundle exec rails console
# In console:
Sidekiq.redis { |c| c.ping }
```

### Viewing logs

**Via Dashboard:**
- Click on any service to view real-time logs

**Via CLI:**
```bash
# Web service logs
railway logs

# Worker service logs
railway logs --service worker

# All services
railway logs --all
```

### Running one-off commands

```bash
# Rails console
railway run rails console

# Rake tasks
railway run rails some:task

# Shell access
railway shell
```

---

## Cost estimation

Railway uses usage-based pricing. Here's an approximate monthly cost:

| Resource | Usage | Monthly cost |
|----------|-------|--------------|
| Web service | 1 GB RAM, always-on | ~$15-25 |
| Worker service | 1 GB RAM, always-on | ~$15-25 |
| MySQL | 1 GB storage | ~$7 |
| Redis | 256 MB | ~$5 |
| MongoDB | 1 GB storage | ~$7 |
| Egress | 10 GB | Included |
| **Total** | | **~$50-75/month** |

Railway offers a free tier with $5 credit/month, suitable for development and testing.

For production workloads, costs scale with usage. Monitor your usage in the Railway dashboard.

---

## Next steps

After successful deployment:

1. **Custom domain:** Settings → Networking → Custom Domain
2. **SSL:** Automatically provided for Railway domains and custom domains
3. **Monitoring:** Use Railway's built-in metrics or integrate with external tools
4. **CI/CD:** Railway automatically deploys on push to connected branch
5. **Backups:** Configure database backups in service settings

For more information, see the [Railway Documentation](https://docs.railway.app/).

---

## Comparison: Railway vs Heroku

| Feature | Railway | Heroku |
|---------|---------|--------|
| Pricing | Usage-based | Dyno-based |
| Free tier | $5 credit/month | Limited hours |
| MySQL | Native support | Via add-on |
| Auto-deploy | Yes | Yes |
| CLI | Yes | Yes |
| Logs | Real-time | Real-time |
| Scaling | Vertical + Horizontal | Dyno-based |
| Complexity | Lower | Medium |

Railway is often more cost-effective for smaller deployments, while Heroku offers more mature enterprise features.

---

## Dockerfile reference

Gumroad includes a Dockerfile optimized for Railway deployment. Here's what it does:

```dockerfile
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

# Generate JS routes file (required for webpack)
# These are build-time only values - real values are set at runtime via Railway
RUN RAILS_ENV=production \
    SECRET_KEY_BASE=dummy_secret_key_base_for_build \
    DEVISE_SECRET_KEY=dummy_devise_secret_for_build \
    DATABASE_NAME=gumroad \
    DATABASE_HOST=localhost \
    DATABASE_PORT=3306 \
    DATABASE_USERNAME=root \
    DATABASE_PASSWORD=password \
    REDIS_HOST=localhost:6379 \
    SIDEKIQ_REDIS_HOST=localhost:6379 \
    RPUSH_REDIS_HOST=localhost:6379 \
    RACK_ATTACK_REDIS_HOST=localhost:6379 \
    MONGO_DATABASE_URL=localhost:27017 \
    MONGO_DATABASE_NAME=gumroad \
    MONGO_DATABASE_USERNAME=mongo \
    MONGO_DATABASE_PASSWORD=password \
    MEMCACHE_SERVERS=localhost:11211 \
    ELASTICSEARCH_HOST=http://localhost:9200 \
    REVISION=build \
    bundle exec rails js:export

# Generate icon names for SCSS and TypeScript
RUN node lib/findIcons.js

# Precompile assets
RUN RAILS_ENV=production \
    SECRET_KEY_BASE=dummy_secret_key_base_for_build \
    DEVISE_SECRET_KEY=dummy_devise_secret_for_build \
    DATABASE_NAME=gumroad \
    DATABASE_HOST=localhost \
    DATABASE_PORT=3306 \
    DATABASE_USERNAME=root \
    DATABASE_PASSWORD=password \
    REDIS_HOST=localhost:6379 \
    SIDEKIQ_REDIS_HOST=localhost:6379 \
    RPUSH_REDIS_HOST=localhost:6379 \
    RACK_ATTACK_REDIS_HOST=localhost:6379 \
    MONGO_DATABASE_URL=localhost:27017 \
    MONGO_DATABASE_NAME=gumroad \
    MONGO_DATABASE_USERNAME=mongo \
    MONGO_DATABASE_PASSWORD=password \
    MEMCACHE_SERVERS=localhost:11211 \
    ELASTICSEARCH_HOST=http://localhost:9200 \
    REVISION=build \
    bundle exec rails assets:precompile

# Expose port
EXPOSE 3000

# Start command
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

### Why these build steps are needed

1. **`rails js:export`** - Generates `routes.js` and `routes.d.ts` files that webpack needs during compilation
2. **`node lib/findIcons.js`** - Generates `_icon_names.scss` (for SCSS) and `icons.d.ts` (for TypeScript) from the icon assets
3. **Dummy environment variables** - Rails requires certain environment variables to be present during asset precompilation, even though they aren't actually used. Real values are configured in Railway and used at runtime.

### Important notes

- The dummy values in the Dockerfile are **only used during the Docker build process**
- Real credentials are set via Railway environment variables and used when the container runs
- The `MONGO_DATABASE_URL` must be in `host:port` format (not a full MongoDB URI)
