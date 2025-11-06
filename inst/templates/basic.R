# taskfile.R
# Define your project tasks here

library(taskr)

define_tasks(

  task("example",
    desc = "An example task",
    cmd = function() {
      message("Hello from taskr!")
      message("Edit taskfile.R to define your own tasks.")
    }
  )

)
