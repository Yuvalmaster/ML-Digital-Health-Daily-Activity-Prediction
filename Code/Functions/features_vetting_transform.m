function [Xv_test, vff_max, vff_mean, vft_max, vft_mean] = features_vetting_transform(X_test, Y_test, I, plot_heatmap)
    % This functions gets as an input the X,Y test data, flag for heat map
    % plot and the selected 20 features. If the function do not get the
    % indexes of the best from feature vetting, it run by manually inserted
    % indexes.
    
    if nargin < 4           % Set default flag (In case the function did not recieved flag as input).
        plot_heatmap = 1;
        I = [1     5    15    16    17    18    21    25    30    31    44    47    48    49    59    62    67    73    83   84];
    end
    %% feature-feature correlation
    % Create new feature matrix & correlate
    Xv_test = X_test(:,I);
    rff_Spearman = corr(Xv_test,'type','Spearman');
    if plot_heatmap
        figure; heatmap(abs(rff_Spearman));title({'Spearman correlation - Heatmap','Test dataset after feature vetting'})
    end

    vff_max  = max(rff_Spearman(rff_Spearman<1));
    vff_mean = mean(rff_Spearman(rff_Spearman<1));

    %% feature-label correlation
    len = size(Xv_test,2);
    W   = zeros(len,1);
    for j = 1:len
        [~,W(j)] = relieff(Xv_test(:,j),Y_test,10);
    end
    vft_max  = max(W);
    vft_mean = mean(W);
end