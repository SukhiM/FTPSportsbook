from pyspark.sql import SparkSession
from pyspark.ml.feature import VectorAssembler
from pyspark.ml.classification import RandomForestClassifier
import pandas as pd
from pyspark.ml.evaluation import BinaryClassificationEvaluator
from sklearn.metrics import classification_report
import csv


# # Create a new csv and transform the "B" and "M" string values of diagnosis into 0 and 1 since RandomForest/Decision Tree models take only numerical output
# df = pd.read_csv("2019-20_pbp.csv")

# # Get the unique values in the 'URL' column
# unique_urls = df['URL'].unique()

# # Create a new empty DataFrame to store the results
# new_df = pd.DataFrame(columns=['HomeTeam', 'AwayTeam', 'WinningTeam'])

# # Iterate over the unique URLs and append the first row of each URL to the new DataFrame
# for url in unique_urls:
#     row = df[df['URL'] == url].iloc[0]
#     new_df = new_df.append(row, ignore_index=True)

# df = new_df[['HomeTeam', 'AwayTeam', 'WinningTeam']] # Prints unique rows correctly - output checked



# # Change the string variable team names to integer values for the Random Forest Model to be able to interpret
# df2 = df
# df2["HomeTeam"] = df2["HomeTeam"].replace({"TOR": 0, "LAC": 1, "CHO": 2, "IND": 3, "ORL": 4, "BRK": 5, "MIA": 6, "PHI": 7, "DAL": 8, "SAS": 9, "UTA": 10, "PHO": 11, "POR": 12, "DET": 13, "HOU": 14, "GSW": 15, "BOS": 16, "MEM": 17, "NOP": 18, "OKC": 19, "DEN": 20, "SAC": 21, "LAL": 22, "MIL": 23, "ATL": 24, "NYK": 25, "CHI": 26, "CLE": 27, "MIN": 28, "WAS": 29})
# df2["AwayTeam"] = df2["AwayTeam"].replace({"TOR": 0, "LAC": 1, "CHO": 2, "IND": 3, "ORL": 4, "BRK": 5, "MIA": 6, "PHI": 7, "DAL": 8, "SAS": 9, "UTA": 10, "PHO": 11, "POR": 12, "DET": 13, "HOU": 14, "GSW": 15, "BOS": 16, "MEM": 17, "NOP": 18, "OKC": 19, "DEN": 20, "SAC": 21, "LAL": 22, "MIL": 23, "ATL": 24, "NYK": 25, "CHI": 26, "CLE": 27, "MIN": 28, "WAS": 29})
# df2["WinningTeam"] = df2["WinningTeam"].replace({"TOR": 0, "LAC": 1, "CHO": 2, "IND": 3, "ORL": 4, "BRK": 5, "MIA": 6, "PHI": 7, "DAL": 8, "SAS": 9, "UTA": 10, "PHO": 11, "POR": 12, "DET": 13, "HOU": 14, "GSW": 15, "BOS": 16, "MEM": 17, "NOP": 18, "OKC": 19, "DEN": 20, "SAC": 21, "LAL": 22, "MIL": 23, "ATL": 24, "NYK": 25, "CHI": 26, "CLE": 27, "MIN": 28, "WAS": 29})
# df2.to_csv("encoded_data.csv")

# Use the modified csv for model creation
spark = SparkSession.builder.getOrCreate() # Create a Spark Session
df = spark.read.csv("encoded_data.csv", inferSchema=True, header=True) # Loads in csv file
# df.show() # For testing, shows csv

# Create a vector of all column types except for the target column, output them as "features"
assembler = VectorAssembler(inputCols= ["HomeTeam", "AwayTeam"],
                                        outputCol="features")

output = assembler.transform(df) # Adds the features column
model_df = output.select(["features", "WinningTeam"]) # Makes a seperate dataframe that only has the features column and target variable column

