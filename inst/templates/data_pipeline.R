# taskfile.R
# Data Pipeline Tasks

library(taskr)

define_tasks(

  task("data:extract",
    desc = "Extract data from source",
    sources = c("scripts/extract.R", "config/db.yml"),
    cmd = function() {
      message("Extracting data...")
      source("scripts/extract.R")
    }
  ),

  task("data:transform",
    desc = "Transform extracted data",
    deps = "data:extract",
    sources = c("scripts/transform.R", "data/raw/*.csv"),
    cmd = function() {
      message("Transforming data...")
      source("scripts/transform.R")
    }
  ),

  task("data:load",
    desc = "Load transformed data to target",
    deps = "data:transform",
    sources = c("scripts/load.R", "data/processed/*.csv"),
    cmd = function() {
      message("Loading data...")
      source("scripts/load.R")
    }
  ),

  task("data:validate",
    desc = "Validate data quality",
    deps = "data:load",
    cmd = function() {
      message("Validating data...")
      source("scripts/validate.R")
    }
  ),

  task("pipeline",
    desc = "Run full ETL pipeline",
    deps = c("data:extract", "data:transform", "data:load", "data:validate"),
    cmd = function() {
      message("Pipeline complete!")
    }
  ),

  task("report",
    desc = "Generate data quality report",
    deps = "data:validate",
    cmd = function() {
      rmarkdown::render("reports/data_quality.Rmd")
    }
  )

)
