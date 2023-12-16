import pandas as pd
import numpy as np
import csv
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression

class NBAResultsPredictor:
    # Defines df and df2 as properties of "self" that can be used later in other functions
    def __init__(self):
        self.df = pd.read_csv("2019-20_pbp.csv")

        # Get the unique values in the 'URL' column
        unique_urls = self.df['URL'].unique()

        # Create a new empty DataFrame to store the results
        new_df = pd.DataFrame(columns=['HomeTeam', 'AwayTeam', 'WinningTeam'])

        # Iterate over the unique URLs and append the first row of each URL to the new DataFrame
        for url in unique_urls:
            row = self.df[self.df['URL'] == url].iloc[0]
            new_df = new_df.append(row, ignore_index=True)

        self.df = new_df[['HomeTeam', 'AwayTeam', 'WinningTeam']] # Prints unique rows correctly - output checked
        self.df = self.df.append(self.df)

        # Array of all unique team names
        self.df3 = pd.Series(self.df['HomeTeam'].unique())
        # print(self.df3) #Prints 30 unique teams - correct output checked

        # The LogisticRegression model only takes float values so I use the unique index from the array of unique teams to represent both teams
        self.df.loc[:, 'HomeTeam'] = self.df['HomeTeam'].apply(lambda x: float(np.where(self.df3.values == x)[0][0]))
        self.df.loc[:, 'AwayTeam'] = self.df['AwayTeam'].apply(lambda x: float(np.where(self.df3.values == x)[0][0]))
        self.df.loc[:, 'WinningTeam'] = self.df['WinningTeam'].apply(lambda x: float(np.where(self.df3.values == x)[0][0]))




    def train_model(self):
        # Split the training data into training and testing sets
        # Two columns that determine the result, column that acts as a target for the model to predict, percent of sample that's used for testing vs training (here 15%), and a seed for the random
        # number generator that ensures you get the same split every time you run the code
        X_train, X_test, y_train, y_test = train_test_split(np.array(self.df[['HomeTeam', 'AwayTeam']]), np.array(self.df[['WinningTeam']]), test_size=0.15, random_state=42)


        # Train the model on the scaled data
        self.model = LinearRegression().fit(X_train, y_train)

        # Test the accuracy of the model
        test_accuracy = self.model.score(X_test, y_test)
        print("Test Accuracy:", test_accuracy)



    def predict_winning_team(self, home_team, away_team):

        # Create a new DataFrame with the team indices
        new_df = np.array([home_team, away_team])

        new_df = new_df.reshape(1, -1)

        # Predict the winning team
        prediction = self.model.predict(new_df)

        prediction = prediction[0][0] # Extract result from multi-dimensional array
        confidence = prediction - round(prediction)

        if(confidence < 0.5): # Make sure confidence value is always looking at chance of winning team winning not losing team losing
            confidence = 1 - confidence
        if(confidence > 1):
            confidence = 0.99
        confidence = confidence * 100

        if (abs(prediction - home_team) < abs(prediction - away_team)):
            array = [home_team, confidence]
        else:
            array = [away_team, confidence]
        return array
    

        
    def predict_for_all(self):
        # Create a list of all possible matchups
        c = 0
        # Create csv file, add first row
        with open("predictions.csv", "a", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["HOMETEAM", "AWAYTEAM", "PREDICTEDWINNER", "PROBABILITY"])
        for i in range(self.df3.size):
            for j in range(self.df3.size): # range is correct, 870 outputs for 30 teams is every combination
                if i != j:
                    c = c + 1
                    # Write the prediction to the CSV file
                    with open("predictions.csv", "a", newline="") as f:
                        writer = csv.writer(f)
                        output = self.predict_winning_team(i, j)
                        writer.writerow([self.df3[i], self.df3[j], self.df3[output[0]], format(output[1], '.2f')])
                    print('Predicted winner between {} vs. {}: {} with a probability of {}'.format(self.df3[i], self.df3[j], self.df3[output[0]], format(output[1], '.2f')))

        print("Total count")
        print(c)


# Example usage:

# Create a predictor object
predictor = NBAResultsPredictor()

# Train the model
predictor.train_model()

predictions = predictor.predict_for_all()
