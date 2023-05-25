const { OpenSeaStreamClient, Network } = require("@opensea/stream-js");
const WebSocket = require("ws");

require("dotenv").config();

const YOUR_API_KEY = process.env.OPENSEA_API;
const client = new OpenSeaStreamClient({
  token: YOUR_API_KEY,
  connectOptions: {
    transport: WebSocket,
  },
});
console.log(client);
client.onItemListed("dopeboredapebros", (event) => {
  // handle event
  console.log(1);
  console.log(event);
});
