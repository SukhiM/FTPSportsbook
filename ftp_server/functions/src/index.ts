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
const oddsKey = "ea24407b8b130f7a2b2a3bf7401fe267";
const oddsURL = `https://api.the-odds-api.com/v4/sports/basketball_nba/odds/?regions=us&oddsFormat=american&bookmakers=fanduel&apiKey=${oddsKey}`;

const nbaTeamsMap = new Map<string, string>([
  ["Atlanta Hawks", "ATL"],
  ["Boston Celtics", "BOS"],
  ["Brooklyn Nets", "BKN"],
  ["Charlotte Hornets", "CHA"],
  ["Chicago Bulls", "CHI"],
  ["Cleveland Cavaliers", "CLE"],
  ["Dallas Mavericks", "DAL"],
  ["Denver Nuggets", "DEN"],
  ["Detroit Pistons", "DET"],
  ["Golden State Warriors", "GSW"],
  ["Houston Rockets", "HOU"],
  ["Indiana Pacers", "IND"],
  ["Los Angeles Clippers", "LAC"],
  ["Los Angeles Lakers", "LAL"],
  ["Memphis Grizzlies", "MEM"],
  ["Miami Heat", "MIA"],
  ["Milwaukee Bucks", "MIL"],
  ["Minnesota Timberwolves", "MIN"],
  ["New Orleans Pelicans", "NOP"],
  ["New York Knicks", "NYK"],
  ["Oklahoma City Thunder", "OKC"],
  ["Orlando Magic", "ORL"],
  ["Philadelphia 76ers", "PHI"],
  ["Phoenix Suns", "PHX"],
  ["Portland Trail Blazers", "POR"],
  ["Sacramento Kings", "SAC"],
  ["San Antonio Spurs", "SAS"],
  ["Toronto Raptors", "TOR"],
  ["Utah Jazz", "UTA"],
  ["Washington Wizards", "WAS"],
]);

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
    let winner = null;

    if (status == "closed") {
      if (game.home_points > game.away_points) {
        winner = game.home.alias;
      } else {
        winner = game.away.alias;
      }
    }

    nbaGamesCollection.doc(gameID).set({
      date: date,
      time: game.scheduled,
      home: homeTeam,
      away: awayTeam,
      id: gameID,
      status: status,
      winner: winner,
    });
  }
  response.status(200).send();
});

