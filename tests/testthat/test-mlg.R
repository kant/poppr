context("Basic multilocus genotype tests")

data(Pinf, package = "poppr")
data(Aeut, package = "poppr")
data(partial_clone, package = "poppr")
data(nancycats, package = "adegenet")
amlg <- mlg.vector(Aeut)
pmlg <- mlg.vector(partial_clone)
nmlg <- mlg.vector(nancycats)
strata(Aeut) <- other(Aeut)$population_hierarchy[-1]
aclone <- as.genclone(Aeut)
atab   <- mlg.table(Aeut, plot = FALSE)
ptab   <- mlg.table(partial_clone, plot = FALSE)
ntab   <- mlg.table(nancycats, plot = FALSE)
sim    <- adegenet::glSim(10, 1e2, ploidy = 2, parallel = FALSE)
lu <- function(x) length(unique(x))


test_that("multilocus genotype vector is same length as samples", {
  expect_equal(length(amlg), nInd(Aeut))
  expect_equal(length(pmlg), nInd(partial_clone))
  expect_equal(length(nmlg), nInd(nancycats))
  expect_equal(lu(amlg), mlg(Aeut, quiet = TRUE))
  expect_equal(lu(pmlg), mlg(partial_clone, quiet = TRUE))
  expect_equal(lu(nmlg), mlg(nancycats, quiet = TRUE))
})


test_that("subsetting and resetting MLGs works", {
  pmlg    <- mlg.vector(Pinf)
  pres    <- mlg.vector(Pinf, reset = TRUE)
  fullmlg <- mlg(Pinf[loc = locNames(Pinf)[-c(1:5)]], quiet = TRUE)
  realmlg <- mlg(Pinf[loc = locNames(Pinf)[-c(1:5)], mlg.reset = TRUE], quiet = TRUE)
  expect_equal(pmlg, Pinf@mlg[])
  expect_false(identical(pmlg, pres))
  expect_equal(Pinf[mlg.reset = TRUE]@mlg[], pres)
  expect_gt(fullmlg, realmlg)
  mll(Pinf) <- "original"
  expect_equal(mll(mll.reset(Pinf, TRUE)), pres)
  mll.custom(Pinf) <- paste("MLL", mll(Pinf))
  cmll  <- as.numeric(as.character(mll(mll.reset(Pinf, "custom"))))
  comll <- as.numeric(as.character(mll(mll.reset(Pinf, c("custom", "original")))))
  expect_equal(cmll, pmlg)
  expect_equal(comll, pres)
})


context("Basic clone correction tests")

test_that("clone correction works for specified levels and throws errors", {
  skip_on_cran()
  strata(aclone) <- other(aclone)[[1]][-1]
  ac <- aclone
  indNames(ac) <- rep("", nInd(ac))
  expect_equal(nmll(aclone), 119L)
  expect_equal(nInd(clonecorrect(aclone, ~Pop)), 120L)
  expect_equal(nInd(clonecorrect(ac, ~Pop)), 120L) # no sample names
  expect_equal(nInd(clonecorrect(aclone, 1L)), 120L) # works with numeric input
  expect_equal(nInd(clonecorrect(aclone, ~Pop/Subpop)), 141L) # with formula
  expect_equal(nInd(clonecorrect(aclone, NA)), 119L) # with nothing
  
  # Errors for unexpected behavior.
  expect_error(clonecorrect(1), "1 is not")
  expect_error(clonecorrect(aclone, ~field/sample), "field, sample") 
  expect_error(clonecorrect(aclone, 1L:4L), "NA")
  strata(ac) <- NULL
  expect_warning(clonecorrect(ac), "Strata is not set for ac")
})

context("mlg.table tests")

test_that("multilocus genotype matrix matches mlg.vector and data", {
  expect_equal(nrow(atab), nPop(Aeut))
  expect_equal(nrow(ptab), nPop(partial_clone))
  expect_equal(nrow(ntab), nPop(nancycats))
  expect_equal(ncol(atab), mlg(Aeut, quiet = TRUE))
  expect_equal(ncol(ptab), mlg(partial_clone, quiet = TRUE))
  expect_equal(ncol(ntab), mlg(nancycats, quiet = TRUE))
  expect_equal(sum(atab), nInd(Aeut))
  expect_equal(sum(ptab), nInd(partial_clone))
  expect_equal(sum(ntab), nInd(nancycats))
})

