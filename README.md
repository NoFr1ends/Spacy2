# Spacy

Spacy is a 2D multiplayer space shooter written in Godot Engine.

The main purpose of this project is to be a demo of how to write a multiplayer
game in Godot with matchmaking using [open-match](https://open-match.dev/) and automatic
game server scaling using [agones](https://agones.dev/).

## Current state of project
Currently the project is still in development and not playable.

## Components
The project is built up with the following components:
- **client** - The game client using the Godot Game Engine, written in GDScript.
- **server/director** - OpenMatch director, fetches open tickets, run the matchmaking function and assign the generated matches to a gameserver, written in Go
- **server/matchmaker** - OpenMatch matchmaker function, currently a very simple matchmaking function, written in Go
- **server/frontend** - Frontend Server which the clients communicate to in order to request matchmaking tickets and query their assignment, written in Go
- **server/game** - GameServer, handling the gameplay logic using Godot Engine, written in GDScript

## License
This project is licensed under the [MIT License](LICENSE.md).

Assets in this project are by [Kenney](https://kenney.nl) licensed under the [CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/) (thanks for your great work in providing so many free assets!).