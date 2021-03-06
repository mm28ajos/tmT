context("read WORDPRESS files")

test_that("readWORDPRESS", {
  WP2 <- readWORDPRESS(path=paste0(getwd(),"/data/Wordpress"))
  text2 <- readWORDPRESS(path=paste0(getwd(),"/data/Wordpress"), do.meta = FALSE, do.text = TRUE)
  meta2 <- readWORDPRESS(path=paste0(getwd(),"/data/Wordpress"), do.meta = TRUE, do.text = FALSE)

  ## WP <- WP2
  ## text <- text2
  ## meta <- meta2
  ## save(WP, text, meta, file="data/WP_Compare.RData")

  load("data/WP_Compare.RData")
  expect_equal(WP2, WP)
  expect_equal(text2, text)
  expect_equal(meta2, meta)
})



