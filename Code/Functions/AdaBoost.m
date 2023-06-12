function [TrainedAdaBoost, AdaBoost_Validation_Accuracy] = AdaBoost(predictors, response)
    % Train a classifier
    % This code specifies all the classifier options and trains the classifier.
    template = templateTree('MaxNumSplits', 20           , ...
                            'NumVariablesToSample', 'all');
    
    classificationEnsemble = fitcensemble(predictors              , ...
                                          response                , ...
                                          'Method', 'AdaBoostM2'  , ...
                                          'NumLearningCycles', 30 , ...
                                          'Learners', template    , ...
                                          'LearnRate', 0.1        , ...
                                          'ClassNames', [0; 1; 2]);
    
    % Create the result struct with predict function
    predictorExtractionFcn     = @(x) array2table(x);
    ensemblePredictFcn         = @(x) predict(classificationEnsemble, x);
    TrainedAdaBoost.predictFcn = @(x) ensemblePredictFcn(predictorExtractionFcn(x));
    
    % Add additional fields to the result struct
    TrainedAdaBoost.ClassificationEnsemble = classificationEnsemble;
    
    % Perform cross-validation
    partitionedModel = crossval(TrainedAdaBoost.ClassificationEnsemble, 'KFold', 5);
    
    % Compute validation accuracy
    AdaBoost_Validation_Accuracy = (1 - kfoldLoss(partitionedModel, 'LossFun', 'ClassifError'));
end