test_that("multilocus genotype matrix works for custom mlgs", {
  pc <- as.genclone(partial_clone)
  mll.levels(pc) <- LETTERS
  expect_identical(LETTERS, colnames(mlg.table(pc, plot = FALSE)))
  mll(pc) <- "original"
  expect_identical(ptab, mlg.table(pc, plot = FALSE))
})

test_that("multilocus genotype matrix can utilize strata", {
  pcount <- mlg.table(Pinf, strata = ~Country, plot = FALSE)
  pcont  <- mlg.table(Pinf, strata = ~Continent, plot = FALSE)
  expect_equal(nrow(pcount), 4)
  expect_equal(nrow(pcont), 2)
})

test_that("mlg.table can take a subset of sublist and blacklist", {
  skip_on_cran()
  nomex <- mlg.table(Pinf, strata = ~Country, sublist = 1:4, blacklist = 3, plot = FALSE)
  expect_equal(nrow(nomex), 3)
  expect_true(!"Mexico" %in% rownames(nomex))
  expect_true(all(rownames(nomex) %in% popNames(setPop(Pinf, ~Country))))
})

test_that("the parameter bar is deprecated in mlg.table", {
  skip_on_cran()
  expect_warning(mlg.table(partial_clone, bar = FALSE))
})

context("mll and nmll function tests")

test_that("mll and nmll works for genind objects", {
  expect_warning(atest <- mll(Aeut, "original"))
  nAeut <- nmll(Aeut)
  expect_equal(atest, amlg)
  expect_equal(nAeut, lu(amlg))
})

test_that("mll and nmll works for genlight objects", {
  expect_warning(atest <- mll(sim, "original"))
  nAeut <- nmll(sim)
  expect_equal(atest, 1:10)
  expect_equal(nAeut, 10)
})

test_that("mll can convert a numeric mlg slot to MLG", {
  expect_is(Pinf@mlg, "integer")
  mll(Pinf) <- "original"
  expect_is(Pinf@mlg, "MLG")
})

context("MLG class printing")

test_that("MLG class can print expected", {
  mll(Pinf) <- "original"
  expect_output(show(Pinf@mlg), "86 original mlgs.")
  mll(Pinf) <- "custom"
  expect_output(show(Pinf@mlg), "86 custom mlgs.")
  mll(Pinf) <- "contracted"
  expect_output(show(Pinf@mlg), "86 contracted mlgs with a cutoff of 0 based on the function diss.dist")
  mll(Pinf) <- "original"
})

context("mlg.crosspop tests")

test_that("mlg.crosspop will work with subsetted genclone objects", {
  strata(Aeut) <- other(Aeut)$population_hierarchy
  agc          <- as.genclone(Aeut)
  Athena       <- popsub(agc, "Athena")

  setPop(Athena)  <- ~Subpop
  expected_output <- structure(list(MLG.13 = structure(c(1L, 1L), .Names = c("8", 
"9")), MLG.23 = structure(c(1L, 1L), .Names = c("4", "6")), MLG.24 = structure(c(1L, 
1L), .Names = c("9", "10")), MLG.32 = structure(c(1L, 1L), .Names = c("7", 
"9")), MLG.52 = structure(c(1L, 1L), .Names = c("5", "9")), MLG.63 = structure(c(1L, 
1L), .Names = c("1", "5"))), .Names = c("MLG.13", "MLG.23", "MLG.24", 
"MLG.32", "MLG.52", "MLG.63"))
  expected_mlgout <- c(13, 23, 24, 32, 52, 63)

  expect_equal(x <- mlg.crosspop(Athena, quiet = TRUE), expected_output)
  expect_equal(y <- mlg.crosspop(Athena, indexreturn = TRUE), expected_mlgout)
  expect_warning(z <- mlg.crosspop(Athena, mlgsub = c(14, 2:5), quiet = TRUE), "The following multilocus genotypes are not defined in this dataset: 2, 3, 4, 5")
})

