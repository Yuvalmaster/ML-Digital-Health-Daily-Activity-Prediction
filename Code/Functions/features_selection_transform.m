function [Xs_test] = features_selection_transform(Xv_test, Y_test, best_comb)
    % Apply the indexes of the best combination after feature selection to
    % the test data set.
    % The chosen best_comb are the features with the best end-results
    % overall.

    if nargin ~= 3           % Set default flag (In case the function did not recieved flag as input).
       best_comb = [ 1     3     4     5     6     7    14    17    18    20];   % Using default 3 bins    - Exhaustive Search 
       %best_comb = [ 1     2     5     7     8    11    14    15    16    17];  % Using precentile 3 bins - Exhaustive Search 
       %best_comb = [ 1     9    19    12    16     5    18    10    14     8];  % Using default 3 bins
       %best_comb = [ 1     12    2     15    5    14    16    17    7      8];  % Using precentile 3 bins
       
    end
    Xs_test = Xv_test(:,best_comb);
end