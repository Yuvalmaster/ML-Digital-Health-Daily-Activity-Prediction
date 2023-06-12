function features = extract_features(Data_table, sensors_indexes_T)
% This function extract all the features. Under %%FEATURES tab (row 27)
% There are description for each set of features from each sensors.

%   Mutual sensors to sample:
%      'accelerometer'
%      'activity'
%      'battery'
%      'bluetooth'
%      'gyroscope'
%      'light'
%      'location'
%      'magnetic_field'
%      'screen'
%      'wifi'
%      'calls'
%      'timezone'

%% Initial variables
    % Initialize allocation vector for each feature
    features = [];
    
    % Coordinates columns
    coordinates_cols = cellfun(@(x) strcmp(Data_table.Properties.VariableNames, x),{'x','y','z'}, 'UniformOutput', false);
    coordinates_cols = coordinates_cols{1} + coordinates_cols{2} + coordinates_cols{3};
    
%% FEATURES
% ======================= Accelerometer features ======================== %
    acc_table = Data_table(logical(sensors_indexes_T.accelerometer),:);
    % Acceleration over x,y,z coordinates
    xyz_acc = table2array(varfun(@(x) str2double(x),...
              Data_table(logical(sensors_indexes_T.accelerometer),logical(coordinates_cols))));

    % Find events in early or late in the day
    late_acc_count  = unique(hour(acc_table.datetime)) > 22;
    early_acc_count = unique(hour(acc_table.datetime)) < 6;
    late_acc_time   = find(hour(acc_table.datetime) > 22);
    early_acc_time  = find(hour(acc_table.datetime) < 6);
    
% 1. peak Accelerometer feature--------------------------------------------
    % Set the mean of maximum over x,y,z axises
    max_acc = mean(max(abs(xyz_acc))); 
    if isempty(max_acc) || max(isnan(max_acc))
        max_acc = 0;
    end
    features = [features max_acc];
 
% 2. std Accelerometer feature---------------------------------------------
    % Set the mean of standard deviation xyz_acc over x,y,z axises
    std_acc = mean(std(xyz_acc));
    if isempty(std_acc) || max(isnan(std_acc))
        std_acc = 0;
    end
    features = [features std_acc];

% 3. crazy hours Accelerometer deviation features--------------------------
    late_acc_deviation = mean(std(xyz_acc(late_acc_time)));
    if isnan(late_acc_deviation) || isempty(late_acc_deviation)
        late_acc_deviation = 0;
    end

    early_acc_deviation = mean(std(xyz_acc(early_acc_time)));
    if isnan(early_acc_deviation) || isempty(early_acc_deviation)
        early_acc_deviation = 0;
    end

% 4. crazy hours Accelerometer max features--------------------------------
    late_acc_max = max(std(xyz_acc(late_acc_time)));
    if isnan(late_acc_max) || isempty(late_acc_max)
        late_acc_max = 0;
    end

    early_acc_max = max(std(xyz_acc(early_acc_time)));
    if isnan(early_acc_max) || isempty(early_acc_max)
        early_acc_max = 0;
    end

% 5. crazy hours Accelerometer time features------------------------------    
    if isempty(late_acc_time) || numel(late_acc_time)==1
        late_acc_time = 0;
    else
        late_acc_time = abs(hours(acc_table.datetime(late_acc_time(1))-...
                                     acc_table.datetime(late_acc_time(end))));
    end
    
    if isempty(early_acc_time) || numel(early_acc_time)==1
       early_acc_time = 0;
    else
        early_acc_time = abs(hours(acc_table.datetime(early_acc_time(1))-...
                                      acc_table.datetime(early_acc_time(end))));
    end

    features = [features, sum(late_acc_count) ,...
                          sum(early_acc_count),...
                          late_acc_time       ,...
                          early_acc_time      ,...
                          early_acc_deviation ,...
                          late_acc_deviation  ,...
                          early_acc_max       ,...
                          late_acc_max       ];