// Returns NBA Game data from Firestore for a given date
export const getNBAGames = onRequest(async (request, response) => {
  corsHandler(request, response, async () => {
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

export const loadNBAOdds = onRequest(async (request, response) => {
  const extractDate = (dateString: string): string => {
    // Convert UTC timestamp to EST date
    const date = new Date(dateString);
    const estOffset = date.getTimezoneOffset() - 300;
    const estDate = new Date(date.getTime() + estOffset * 60000);

    const year = estDate.getFullYear();
    const month = (estDate.getMonth() + 1).toString().padStart(2, "0");
    const day = estDate.getDate().toString().padStart(2, "0");

    return `${year}-${month}-${day}`;
  };

  let json;
  const gamesUpdated = [];

  try {
    const resp: any = await fetch(oddsURL);
    json = await resp.json();
    const gamesArr = json;
    const nbaGamesCollection = getFirestore().collection("nba_games");

    for (const game of gamesArr) {
      const date = extractDate(game.commence_time);
      const homeTeam = game.home_team;
      const awayTeam = game.away_team;

      if (game.bookmakers.empty) {
        continue;
      }

      const dateRef = nbaGamesCollection.doc(date);
      const gameQuery = await dateRef.collection("games")
        .where("home", "==", nbaTeamsMap.get(homeTeam))
        .where("away", "==", nbaTeamsMap.get(awayTeam)).get();

      // Should only be one match for the query
      if (!gameQuery.empty) {
        const gameDoc = gameQuery.docs[0];
        const gameRef = gameDoc.ref;

        await gameRef.update({
          homeOdds: game.bookmakers[0].markets[0].outcomes[0].price,
          awayOdds: game.bookmakers[0].markets[0].outcomes[1].price,
        });
        gamesUpdated.push(gameRef.id);
      } else {
        continue;
      }
    }
  } catch (error) {
    response.status(500).send("Error loading NBA odds: " + error);
  }

  response.status(200).send(gamesUpdated);
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
    const date = request.body.date;
    if (!date) {
      response.status(400).send("No date provided");
      return;
    }

    try {
      const db = getFirestore();

      // Start a transaction to ensure atomic read and write operations
      await db.runTransaction(async (transaction) => {
        const userRef = db.collection("users").doc(uid);
        const gameRef = db.collection("nba_games").doc(date)
          .collection("games").doc(gameID);

        if (!gameRef) {
          response.status(400).send("Can't find the game referenced");
        }

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
        const pendingBetRef = db.collection("pending_bets").doc();
        const globalFeedPost = db.collection("global_feed").doc();

        // Deduct the bet amount from the user's balance & add to history
        transaction.update(userRef, {balance: userBalance - amount});
        transaction.set(newBetRef, {
          gameID: gameID,
          amount: amount,
          team: team,
          matchup: request.body.matchup,
          placedAt: admin.firestore.FieldValue.serverTimestamp(),
          status: "pending",
          feedPost: globalFeedPost,
          gameRef: gameRef,
        });

        await globalFeedPost.set({
          username: userData!.username,
          team: team,
          matchup: request.body.matchup,
          placedAt: admin.firestore.FieldValue.serverTimestamp(),
          betRef: newBetRef,
          type: "betslip",
        });
        await pendingBetRef.set({
          betRef: newBetRef,
          gameRef: gameRef,
          uid: uid,
        });
      });
      // If the transaction completes successfully, send back a success message
      response.status(200).send("Bet placed successfully");
    } catch (error) {
      console.error("Transaction failure:", error);
      response.status(500).send("Transaction failure: " + error);
    }

    response.status(200).send();
  });
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

// Updates games played for a date and runs through pending bets
export const updateDay = onRequest(async (request, response) => {
  corsHandler(request, response, async () => {
    const db = getFirestore();

    // Update status of games played
    const formatDate = (date: Date): string => {
      const year = date.getFullYear();
      const month = (date.getMonth() + 1).
        toString().padStart(2, "0"); // Months are 0-based, hence +1
      const day = date.getDate().toString().padStart(2, "0");

      return `${year}/${month}/${day}`;
    };

    const reqDate = new Date();
    reqDate.setDate(reqDate.getDate() - 1);
    const date = formatDate(reqDate);

    const resp: any = await fetch("http://api.sportradar.us/nba/trial/v8/en/games/" +
      date + "/schedule.json?api_key=" + sportsRadarNBAKey);
    const json = await resp.json();
    const gamesArr = json.games;

    const dbDateString = date.replace(/\//g, "-");

    const nbaGamesCollection = db.collection("nba_games")
      .doc(dbDateString).collection("games");

    for (const game of gamesArr) {
      try {
        const gameID = game.id;
        const status = game.status;
        let winner;

        if (status == "closed") {
          if (game.home_points > game.away_points) {
            winner = game.home.alias;
          } else {
            winner = game.away.alias;
          }
        } else {
          continue;
        }

        await nbaGamesCollection.doc(gameID).update({
          status: status,
          winner: winner,
        });
      } catch (error) {
        console.error("Error updating game: " + error);
        response.status(500).send("Error updating game: " + error);
      }
    }

    // Handle pending bets
    const pendingBets = await db.collection("pending_bets").get();
    for (const bet of pendingBets.docs) {
      try {
        const pendingBetData = bet.data();
        const gameSnapshot = await pendingBetData.gameRef.get();
        const gameData = gameSnapshot.data();
        if (gameData.status != "closed") {
          continue;
        }
        if (!pendingBetData.gameRef) {
          response.send("gameRef is undefined").status(403);
        }

        if (!pendingBetData.betRef) {
          response.send("betRef is undefined").status(403);
        }
        const userRef = db.collection("users").doc(pendingBetData.uid);
        const betSnapshot = await pendingBetData.betRef.get();
        const betData = betSnapshot.data();
        const feedSnapshot = await betData.feedPost.get();

        if (betData.team == gameData.winner) {
          await betSnapshot.ref.update({status: "won"});
          await userRef.update({balance:
            admin.firestore.FieldValue.increment(betData.amount * 2)});
          await feedSnapshot.ref.update({status: "won"});
        } else {
          await betSnapshot.ref.update({status: "lost"});
          await feedSnapshot.ref.update({status: "lost"});
        }

        await bet.ref.delete();
      } catch (error) {
        console.error("Error handling pending bet: " + error);
        response.status(500).send("Error handling pending bet: " + error);
      }
    }

    response.status(200).send("Updated games and handled pending bets");
  });
});

export const shareBetSlip = onRequest(async (request, response) => {
  corsHandler(request, response, async () => {
    const uid = request.body.uid;
    const betID = request.body.betID;
    const message = request.body.message;

    if (!uid) {
      response.status(400).send("No user ID provided");
      return;
    }

    if (!betID) {
      response.status(400).send("No bet ID provided");
      return;
    }

    if (!message) {
      response.status(400).send("No message provided");
      return;
    }

    const db = getFirestore();

    try {
      const userSnapshot = await db.collection("users").doc(uid).get();
      const userData = userSnapshot.data();

      const betSnapshot = await db.collection("users").doc(uid)
        .collection("bet_history").doc(betID).get();
      const betData = betSnapshot.data();

      if (!betData) {
        response.status(400).send("No bet data found");
        return;
      }

      const result = betData.status === "lost" ?
        `Lost ${betData.team} to win` : `Won ${betData.team} to win`;

      const globalFeedPost = db.collection("global_feed").doc();

      await globalFeedPost.set({
        username: userData!.username,
        message: message,
        result: result,
        matchup: betData.matchup,
        amount: betData.amount,
        payout: betData.payout ?? 0,
        placedAt: admin.firestore.FieldValue.serverTimestamp(),
        type: "share",
      });
    } catch (e) {
      response.status(500).send(`Error sharing bet slip: ${e}`);
    }

    response.status(200).send();
  });
});
