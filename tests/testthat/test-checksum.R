test_that("calculate_checksums() works for existing files", {

  # Create temp file
  temp_file <- tempfile()
  writeLines("test content", temp_file)

  checksums <- calculate_checksums(temp_file)

  expect_type(checksums, "character")
  expect_equal(length(checksums), 1)
  expect_true(nzchar(checksums[1]))

  # Clean up
  unlink(temp_file)
})


test_that("calculate_checksums() handles missing files", {

  expect_warning(
    checksums <- calculate_checksums("/nonexistent/file.txt"),
    "File not found"
  )

  expect_true(is.na(checksums[1]))
})


test_that("needs_run() returns TRUE for tasks without sources", {

  t <- task("test", cmd = function() 1)

  expect_true(needs_run(t))
})


test_that("needs_run() returns TRUE for tasks never run", {

  temp_file <- tempfile()
  writeLines("test", temp_file)

  t <- task("test",
    sources = temp_file,
    cmd = function() 1
  )

  expect_true(needs_run(t))

  # Clean up
  unlink(temp_file)
})


test_that("needs_run() returns FALSE if files unchanged", {

  temp_file <- tempfile()
  writeLines("test", temp_file)

  t <- task("test",
    sources = temp_file,
    cmd = function() 1
  )

  # Set checksums as if already run
  t$last_hash <- calculate_checksums(temp_file)

  expect_false(needs_run(t))

  # Clean up
  unlink(temp_file)
})


test_that("needs_run() returns TRUE if files changed", {

  temp_file <- tempfile()
  writeLines("test", temp_file)

  t <- task("test",
    sources = temp_file,
    cmd = function() 1
  )

  # Set checksums
  t$last_hash <- calculate_checksums(temp_file)

  # Modify file
  writeLines("modified", temp_file)

  expect_true(needs_run(t))

  # Clean up
  unlink(temp_file)
})


test_that("update_checksums() updates task state", {

  temp_file <- tempfile()
  writeLines("test", temp_file)

  t <- task("test",
    sources = temp_file,
    cmd = function() 1
  )

  t_updated <- update_checksums(t)

  expect_false(is.null(t_updated$last_hash))
  expect_false(is.null(t_updated$last_run))

  # Clean up
  unlink(temp_file)
})
