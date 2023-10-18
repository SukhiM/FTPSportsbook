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

export const getNBAGames = onRequest(async (request, response) => {
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

export const testHTTP = onRequest(async (request, response) => {
  response.send("Works");
});
