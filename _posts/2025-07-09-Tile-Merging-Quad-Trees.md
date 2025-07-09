# Image Decomposition and Tile Merging Using Quad Trees

A quad tree is a data structure well-known in the world of game development, used for collision detection: is one game object touching or overlapping another?

There are already many articles out there about quad trees and their uses for collision detection in games, but they have other uses as well, apparently less well-known than their use in games.

One use for quad trees that recently surprised me was in image decomposition/compression and tile merging (which are essentially the same thing as far as quad trees are concerned). 

To talk about the solution that quad trees provide, we need to talk about what problem the solution solves first. 

I will refer to both problems interchangeably for the remainder of the post because both problems are the same as far as quad trees are concerned, and an explanation for one is just as applicable to the other.

## The Tile Merging Problem

### Tiles in games

In 2D games, it is common to create the background environment as a set of "tiles". 

What is a tile? A small image repeated in a game's world to make up the environment.

The following screenshot from the first Mario game from the NES is illustrative. The blocks to the left of the bridge are all repeated tiles: blocks which are 8 pixels wide and 8 pixels tall.

TODO: copy screenshot https://www.nintendolife.com/games/nes/super_mario_bros#enlarge-7

The other aspect of tiles is their behaviour. Some tiles are purely for ornamental purposes, but we are only concerned with tiles that have associated behaviour. For example, those grey blocks stop Mario from falling down.

### Merged tiles

To understand what is referred to by merging tiles, it helps to consider a level in a game.

We likely have dozens of repeated tiles on the screen. Many of these tiles are adjacent to each other and form a larger square or rectangular object.

While it looks like a single object to us, there are still dozens of small tiles making up this object in the code. 

We probably don't want to do anything about that as far as visuals are concerned, but for the purposes of behaviour, we can consider multiple adjacent tiles which look like a larger square to actually be a single larger square.

The below image shows what this looks like. 

TODO: merged tile image. Tile looks like one square and it actually is four squares in terms of behaviour. However, show that it is possible to merge into a single square (for behaviour).

Graphically, there are four tiles. There are four squares with identical behaviour when Mario touches them.

However, we can reduce memory usage and make our code faster if we consider (for the purposes of behaviour) that only one single square exists, spanning the size of all four squares.

This is the tile merging problem. We would like to consider adjacent tiles to be one larger tile.

How do we find adjacent tiles and merge them? There are different algorithms. This blog post focuses on a surprisingly simple one using quad trees.

## Identifying Mergeable Tiles with Quad Trees

### Building a Quad Tree

A quad tree is a data structure thas has two cases to deal with:

1. The node may be a **Leaf** with an item (where an item possibly contains coordinates and other data)
  - If we support overlapping items, the Leaf may hold a list of items, but overlapping is impossible for a flattened image, and rare for tile implementations
2. The node may be a **Branch** with links to top left, top right, bottom left and bottom right nodes (where a node can be a Leaf or another Branch)
  - The Branch case may also hold items that have coordinates fitting more than one quadrant, but this is implementation development

A quad tree gets its name from the four links in the Branch case, which divides a square area into four quadrants: top left, top right, bottom left and bottom right quadrants.

This division is done recursively until some condition is met. For our purposes, we keep dividing recursively until everything contained in the quadrant meets some level of "sameness".

For tiles, we keep dividing until every tile in this quadrant's coordinates is a tile of the same type.

For image compression, we keep dividing until every pixel in this specific quadrant has the same colour. 

- If we are doing lossy compression, we have some level of tolerance for how different the pixels in a quadrant can be. If the quadrant does not exceed this limit, we replace all of the different colours in the quadrant with just one colour.

The diagram below highlights this.

TODO: create image with different quadrants labelled (different pixel colour for each quadrant). Top right quadrant should divide one more time.

As shown in the diagram, quadrants have different colour values. Except for the top right quadrant, each quadrant has one colour value. 

The top right quadrant has more than one colour value, so it must be divided again until each quadrant has just one colour.

Some implementation details to be aware of are noted below.

#### Use a square

The division process highlights the reason the quad tree must be a square. 

In the "smallest" case, a quadrant is just a single pixel. With a square, we can keep dividing continually until we each a square that is one pixel in height and one pixel in width.

If our image was a rectangle instead, we wouldn't be able to create a quadrant which is exactly 1 pixel high and 1 pixel wide.

To solve this issue where we want to decompose a rectangular image, we say the image is a square (the size being either the width or the height depending on which is larger). 

We can then use null values, an option/maybe type, junk data that is used nowhere else, or whatever, for the coordinates that don't exist in the original image. 

We can add an Empty case to the quad tree data type to describe null quadrants if we want, and return `Empty` instead of a `Leaf`, when we encounter an area with junk data.

#### Handle division by odd numbers correctly

Our goal is to divide a quadran into four more quadrants of equal size, but sometimes this is not exactly possible.

Say we have a quadrant that is 5 pixels in width and height. With integer division, `5 / 2 = 2`. 

This seems to suggest we want four sub-quadrants that are 2 pixels wide and 2 pixels tall, but we clearly don't because we would be missing a pixel, and our task demands pixel-perfect correctness.

We deal with this issue by making two quadrants which are 2 pixels tall, and two quadrants which are 3 pixels tall.

It is no help to address this problem by considering floating point numbers, because pixels are integers themselves. A single pixel cannot be split in half.

#### Optimal merging

It is common in the field of image compression to use the method of quad tree decomposition as a "first pass", and then to perform additional compression algorithms afterwards.

Why is this? One reason is that quad tree decomposition does not merge pixels or tiles into the minimum number possible.

We can clearly see this from the below diagram.

TODO: add a diagram with a 4 pixel box at the centre.

In this diagram, we see a box at the very centre. 

However, because this box has pixel coordinates across four different quadrants, it is treated as four different tiles and not one.

For this reason, when the goal is to minimise the number of tiles, it can be helpful to run additional algorithms on the quad tree afterwards and modify the items within further.

#### You might not need quad trees

The previous section stated that quad trees are not guaranteed to decompose tiles into the minimum number possible, and we might run other algorithms afterwards.

However, sometimes a "good enough" solution is just what we need. For example, we might want to reduce tile count while the program is running, and then minimise the number of tiles only when we export them. (This is what I am doing in a pixel editing program I am working on.)

Our main consideration in this article is reducing the number of tiles, but the time taken for the process to be done is also an important consideration for some applications. 

We might be okay with a "good enough" output that takes less time to perform but does not produce the minimum number of squares.

In my program, there are two times to be aware of: (a) merging when the program is running, before showing the user the pixels they entered, and (b) merging when exporting to a file.

In the first case, we don't need an optimal output because the output is ephemeral and does not have much of a performance impact. However, in the second case, we want to save the file to disk and later use it, so spending a bit more time makes sense.

When our output is ephemeral, we can skip building the quad tree. We can follow the same process where we divide squares into quadrants, but at the level where we would normally create a Leaf, we could instead choose to insert the item into another data structure (like an array, a linked list, or a binary tree).

We follow the same algorithm, but produce a different output from it.

## Code implementation

There is a Standard ML implementation of a quad tree at the following repository. 

https://github.com/hummy123/quad-tree-impl/

One can write additional functions, such as point queries, using the same principles outlined in the article.
