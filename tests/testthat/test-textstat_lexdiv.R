context("test textstat_lexdiv")

test_that("textstat_lexdiv computation is correct", {
    mydfm <- dfm(c(d1 = "b a b a b a b a",
                   d2 = "a a b b"))
    
    expect_equivalent(
        textstat_lexdiv(mydfm, "TTR"),
        data.frame(document = c('d1', 'd2'), TTR = c(0.25, 0.5),
                   stringsAsFactors = FALSE)
    )
})

test_that("textstat_lexdiv CTTR works correct", {
    mydfm <- dfm(c(d1 = "b a b a b a b a",
                   d2 = "a a b b"))
    
    expect_equivalent(
        textstat_lexdiv(mydfm, "CTTR")$CTTR,
        c(2/sqrt(2*8), 2/sqrt(2*4)),
        tolerance = 0.01 
    )
})

test_that("textstat_lexdiv R works correct", {
    mydfm <- dfm(c(d1 = "b a b a b a b a",
                   d2 = "a a b b"))
    
    expect_equivalent(
        textstat_lexdiv(mydfm, "R")$R,
        c(2/sqrt(8), 2/sqrt(4)),
        tolerance = 0.01 
    )
})

test_that("textstat_lexdiv C works correct", {
    mydfm <- dfm(c(d1 = "b a b a b a b a",
                   d2 = "a a b b"))
    
    expect_equivalent(
        textstat_lexdiv(mydfm, "C")$C,
        c(log10(2)/log10(8), log10(2)/log10(4)),
        tolerance = 0.01 
    )
})

test_that("textstat_lexdiv Maas works correct", {
    mydfm <- dfm(c(d1 = "b a b a b a b a",
                   d2 = "a a b b"))
    
    expect_equivalent(
        textstat_lexdiv(mydfm, "Maas")$Maas[1],
        sqrt((log10(8) - log10(2))/log10(8)^2),
        tolerance = 0.01 
    )
})

test_that("textstat_lexdiv works with a single document dfm (#706)", {
    mytxt <- "one one two one one two one"
    mydfm <- dfm(mytxt)
    expect_equivalent(
        textstat_lexdiv(mydfm, c("TTR", "C")),
        data.frame(document = "text1", TTR = 0.286, C = 0.356, 
                   stringsAsFactors = FALSE),
        tolerance = 0.01
    )
})

test_that("raises error when dfm is empty (#1419)", {
    
    mx <- dfm_trim(data_dfm_lbgexample, 1000)
    expect_error(textstat_lexdiv(mx, c("TTR", "C")),
                 quanteda:::message_error("dfm_empty"))
    
})


test_that("Yule's K and Herndon's Vm correction are (approximately) correct", {
    # read in Latin version of Ch 1 of the Gospel according to St. John
    # example from Table 1 of Miranda-Garcia, A, and J Calle-Martin. 2005.
    # “Yule's Characteristic K Revisited.” Language Resources and Evaluation
    # 39(4): 287–94.
    # text source: http://www.latinvulgate.com/verse.aspx?t=1&b=4&c=1
    data_corpus_stjohn <- read.csv("../data/corpora/stjohn_latin.csv", stringsAsFactors = FALSE) %>%
        corpus(text_field = "latin") %>%
        texts(groups = "chapter") %>%  # combine verses into a single document
        corpus(docvars = data.frame(chapter = 1:4))
    docnames(data_corpus_stjohn) <- paste0("chap", 1:4)    

    data_dfm_stjohn <- data_corpus_stjohn %>%
        tokens(remove_punct = TRUE) %>%
        tokens_tolower() %>%
        dfm()
    
    # work with chapter 1
    data_dfm_stjohnch1 <- dfm_subset(data_dfm_stjohn, chapter == 1)

    expect_equal(
        as.integer(ntoken(data_dfm_stjohnch1)), # 770
        755L,     # from Miranda-Garcia and Calle-Martin (2005, Table 1)
        tol = 15  # might differ b/c of different translations, spellings, or token-counting method
    )
    
    expect_equal(
        as.integer(ntype(data_dfm_stjohnch1)),  # 329
        331L,     # from Miranda-Garcia and Calle-Martin (2005, Table 1)
        tol = 2   # might be off because of different translations or token-counting method
    )
    
    expect_equivalent(
        textstat_lexdiv(data_dfm_stjohnch1, "K"),  # 129.0943
        # from Miranda-Garcia and Calle-Martin (2005, Table 3)
        data.frame(document = "chap1", K = 126.3366167, stringsAsFactors = FALSE), 
        tol = 3
    )
    
    # tests on multiple documents - this is Ch 1 and Chs 1-4 as per the first two rows of 
    # Table 3 of Miranda-Garcia and Calle-Martin (2005)
    data_dfm_stjohncomb <- rbind(data_dfm_stjohnch1, 
                                 dfm_group(data_dfm_stjohn, rep(1, 4)))
    docnames(data_dfm_stjohncomb)[2] <- "chaps1-4"
    expect_equivalent(
        textstat_lexdiv(data_dfm_stjohncomb, "K"),
        data.frame(document = c("chap1", "chaps1-4"), K = c(126.3366167, 99.43763148), stringsAsFactors = FALSE),
        tol = 3
    )

    # try also Herdan's Vm and Simpson's D - these are VERY WEAK tests
    expect_true(
        all(textstat_lexdiv(data_dfm_stjohncomb, "D")[1, "D", drop = TRUE] > 0)
    )
    expect_true(
        all(textstat_lexdiv(data_dfm_stjohncomb, "Vm")[1, "Vm", drop = TRUE] > 0)
    )
    
    # test equality as per Tweedie and Baayen (1998, Eq. 19)
    # this needs checking - the tol value is a fudge
    result <- textstat_lexdiv(data_dfm_stjohncomb, c("K", "Vm"))
    K <- result[["K"]]
    Vm <- result[["Vm"]]
    expect_equal(
        Vm^2,
        as.numeric(K / 10^4 + (1 / ntoken(data_dfm_stjohncomb) - 1 / ntype(data_dfm_stjohncomb))),
        tol = .0013
    )
})

