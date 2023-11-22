/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */
import {onRequest} from "firebase-functions/v2/https";
import {getFirestore} from "firebase-admin/firestore";
import * as admin from "firebase-admin";
import * as cors from "cors";

import {tmpdir} from "os";
import {join} from "path";
import {promises as fs} from "fs";

import {initializeApp} from "firebase-admin/app";

const corsHandler = cors({origin: true});
initializeApp();

const sportsRadarNBAKey = "pdmqy8pxggcnh6ejjbe8mdsz";
// const oddsKey = "ea24407b8b130f7a2b2a3bf7401fe267";

// Loads NBA Game data from SportsRadar API and stores in Firestore
export const loadNBAGames = onRequest(async (request, response) => {
  const formatDate = (date: Date): string => {
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).
      toString().padStart(2, "0"); // Months are 0-based, hence +1
    const day = date.getDate().toString().padStart(2, "0");

    return `${year}/${month}/${day}`;
  };

  let passedDate: Date;
  if (!request.body.date) {
    passedDate = new Date();
  } else {
    passedDate = new Date(request.body.date);
  }
  const reqDate = formatDate(passedDate);
  const resp: any = await fetch("http://api.sportradar.us/nba/trial/v8/en/games/" +
    reqDate + "/schedule.json?api_key=" + sportsRadarNBAKey);
  const json = await resp.json();
  const date = json.date;
  const gamesArr = json.games;

  const nbaGamesCollection = getFirestore().collection("nba_games")
    .doc(date).collection("games");

  for (const game of gamesArr) {
    const homeTeam = game.home.alias;
    const awayTeam = game.away.alias;
    const gameID = game.id;
    const status = game.status;
    nbaGamesCollection.doc(gameID).set({
      date: date,
      time: game.scheduled,
      home: homeTeam,
      away: awayTeam,
      id: gameID,
      status: status,
    });
  }
  response.status(200).send();
});

// Returns NBA Game data from Firestore for a given date
export const getNBAGames = onRequest(async (request, response) => {
  corsHandler(request, response, async () => {
    /*
    TODO:
    - Get the date from the request
    - Query Firestore for games on date
    - Return the games
    */

    const gamesList: any = [];

    // Date will be changed to be read from request body
    const date = request.body.date;
    const nbaGamesCollection = getFirestore().collection("nba_games")
      .doc(date).collection("games").get();
    (await nbaGamesCollection).forEach((doc) => {
      const gameData = doc.data();
      gameData.gameID = doc.id;
      gamesList.push(gameData);
    });

    response.send(gamesList);
  });
});

// Places a bet for a user on a game and stores in user's history
export const placeBet = onRequest(async (request, response) => {
  corsHandler(request, response, async () => {
    const uid = request.body.uid;
    if (!uid) {
      response.status(400).send("No user ID provided");
      return;
    }

    const gameID = request.body.gameID;
    if (!gameID) {
      response.status(400).send("No game ID provided");
      return;
    }

    const team = request.body.team;
    if (!team) {
      response.status(400).send("No team provided");
      return;
    }

    const amount = Number(request.body.amount);
    if (!amount) {
      response.status(400).send("No amount provided");
      return;
    }

    try {
      const db = getFirestore();

      // Start a transaction to ensure atomic read and write operations
      await db.runTransaction(async (transaction) => {
        const userRef = db.collection("users").doc(uid);

        // Get the user's current balance by retrieving the snapshot first
        const userSnapshot = await transaction.get(userRef);
        const userData = userSnapshot.data();

        const userBalance = userData!.balance;

        // Check if the balance is sufficient for the bet
        if (userBalance < amount) {
          response.status(400).send("Insufficient balance");
          return;
        }

        const newBetRef = userRef.collection("bet_history").doc();

        // Deduct the bet amount from the user's balance & add to history
        transaction.update(userRef, {balance: userBalance - amount});
        transaction.set(newBetRef, {
          gameID: gameID,
          amount: amount,
          team: team,
          matchup: request.body.matchup,
          placedAt: admin.firestore.FieldValue.serverTimestamp(),
          // include other bet details as necessary
        });
        db.collection("pending_bets").doc().set({
          betRef: newBetRef,
          uid: uid,
        });
      });

      const username = (await db.collection("users")
        .doc(uid).get()).data()!.username;
      const globalFeedRef = getFirestore().collection("global_feed");
      globalFeedRef.add({
        username: username,
        team: team,
        matchup: request.body.matchup,
        placedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // If the transaction completes successfully, send back a success message
      response.status(200).send("Bet placed successfully");
    } catch (error) {
      console.error("Transaction failure:", error);
      response.status(500).send("Transaction failure");
    }

    response.status(200).send();
  });
});

export const testHTTP = onRequest(async (request, response) => {
  response.send("Works");
});

export const importPredictionsJSONtoFirestore =
  onRequest(async (request, response) => {
    const bucketName = "ftp-sportsbook.appspot.com";
    const filePath = "predictions.json";
    const bucket = admin.storage().bucket(bucketName);

    const tempFilePath = join(tmpdir(), "predictions.json");

    // Download the file from the storage bucket.
    try {
      await bucket.file(filePath).download({
        destination: tempFilePath,
      });

      // Read the JSON file.
      const fileContent = await fs.readFile(tempFilePath, "utf8");
      const predictionsArray = JSON.parse(fileContent);

      // Loop through the array of predictions.
      for (const prediction of predictionsArray) {
        const {HOMETEAM, AWAYTEAM, PREDICTEDWINNER, PROBABILITY} = prediction;

        // Firestore write.
        await admin.firestore()
          .collection("predictions")
          .doc(HOMETEAM)
          .collection("AWAYTEAMS")
          .doc(AWAYTEAM)
          .set({
            predictedWinner: PREDICTEDWINNER,
            probability: PROBABILITY,
          });
      }

      // Clean up the temporary file.
      await fs.unlink(tempFilePath);

      response.send("JSON imported to Firestore successfully.");
    } catch (error) {
      console.error("JSON import failed:", error);
      response.status(500).send("Internal Server Error");
    }
  });
