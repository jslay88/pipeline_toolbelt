# Pipeline Toolbelt
Alpine image packaged with commonly used cli tools for pipelines

You may use this image by pulling

    docker pull ghcr.io/jslay88/pipeline_toolbelt


## Available Tools
* `aws` - AWS CLI  (see `Dockerfile` for version)
* `mysql` - MySQL Client Tools
* `psql` - Postgres Client Tools (as well as the other `pg_*` tools)
* `generate_password` - Python script for generating complex 
passwords with options

Many others not listed (`bash`, `git`, `curl`, `wget`).
Explore the image to find more!

    compgen -c
