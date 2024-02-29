#! /usr/bin/env node
import { io } from "socket.io-client";

// const socket = io("http://localhost:3333");

// socket.on("connect", () => {
//   console.log(`Connected to server with id: ${socket.id}`);
//   socket.send("Hello from the client!");
// });

import yargs from "yargs";
import { hideBin } from "yargs/helpers";

yargs(hideBin(process.argv))
  .command(
    "read",
    "read from the connection",
    (yargs) => yargs,
    (argv) => {
      read(argv.server ?? "ws://localhost:3333");
    },
  )
  .command(
    "write <message>",
    "write to the connection",
    (yargs) => {
      return yargs.positional("message", {
        type: "string",
        description: "The message to send",
      });
    },
    (argv) => {
      write(argv.server ?? "ws://localhost:3333", argv.message);
    },
  )
  .option("server", {
    alias: "s",
    type: "string",
    description: "The server to connect to",
  })
  .parse();

function write(server, message) {
  console.log("writing");
  const socket = io(server);

  socket.on("connect", () => {
    console.log(`Connected to server with id: ${socket.id}`);
    socket.send(message, (ack) => {
      socket.disconnect();
      process.exit(0);
    });
  });
}

function read(server) {
  const socket = io(server);

  socket.on("connect", () => {
    console.log(`Connected to server with id: ${socket.id}`);
  });

  socket.on("message", (data) => {
    console.log(data);
  });

  socket.on("disconnect", () => {
    console.log("Disconnected from server");
    process.exit(0);
  });
}