test_that("textstat_lexdiv works similarly for corpus and tokens", {
    txt <- c(d1 = "b a b a b a b a",
             d2 = "a a b b")
    mydfm <- dfm(txt)
    mytokens <- tokens(txt)
    expect_identical(
        textstat_lexdiv(mydfm, "all"),
        textstat_lexdiv(mytokens, "all")
    )
})

test_that("textstat_lexdiv supports removal of punctuation, numbers and symbols", {
    txt <- c(d1 = "a a  b b  c c",
             d2 = "a a , b b . c c / & ^ *** ### 1 2 3 4")
    mydfm <- dfm(txt)
    mytokens <- tokens(txt)
    expect_identical(
        textstat_lexdiv(mydfm["d1", ], "all")[, -1], 
        textstat_lexdiv(mydfm["d2", ], "all")[, -1]
    )
    expect_identical(
        textstat_lexdiv(mytokens["d1", ], "all")[,-1], 
        textstat_lexdiv(mytokens["d2", ], "all")[,-1]
    )
})

test_that("textstat_lexdiv supports removal of hyphenation", {
    y <- dfm(c(d1 = "apple-pear orange-fruit elephant-ferrari",
               d2 = "alpha-beta charlie-delta echo-foxtrot"))
    z <- dfm(c(d1 = "apple pear orange fruit elephant ferrari",
               d2 ="alpha beta charlie delta echo foxtrot" ))
    expect_identical(
        textstat_lexdiv(y, measure = "all", remove_hyphens = TRUE), 
        textstat_lexdiv(z, measure = "all", remove_hyphens = TRUE)
    )
})

test_that("textstat_lexdiv can handle hyphenated words containing duplicated tokens ", {
    dfm_nested <- corpus(c(d1 = "have we not-we-have bicycle ! % 123 ^ ")) %>% dfm()
    # not-we-have should be separated into three tokens, with hyphens being removed
    # remaining punctuation, symbols and numbers should also be removed
    # dfm_nested should only have 4 types with 6 tokens
    dfm_non_nested <- corpus(c(d1 = "a b b c c d")) %>% dfm()
    expect_identical(textstat_lexdiv(dfm_nested, measure = "all", remove_hyphens = TRUE), 
                     textstat_lexdiv(dfm_non_nested))
})

test_that("textstat_lexdiv.dfm and .tokens work same with remove_* options", {
    txt <- c("There's shrimp-kabobs,
              shrimp creole, shrimp gumbo. Pan fried, deep fried, stir-fried. There's
              pineapple shrimp, lemon shrimp, coconut shrimp, pepper shrimp, shrimp soup,
              shrimp stew, shrimp salad, shrimp and potatoes, shrimp burger, shrimp
              sandwich.",
             "A shrimp-kabob costs $0.50, shrimp costs $0.25.")
    expect_identical(
        textstat_lexdiv(tokens(txt), measure = "TTR", remove_hyphens = TRUE),
        textstat_lexdiv(dfm(txt), measure = "TTR", remove_hyphens = TRUE)
    )
    expect_identical(
        textstat_lexdiv(tokens(txt), measure = "TTR", 
                        remove_punct = TRUE, remove_hyphens = TRUE),
        textstat_lexdiv(dfm(txt), measure = "TTR", 
                        remove_punct = TRUE, remove_hyphens = TRUE)
    )
    expect_identical(
        textstat_lexdiv(tokens(txt), measure = "TTR", remove_punct = TRUE),
        textstat_lexdiv(dfm(txt), measure = "TTR", remove_punct = TRUE)
    )
    expect_identical(
        textstat_lexdiv(tokens(txt[2]), measure = "TTR", remove_symbols = TRUE),
        textstat_lexdiv(dfm(txt[2]), measure = "TTR", remove_symbols = TRUE)
    )
    expect_true(
        textstat_lexdiv(dfm(txt[2]), measure = "TTR", remove_symbols = TRUE)[1, "TTR"] !=
        textstat_lexdiv(dfm(txt[2]), measure = "TTR", remove_symbols = FALSE)[1, "TTR"]
    )
    expect_identical(
        textstat_lexdiv(tokens(txt), measure = "TTR", remove_numbers = TRUE),
        textstat_lexdiv(dfm(txt), measure = "TTR", remove_numbers = TRUE)
    )
})
