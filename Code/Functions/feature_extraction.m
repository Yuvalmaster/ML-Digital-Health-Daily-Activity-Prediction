function [X_train, Y_train, X_test, Y_test, n_test_0, n_test_1, n_test_2, n_train_0, n_train_1, n_train_2] = feature_extraction(train_folder_path, test_folder_path)
 % This function extract the raw data and extract features based on every 
 % days in the labels data. The Train and Test data run through each day in
 % each month, calculating features for each day in the label matrices. In
 % order to deal with multiple data points in the same day due to bad
 % labeling, the function keeps only the last (based on daytime) label, and
 % ignore the rest, since It cannot be determined as the previous day's
 % label, since there are some labels CSV files with 3 events per day. 

    %% Load Data
    % Load train data
    [train_data_files_name, train_raw_data, train_label_data] = Extract_data(train_folder_path);
    % Load test data
    [test_data_files_name,  test_raw_data,  test_label_data ] = Extract_data(test_folder_path );

    %% Find mutual sensors between all subjects & sort events
    %sensors = MutualSensors(train_raw_data,test_raw_data);
    sensors = {'accelerometer' , 'activity' , 'battery',...
               'bluetooth'     , 'gyroscope', 'light'  ,...
               'magnetic_field', 'screen'   , 'wifi'   ,...
               'location'      , 'calls'    , 'timezone'};

    %% TRAIN DATA
    X_train = []; Y_train = [];
    subject_features  = [];
    sub_day_num_train = []; 

    % Run through all subjects
    h = waitbar(0, sprintf('Calculating features Train Dataset'));
    for subject = 1:numel(train_raw_data)
        LABELS = train_label_data{subject};
        months = month(train_raw_data{subject}.datetime);
        days   = day(  train_raw_data{subject}.datetime);

        % Datetime of all labels
        try
            LABELS_TIME = LABELS.('חותמת זמן');
        catch
            LABELS_TIME = LABELS.Timestamp;     
        end
    
        if  iscell(LABELS_TIME)
            LABELS_TIME = cellfun(@(x) datetime(x), LABELS_TIME); clc;
        end
        
        % Run through all months
        MONTHS = unique(month(LABELS_TIME));
        
        for MONTH = 1:numel(MONTHS)
            % Run through every day
            % ALL DAYS IN CURRENT MONTH
            DAYS = day(LABELS_TIME); 
            DAYS = DAYS(month(LABELS_TIME) == MONTHS(MONTH));

            % Find starting index of days in current month
            Days_idx = month(LABELS_TIME) == MONTHS(MONTH);
            [~,idx]  = max(Days_idx);
 
            % Remove duplicates of multiple labels in the same day and
            % update LABELS table
            removeduplicates = ones(size(LABELS,1),1);
            removeduplicates(find(diff([0, DAYS']) == 0)-1+idx) = 0;
            
            % Remove incorrect indexes from bad data!
            [~,min_day_loc] = min(DAYS); 
            if min_day_loc ~= 1 
                removeduplicates((1:min_day_loc-1)+idx) = 0;
            end

            LABELS = LABELS(logical(removeduplicates),:);
            LABELS_TIME = LABELS_TIME(logical(removeduplicates),:);

            % WORK WITH UNIQUE DAYS
            DAYS = DAYS(min_day_loc:end);
            DAYS = unique(DAYS);
            
            for DAY = 1:numel(DAYS)
                waitbar(subject/numel(train_raw_data), h, sprintf('Calculating features Train Dataset\nSubject: %d, MONTH: %d, DAY: %d',subject, MONTHS(MONTH),DAYS(DAY)))
                idx = (months == MONTHS(MONTH)) & (days == DAYS(DAY));
                
                % Set data whitin current day
                data = train_raw_data{subject}(idx,:);

                % initialize events matrix
                events_sensor = [];       
        
                % Set events indexes
                for sensor = 1:numel(sensors)-1
                    events_sensor(: , sensor) = cellfun(@(x) strcmp(x, sensors{sensor}), data.type);
                end
                
                % Add events for different time zones 
                events_sensor(: , end+1) = cellfun(@(x) ~strcmp(x, 'Asia/Jerusalem'), data.timezone);
                
                % Create table of events indexes for each sensor
                events_sensor_T = array2table(events_sensor,'VariableNames',sensors);
        
                % Find features
                features = extract_features(data, events_sensor_T);
                subject_features = [subject_features; features];
            end
        end
        
        % NORMALIZE FEATURES PER SUBJECT
        subject_features_norm = normalize(subject_features,'norm');   % Normalize according to L2-norm.
        subject_features(:,max(isnan(subject_features_norm)~=1)) =...
        subject_features_norm(:,max(isnan(subject_features_norm)~=1)); 
        subject_features = normalize(subject_features,'range');       % Normalize all between [0,1]
        
        % Number of samples per subject
        sub_day_num_train = [sub_day_num_train size(subject_features,1)]; 
        
        % Features matrix
        X_train = [X_train; subject_features];
        
        % Labels vector
        label_score = LABELS.('איך היה היום האחרון?');       
        
        label_score(label_score < 4)                   = 0;
        label_score(label_score > 3 & label_score < 8) = 1;
        label_score(label_score > 7)                   = 2;
        
        Y_train = [Y_train ; label_score];
        if size(subject_features,1) ~= size(LABELS,1)
            warning('ERROR - Mismatch of LABELS-features')
        end

        % Reset for next subject 
        subject_features = [];
    end
    n_train_0 = sum(Y_train==0);
    n_train_1 = sum(Y_train==1);
    n_train_2 = sum(Y_train==2);
    close(h)

    %% TEST DATA
    X_test = []; Y_test = [];
    subject_features  = [];
    sub_day_num_test  = []; 

    % Run through all subjects
    h = waitbar(0, sprintf('Calculating features test Dataset'));
    for subject = 1:numel(test_raw_data)
        LABELS = test_label_data{subject};
        months = month(test_raw_data{subject}.datetime);
        days   = day(  test_raw_data{subject}.datetime);

        % Datetime of all labels
        try
            LABELS_TIME = LABELS.('חותמת זמן');
        catch
            LABELS_TIME = LABELS.Timestamp;     
        end
    
        if  iscell(LABELS_TIME)
            LABELS_TIME = cellfun(@(x) datetime(x), LABELS_TIME); clc;
        end
        
        % Run through all months
        MONTHS = unique(month(LABELS_TIME));
        
        for MONTH = 1:numel(MONTHS)
            % Run through every day
            % ALL DAYS IN CURRENT MONTH
            DAYS = day(LABELS_TIME); 
            DAYS = DAYS(month(LABELS_TIME) == MONTHS(MONTH));

            % Find starting index of days in current month
            Days_idx = month(LABELS_TIME) == MONTHS(MONTH);
            [~,idx]  = max(Days_idx);
 
            % Remove duplicates of multiple labels in the same day and
            % update LABELS table
            removeduplicates = ones(size(LABELS,1),1);
            removeduplicates(find(diff([0, DAYS']) == 0)-1+idx) = 0;
            
            % Remove incorrect indexes from bad data!
            [~,min_day_loc] = min(DAYS); 
            if min_day_loc ~= 1 
                removeduplicates((1:min_day_loc-1)+idx) = 0;
            end

            LABELS = LABELS(logical(removeduplicates),:);
            LABELS_TIME = LABELS_TIME(logical(removeduplicates),:);

            % WORK WITH UNIQUE DAYS
            DAYS = DAYS(min_day_loc:end);
            DAYS = unique(DAYS);
            
            for DAY = 1:numel(DAYS)
                waitbar(subject/numel(test_raw_data), h, sprintf('Calculating features test Dataset\nSubject: %d, MONTH: %d, DAY: %d',subject, MONTHS(MONTH),DAYS(DAY)))
                idx = (months == MONTHS(MONTH)) & (days == DAYS(DAY));
                
                % Set data whitin current day
                data = test_raw_data{subject}(idx,:);

                % initialize events matrix
                events_sensor = [];       
        
                % Set events indexes
                for sensor = 1:numel(sensors)-1
                    events_sensor(: , sensor) = cellfun(@(x) strcmp(x, sensors{sensor}), data.type);
                end
                
                % Add events for different time zones 
                events_sensor(: , end+1) = cellfun(@(x) ~strcmp(x, 'Asia/Jerusalem'), data.timezone);
                
                % Create table of events indexes for each sensor
                events_sensor_T = array2table(events_sensor,'VariableNames',sensors);
        
                % Find features
                features = extract_features(data, events_sensor_T);
                subject_features = [subject_features; features];
            end
        end
        % NORMALIZE FEATURES PER SUBJECT
        subject_features_norm = normalize(subject_features,'norm');   % Normalize according to L2-norm.
        subject_features(:,max(isnan(subject_features_norm)~=1)) =...
        subject_features_norm(:,max(isnan(subject_features_norm)~=1)); 
        subject_features = normalize(subject_features,'range');       % Normalize all between [0,1]
        
        % Number of samples per subject
        sub_day_num_test = [sub_day_num_test size(subject_features,1)]; 
        
        % Features matrix
        X_test = [X_test; subject_features];
        
        % Labels vector
        label_score = LABELS.('איך היה היום האחרון?');            
        
        label_score(label_score < 4)                   = 0;
        label_score(label_score > 3 & label_score < 8) = 1;
        label_score(label_score > 7)                   = 2;
        
        Y_test = [Y_test ; label_score];
        if size(subject_features,1) ~= size(LABELS,1)
            warning('ERROR - Mismatch of LABELS-features')
        end

        % Reset for next subject 
        subject_features = [];
    end
    n_test_0 = sum(Y_test==0);
    n_test_1 = sum(Y_test==1);
    n_test_2 = sum(Y_test==2);
    close(h);

end