function [best_model, best_model_accuracy, score_knn_adaboost_lsvm, sensitivity_arr, precision_arr, f1_score_arr, train_auc_arr, test_auc_arr] = bhq_classify_load(Xs_test, Y_test, Xs_train, Y_train)
% Score calculation is defined by combination of validation accuracy,
% model accuracy on train dataset,
% average precision in train dataset, average recall in train dataset.
% The most weighted parameters in term of accurate predictions in this 
% case are the precision and accuracy of the cross-validation, which I 
% include in the score with higher precentage. The reason for high 
% precision contribution is high PPV, which is important to obsereve over 
% high number of false positives and incorrect classifications.
% In addition, I added small contribiution of the recall in train 
% dataset and model accuracy in test dataset, since the recall
% estimates the probability that a class are selected from the pool,
% while there are many instances of class 1 when for class 0 and 2
% there are not many instances. 
%
% All models were tuned by adjustinbg hyperparameter according to elbow
% method in error/parameter value graph. In order to make it as efficient
% and easy to tune as possible, all measurments of hyper parameters were
% monitored using the Classification learner app in MATLAB. The data was
% saved under ClassificationLearnerSession2.mat
% 
% The result shows that the data was not sufficient for the classification
% (81.98% accuracy for on Test dataset, 78.37% accuracy on Train dataset)
% task since the accuracy is not great, and especially the ROC. It might
% also be due to improper feature selection but for internal testing I
% measured the result with different selected features (which can be seen
% under feature_selection_transform function) and got the best result using
% the original combination.
% Another possible factor for the sub optimal results is the normalization,
% which may have caused several features to seems irelevant; However, this
% was also tested by different types of normalization and I got the best
% results using the normalization in feature extraction function.
%
% Since the number of samples is not big enough I
% believe that with much more data (<2000 samples) the results may be much
% better then the current ones. Also the veriaty of each subject
% contribiutes big time to deviations from good results, since each person
% behaves differently with his smartphone, have different daily routines
% and personal life. Bigger population could improve the results a lot.

%% Variables and settings
    rng('default') % For reproducibility

    Models      = {'KNN', 'Linear SVM', 'AdaBoost'};
    Models_func = {@CKNN, @SVM, @AdaBoost};
    Classes     = unique(Y_train); % All unique classes in dataset
    tab         = tabulate(Y_train);

    % Lists for trained model for each classifier
    Trained_model_list  = {};
    Confusion_mat_list  = {};

    % Preallocation
    Val_Accuracy_model_list = zeros(1, numel(Models));
    precision_model_list    = zeros(1, numel(Models));
    recall_model_list       = zeros(1, numel(Models));
    f1_score_model_list     = zeros(1, numel(Models));
    
    precision = zeros(1, numel(Models));
    recall    = zeros(1, numel(Models));
    f1_score  = zeros(1, numel(Models));

%% Train Models   
    h = waitbar(0,'Searching for optimal model');
    for model = 1:numel(Models)
        waitbar(model/numel(Models) , h, sprintf('Searching for optimal Model:\n Currently testing %s ', Models{model}))
        % Training the model
        [Trained_model, Accuracy] = Models_func{model}(Xs_train, Y_train);
        
        % Export model's results
        conf_mat                       = confusionmat(Y_train, Trained_model.predictFcn(Xs_train));
        Confusion_mat_list{model}      = conf_mat;
        Trained_model_list{model}      = Trained_model;
        Val_Accuracy_model_list(model) = Accuracy;
        model_accuracy_list(model)     = sum(Y_test == Trained_model.predictFcn(Xs_test))/numel(Y_test);

        % sum results in confusion matrix
        for i=1:numel(Classes)
        % Calculate true positive rate (sensitivity)
        recall(i) = conf_mat(i,i) / sum(conf_mat(i,:));
        
        % Calculate positive predictive value (precision)
        precision(i)   = conf_mat(i,i) / sum(conf_mat(:,i));
        
        % Calculate F1 score
        f1_score(i)    = 2 * (precision(i) * recall(i))...
                           / (precision(i) + recall(i));
        end
        precision_model_list(model,:) = precision;
        recall_model_list(model,:)    = recall;
        f1_score_model_list(model,:)  = f1_score;
    end
    close(h)