training_df, test_df = model_df.randomSplit([0.7, 0.3]) # Split the training and testing sets
#Create the RandomForest model using the training set
rf_classifier = RandomForestClassifier(labelCol="WinningTeam",
                                       numTrees=50).fit(training_df)
rf_predictions = rf_classifier.transform(test_df) # Use the testing set to test the model's accuracy
print("Random Forest Model Predictions: ")
print(rf_predictions.show()) # Print results of accuracy



# Accuracy Evaluation

RF_predictions = rf_predictions.select("prediction")
RF_actual = rf_predictions.select("WinningTeam")
# Convert the columns to arrays : This looks at the underlying Spark RDD which is the format of rf_predictions 
# and applies a lambda function to it that just returns the values of the WinningTeam/prediction columns, allowing 
# the given column to be collected into the corresponding variable
RF_predictions = RF_predictions.rdd.flatMap(lambda row: row).collect()
RF_actual = RF_actual.rdd.flatMap(lambda row: row).collect()

# Print precision, recall, and f1 Score
print("Random Forest Model Accuracy: ")
print(classification_report(RF_actual, RF_predictions))


# Write results of all matchups including probability into csv file

# Create a list of all possible matchups

# with open("all_combinations.csv", "a", newline="") as f:
#     writer = csv.writer(f)
#     writer.writerow(["", "HomeTeam", "AwayTeam", "WinningTeam"]) # Same format as encoded_data.csv so I can use the same process to run the model on it
#     for i in range(30):
#         for j in range(30):
#             if i != j:
#                 writer.writerow([i, j, i]) # Correct output; winningteam doesnt matter here since I'm only taking prediction and probability not accuracy


spark_pred = SparkSession.builder.getOrCreate() # Create a Spark Session
df_pred = spark_pred.read.csv("all_combinations.csv", inferSchema=True, header=True) # Loads in csv file

# Create a vector of all column types except for the target column, output them as "features"
assembler_pred = VectorAssembler(inputCols= ["HomeTeam", "AwayTeam"],
                                        outputCol="features")

output_pred = assembler.transform(df_pred) # Adds the features column
model_df_pred = output.select(["features", "WinningTeam"]) # Makes a seperate dataframe that only has the features column and target variable column

pred = rf_classifier.transform(model_df_pred) # Running the model on every team combination
print(pred.show())

RF_predictions = pred.select("prediction")
RF_predictions = RF_predictions.rdd.flatMap(lambda row: row).collect()
RF_probability = pred.select("probability")
RF_probability = RF_probability.rdd.flatMap(lambda row: row).collect() # Take all probability values as well
RF_features = pred.select("features")
RF_features = RF_features.rdd.flatMap(lambda row: row).collect() # Take the features list for both teams playing

teams = { # Teams substitution matrix to make the ints go back to team names
  0: "TOR",
  1: "LAC",
  2: "CHO",
  3: "IND",
  4: "ORL",
  5: "BRK",
  6: "MIA",
  7: "PHI",
  8: "DAL",
  9: "SAS",
  10: "UTA",
  11: "PHO",
  12: "POR",
  13: "DET",
  14: "HOU",
  15: "GSW",
  16: "BOS",
  17: "MEM",
  18: "NOP",
  19: "OKC",
  20: "DEN",
  21: "SAC",
  22: "LAL",
  23: "MIL",
  24: "ATL",
  25: "NYK",
  26: "CHI",
  27: "CLE",
  28: "MIN",
  29: "WAS"
}


# Write the prediction to the CSV file
with open("predictions.csv", "a", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["HOMETEAM", "AWAYTEAM", "PREDICTEDWINNER", "PROBABILITY"])
    for i in range(len(RF_probability)):
        writer.writerow([teams[RF_features[i][0]], teams[RF_features[i][1]], teams[RF_predictions[i]], format(RF_probability[i], '.2f')])


print('Predicted winner between {} vs. {}: {} with a probability of {}'.format(teams[RF_features[i][0]], teams[RF_features[i][1]], teams[RF_predictions[i]], format(RF_probability[i], '.2f')))


