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
    nbaGamesCollection.doc(homeTeam + "v" + awayTeam).set({
      date: date,
      time: game.scheduled,
      home: homeTeam,
      away: awayTeam,
    });
  }

  response.send(json);
});

// Returns NBA Game data from Firestore for a given date
export const getNBAGames = onRequest(async (request, response) => {
  /*
  TODO:
  - Get the date from the request
  - Query Firestore for games on date
  - Return the games
  */
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