% ========================== Activity features ========================== %
    activity_table     = Data_table(logical(sensors_indexes_T.activity),:);
    activity_status    = activity_table.sub_type; % activity status tab
    activity_certainty = activity_table.level;    % activity status certainty tab
    
    % To determine that the subject did an activity, it must cross the set
    % threshold in status certainty tab
    thresh = 60; 

    count_still      = strcmpi(activity_status,'still'     );
    count_tilting    = strcmpi(activity_status,'tilting'   );
    count_on_foot    = strcmpi(activity_status,'on_foot'   );
    count_in_vehicle = strcmpi(activity_status,'in_vehicle');

% 1. count status features-------------------------------------------------
    features = [features, sum(count_still      & activity_certainty > thresh),...
                          sum(count_tilting    & activity_certainty > thresh),...
                          sum(count_on_foot    & activity_certainty > thresh),...
                          sum(count_in_vehicle & activity_certainty > thresh)];

% 2. activity duration features--------------------------------------------
    % Calculating the time of each activity during the day by measuring the
    % time between each event. If the certainty is below the set threshold,
    % it will not include in the time calculation, which can give
    % inconsisted, yet still informative feature. Over proper sampling this
    % feature can be really helpful.
    still_time      = 0;
    tilting_time    = 0;
    on_foot_time    = 0;
    in_vehicle_time = 0;

    for i = wrev(2:numel(activity_status))
        if strcmpi(activity_status(i),'still') && activity_certainty(i) > thresh
            still_time = still_time + abs(hours(        ...
                         activity_table.datetime(i,:) - ...
                         activity_table.datetime(i-1,:) ...
                         ));

        elseif strcmpi(activity_status(i),'tilting') && activity_certainty(i) > thresh
            tilting_time = tilting_time + abs(hours(      ...
                           activity_table.datetime(i,:) - ...
                           activity_table.datetime(i-1,:) ...
                           ));

        elseif strcmpi(activity_status(i),'on_foot') && activity_certainty(i) > thresh
            on_foot_time = on_foot_time + abs(hours(      ...
                           activity_table.datetime(i,:) - ...
                           activity_table.datetime(i-1,:) ...
                           ));

        elseif strcmpi(activity_status(i),'in_vehicle') && activity_certainty(i) > thresh
            in_vehicle_time = in_vehicle_time + abs(hours(   ...
                              activity_table.datetime(i,:) - ...
                              activity_table.datetime(i-1,:) ...
                              ));
        end
    end

    features = [features, still_time      ,...
                          tilting_time    ,...
                          on_foot_time    ,...
                          in_vehicle_time];


% ========================== Battery features =========================== %
    battery_table = Data_table(logical(sensors_indexes_T.battery),:);
    
    % Load battery status ('Charging', 'Discharging', 'Full')
    battery_charge_status = battery_table.sensor_status;
    
    % Load battery precentage over time
    battery_precentage = cellfun(@(x) str2double(x), battery_table.value); 
    
    % Count states
    count_charge    = strcmpi(battery_charge_status,'charging'   );
    count_discharge = strcmpi(battery_charge_status,'discharging');

