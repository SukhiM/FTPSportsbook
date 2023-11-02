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

import {initializeApp} from "firebase-admin/app";
import axios from "axios";

const loadNBAGamesAddress = "https://loadnbagames-kca5bali4a-uc.a.run.app";

initializeApp();

const sportsRadarNBAKey = "pdmqy8pxggcnh6ejjbe8mdsz";
// const oddsKey = "ea24407b8b130f7a2b2a3bf7401fe267";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// Loads NBA Game data from SportsRadar API and stores in Firestore
export const loadNBAGames = onRequest(async (request, response) => {
  const formatDate = (date: Date): string => {
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, "0"); // Months are 0-based, hence +1
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
  const resp: any = await fetch("http://api.sportradar.us/nba/trial/v8/en/games/" + reqDate + "/schedule.json?api_key=" + sportsRadarNBAKey);
  const json = await resp.json();
  const date = json.date;
  const gamesArr = json.games;

  const nbaGamesCollection = getFirestore().collection("nba_games")
    .doc(date).collection("games");

  for (const game of gamesArr) {
    const homeTeam = game.home.alias;
    const awayTeam = game.away.alias;
    const gameID = game.id;
    nbaGamesCollection.doc(gameID).set({
      date: date,
      time: game.scheduled,
      home: homeTeam,
      away: awayTeam,
      id: gameID,
    });
  }

  // const oddsResp = await fetch("https://api.the-odds-api.com/v4/sports/basketball_nba/odds/?apiKey=" + oddsKey + "&regions=us&markets=h2h&bookmakers=draftkings");
  // const oddsJSON = await oddsResp.json();

  // for (const game of oddsJSON) {
  //   const homeTeam = game.home_team;
  //   const awayTeam = game.away_team;

  //   const gameBoomaker = game.bookmakers[0].markets.outcomes;

  //   const homeOdds = gameBoomaker[0].price;
  //   const awayOdds = gameBoomaker[1].price;

  //   // TODO: Find game in DB and update odds
  // }

  response.status(200).send();
});

// Returns NBA Game data from Firestore for a given date
export const getNBAGames = onRequest(async (request, response) => {
  /*
  TODO:
  - Get the date from the request
  - Query Firestore for games on date
  - Return the games
  */

  const gamesList: any = [];

  // Date will be changed to be read from request body
  const date = request.body.date;
  let nbaGamesCollection = getFirestore().collection("nba_games")
    .doc(date).collection("games").get();
  (await nbaGamesCollection).forEach((doc) => {
    gamesList.push(doc.data());
  });

  if (gamesList.isEmpty) {
    const body = {
      "date": date,
    };

    const response = await axios.post(loadNBAGamesAddress, body);
    if (response.status == 200) {
      nbaGamesCollection = getFirestore().collection("nba_games")
        .doc(date).collection("games").get();
      (await nbaGamesCollection).forEach((doc) => {
        gamesList.push(doc.data());
      });
    } else {
      response.send(response)
    }
  }
  response.send(gamesList);
});

// Places a bet for a user on a game and stores in user's history
export const placeBet = onRequest(async (request, response) => {
  /*
  TODO:
  - Get the user ID from the request
  - Get the bet from the request
  - Get the game from the request
  - Add bet to history for user
  - Return confirmation to client
  */
});

export const testHTTP = onRequest(async (request, response) => {
  response.send("Works");
});
