#!/usr/bin/env Rscript
args <- as.numeric(commandArgs(trailingOnly = TRUE))
message(paste0("Running with arguments: ",""))
message(args)
args1 <- args[1]
args2 <- args[2]

# Assign parallel jobs
iter_cvseed <- 1
iter_cvseed <- args1
test_run <- T
benchMark <- T
model_id <- "final"


# set paths and load libraries
setwd("/storage/groups/cbm01/workspace/alexander.ohnmacht/dream/antipd1")
dir.create(paste0(getwd(),"/models/",model_id))
logfile <- paste0(getwd(),"/models/",model_id,"/","logs.txt")
cat(paste0("Run name: ", model_id,"\n"), file = logfile, append = T)
cat(paste0("Small run: ", test_run,"\n"), file = logfile, append = T)
cat(paste0("Benchmark: ", benchMark,"\n"), file = logfile, append = T)
cat("\n", file = logfile, append = T)
add_library_path <- "~/R/x86_64-redhat-linux-gnu-library/3.6"


library(withr)
add_library_path <- "~/R/x86_64-redhat-linux-gnu-library/3.6"
with_libpaths(new = add_library_path, library(data.table, lib.loc = add_library_path))
with_libpaths(new = add_library_path, library(Rcpp, lib.loc = add_library_path))
with_libpaths(new = add_library_path, library(lgr, lib.loc = add_library_path))
with_libpaths(new = add_library_path, library(mlr3, lib.loc = add_library_path))
with_libpaths(new = add_library_path, library(mlr3proba, lib.loc = add_library_path))
with_libpaths(new = add_library_path, library(mlr3learners.randomforestsrc, lib.loc = add_library_path))
with_libpaths(new = add_library_path, library(mlr3learners, lib.loc = add_library_path))
with_libpaths(new = add_library_path, library(future, lib.loc = add_library_path))
with_libpaths(new = add_library_path, library(mlr3tuning, lib.loc = add_library_path))
with_libpaths(new = add_library_path, library(paradox, lib.loc = add_library_path))
with_libpaths(new = add_library_path, library(bbotk, lib.loc = add_library_path))
library(survival)
library(tidyverse)
with_libpaths(new = add_library_path, library(ggfortify, lib.loc = add_library_path))
with_libpaths(new = add_library_path, library(survminer, lib.loc = add_library_path))
with_libpaths(new = add_library_path, library(future.apply, lib.loc = add_library_path))
with_libpaths(new = add_library_path, library(mlr3misc, lib.loc = add_library_path))
with_libpaths(new = add_library_path, library(mlr3filters, lib.loc = add_library_path))
with_libpaths(new = add_library_path, library(mlr3fselect, lib.loc = add_library_path))
with_libpaths(new = add_library_path, library(mlr3pipelines, lib.loc = add_library_path))
with_libpaths(new = add_library_path, library(mlr3learners.pycox, lib.loc = add_library_path))
with_libpaths(new = add_library_path, library(visNetwork, lib.loc = add_library_path))
with_libpaths(new = add_library_path, library(mlr3measures, lib.loc = add_library_path))
with_libpaths(new = add_library_path, library(praznik, lib.loc = add_library_path))
with_libpaths(new = add_library_path, library(survAUC, lib.loc = add_library_path))
with_libpaths(new = add_library_path, library(xgboost, lib.loc = add_library_path))
###############################################

