function [TrainedCKNN, CKNN_Validation_Accuracy] = CKNN(predictors, response)
    % Train a classifier
    % This code specifies all the classifier options and trains the classifier.
    classificationKNN = fitcknn(predictors                  , ...
                                response                    , ...
                                'Distance', 'euclidean'     , ...
                                'Exponent', []              , ...
                                'NumNeighbors', 1           , ...
                                'DistanceWeight', 'Equal'   , ...
                                'Standardize', true         , ...
                                'ClassNames', [0; 1; 2]     );
    
    % Create the result struct with predict function
    predictorExtractionFcn = @(x) array2table(x);
    knnPredictFcn          = @(x) predict(classificationKNN, x);
    TrainedCKNN.predictFcn = @(x) knnPredictFcn(predictorExtractionFcn(x));
    
    % Add additional fields to the result struct
    TrainedCKNN.ClassificationKNN = classificationKNN;
    
    % Perform cross-validation
    partitionedModel = crossval(TrainedCKNN.ClassificationKNN, 'KFold', 5);

    % Compute validation accuracy
    CKNN_Validation_Accuracy = (1 - kfoldLoss(partitionedModel, 'LossFun', 'ClassifError'));

end