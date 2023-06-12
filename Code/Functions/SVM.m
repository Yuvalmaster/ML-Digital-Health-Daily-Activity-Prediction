function [TrainedSVM, SVM_Validation_Accuracy] = SVM(predictors, response)
    % Train a classifier
    % This code specifies all the classifier options and trains the classifier.
    template = templateSVM('KernelFunction', 'linear'   , ...
                           'PolynomialOrder', []        , ...
                           'KernelScale', 'auto'        , ...
                           'BoxConstraint', 1           , ...
                           'Standardize', true);
    
    classificationSVM = fitcecoc(predictors             , ...
                                 response               , ...
                                 'Learners', template   , ...
                                 'Coding', 'onevsall'   , ...
                                 'ClassNames', [0; 1; 2]);
    
    % Create the result struct with predict function
    predictorExtractionFcn = @(x) array2table(x);
    svmPredictFcn          = @(x) predict(classificationSVM, x);
    TrainedSVM.predictFcn  = @(x) svmPredictFcn(predictorExtractionFcn(x));
    
    % Add additional fields to the result struct
    TrainedSVM.ClassificationSVM = classificationSVM;
    
    % Perform cross-validation
    partitionedModel = crossval(TrainedSVM.ClassificationSVM, 'KFold', 5);
    
    % Compute validation accuracy
    SVM_Validation_Accuracy = (1 - kfoldLoss(partitionedModel, 'LossFun', 'ClassifError'));
end