% 1. number of chargings feature ------------------------------------------
    % Count the number of starting charging only!
    charging_events = sum(diff([0, diff(count_charge')==1 , 0]) > 0);
    features        = [features charging_events];
    
% 2. draining time features -----------------------------------------------
    % Calculate the average discharging time and total discharging time 
    % during the day
    start_discharge = find([0, diff(count_discharge)'==1,  0]);
    end_discharge   = find([0, diff(count_discharge)'==-1, 0])-1;
    
    % the following section checks for inconsistencies and match edge cases
    if length(start_discharge) < length(end_discharge)
        start_discharge = [1, start_discharge];
    
    elseif length(start_discharge) > length(end_discharge)
        end_discharge = [end_discharge, size(battery_charge_status,1)];
    end
    
    % Calculate time of discharging
    if isempty(end_discharge) && isempty(start_discharge)
        discharge_time = 0;
    else
        discharge_time = zeros(1,numel(start_discharge));
        for i = 1:numel(start_discharge)
            discharge_time(i) = abs(hours(... 
                                battery_table.datetime(start_discharge(i))-...
                                battery_table.datetime(end_discharge(i))   ...
                                ));     
        end
    end
    features = [features mean(discharge_time)]; % mean  time of discharging
    features = [features sum(discharge_time )]; % Total time of discharging
    
% 3. charging time features -----------------------------------------------
    % Calculate the average charging time and total charging time during
    % the day
    start_charge = find([0, diff(count_charge)'==1,  0]);
    end_charge   = find([0, diff(count_charge)'==-1, 0])-1;
    
    % the following section checks for inconsistencies and match edge cases
    if length(start_charge) < length(end_charge)
        start_charge = [1, start_charge];
    
    elseif length(start_charge) > length(end_charge)
        end_charge = [end_charge size(battery_charge_status,1)];
    end
    
    % Calculate time of charging
    if isempty(end_charge) && isempty(start_charge)
        charge_time = 0;
    else
        charge_time = zeros(1,numel(start_charge));
        for i = 1:numel(start_charge)
            charge_time(i) = abs(hours(... 
                             battery_table.datetime(start_charge(i))-...
                             battery_table.datetime(end_charge(i))   ...
                             ));  
        end
    end
    
    features = [features mean(charge_time)]; % mean  time of charging
    features = [features sum(charge_time )]; % total time of charging

% 4. Low battery features -------------------------------------------------
    % Find events of battery lower than set threshold. The function
    % calculates the mean time with low battery, the total time with low
    % battery and number of times the phone was discharged to low battery
    % during the day
    low_bat_thresh    = 50;
    low_battery       = battery_precentage <= low_bat_thresh;

    start_low_battery = find([0, diff(low_battery)'==-1, 0])-1;
    end_low_battery   = find([0, diff(low_battery)'== 1, 0]);

     % the following section checks for inconsistencies and match edge cases
     if length(start_low_battery) < length(end_low_battery)
        start_low_battery = [start_low_battery, size(battery_precentage,1)];
    
     elseif length(start_low_battery) > length(end_low_battery)
         end_low_battery = [1, end_low_battery];
    end
    
    % Calculate time of low battery
    if isempty(end_low_battery) && isempty(start_low_battery)
        low_battery_time = 0;
    else
        low_battery_time = zeros(1, numel(start_low_battery));
        for i = 1:numel(start_low_battery)
            low_battery_time(i) = abs(hours(... 
                                  battery_table.datetime(start_low_battery(i))-...
                                  battery_table.datetime(end_low_battery(i))   ...
                                  ));   
        end
    end
    features = [features mean(low_battery_time   )]; % mean  time of low battery
    features = [features sum(low_battery_time    )]; % total time of low battery
    features = [features length(start_low_battery)]; % number of events of low battery


% ========================== bluetooth features ========================= %
    bluetooth_table = Data_table(logical(sensors_indexes_T.bluetooth),:);
    bluetooth_level = bluetooth_table.level;
    b_signal_thresh = -50; % Signal threshold

% 1. signal strength features----------------------------------------------
    features = [features mean(bluetooth_level(~isnan(bluetooth_level)))]; % mean signal strength throughout the day
    features = [features std( bluetooth_level(~isnan(bluetooth_level)))]; % std  signal strength throughout the day

% 2. Strong signal time features-------------------------------------------
    find_confines = diff([0, diff(find(bluetooth_level > b_signal_thresh))'==1, 0]);
    start_strong_signal = find(find_confines == -1);
    end_strong_signal   = find(find_confines == 1);

     % the following section checks for inconsistencies and match edge cases
     if length(start_strong_signal) < length(end_strong_signal)
        start_strong_signal = [start_strong_signal, size(find_confines,1)];
    
     elseif length(start_strong_signal) > length(end_strong_signal)
         end_strong_signal = [1, end_strong_signal];
     end
    
     % Calculate time of strong signal
     if isempty(start_strong_signal) && isempty(end_strong_signal)
        strong_signal_time = 0;
    else
        strong_signal_time = zeros(1, numel(start_strong_signal));
        for i = 1:numel(start_strong_signal)
            strong_signal_time(i) = abs(hours(... 
                                  bluetooth_table.datetime(start_strong_signal(i))-...
                                  bluetooth_table.datetime(end_strong_signal(i))   ...
                                  ));   
        end
     end

 % 3. number of unique devices feature-------------------------------------
    unique_bluetooth_devices = unique(bluetooth_table.suuid);

    features = [features mean(strong_signal_time       )]; % mean  time of strong signal
    features = [features sum(strong_signal_time        )]; % total time of strong signal
    features = [features length(strong_signal_time     )]; % number of events of strong signal
    features = [features numel(unique_bluetooth_devices)]; % number unique bluetooth devices


% ========================== Gyroscope features ========================= %
    % Acceleration over x,y,z coordinates
    xyz_gyro = table2array(varfun(@(x) str2double(x),...
               Data_table(logical(sensors_indexes_T.gyroscope),logical(coordinates_cols))));
    gyro_table = Data_table(logical(sensors_indexes_T.gyroscope),:);
    
    % Find events in early or late in the day
    late_gyro_count  = unique(hour(gyro_table.datetime)) > 22;
    early_gyro_count = unique(hour(gyro_table.datetime)) < 6;
    late_gyro_time   = find(hour(gyro_table.datetime) > 22);
    early_gyro_time  = find(hour(gyro_table.datetime) < 6);
    
% 1. peak gyroscope feature------------------------------------------------
    % Set the mean of maximum over x,y,z axises
    max_gyro = mean(max(abs(xyz_gyro))); 
    if isempty(max_gyro) || max(isnan(max_gyro))
        max_gyro = 0;
    end
    features = [features max_gyro];
 
% 2. std gyroscope feature-------------------------------------------------
    % Set the mean of standard deviation xyz_gyro over x,y,z axises
    std_gyro = mean(std(xyz_gyro));
    if isempty(std_gyro) || max(isnan(std_gyro))
        std_gyro = 0;
    end
    features = [features std_gyro];

% 3. crazy hours gyroscope deviation features------------------------------
    late_gyro_deviation = mean(std(xyz_gyro(late_gyro_time)));
    if isnan(late_gyro_deviation) || isempty(late_gyro_deviation)
        late_gyro_deviation = 0;
    end

    early_gyro_deviation = mean(std(xyz_gyro(early_gyro_time)));
    if isnan(early_gyro_deviation) || isempty(early_gyro_deviation)
        early_gyro_deviation = 0;
    end

% 4. crazy hours gyroscope max features------------------------------------
    late_gyro_max = max(std(xyz_gyro(late_gyro_time)));
    if isnan(late_gyro_max) || isempty(late_gyro_max)
        late_gyro_max = 0;
    end

    early_gyro_max = max(std(xyz_gyro(early_gyro_time)));
    if isnan(early_gyro_max) || isempty(early_gyro_max)
        early_gyro_max = 0;
    end

% 5. crazy hours gyroscope time features-----------------------------------    
    if isempty(late_gyro_time) || numel(late_gyro_time)==1
        late_gyro_time = 0;
    else
        late_gyro_time = abs(hours(gyro_table.datetime(late_gyro_time(1))-...
                                     gyro_table.datetime(late_gyro_time(end))));
    end
    
    if isempty(early_gyro_time) || numel(early_gyro_time)==1
       early_gyro_time = 0;
    else
        early_gyro_time = abs(hours(gyro_table.datetime(early_gyro_time(1))-...
                                      gyro_table.datetime(early_gyro_time(end))));
    end

    features = [features, sum(late_gyro_count) ,...
                          sum(early_gyro_count),...
                          late_gyro_time       ,...
                          early_gyro_time      ,...
                          early_gyro_deviation ,...
                          late_gyro_deviation  ,...
                          early_gyro_max       ,...
                          late_gyro_max       ];


% ============================ light features =========================== %
    light_table = Data_table(logical(sensors_indexes_T.light),:);
    
    % Load illumination level over time
    illumination_level = cellfun(@(x) str2double(x),light_table.value);

% 1. Max illumination features---------------------------------------------
    [max_light, max_light_idx] = max(illumination_level);         % max illumination
    if isempty(max_light)
        max_light      = 0;
        max_light_time = 0;
    else
        max_light_time = hour(light_table(max_light_idx,:).datetime); % time of max illumination
    end
    
    features = [features max_light max_light_time];


% =========================== location features ========================= %
    location_table = Data_table(logical(sensors_indexes_T.location),:);
    
    % Traveling distance vector throughout the day
    traveling_dist = cellfun(@(x) str2double(x),location_table.value);
    traveling_dist(isnan(traveling_dist)) = 0;

    % GPS accuracy data
    gps_accuracy       = location_table.level;
    accuracy_threshold = 20; % Threshold for low GPS signal accuracy

% 1. time spent with GPS accuracy features---------------------------------
    % Total high and low GPS accuracy occurances precentage
    high_acc_GPS = sum(gps_accuracy <= accuracy_threshold)/numel(gps_accuracy);
    low_acc_GPS  = sum(gps_accuracy >  accuracy_threshold)/numel(gps_accuracy);
    
    % Total low GPS accuracy time throught the day
    low_acc_events = []; counter = 0;
    low_acc_idx = (gps_accuracy > accuracy_threshold)==1;
    if ~isempty(low_acc_idx)
        i = 1;
        j = 1+1;
        while i <= length(low_acc_idx) && j <= length(low_acc_idx) 
            % Checks wheter the current event is different from the
            % required, and that the previous event was indeed the event
            % the algorithm looking for. (Also address edge cases)
            if (~ismember(j,find(low_acc_idx)) && ismember(j-1,find(low_acc_idx))) || (j == length(low_acc_idx) && low_acc_idx(j-1))
                low_acc_events = [low_acc_events, abs(hours(...
                                                  location_table.datetime(j)-...
                                                  location_table.datetime(i)))];
                i=j;
            end

            % Counter deal with event of only one concecutive event, which
            % will eliminate counting throughout the data while the event is absent 
            if ~ismember(j-1,find(low_acc_idx))
                counter = counter + 1;
            end
            if counter == 2
                counter = 0;
                i=j;
            end
            j=j+1;
        end
    end
    
    features = [features mean(low_acc_events),...
                         std( low_acc_events),...
                         sum( low_acc_events),...
                         high_acc_GPS        ,...
                         low_acc_GPS         ];


% 2. traveling distance features-------------------------------------------
    total_travel = sum(traveling_dist);
    mean_travel  = mean(traveling_dist);
    std_travel   = std(traveling_dist);
    
    % Find all the traveling distance before 6 a.m.
    travel_crazy_hours = sum(traveling_dist(hour(location_table.datetime) < 6));

    features = [features total_travel      ,...
                         mean_travel       ,...
                         std_travel        ,...
                         travel_crazy_hours];

% ======================== magnetic field features ====================== %
    magnet_table = Data_table(logical(sensors_indexes_T.magnetic_field),:);
    xyz_magnet = table2array(varfun(@(x) str2double(x),...
           Data_table(logical(sensors_indexes_T.magnetic_field),logical(coordinates_cols))));
    
    % Find events in early or late in the day
    late_magnet_count  = unique(hour(magnet_table.datetime)) > 22;
    early_magnet_count = unique(hour(magnet_table.datetime)) < 6;
    late_magnet_time   = find(hour(magnet_table.datetime) > 22);
    early_magnet_time  = find(hour(magnet_table.datetime) < 6);
    
% 1. peak Magnetic field feature-------------------------------------------
    % Set the mean of maximum over x,y,z axises
    max_magnet = mean(max(abs(xyz_magnet))); 
    if isempty(max_magnet) || max(isnan(max_magnet))
        max_magnet = 0;
    end
    features = [features max_magnet];
 
% 2. std Magnetic field feature--------------------------------------------
    % Set the mean of standard deviation xyz_magnet magnet field over x,y,z axises
    std_magnet = mean(std(xyz_magnet));
    if isempty(std_magnet) || max(isnan(std_magnet))
        std_magnet = 0;
    end
    features = [features std_magnet];

% 3. crazy hours Magnetic field deviation features-------------------------
    late_magnet_deviation = mean(std(xyz_magnet(late_magnet_time)));
    if isnan(late_magnet_deviation) || isempty(late_magnet_deviation)
        late_magnet_deviation = 0;
    end

    early_magnet_deviation = mean(std(xyz_magnet(early_magnet_time)));
    if isnan(early_magnet_deviation) || isempty(early_magnet_deviation)
        early_magnet_deviation = 0;
    end

% 4. crazy hours Magnetic field max features-------------------------------
    late_magnet_max = max(std(xyz_magnet(late_magnet_time)));
    if isnan(late_magnet_max) || isempty(late_magnet_max)
        late_magnet_max = 0;
    end

    early_magnet_max = max(std(xyz_magnet(early_magnet_time)));
    if isnan(early_magnet_max) || isempty(early_magnet_max)
        early_magnet_max = 0;
    end

% 5. crazy hours Magnetic field time features------------------------------    
    if isempty(late_magnet_time) || numel(late_magnet_time)==1
        late_magnet_time = 0;
    else
        late_magnet_time = abs(hours(magnet_table.datetime(late_magnet_time(1))-...
                                     magnet_table.datetime(late_magnet_time(end))));
    end
    
    if isempty(early_magnet_time) || numel(early_magnet_time)==1
       early_magnet_time = 0;
    else
        early_magnet_time = abs(hours(magnet_table.datetime(early_magnet_time(1))-...
                                      magnet_table.datetime(early_magnet_time(end))));
    end

    features = [features, sum(late_magnet_count) ,...
                          sum(early_magnet_count),...
                          late_magnet_time       ,...
                          early_magnet_time      ,...
                          early_magnet_deviation ,...
                          late_magnet_deviation  ,...
                          early_magnet_max       ,...
                          late_magnet_max       ];


% ============================= screen features ========================= %
    % Find screen time
    screen_table = Data_table(logical(sensors_indexes_T.screen),:);
    screen_state = cellfun(@(x) strcmp(x, 'on'),screen_table.sensor_status);

% 1. screen time features--------------------------------------------------
    screen_time = []; counter = 0;
    screen_on = find(screen_state==1);
    if ~isempty(screen_on)
        i = 1;
        j = 1+1;
        while i <= length(screen_state) && j <= length(screen_state) 
            % Checks wheter the current event is different from the
            % required, and that the previous event was indeed the event
            % the algorithm looking for. (Also address edge cases)
            if (~ismember(j,screen_on) && ismember(j-1,screen_on)) || (j == length(screen_state) && screen_state(j-1))
                screen_time = [screen_time, abs(hours(...
                                            screen_table.datetime(j)-...
                                            screen_table.datetime(i)))];
                i=j;
            end

            % Counter deal with event of only one concecutive event, which
            % will eliminate counting throughout the data while the event is absent 
            if ~ismember(j-1,screen_on)
                counter = counter + 1;
            end
            if counter == 2
                counter = 0;
                i=j;
            end
            j=j+1;
        end
    end
    
    features = [features mean(screen_time),...
                         std( screen_time),...
                         sum( screen_time)];
    
% 2. Find screen time between 00:00-4:59-----------------------------------
    crazy_hours    = find(hour(screen_table.datetime) < 5 );
    crazy_hours_on = find(hour(screen_table.datetime) < 5 & screen_state);
    screen_time_from12 = 0; counter = 0;
    
    if ~isempty(crazy_hours_on)
        i = 1;
        j = 2;
        while i <= length(crazy_hours) && j <= length(crazy_hours)
            % Checks wheter the current event is different from the
            % required, and that the previous event was indeed the event
            % the algorithm looking for. (Also address edge cases)
            curr_event = crazy_hours(j);
            if (~ismember(curr_event,crazy_hours_on) && ismember(crazy_hours(j-1),crazy_hours_on)) || (j == length(crazy_hours) && ismember(curr_event,crazy_hours_on))
                screen_time_from12 = screen_time_from12 + abs(hours(...
                                                          screen_table.datetime(crazy_hours(j))-...
                                                          screen_table.datetime(crazy_hours(i))));
                i=j;
            end

            % Counter deal with event of only one concecutive event, which
            % will eliminate counting throughout the data while the event is absent 
            if ~ismember(crazy_hours(j-1),crazy_hours_on)
                counter = counter + 1;
            end
            if counter == 2
                counter = 0;
                i=j;
            end            
            j=j+1;
        end
    end
    
    features = [features  screen_time_from12];


% ============================== wifi features ========================== %
    wifi_table = Data_table(logical(sensors_indexes_T.wifi),:);
    wifi_level = wifi_table.level;
    b_signal_thresh = -50;

% 1. signal strength features----------------------------------------------
    features = [features mean(wifi_level(~isnan(wifi_level)))]; % mean signal strength throughout the day
    features = [features std( wifi_level(~isnan(wifi_level)))]; % std  signal strength throughout the day

% 2. Strong signal time features-------------------------------------------
    find_confines = diff([0, diff(find(wifi_level > b_signal_thresh))'==1, 0]);
    start_strong_signal = find(find_confines == -1);
    end_strong_signal   = find(find_confines == 1);

     % the following section checks for inconsistencies and match edge cases
     if length(start_strong_signal) < length(end_strong_signal)
        start_strong_signal = [start_strong_signal, size(find_confines,1)];
    
     elseif length(start_strong_signal) > length(end_strong_signal)
         end_strong_signal = [1, end_strong_signal];
     end
    
     % Calculate time of strong signal
     if isempty(start_strong_signal) && isempty(end_strong_signal)
        strong_signal_time = 0;
    else
        strong_signal_time = zeros(1, numel(start_strong_signal));
        for i = 1:numel(start_strong_signal)
            strong_signal_time(i) = abs(hours(... 
                                  wifi_table.datetime(start_strong_signal(i))-...
                                  wifi_table.datetime(end_strong_signal(i))   ...
                                  ));   
        end
     end

 % 3. number of unique devices feature-------------------------------------
    unique_wifi_devices = unique(wifi_table.suuid);

    features = [features mean(strong_signal_time   )]; % mean  time of strong signal
    features = [features sum(strong_signal_time    )]; % total time of strong signal
    features = [features length(strong_signal_time )]; % number of events of strong signal
    features = [features numel(unique_wifi_devices) ]; % number unique wifi devices
  

% ============================= calls features ========================== %
    calls_table = Data_table(logical(sensors_indexes_T.calls),:);

    total_calls     = size(calls_table,1);
    incoming_calls  = cellfun(@(x) strcmpi(x, 'incoming'), calls_table.sensor_status);
    outgoing_calls  = cellfun(@(x) strcmpi(x, 'outgoing'), calls_table.sensor_status);
    missed_calls    = cellfun(@(x) strcmpi(x, 'missed'  ), calls_table.sensor_status);
    rejected_calls  = cellfun(@(x) strcmpi(x, 'rejected'), calls_table.sensor_status);
    unique_contacts = unique(calls_table.suuid);

% 1. number of calls features----------------------------------------------
    features = [features total_calls           ,...
                         numel(unique_contacts),...
                         sum(rejected_calls)   ,...
                         sum(missed_calls)     ,...
                         sum(incoming_calls)+  ...
                         sum(outgoing_calls)   ];

 % 2. durations features---------------------------------------------------
    calls_durations = [calls_table(incoming_calls,:).level',... 
                       calls_table(outgoing_calls,:).level'];
    if isempty(calls_durations)
        calls_durations = 0;
    end

    features = [features sum( calls_durations),...
                         std( calls_durations),...
                         mean(calls_durations)];

 % 3. calls in crazy hours features----------------------------------------
    crazy_hours_calls    = hour(calls_table.datetime) < 6 & (outgoing_calls | incoming_calls);
    crazy_hours_air_time = calls_table(crazy_hours_calls,:).level;
    
    features = [features sum( crazy_hours_air_time),...
                         std( crazy_hours_air_time),...
                         mean(crazy_hours_air_time)];


% =========================== timezone features ========================= %
    unique_timezones = unique(Data_table.timezone);
    
    features = [features numel(unique_timezones)];
    

    features(isnan(features)) = 0;
end


    