test_that("mlg.crosspop can take sublist and blacklist", {
  skip_on_cran()
  strata(Aeut) <- other(Aeut)$population_hierarchy
  agc          <- as.genclone(Aeut)
  Athena       <- popsub(agc, "Athena")
  
  setPop(Athena) <- ~Subpop
  expectation <- structure(list(MLG.13 = structure(c(1L, 1L), .Names = c("8", 
"9")), MLG.23 = structure(c(1L, 1L), .Names = c("4", "6")), MLG.24 = structure(c(1L, 
1L), .Names = c("9", "10")), MLG.32 = structure(c(1L, 1L), .Names = c("7", 
"9")), MLG.52 = structure(c(1L, 1L), .Names = c("5", "9"))), .Names = c("MLG.13", 
"MLG.23", "MLG.24", "MLG.32", "MLG.52"))
  
  expect_output(show(mlg.crosspop(Athena, blacklist = 1)), "MLG.13: \\(2 inds\\) 8 9")
  expect_output(show(mlg.crosspop(Athena, blacklist = "1")), "MLG.13: \\(2 inds\\) 8 9")
  expect_output(show(mlg.crosspop(Athena, sublist = 1:10, blacklist = "1")), "MLG.13: \\(2 inds\\) 8 9")
  expect_equivalent(mlg.crosspop(Athena, sublist = 1:10, blacklist = "1", quiet = TRUE), expectation)
})

test_that("mlg.crosspop can return a data frame", {
  skip_on_cran()
  df <- mlg.crosspop(aclone, df = TRUE, quiet = TRUE)
  expect_is(df, "data.frame")
  expect_equal(nrow(df), 2L)
  expect_equal(ncol(df), 3L)
})

test_that("mlg.crosspop works with custom mlgs", {
  skip_on_cran()
  pc <- as.genclone(partial_clone)
  mll.custom(pc) <- LETTERS[mll(pc)]
  ROSEBUD <- c("R", "O", "S", "E", "B", "U", "D")
  rosebud <- mlg.crosspop(pc, mlgsub = ROSEBUD, quiet = TRUE)
  expect_is(rosebud, "list")
  expect_equal(length(rosebud), nchar("rosebud"))
  expect_equal(mlg.crosspop(pc, mlgsub = ROSEBUD, indexreturn = TRUE), ROSEBUD)
})

test_that("mlg.crosspop will throw an error when no populations are present", {
  skip_on_cran()
  expect_error(n1 <- mlg.crosspop(Aeut[pop = 1]))
  expect_error(n2 <- mlg.crosspop(Aeut, sublist = 1))
})

test_that("mlg.crosspop will send a message and return NULL if no cross-population MLGs are detected", {
  skip_on_cran()
  expect_message(n <- mlg.crosspop(nancycats))
  expect_null(n)
})

test_that("mlg.crosspop will handle strata", {
  skip_on_cran()
  sp <- mlg.crosspop(aclone, strata = ~Subpop, quiet = TRUE)
  expect_equal(length(sp), 17L)
})


context("mlg.id tests")

