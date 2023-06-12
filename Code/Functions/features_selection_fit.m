function [Xs_train, best_comb] = features_selection_fit(Xv_train, Y_train)
% This function discretisize the train data and find the best combination
% using exhustive search and fscmrmr function. the scores are calculated as
% sum of each run, finding the highest combination score.

%% Set number of combinations
    k              = 10;                        % Number of final features
    len            = size(Xv_train,2);          % Number of current features
    combinations   = 1:len;                     
    combinations   = nchoosek(combinations,k);  % Number of k current features combinations
    n_combinations = size(combinations,1);      % Number of combinations

    scores         = zeros(n_combinations,1);
    
    %% Run combinations
    tic
    h = waitbar(0,'Run feature selection - Please wait');
    for i=1:n_combinations
        d_Xv_train = zeros(size(Xv_train,1),k);
        for r = 1:k
            [d_Xv_train(:,r),~] = discretize(Xv_train(:,combinations(i,r)),3);
        end
        
        [~,score] = fscmrmr(d_Xv_train,Y_train);
        scores(i) = sum(score);


    waitbar(i / n_combinations, h, sprintf('Run feature selection - Progress: %d %%', floor(i/n_combinations*100)))

    end
    
    [~, max_comb_num] = max(scores);
    best_comb = combinations(max_comb_num,:);
    Xs_train  = Xv_train(:,best_comb);

    close(h)
    toc
    disp(' ')

end