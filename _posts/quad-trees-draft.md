## Image Decomposition and Tile Merging Using Quad Trees

A quad tree is a data structure well-known in the world of game development, used for collision detection: is one game object touching or overlapping another?

There are already many articles out there about quad trees and their uses for collision detection in games, but they have other uses as well, apparently less well-known than their use in games.

One use for quad trees that recently surprised me was in image decomposition/compression and tile merging (which are essentially the same thing as far as quad trees are concerned). 

To talk about the solution that quad trees provide, we need to talk about what problem the solution solves first. 

I will explicitly refer to the tile merging problem for the remainder of the post, but because both problems are the same as far as quad trees are concerned, an explanation for one is just as applicable to the other.

### The Tile Merging Problem

#### Tiles in games

In 2D games, it is common to create the background environment as a set of "tiles". 

What is a tile? A small image repeated in a game's world to make up the environment.

The following screenshot from the first Mario game from the NES is illustrative. The blocks to the left of the bridge are all repeated tiles: blocks which are 8 pixels wide and 8 pixels tall.

TODO: copy screenshot https://www.nintendolife.com/games/nes/super_mario_bros#enlarge-7

The other aspect of tiles is their behaviour. Some tiles are purely for ornamental purposes, but we are only concerned with tiles that have associated behaviour. For example, those grey blocks stop Mario from falling down.

#### Merged tiles

To understand what is referred to by merging tiles, it helps to consider a level in a game.

We likely have dozens of repeated tiles on the screen. Many of these tiles are adjacent to each other and form a larger square or rectangular object.

While it looks like a single object to us, there are still dozens of small tiles making up this object in the code. 

We probably don't want to do anything about that as far as visuals are concerned, but for the purposes of behaviour, we can consider adjacent tiles which look like a larger square to actually be a larger square.

The below image shows what this looks like. 

TODO: merged tile image

Graphically, there are four tiles. There are four squares with identical behaviour. 

However, we can reduce memory usage and make our code faster if we consider (for the purposes of behaviour) that only one single square exists.

This is the tile merging problem. We would like to consider adjacent tiles to be one larger tile.