%% Choose Best Model
    for model = 1:numel(Models)
        avg_pre(model) = mean(precision_model_list(model, ~isnan(precision_model_list(model,:)))); % Average precision for all classes
        avg_rec(model) = mean(recall_model_list(model,   ~isnan(recall_model_list(model,:))));     % Average recall for all classes
    end  
    score_knn_adaboost_lsvm = 0.5 .* Val_Accuracy_model_list +... % Validation accuracy of the model using 5-fold cross validation on train dataset.
                              0.1 .* model_accuracy_list     +... % Accuracy of the model on test dataset (after training).
                              0.3 .* avg_pre                 +... % Average precision for all classes.
                              0.1 .* avg_rec                 ;    % Average recall for all classes.


    [~,best_model_idx] = max(score_knn_adaboost_lsvm);

    best_model = Models{best_model_idx};

    % Predict Optimal model on Train Set
    [y_pred_train, score_train] = Trained_model_list{best_model_idx}.predictFcn(Xs_train);
    train_accuracy              = 100 .* sum(Y_train == y_pred_train)/numel(Y_train);
    fprintf('Train Accuracy with optimal model: %.2f\n',train_accuracy);

    % Predict Optimal model on Test Set
    [y_pred_test, score_test] = Trained_model_list{best_model_idx}.predictFcn(Xs_test);
    best_model_accuracy       = 100 .* sum(Y_test == y_pred_test)/numel(Y_test);
    fprintf('Test Accuracy with optimal model: %.2f\n', best_model_accuracy); 

%% Calculate Sensitivity, Precision, F1 Score
    % Initialize variables to store scores
    sensitivity_arr =  precision_model_list(best_model_idx,:);
    precision_arr   = recall_model_list(best_model_idx,:);
    f1_score_arr    = f1_score_model_list(best_model_idx,:);
    
    
%% ROC & AUC
    % Calculate ROC & AUC on Train and Test Set for each class
    train_auc_arr = zeros(1, size(tab,1)-2);
    test_auc_arr  = zeros(1, size(tab,1)-2);
    for i=1:size(tab,1)
        % Train AUC & ROC
        [FPR_train, TPR_train, threshold_train, train_auc_arr(1, i)]  = perfcurve(Y_train, score_train(:,i), tab(i));

        % Plot Train ROC
        figure; plot3(FPR_train, TPR_train, threshold_train); set(gca,'CameraPosition',[0.5,0.5,10])
        line([0 1 0], [0 1 0], 'color', 'r'); 
        xlabel('FPR'); ylabel('TPR'); zlabel('Threshold'); xlim([0 1]); ylim([0 1])
        title(['Train ROC curve - Class No. ',num2str(tab(i,1)),' vs. rest'])
        
        ind_max_sensitivity = find(TPR_train == 1);
        fprintf('Threshold for operating point with maximum sensitivity - Class %d :\t',tab(i,1))
        fprintf('  %1.3f',threshold_train(ind_max_sensitivity(1)))
        
        % Test AUC & ROC
        [x_ROC_test, y_ROC_test, threshold_test, test_auc_arr(1, i)] = perfcurve(Y_test, score_test(:,i), tab(i));

        % Plot Test ROC
        figure; plot3(x_ROC_test,y_ROC_test,threshold_test); set(gca,'CameraPosition',[0.5,0.5,10])
        line([0 1 0], [0 1 0], 'color', 'r'); 
        xlabel('FPR'); ylabel('TPR'); zlabel('Threshold'); xlim([0 1]); ylim([0 1])
        title(['Test ROC curve - Class No. ',num2str(tab(i,1)),' vs. rest'])

        disp(' ')
    end
    disp(' ')


end