test_that("mlg.id Aeut works", {
  expected_output <- structure(list(`1` = "055", `2` = c("101", "103"), `3` = "111", 
                                    `4` = "112", `5` = "110", `6` = "102", `7` = "020", `8` = "007", 
                                    `9` = "068", `10` = "069", `11` = "073", `12` = "075", `13` = c("072", 
                                                                                                    "080"), `14` = c("074", "076", "077"), `15` = "079", `16` = c("004", 
                                                                                                                                                                  "009"), `17` = c("003", "008"), `18` = "095", `19` = "094", 
                                    `20` = c("022", "023", "024", "025", "027", "028", "029", 
                                             "030", "031"), `21` = "060", `22` = "043", `23` = c("038", 
                                                                                                 "059"), `24` = c("084", "090"), `25` = "063", `26` = "005", 
                                    `27` = "071", `28` = "032", `29` = "078", `30` = "026", `31` = c("089", 
                                                                                                     "092"), `32` = c("065", "081"), `33` = "053", `34` = "051", 
                                    `35` = c("046", "048", "050"), `36` = c("045", "047"), `37` = "088", 
                                    `38` = "087", `39` = "056", `40` = "091", `41` = "082", `42` = "006", 
                                    `43` = "083", `44` = "013", `45` = "017", `46` = "085", `47` = "061", 
                                    `48` = "062", `49` = "066", `50` = "064", `51` = "015", `52` = c("052", 
                                                                                                     "086"), `53` = "002", `54` = "115", `55` = "151", `56` = "113", 
                                    `57` = "042", `58` = "109", `59` = c("057", "159"), `60` = c("067", 
                                                                                                 "070"), `61` = "058", `62` = "049", `63` = c("001", "054"
                                                                                                 ), `64` = "096", `65` = "040", `66` = c("033", "034", "036", 
                                                                                                                                         "039", "041"), `67` = "037", `68` = "035", `69` = c("145", 
                                                                                                                                                                                             "146", "148", "149"), `70` = c("124", "126", "127", "131", 
                                                                                                                                                                                                                            "133"), `71` = "156", `72` = c("152", "154"), `73` = "116", 
                                    `74` = c("139", "140", "141"), `75` = c("134", "135", "137", 
                                                                            "142", "147"), `76` = c("125", "162"), `77` = c("160", "168", 
                                                                                                                            "170"), `78` = c("169", "177"), `79` = "175", `80` = c("107", 
                                                                                                                                                                                   "108", "117", "120", "121", "122", "164", "167", "172", "183"
                                                                                                                            ), `81` = c("130", "182"), `82` = "099", `83` = "100", `84` = "114", 
                                    `85` = "157", `86` = "098", `87` = c("158", "171"), `88` = c("123", 
                                                                                                 "166"), `89` = "118", `90` = c("128", "163"), `91` = c("104", 
                                                                                                                                                        "173"), `92` = "132", `93` = "010", `94` = "011", `95` = "180", 
                                    `96` = c("138", "144"), `97` = c("181", "184", "185", "186"
                                    ), `98` = "143", `99` = c("136", "165"), `100` = "150", `101` = c("174", 
                                                                                                      "187"), `102` = "176", `103` = c("178", "179"), `104` = "129", 
                                    `105` = "153", `106` = "119", `107` = "161", `108` = "097", 
                                    `109` = "093", `110` = "018", `111` = "021", `112` = "012", 
                                    `113` = "016", `114` = "019", `115` = "155", `116` = "106", 
                                    `117` = "105", `118` = "014", `119` = "044"), .Names = c("1", 
                                                                                             "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", 
                                                                                             "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", 
                                                                                             "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", 
                                                                                             "36", "37", "38", "39", "40", "41", "42", "43", "44", "45", "46", 
                                                                                             "47", "48", "49", "50", "51", "52", "53", "54", "55", "56", "57", 
                                                                                             "58", "59", "60", "61", "62", "63", "64", "65", "66", "67", "68", 
                                                                                             "69", "70", "71", "72", "73", "74", "75", "76", "77", "78", "79", 
                                                                                             "80", "81", "82", "83", "84", "85", "86", "87", "88", "89", "90", 
                                                                                             "91", "92", "93", "94", "95", "96", "97", "98", "99", "100", 
                                                                                             "101", "102", "103", "104", "105", "106", "107", "108", "109", 
                                                                                             "110", "111", "112", "113", "114", "115", "116", "117", "118", 
                                                                                             "119"))
  x    <- mlg.id(Aeut)
  Avec <- mlg.vector(Aeut)
  expect_equal(lapply(x, as.integer), lapply(expected_output, as.integer))
  expect_equal(length(x), lu(Avec))
  expect_equivalent(sapply(x, length), as.vector(table(Avec)))
  expect_equal(names(x[1]), "1")
  })

