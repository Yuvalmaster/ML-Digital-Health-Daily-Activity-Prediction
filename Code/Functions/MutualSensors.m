function sensors = MutualSensors(train_raw_data,test_raw_data)
% This is test function to find all mutual sensors.

    % Initiate with first subject sensors
    curr_subject = unique(train_raw_data{1}.type);
    
    % Run through all subjects, find mutual sensors (train data)
    for subject = 2:numel(train_raw_data)-1  
        next_subject   = unique(train_raw_data{subject+1}.type); % The next subject's unique sensors
        search_sensors = ismember(curr_subject, next_subject  ); % search mutual sensors
        
        % set new current subject's sensors based on mutuality
        curr_subject   = curr_subject(search_sensors);          
    end

    % Run through all subjects, find mutual sensors (test data)
    for subject = 1:numel(test_raw_data)-1
        next_subject   = unique(test_raw_data{subject+1}.type);  % The next subject's unique sensors
        search_sensors = ismember(curr_subject, next_subject );  % search mutual sensors

        % set new current subject's sensors based on mutuality
        curr_subject   = curr_subject(search_sensors);          
    end
    sensors = unique(curr_subject); % determine all unique mutual sensors.
end