cache.fundingrequired <- function() {
  
  env.txt <- readLines(".env")
  process.env.BTCPAY_API_KEY <- gsub("(BTCPAY_API_KEY=)|( )", "", env.txt[grepl("BTCPAY_API_KEY=", env.txt)])
  process.env.BTCPAY_URL <- gsub("(BTCPAY_URL=)|( )", "", env.txt[grepl("BTCPAY_URL=", env.txt)])
  process.env.BTCPAY_STORE_ID <- gsub("(BTCPAY_STORE_ID=)|( )", "", env.txt[grepl("BTCPAY_STORE_ID=", env.txt)])
  process.env.STRIPE_SECRET_KEY <- gsub("(STRIPE_SECRET_KEY=)|( )", "", env.txt[grepl("STRIPE_SECRET_KEY=", env.txt)])

  monerofund.website <- readLines("https://monerofund.org/")
  buildId <- regmatches(monerofund.website, regexpr("buildId\":\"[_0-9a-zA-Z]+", monerofund.website))
  buildId <- gsub("buildId\":\"", "", buildId)
  
  projects.json <- RJSONIO::fromJSON(paste0(
    "https://monerofund.org/_next/data/", buildId, "/projects.json"))$pageProps$projects

  needs.funding.index <- NULL

  for (i in seq_along(projects.json)) {
    if (!projects.json[[i]]$isFunded) {
      needs.funding.index <- c(needs.funding.index, i)
    }
  }

  ## TODO: DELETE BEFORE DEPLOYMENT
  needs.funding.index <- 1

  if (length(needs.funding.index) == 0) {
    return("")
  }

  USD.to.XMR <- RJSONIO::fromJSON("https://min-api.cryptocompare.com/data/pricemulti?fsyms=XMR&tsyms=USD")$XMR

  json.return <- list()

  for (project.index in needs.funding.index) {
    slug <- projects.json[[project.index]]$slug

    BTCPay.auth <- paste0("token ", process.env.BTCPAY_API_KEY)

    invoices.url <- paste0(process.env.BTCPAY_URL, "stores/", process.env.BTCPAY_STORE_ID, "/invoices")

    invoices <- RCurl::getForm(invoices.url,
      .opts = list(httpheader = c(
        "Content-Type" = "application/json",
        Authorization = BTCPay.auth
      ))
    )

    invoices <- RJSONIO::fromJSON(invoices, asText = TRUE)

    numdonationsxmr <- 0
    numdonationsbtc <- 0
    totaldonationsxmr <- 0
    totaldonationsbtc <- 0
    totaldonationsinfiatxmr <- 0
    totaldonationsinfiatbtc <- 0

    for (i in seq_along(invoices)) {
      if ((!is.list(invoices[[i]]$metadata)) || invoices[[i]]$metadata$orderId != slug) {
        next
      }
      id <- invoices[[i]]$id
      dataiter.url <- paste0(process.env.BTCPAY_URL, "stores/", process.env.BTCPAY_STORE_ID, "/invoices/", id, "/payment-methods")

      responseiter <- RCurl::getForm(dataiter.url,
        .opts = list(httpheader = c(
          "Content-Type" = "application/json",
          Authorization = BTCPay.auth
        ))
      )

      dataiter <- RJSONIO::fromJSON(responseiter, asText = TRUE)

      for (j in seq_along(dataiter)) {
        if (dataiter[[j]]$cryptoCode == "XMR" && as.numeric(dataiter[[j]]$paymentMethodPaid) > 0) {
          numdonationsxmr <- numdonationsxmr + 1
          totaldonationsxmr <- totaldonationsxmr + as.numeric(dataiter[[j]]$paymentMethodPaid)
          totaldonationsinfiatxmr <- totaldonationsinfiatxmr + as.numeric(dataiter[[j]]$paymentMethodPaid) * as.numeric(dataiter[[j]]$rate)
        }

        if (dataiter[[j]]$cryptoCode == "BTC" && as.numeric(dataiter[[j]]$paymentMethodPaid) > 0) {
          numdonationsbtc <- numdonationsbtc + 1
          totaldonationsbtc <- totaldonationsbtc + as.numeric(dataiter[[j]]$paymentMethodPaid)
          totaldonationsinfiatbtc <- totaldonationsinfiatbtc + as.numeric(dataiter[[j]]$paymentMethodPaid) * as.numeric(dataiter[[j]]$rate)
        }
      }
    }




    urlstripe <- "https://api.stripe.com/v1/charges"
    authstripe <- paste0("Bearer ", process.env.STRIPE_SECRET_KEY)

    responsestripe <- RCurl::getForm(urlstripe,
      .opts = list(httpheader = c(
        "Content-Type" = "application/json",
        Authorization = authstripe
      ))
    )

    responsestripe <- RJSONIO::fromJSON(responsestripe, asText = TRUE)$data

    numdonationsfiat <- 0
    totaldonationsinfiat <- 0
    for (i in seq_along(responsestripe)) {
      if ((!("project_slug" %in% names(responsestripe[[i]]$metadata))) ||
        responsestripe[[i]]$metadata[["project_slug"]] != slug) {
        next
      }

      numdonationsfiat <- numdonationsfiat + 1
      totaldonationsinfiat <- totaldonationsinfiat + responsestripe[[i]]$amount / 100
    }

    title <- projects.json[[project.index]]$title
    author <- projects.json[[project.index]]$nym
    url <- paste0("https://monerofund.org/projects/", slug)
    target_amount <- round(projects.json[[1]]$goal / USD.to.XMR) # Round to nearest whole XMR
    target_currency <- "XMR"

    raised_amount <- totaldonationsxmr + totaldonationsinfiatbtc / USD.to.XMR + totaldonationsinfiat / USD.to.XMR
    raised_amount <- round(raised_amount, digits = 2) # Round to hundredths of XMR

    contributions <- numdonationsxmr + numdonationsbtc + numdonationsfiat

    json.return[[length(json.return) + 1]] <- list(
      title = jsonlite::unbox(title),
      author = jsonlite::unbox(author),
      url = jsonlite::unbox(url),
      target_amount = jsonlite::unbox(target_amount),
      target_currency = jsonlite::unbox(target_currency),
      raised_amount = jsonlite::unbox(raised_amount),
      contributions = jsonlite::unbox(contributions)
    )
    # https://www.rplumber.io/articles/rendering-output.html#boxed-vs-unboxed-json
  }

  saveRDS(json.return, file = "fundingrequiredJSON.rds")
}


cache.fundingrequired()

