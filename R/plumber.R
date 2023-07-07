#* @get /fundingrequired
fundingrequired <- function() {

  cmd <- cronR::cron_rscript("cache-fundingrequired.R")
  try(cronR::cron_add(command = cmd, frequency = "*/10 * * * *", id = "getdonationdata", ask = FALSE))
  # Every 10 minutes
  # If the cron job already exists, then this line gives an error message, but continues to the return value
  
  return(readRDS("fundingrequiredJSON.rds"))

}