which <- "PFS"
load("metadata/features_symbols_v3_nanostring.RData")
load("metadata/response_v3_nanostring.RData")
if(which == "OS"){
  datac <- datac %>% dplyr::select(-c(RECIST, PFS, PFS.Event, Response, Age, Gender))
  datac <- datac %>% dplyr::rename(OSevent = OS.Event)
  time <- "OS"
  event <- "OSevent"
  datac <- datac[!is.na(datac$OS) & !is.na(datac$OSevent),]
}
if(which == "PFS"){
  datac <- datac %>% dplyr::select(-c(RECIST, OS, OS.Event, Response, Age, Gender))
  datac <- datac %>% dplyr::rename(PFSevent = PFS.Event)
  time <- "PFS"
  event <- "PFSevent"
  datac <- datac[!is.na(datac$PFS) & !is.na(datac$PFSevent),]
}
if(which == "ORR"){
  datac <- datac %>% dplyr::select(-c(RECIST, PFS, PFS.Event, OS, OS.Event, Age, Gender))
  datac <- datac[!is.na(datac$Response),,drop = F]
}
data <- merge(datac, datam, by = 0)
data <- data %>% dplyr::select(-c(Row.names))
colnames(data) <- make.names(colnames(data))
data <- as_tibble(data)
data[] <- lapply(data, c)

save(data, file  = "metadata/train_data_PFS.RData")

# Define parameters
if(test_run)
{n_evals <- 20; btr <- 2; resolution <- 50; reps <- 2}else{n_evals <- 100; btr <- 100; resolution <- 100; reps <- 10;} # limit tuning in testrun
BootsTrap <- rsmp("bootstrap", ratio = 1, repeats = btr)
CrossValidation <- rsmp("repeated_cv", folds = 5, repeats = reps)
measure = MeasureSurvCindex$new(weight_meth = 'G2') #msr("surv.cindex")
###############################################

# Define filters
#filt_var <- mlr_pipeops$get("filter", mlr_filters$get("variance"))
#filt_names_1 <- c("variance_filter")
#filt_uni <- flt("importance")
#filt_uni$learner = lrn("surv.ranger")
#filt_uni$learner$param_set$values = list(importance = "impurity")
#filt_uni_pipe <- mlr_pipeops$get("filter", filt_uni)
#filt_names <- c("univariate_filter")

#graph <- mlr_pipeops$get("branch", filt_names_1, id = "branch1") %>>%
#  gunion(list(
#    filt_var
#  ))
#graph <- graph %>>% #unbranch
#  mlr_pipeops$get("unbranch",
#                  filt_names_1,
#                  id = "unbranch1") 

#graph <- graph %>>%
#  mlr_pipeops$get("branch", filt_names, id = "branch2") %>>%
#  gunion(list(
#    #filt_mrmr,
#    filt_uni_pipe
#  ))
#graph <- graph %>>% #unbranch
#  mlr_pipeops$get("unbranch",
#                  filt_names,
#                  id = "unbranch2") 
###############################################


# Define learner
lrn_glm <- mlr_pipeops$get("learner", learner = mlr_learners$get("surv.ranger"))
lrn_names <- c("glm")

graph <- mlr_pipeops$get("branch", lrn_names, id = "branch1") %>>% 
  gunion(list(
    lrn_glm
  ))
graph <- graph %>>% #unbranch
  mlr_pipeops$get("unbranch", 
                  lrn_names, 
                  id = "unbranch1") 
###############################################


# Vis network
#pdf(paste0(getwd(),"/metadata/models/",model_id,"/","graph.pdf"))
graph$plot(html = T)
#dev.off()
###############################################


# Make parameters
ps <- ParamSet$new(list(
  #ParamInt$new("variance.filter.nfeat", lower = 300, upper = 300, default = 300),
  #ParamInt$new("importance.filter.nfeat", lower = 100, upper = 300, default = 200),
  #ParamDbl$new("mrmr.filter.nfeat", lower = 2, upper = 50),
  #ParamDbl$new("surv.cv_glmnet.alpha", lower = 0.0, upper = 1),
  
  ParamFct$new("branch1.selection", levels = lrn_names)#,
  #ParamFct$new("branch2.selection", levels = filt_names),
  #ParamFct$new("branch3.selection", levels = lrn_names )
))
###############################################


# Define dependencies
#ps$add_dep("variance.filter.nfeat",
#           "branch1.selection", CondEqual$new("variance_filter"))
#ps$add_dep("importance.filter.nfeat",
#           "branch2.selection", CondEqual$new("univariate_filter"))
###############################################


