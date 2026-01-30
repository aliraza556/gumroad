# Deploying Gumroad to Railway

This guide provides step-by-step instructions for deploying Gumroad to [Railway](https://railway.app/). Railway offers a modern deployment experience with built-in support for databases and services, making it an excellent choice for deploying full-stack Rails applications.

## Table of contents

- [Prerequisites](#prerequisites)
- [Video walkthrough](#video-walkthrough)
- [Quick start](#quick-start)
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
- The Gumroad repository cloned locally

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

<!-- TODO: Add video demonstration -->
> A video walkthrough of this deployment process is coming soon.

## Quick start

Railway supports deployment via the web dashboard or CLI. Here's the CLI quick start:

```bash
# Login to Railway
railway login

# Initialize a new project
railway init

# Add MySQL database
railway add --database mysql

# Add Redis
railway add --database redis

# Link to your project
railway link

# Set environment variables
railway variables set RAILS_ENV=production
railway variables set RACK_ENV=production
railway variables set RAILS_LOG_TO_STDOUT=enabled
railway variables set RAILS_SERVE_STATIC_FILES=enabled

# Deploy
railway up
```

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

# MongoDB configuration
railway variables set MONGO_DATABASE_URL='${{MongoDB.MONGO_URL}}'
railway variables set MONGO_DATABASE_NAME=gumroad_production
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

#### Configure Nixpacks (Railway's buildpack)

Create a `nixpacks.toml` file in your project root:

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
    "bundle exec rails assets:precompile"
]

[start]
cmd = "bundle exec puma -C config/puma.rb"
```

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

For reproducible deployments, create a `railway.json` file:

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS",
    "buildCommand": "bundle install && npm install && bundle exec rails assets:precompile"
  },
  "deploy": {
    "startCommand": "bundle exec puma -C config/puma.rb",
    "healthcheckPath": "/up",
    "healthcheckTimeout": 300,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

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

#### Build fails with missing system dependencies

Update your `nixpacks.toml` to include required packages:

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
railway run rails db:version
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
railway run rails console
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
