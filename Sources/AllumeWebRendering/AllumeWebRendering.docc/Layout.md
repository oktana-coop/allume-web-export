# Layout

An Allume export records where cards, comments and ink sit on a board, and how big they are. Layout
works out what else the HTML needs: an estimate of how wide text blocks are, a board's content
bounds, its connection lines and the scale of its previews. It does so once for each board, when the
site is built, so that lines and previews show without JavaScript.

Positions and sizes are in CSS pixels at 100% zoom, measured from the board's top left. The screen
and the zoom level only come in later, in the browser.

## What the export gives

- Cards and comments: their place and size.
- Text blocks, written straight on the board rather than in a card: where each one starts and the
  width it wraps at, but not how wide it is.
- Ink: each drawing as an image, and its size. The image's top left is the board's top left, and the
  strokes sit inside it where they were drawn.
- Connections: the two things each one joins, but not the line between them.

## Text blocks

The export doesn't record how wide a text block is, so its width is _estimated_: about 10 pixels per
character, an average for the 18-pixel font the views draw text blocks in. Its height follows from
the estimate, since the text wraps at its width and each line is 24 pixels high. A paragraph of 100
characters is estimated at about 1,000 pixels wide, so if it wraps at 400 it takes three lines, 72
pixels high.

## Content bounds

A board's content bounds are the smallest rectangle around its cards, comments, text blocks and ink.
Ink only pushes the far edges out, since its image starts at the board's top left. For a card at
(100, 50), 200 wide and 100 high, and a text block of two lines at (50, 500), so 48 high, the
content bounds are the dashed rectangle:

```
· (0, 0)

    (50, 50)
    ┌╌╌╌╌┌───────────────────┐
    ╎    │       card        │
    ╎    └───────────────────┘
    ╎                        ╎
    ┌──────────────┐         ╎
    │ text block   │         ╎
    └──────────────┘╌╌╌╌╌╌╌╌╌┘
                    (300, 548)
```

The viewer uses them to fit the board to the window, with the margin from its top left, and to limit
zooming out and panning.

## Connection lines

As in Allume, a connection is a straight line between the centers of the two things it joins, drawn
from the edge of one to the edge of the other and stopping 10 short of both. When the two are too
close for that, there's no line. For cards 100 by 100 at (0, 0) and (300, 0), it runs from (110, 50)
to (290, 50):

```
┌──────┐                    ┌──────┐
│   •──┼──·────────────·────┼──•   │
└──────┘                    └──────┘
```

## Previews

A card that shows another board draws it scaled down to fit the card, the way the viewer fits it to
the window. A board with little on it would then be scaled up, and look bigger in the preview than
in its own view. A preview shouldn't exceed the board's actual size, so its scale is capped at 80%.
