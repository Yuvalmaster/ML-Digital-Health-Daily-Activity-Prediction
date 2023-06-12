# Predicting Users' Daily Activities using Smartphone Sensor Data 📱🏃
This repository showcases a project that focuses on predicting users' daily activities using data collected from multiple sensors in smartphones. The project utilizes machine learning techniques to analyze the sensor data, provide insights into users' behavior patterns, and predict their level of activity at each day.

## Project Overview
The main objective of this project is to leverage the rich sensors data available on smartphones to gain insights into users' daily activities. By analyzing this data, the project aims to predict the level of activity performed each day by users. This prediction can provide valuable information for applications in health monitoring, behavior analysis, and personalized services.

## Implementation Details
The entire project is implemented in MATLAB. The MATLAB code is structured and organized within the repository's folder structure, with the necessary functions and scripts contained in the Functions folder.

To ensure accurate activity prediction, the project follows a systematic approach that consists of several key steps. These steps include data sampling, filtering, event triggering, feature extraction, feature selection, and classification.

The first step is data sampling, where sensors data from smartphones are collected to capture the users' movements and behavior over long period of time. This raw data is then processed using filtering techniques to remove noise, artifacts, and irrelevant information.

Event triggering mechanisms are employed to detect specific patterns or transitions within the processed data. These triggers help in segmenting the data into meaningful units corresponding to different activities. This segmentation is crucial for subsequent analysis and prediction.

Feature extraction techniques are then applied to the segmented data to extract meaningful information. Various time-domain and frequency-domain features are computed from each sensor. Additionally, feature selection methods are employed to identify the most relevant features that contribute significantly to the prediction accuracy.

Finally, the processed data, along with the extracted features, are used to train a classification model.

## Repository Structure
Here is an overview of the repository's main components:

* Functions: This folder contains all the necessary MATLAB functions and scripts required for data processing, feature extraction, feature selection, and classification. These functions are carefully organized to ensure modularity and reusability.

* Data Folder: To access the data required for this project, please send me an email. Upon request, a link will be provided to access the Data folder, which contains the raw sensor data collected from the wearable device.

* Train Folder: The Train folder includes preprocessed data that has undergone the necessary steps of sampling, filtering, event triggering, and feature extraction. This data is utilized to train the classification model.

* Test Folder: The Test folder comprises separate datasets used for evaluating the trained classification model's performance. These datasets contain unseen samples of sensor data, and the model's predictions are compared with ground truth labels to assess its accuracy.

## Accessing the Repository
To access the data required for this project, including the Data, Train, and Test folders, please send me an email, and I will be glad to provide you with a link that includes all the files. Accessing these folders will allow you to explore the dataset used for training and testing the activity prediction model.

Feel free to navigate through the repository, explore the project details, and review the MATLAB code. If you have any questions or require additional information, please don't hesitate to contact me.

Note: Due to the sensitivity and size of the data, access to the Data, Train, and Test folders is granted upon request to ensure its proper usage and privacy.