test_that("mlg.id Pinf works", {
  expected_output <- structure(list(`1` = structure("PiEC06", .Names = "09"), `4` = structure("PiMX03", .Names = "19"), 
                                    `5` = structure("PiMX04", .Names = "20"), `6` = structure("PiMXT01", .Names = "56"), 
                                    `7` = structure("PiPE03", .Names = "67"), `8` = structure("PiPE01", .Names = "65"), 
                                    `10` = structure("PiPE07", .Names = "71"), `11` = structure("PiPE06", .Names = "70"), 
                                    `12` = structure(c("PiPE10", "PiPE26"), .Names = c("74", 
                                                                                       "85")), `13` = structure("PiMX01", .Names = "17"), `14` = structure("PiEC02", .Names = "07"), 
                                    `15` = structure("PiPE04", .Names = "68"), `17` = structure(c("PiCO01", 
                                                                                                  "PiCO03", "PiCO04"), .Names = c("01", "03", "04")), `19` = structure("PiEC03", .Names = "08"), 
                                    `21` = structure("PiMX42", .Names = "47"), `22` = structure("PiEC01", .Names = "06"), 
                                    `23` = structure("PiPE09", .Names = "73"), `24` = structure("PiCO02", .Names = "02"), 
                                    `25` = structure("PiPE05", .Names = "69"), `30` = structure("PiMX07", .Names = "23"), 
                                    `33` = structure("PiMX20", .Names = "34"), `34` = structure(c("PiMX48", 
                                                                                                  "PiMX49", "PiMX50"), .Names = c("53", "54", "55")), `35` = structure("PiPE13", .Names = "77"), 
                                    `36` = structure(c("PiPE11", "PiPE12", "PiPE14"), .Names = c("75", 
                                                                                                 "76", "78")), `37` = structure("PiMX06", .Names = "22"), 
                                    `38` = structure("PiMX02", .Names = "18"), `39` = structure("PiMX12", .Names = "26"), 
                                    `40` = structure("PiMXT06", .Names = "61"), `41` = structure("PiMX19", .Names = "33"), 
                                    `42` = structure("PiMX17", .Names = "31"), `45` = structure("PiMX13", .Names = "27"), 
                                    `46` = structure("PiMX24", .Names = "38"), `47` = structure(c("PiPE02", 
                                                                                                  "PiPE08"), .Names = c("66", "72")), `50` = structure("PiMX23", .Names = "37"), 
                                    `51` = structure("PiMX10", .Names = "24"), `52` = structure("PiMX29", .Names = "43"), 
                                    `53` = structure("PiMX05", .Names = "21"), `54` = structure("PiCO05", .Names = "05"), 
                                    `55` = structure("PiMXT07", .Names = "62"), `56` = structure("PiMX11", .Names = "25"), 
                                    `57` = structure("PiMX26", .Names = "40"), `58` = structure("PiMX22", .Names = "36"), 
                                    `59` = structure("PiMX14", .Names = "28"), `61` = structure("PiMX18", .Names = "32"), 
                                    `62` = structure("PiMX15", .Names = "29"), `63` = structure(c("PiPE22", 
                                                                                                  "PiPE24", "PiPE25"), .Names = c("81", "83", "84")), `68` = structure("PiPE23", .Names = "82"), 
                                    `69` = structure("PiEC10", .Names = "12"), `71` = structure("PiPE21", .Names = "80"), 
                                    `72` = structure("PiPE20", .Names = "79"), `74` = structure("PiEC12", .Names = "14"), 
                                    `75` = structure(c("PiEC13", "PiEC14"), .Names = c("15", 
                                                                                       "16")), `77` = structure("PiMX28", .Names = "42"), `79` = structure("PiEC11", .Names = "13"), 
                                    `80` = structure("PiMX16", .Names = "30"), `83` = structure("PiEC08", .Names = "11"), 
                                    `84` = structure("PiEC07", .Names = "10"), `93` = structure("PiMX30", .Names = "44"), 
                                    `94` = structure("PiMX41", .Names = "46"), `95` = structure("PiMX27", .Names = "41"), 
                                    `96` = structure("PiMX43", .Names = "48"), `97` = structure(c("PiMX44", 
                                                                                                  "PiMX45", "PiMX46", "PiMX47"), .Names = c("49", "50", "51", 
                                                                                                                                            "52")), `98` = structure("PiMX25", .Names = "39"), `99` = structure("PiMX40", .Names = "45"), 
                                    `104` = structure("PiMXT02", .Names = "57"), `105` = structure("PiMXT05", .Names = "60"), 
                                    `106` = structure("PiPE27", .Names = "86"), `109` = structure("PiMXT03", .Names = "58"), 
                                    `110` = structure("PiMX21", .Names = "35"), `115` = structure("PiMXT04", .Names = "59"), 
                                    `116` = structure("PiMXt48", .Names = "63"), `117` = structure("PiMXt68", .Names = "64")), .Names = c("1", 
                                                                                                                                          "4", "5", "6", "7", "8", "10", "11", "12", "13", "14", "15", 
                                                                                                                                          "17", "19", "21", "22", "23", "24", "25", "30", "33", "34", "35", 
                                                                                                                                          "36", "37", "38", "39", "40", "41", "42", "45", "46", "47", "50", 
                                                                                                                                          "51", "52", "53", "54", "55", "56", "57", "58", "59", "61", "62", 
                                                                                                                                          "63", "68", "69", "71", "72", "74", "75", "77", "79", "80", "83", 
                                                                                                                                          "84", "93", "94", "95", "96", "97", "98", "99", "104", "105", 
                                                                                                                                          "106", "109", "110", "115", "116", "117"))
  x    <- mlg.id(Pinf)
  Pvec <- mlg.vector(Pinf)
  expect_equal(x, expected_output)
  expect_equal(length(x), lu(Pvec))
  expect_equivalent(sapply(x, length), as.vector(table(Pvec)))
  expect_equal(names(x[1]), "1")
})