# tuner
terminator <- trm("evals", n_evals = n_evals)
glrn <- GraphLearner$new(graph)
#glrn$predict_type <-  "prob"
tuner = mlr3tuning::tnr("grid_search", resolution = resolution)
autotune = AutoTuner$new(
  learner = glrn,
  resampling = CrossValidation,
  measure = measure,
  search_space = ps,
  tuner = tuner,
  terminator = terminator)
#autotune$learner$param_set$values = list(#variance.filter.nfeat = 10000, 
#                             #importance.filter.nfeat = 1000,
#                             #classif.cv_glmnet.alpha = 0,
#                             branch1.selection = "variance_filter",
#                             branch2.selection = "univariate_filter",
#                             branch3.selection = "glm")


# Initialize graph task
glrn <- GraphLearner$new(graph)
#glrn$predict_type <-  "prob"
glrn$param_set$values = list(branch1.selection = "glm")
#data$Response <- factor(data$Response)
task <- TaskSurv$new(id = "PFS", 
                     backend = data,
                     time = "PFS",
                     event = "PFSevent",
                     type = "right")
task$properties = "weights"
###############################################

# train full
set.seed(iter_cvseed)
glrn$train(task) # untuned
autotune$train(task) #tuned
###############################################
###############################################

# Save training
save(glrn, file = paste0(getwd(),"/models/",model_id,"/","untuned_PFS.RData"))
save(autotune, file = paste0(getwd(),"/models/",model_id,"/","tuned_PFS.RData"))
###############################################


# training set results
features_test <- get(load("metadata/features_symbols_v3_nanostring.RData"))
response_test <- get(load("metadata/response_v3_nanostring.RData"))
data_train <- merge(response_test, features_test, by = 0) %>% column_to_rownames("Row.names")
colnames(data_train) <- make.names(colnames(data_train))
data_train <- data_train %>% dplyr::rename(OSevent = OS.Event)
data_train <- data_train %>% dplyr::rename(PFSevent = PFS.Event)
prediction <- autotune$predict_newdata(data_train, task)
cat("C-index untuned (training):\n", file = logfile, append = T)
cat(paste0(round(prediction$score(),4),"\n"), file = logfile, append = T)
cat("-------\n", file = logfile, append = T)
#prediction <- autotune$predict_newdata(data_train, task)
#cat("C-index tuned:\n (training)", file = logfile, append = T)
#cat(paste0(round(prediction$score(),4),"\n"), file = logfile, append = T)
#cat("-------\n", file = logfile, append = T)
###############################################


# Benchmark
if(benchMark){
  set.seed(iter_cvseed)
  design <- benchmark_grid(tasks = task, 
                           learner = list(glrn),#, autotune),
                           resamplings = CrossValidation)
  bmr <- benchmark(design)
  save(bmr, file = paste0(getwd(),"/models/",model_id,"/","benchmark.RData"))
  cat("C-index untuned (test):\n", file = logfile, append = T)
  cat(paste0(bmr$aggregate(),"\n"), file = logfile, append = T)
  cat("-------\n", file = logfile, append = T)
}
###############################################

# check for significant stratification
aggr <- bmr$aggregate(measure)
prediction <- as.data.table(aggr$resample_result[[1]]$prediction())
crank <- prediction$crank
x <- crank
crank[x< quantile(x)[["25%"]]] <- "low"
crank[x> quantile(x)[["25%"]] & x< quantile(x)[["75%"]]] <- "middle"
crank[x> quantile(x)[["75%"]]] <- "high"

fit <- survfit(Surv(time = OS, event = OSevent) ~ crank,
               data = data_train[prediction$row_id,])
plt <- ggsurvplot(fit, conf.int=TRUE, pval=TRUE, risk.table=TRUE)

pdf(paste0(getwd(),"/metadata/models/",model_id,"/","survivals_train_cv.pdf"))
plt
dev.off()
###############################################