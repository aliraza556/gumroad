# Deploying Gumroad to Heroku

This guide provides step-by-step instructions for deploying Gumroad to Heroku. The deployment has been tested and follows Gumroad's current stack (MySQL, Redis, Sidekiq, Elasticsearch).

## Table of contents

- [Prerequisites](#prerequisites)
- [Video walkthrough](#video-walkthrough)
- [Quick start](#quick-start)
- [Detailed setup](#detailed-setup)
  - [Step 1: Create Heroku app](#step-1-create-heroku-app)
  - [Step 2: Configure buildpacks](#step-2-configure-buildpacks)
  - [Step 3: Provision add-ons](#step-3-provision-add-ons)
  - [Step 4: Configure environment variables](#step-4-configure-environment-variables)
  - [Step 5: Deploy the application](#step-5-deploy-the-application)
  - [Step 6: Post-deployment setup](#step-6-post-deployment-setup)
- [Scaling](#scaling)
- [Troubleshooting](#troubleshooting)
- [Cost estimation](#cost-estimation)

---

## Prerequisites

Before you begin, ensure you have:

- A [Heroku account](https://signup.heroku.com/) (credit card required for add-ons)
- [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli) installed
- [Git](https://git-scm.com/) installed
- The Gumroad repository cloned locally

## Video walkthrough

<!-- TODO: Add video demonstration -->
> A video walkthrough of this deployment process is coming soon.

## Quick start

For experienced users, here's a quick setup script:

```bash
# Login to Heroku
heroku login

# Create app
heroku create your-gumroad-app

# Set buildpacks
heroku buildpacks:add heroku/nodejs
heroku buildpacks:add heroku/ruby
heroku buildpacks:add https://github.com/heroku/heroku-buildpack-apt

# Add add-ons
heroku addons:create jawsdb:kitefin          # MySQL
heroku addons:create heroku-redis:mini       # Redis
heroku addons:create bonsai:sandbox-6        # Elasticsearch
heroku addons:create mongolab:sandbox        # MongoDB

# Set essential config
heroku config:set RAILS_ENV=production
heroku config:set RACK_ENV=production
heroku config:set RAILS_LOG_TO_STDOUT=enabled
heroku config:set RAILS_SERVE_STATIC_FILES=enabled

# Deploy
git push heroku main

# Run migrations and setup
heroku run rails db:migrate
heroku run rails db:seed
```

## Detailed setup

### Step 1: Create Heroku app

1. Login to Heroku CLI:

```bash
heroku login
```

2. Create a new Heroku application:

```bash
heroku create your-gumroad-app
```

Replace `your-gumroad-app` with your desired app name. This will also add a `heroku` git remote to your repository.

3. Verify the app was created:

```bash
heroku apps:info
```

### Step 2: Configure buildpacks

Gumroad requires multiple buildpacks for its dependencies:

```bash
# Node.js for frontend assets
heroku buildpacks:add heroku/nodejs

# Ruby for Rails application
heroku buildpacks:add heroku/ruby

# APT for system dependencies (ImageMagick, FFmpeg, etc.)
heroku buildpacks:add https://github.com/heroku/heroku-buildpack-apt
```

Create an `Aptfile` in the project root for system dependencies:

```bash
cat > Aptfile << 'EOF'
imagemagick
libvips-dev
ffmpeg
pdftk
wkhtmltopdf
EOF
```

Verify buildpack order (should be: apt → nodejs → ruby):

```bash
heroku buildpacks
```

### Step 3: Provision add-ons

#### MySQL Database (JawsDB)

Gumroad uses MySQL. Provision JawsDB:

```bash
# Development/testing (free tier)
heroku addons:create jawsdb:kitefin

# Production (paid tier with better performance)
heroku addons:create jawsdb:leopard
```

Parse the database URL and set individual variables:

```bash
# Get the JAWSDB_URL
heroku config:get JAWSDB_URL

# The URL format is: mysql://username:password@host:port/database
# Set individual environment variables
heroku config:set DATABASE_HOST=<host>
heroku config:set DATABASE_PORT=3306
heroku config:set DATABASE_NAME=<database>
heroku config:set DATABASE_USERNAME=<username>
heroku config:set DATABASE_PASSWORD=<password>
```

#### Redis

Redis is required for Sidekiq, caching, and AnyCable:

```bash
# Development/testing
heroku addons:create heroku-redis:mini

# Production
heroku addons:create heroku-redis:premium-0
```

Set Redis configuration:

```bash
REDIS_URL=$(heroku config:get REDIS_URL)
heroku config:set REDIS_HOST=$REDIS_URL
heroku config:set SIDEKIQ_REDIS_HOST=$REDIS_URL
heroku config:set RPUSH_REDIS_HOST=$REDIS_URL
heroku config:set RACK_ATTACK_REDIS_HOST=$REDIS_URL
```

#### Elasticsearch (Bonsai)

```bash
# Development/testing (free tier)
heroku addons:create bonsai:sandbox-6

# Production
heroku addons:create bonsai:standard-sm
```

Set Elasticsearch configuration:

```bash
BONSAI_URL=$(heroku config:get BONSAI_URL)
heroku config:set ELASTICSEARCH_HOST=$BONSAI_URL
```

#### MongoDB (MongoDB Atlas via ObjectRocket or mLab)

```bash
# Using MongoLab (now MongoDB Atlas on Heroku)
heroku addons:create mongolab:sandbox
```

Configure MongoDB:

```bash
MONGODB_URI=$(heroku config:get MONGODB_URI)
heroku config:set MONGO_DATABASE_URL=$MONGODB_URI
heroku config:set MONGO_DATABASE_NAME=gumroad_production
```

### Step 4: Configure environment variables

Set the required environment variables. Create a script or run these commands:

```bash
# Rails configuration
heroku config:set RAILS_ENV=production
heroku config:set RACK_ENV=production
heroku config:set RAILS_LOG_TO_STDOUT=enabled
heroku config:set RAILS_SERVE_STATIC_FILES=enabled
heroku config:set RAILS_MAX_THREADS=5
heroku config:set PUMA_WORKER_PROCESSES=2

# Generate and set secret key
heroku config:set SECRET_KEY_BASE=$(rails secret)

# Devise secret key
heroku config:set DEVISE_SECRET_KEY=$(rails secret)

# Skip replica configuration for single-instance setup
heroku config:set USE_DB_WORKER_REPLICAS=false
heroku config:set SKIP_NATIVE_MYSQL_RECONNECT=true
```

#### External services (configure as needed)

For a fully functional deployment, you'll need to configure additional services. See `.env.production.example` for the complete list.

Essential services:

```bash
# AWS S3 (for file storage)
heroku config:set AWS_ACCESS_KEY_ID=your_key
heroku config:set AWS_SECRET_ACCESS_KEY=your_secret
heroku config:set AWS_DEFAULT_REGION=us-east-1

# Stripe (for payments)
heroku config:set STRIPE_API_KEY=your_stripe_secret_key
heroku config:set STRIPE_PUBLIC_KEY_PROD=your_stripe_public_key

# Email service (Resend or SendGrid)
heroku config:set RESEND_DEFAULT_API_KEY=your_resend_key
```

### Step 5: Deploy the application

1. Ensure your code is committed:

```bash
git add .
git commit -m "Prepare for Heroku deployment"
```

2. Deploy to Heroku:

```bash
git push heroku main
```

If your default branch is `master`:

```bash
git push heroku master
```

3. The deployment will:
   - Install Node.js dependencies
   - Install Ruby gems
   - Precompile assets
   - Run database migrations (via the `release` phase in `Procfile`)

4. Monitor the deployment:

```bash
heroku logs --tail
```

### Step 6: Post-deployment setup

#### Start the worker dyno

```bash
heroku ps:scale worker=1
```

#### Seed the database (if needed)

```bash
heroku run rails db:seed
```

#### Reindex Elasticsearch

```bash
heroku run rails console
```

In the console:

```ruby
DevTools.delete_all_indices_and_reindex_all
```

#### Verify the deployment

```bash
# Check app status
heroku ps

# Open the app
heroku open
```

---

## Scaling

### Web dynos

```bash
# Scale web dynos
heroku ps:scale web=2

# Use performance dynos for production
heroku ps:type web=standard-2x
```

### Worker dynos

```bash
# Scale worker dynos
heroku ps:scale worker=2

# Use performance dynos for heavy background processing
heroku ps:type worker=standard-2x
```

### Auto-scaling

Consider using Heroku's autoscaling features or add-ons like [HireFire](https://www.hirefire.io/) for automatic scaling based on queue depth.

---

## Troubleshooting

### Common issues

#### Asset compilation fails

```bash
# Clear the build cache
heroku builds:cache:purge

# Redeploy
git push heroku main
```

#### Database connection errors

Verify your database credentials:

```bash
heroku config | grep DATABASE
heroku run rails db:version
```

#### Memory issues (R14 errors)

Increase dyno size or optimize:

```bash
heroku ps:type web=standard-2x
```

Or reduce Puma workers:

```bash
heroku config:set PUMA_WORKER_PROCESSES=1
```

#### Sidekiq jobs not processing

Ensure the worker dyno is running:

```bash
heroku ps
heroku ps:scale worker=1
```

Check Sidekiq logs:

```bash
heroku logs --tail --dyno worker
```

### Viewing logs

```bash
# All logs
heroku logs --tail

# Web dyno logs only
heroku logs --tail --dyno web

# Worker dyno logs only
heroku logs --tail --dyno worker
```

### Running one-off commands

```bash
# Rails console
heroku run rails console

# Rake tasks
heroku run rails rake_task_name

# Bash shell
heroku run bash
```

---

## Cost estimation

Here's an approximate monthly cost breakdown for a production Heroku deployment:

| Resource | Plan | Monthly cost |
|----------|------|--------------|
| Web dyno | Standard-2X (x2) | $100 |
| Worker dyno | Standard-2X (x1) | $50 |
| JawsDB MySQL | Leopard | $50 |
| Heroku Redis | Premium-0 | $15 |
| Bonsai Elasticsearch | Standard-SM | $50 |
| MongoDB Atlas | M10 | $60 |
| **Total** | | **~$325/month** |

For development/testing, you can use free or hobby tiers to significantly reduce costs.

---

## Next steps

After successful deployment:

1. Set up a custom domain: `heroku domains:add your-domain.com`
2. Enable SSL: `heroku certs:auto:enable`
3. Configure monitoring (New Relic, Scout, etc.)
4. Set up CI/CD with Heroku Pipelines
5. Configure backups for your databases

For more information, see the [Heroku Dev Center](https://devcenter.heroku.com/).