context("mll.reset tests")

test_that("mll.reset works with non-MLG class slots", {
  skip_on_cran()
  Pinf@mlg <- Pinf@mlg[]
  expect_is(Pinf@mlg, "integer")
  expect_error(mll.reset(Pinf), "please")
  Pinf <- mll.reset(Pinf, TRUE)
  expect_is(Pinf@mlg, "MLG")
})

test_that("mll.reset will reset filtered MLGs", {
  skip_on_cran()
  mlg.filter(Pinf, dist = dist) <- 3
  Pinf.res <- mll.reset(Pinf, "contracted")
  expect_lt(lu(mll(Pinf)), lu(mll(Pinf.res)))
  expect_equal(mll(Pinf, "original"), mll(Pinf.res, "contracted"))
})

test_that("mll.reset will reset subset genclone with no MLG class", {
  skip_on_cran()
  data(monpop)
  expect_equal(suppressWarnings(monpop %>% nmll()), 264L)
  expect_equal(suppressWarnings(monpop[loc = 1:2, mlg.reset = TRUE] %>% nmll()), 14L)
  expect_equal(suppressWarnings(monpop[loc = 1:2] %>% mll.reset(TRUE) %>% nmll()), 14L)
})

context("mlg.filter tests")

test_that("multilocus genotype filtering functions correctly", {
  skip_on_cran()
  # amlg  <- mlg.vector(Aeut)
  # pmlg  <- mlg.vector(partial_clone)
  # nmlg  <- mlg.vector(nancycats)
  adist <- diss.dist(Aeut)
  pdist <- diss.dist(partial_clone)
  ndist <- diss.dist(nancycats)
  afilt <- function(thresh = 0, d = adist) mlg.filter(Aeut, thresh, distance = d)
  pfilt <- function(thresh = 0, d = pdist) mlg.filter(partial_clone, thresh, distance = d)
  nfilt <- function(thresh = 0, d = ndist) mlg.filter(nancycats, thresh, distance = d)

 
  # No clustering should happen if the threshold is set to 0
  expect_equal(lu(amlg), lu(afilt(0)))
  expect_equal(lu(pmlg), lu(pfilt(0)))
  expect_equal(lu(nmlg), lu(nfilt(0)))

  # All clusters should be merged for an arbitrarily large threshold
  expect_equal(1, lu(afilt(1000L)))
  expect_equal(1, lu(pfilt(1000L)))
  expect_equal(1, lu(pfilt(1000L)))

  # The different methods of passing distance should produce the same results
  adis <- diss.dist(missingno(Aeut, "mean", quiet=TRUE))
  suppressWarnings({
    pdis <- diss.dist(missingno(partial_clone, "mean", quiet=TRUE))
    ndis <- diss.dist(missingno(nancycats, "mean", quiet=TRUE))
  
    expect_equal(mlg.filter(Aeut, 0.3, missing="mean", distance=adis), 
                 mlg.filter(Aeut, 0.3, missing="mean", distance=diss.dist))
    expect_equal(mlg.filter(Aeut, 0.3, missing="mean", distance=adis),  
                 mlg.filter(Aeut, 0.3, missing="mean", distance="diss.dist"))
    
    expect_equal(mlg.filter(nancycats, 0.3, missing="mean", distance=ndis), 
                 mlg.filter(nancycats, 0.3, missing="mean", distance=diss.dist))
    expect_equal(mlg.filter(nancycats, 0.3, missing="mean", distance=ndis), 
                 mlg.filter(nancycats, 0.3, missing="mean", distance="diss.dist"))
    
    expect_equal(mlg.filter(partial_clone, 0.3, missing="mean", distance=pdis), 
                 mlg.filter(partial_clone, 0.3, missing="mean", distance=diss.dist))
    expect_equal(mlg.filter(partial_clone, 0.3, missing="mean", distance=pdis), 
                 mlg.filter(partial_clone, 0.3, missing="mean", distance="diss.dist"))
  })
})

context("misc. mlg tests")

test_that("mlg functions require genind/genlight objects", {
  skip_on_cran()
  expect_error(mlg(1:10))
  expect_error(mlg.id(1:10))
  expect_error(mlg.table(1:10))
})

test_that("a value of 1 is returned for a single row genind object", {
  skip_on_cran()
  expect_output(pcres.gi <- mlg(partial_clone[1]), "###")
  expect_equal(pcres.gi, 1L)
})