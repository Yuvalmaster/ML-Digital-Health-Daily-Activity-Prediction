function [data_files_name, raw_data, Label_data] = Extract_data(data_dir)
% This function load the raw data and prepare it for munipulation.
%% FILE NAMES EXTRACTION
    d_files = dir(data_dir);
    files   = {d_files.name};
    
    % Extract Files names
    h = waitbar(0,'Loading Data - Please wait');
    data_files = {}; Label_files = {};
    for i=1:length(files)

       if contains(files(i),'csv')
           data_files  = [data_files   ; files{i}];

       elseif contains(files(i),'xlsx')
           Label_files = [Label_files  ; files{i}];

       end
       waitbar(i / size(length(files),1))
    end
    close(h)

    % Data Table of Files names
    data_files_name = table(data_files, Label_files);
    
%% DATA EXTRACTION
    % Extract data from each file
    h = waitbar(0,'Extracting Data - Please wait');
    raw_data = {}; Label_data = {};
    for i=1:size(data_files_name,1)

        Data_S = readtable([data_dir  '\'  data_files_name.data_files{i,:}],'Format','auto');
        Data_T = readtable([data_dir  '\'  data_files_name.Label_files{i,:}],'Format','auto','VariableNamingRule', 'preserve');

        raw_data{i}   = Data_S;
        Label_data{i} = Data_T;
        
        waitbar(i / size(data_files_name,1))
    end
    close(h)
end


