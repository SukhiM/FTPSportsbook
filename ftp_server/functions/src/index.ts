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

initializeApp();

const sportsRadarNBAKey = "pdmqy8pxggcnh6ejjbe8mdsz";
// const oddsKey = "ea24407b8b130f7a2b2a3bf7401fe267";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// Loads NBA Game data from SportsRadar API and stores in Firestore
export const loadNBAGames = onRequest(async (request, response) => {
  /*
  TODO:
  - Modify function to use date from request;
      currently hardcoded date of 10/24/2023
  - Load odds for each game
  */

  const resp: any = await fetch("http://api.sportradar.us/nba/trial/v8/en/games/2023/10/24/schedule.json?api_key=" + sportsRadarNBAKey);
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
  const date = "2023-10-24";
  const nbaGamesCollection = getFirestore().collection("nba_games")
    .doc(date).collection("games").get();
  (await nbaGamesCollection).forEach((doc) => {
    gamesList.push(doc.data());
  });
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
