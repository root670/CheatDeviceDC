# Cheat Device for Dreamcast
Cheat Device is a game enhancer for the Sega Dreamcast similar to GameShark and CodeBreaker.

## Building
For ease of development, everything is built using the "nold360/kallistios-sdk" Docker image. As such, you need to have Docker installed to compile Cheat Device. Once it's installed all you need to do is run `./docker-make` to compile the project and `./docker-make release` to compile the project and generate self-booting disc images.