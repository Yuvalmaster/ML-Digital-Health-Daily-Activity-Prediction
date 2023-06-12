%% Load data, feature extraction 
% X — Feature matrix
% Y — labels
% n_0, n_1, n_2 - number of instances for each class

tmp = split(pwd,'\');
tmp = join(tmp(1:end-1,1),'\');
mainpath = tmp{1,1};

addpath(strcat(pwd,'\Functions'))

train_folder_path = strcat(mainpath,'\train');
test_folder_path = strcat(mainpath,'\test');

[X_train, Y_train, X_test, Y_test, n_test_0, n_test_1, n_test_2, n_train_0, n_train_1, n_train_2] = ...
    feature_extraction(train_folder_path, test_folder_path); 

disp(['train feature matrix dim: ', num2str(size(X_train))])
disp(['train labels dim: ', num2str(size(Y_train))])
disp(['test feature matrix dim: ', num2str(size(X_test))])
disp(['test labels dim: ', num2str(size(Y_test))])
disp(['class 0 train samples: ', num2str(n_train_0)]) 
disp(['class 1 train samples: ', num2str(n_train_1)]) 
disp(['class 2 train samples: ', num2str(n_train_2)])
disp(['class 0 test samples: ', num2str(n_test_0)]) 
disp(['class 1 test samples: ', num2str(n_test_1)]) 
disp(['class 2 test samples: ', num2str(n_test_2)])



%% Imputation, baseline correction and normalization

[X_train, Y_train, X_test, Y_test] = features_preperation(X_train, Y_train, X_test, Y_test); 

%% Features vetting
% vff_max - feature-feature maximum correlation value
% vff_mean - feature-feature average correlation value
% vft_max - feature-target maximum Relieff value
% vft_mean - feature-target average Relieff value

[vff_max, vff_mean, vft_max, vft_mean] = before_features_vetting_fit(X_train, Y_train); 
% return stats of scores (for monitoring) before you apply features vetting.
disp(['train prior to features vetting feature-feature max: ', num2str(vff_max)])
disp(['train prior to features vetting feature-feature average: ', num2str(vff_mean)])
disp(['train prior to features vetting feature-target max: ', num2str(vft_max)])
disp(['train prior to features vetting feature-target average: ', num2str(vft_mean)])

[Xv_train, vff_max, vff_mean, vft_max, vft_mean] = features_vetting_fit(X_train, Y_train); 
% perform features vetting
disp(['train features vetting feature-feature max: ', num2str(vff_max)])
disp(['train features vetting feature-feature average: ', num2str(vff_mean)])
disp(['train features vetting feature-target max: ', num2str(vft_max)])
disp(['train features vetting feature-target average: ', num2str(vft_mean)])

[Xv_test, vff_max, vff_mean, vft_max, vft_mean] = features_vetting_transform(X_test, Y_test); 
% apply features vetting manualy on test dataset
disp(['test features vetting feature-feature max: ', num2str(vff_max)])
disp(['test features vetting feature-feature average: ', num2str(vff_mean)])
disp(['test features vetting feature-target max: ', num2str(vft_max)])
disp(['test features vetting feature-target average: ', num2str(vft_mean)])

%% Features selection
% best_comb - best combination in any format 

[Xs_train, best_comb] = features_selection_fit(Xv_train, Y_train); 
disp(append('best combination: ', num2str(best_comb)))

[Xs_test] = features_selection_transform(Xv_test, Y_test); 

%% Classification 
% best_model - name of the best model.
% best_model_accuracy - accuracy of best model on test dataset.
% score_knn_adaboost_lsvm - according to the chosen metric - scores array of the 3 classifiers. 
% sensitivity_arr - sensitivity per class 
% example - sensitivity_arr = [0.66 for class 1 , ... , 0.59 for class 5]
% precision_arr - precision per class 
% f1_score_arr - f1_score per class 
% auc_arr_arr - auc_arr per class

[best_model, best_model_accuracy, score_knn_adaboost_lsvm, sensitivity_arr, precision_arr, f1_score_arr, train_auc_arr, test_auc_arr] = ...
    bhq_classify_load(Xs_test, Y_test, Xs_train, Y_train); 

disp(['selected model: ', best_model])
disp(['selected model accuracy: ', num2str(best_model_accuracy)])
disp(['knn adaboost lsvm scores: ', num2str(score_knn_adaboost_lsvm)])
disp(['sensitivity per class: ', num2str(sensitivity_arr)])
disp(['average sensitivity : ', num2str(mean(sensitivity_arr))])
disp(['precision per class: ', num2str(precision_arr)])
disp(['average precision : ', num2str(mean(precision_arr))])
disp(['f1 per class: ', num2str(f1_score_arr)])
disp(['average f1 : ', num2str(mean(f1_score_arr))])
disp(['train auc per class: ', num2str(train_auc_arr)])
disp(['average train auc : ', num2str(mean(train_auc_arr))])
disp(['test auc per class: ', num2str(test_auc_arr)])
disp(['average test auc : ', num2str(mean(test_auc_arr))])

