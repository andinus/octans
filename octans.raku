#!/usr/bin/env raku

use v6.d;
use WWW;

unit sub MAIN (
    Str $url, #= url for Algot's crossword
    Str :$dict = "/usr/share/dict/words", #= dictionary file
    Bool :v($verbose), #= increase verbosity
);

# @directions is holding a list of directions we can move in. It's
# used later for neighbors subroutine.
my List @directions[4] = (
    # $y, $x
    ( +1, +0 ), # bottom
    ( -1, +0 ), # top
    ( +0, +1 ), # left
    ( +0, -1 ), # right
);

# This code is just for testing purpose. The code below that is
# getting the puzzle & parsing it will set @puzzle & @gray-squares
# like this:

# We can call @puzzle[$y][$x] to get the character. $y stands for
# column & $x for row, so @puzzle[0][3] will return `k' for this
# sample @puzzle:

# my List @puzzle = (
#     <n a t k>,
#     <i m e c>,
#     <a r d e>,
#     <t e c h>
# );

# my List @gray-squares = (3, 0), (2, 0); # $y, $x

# @puzzle will hold the puzzle grid.
my @puzzle;

# @gray-squares will hold the position of gray squares. Algot marks
# them with an asterisk ("*") after the character.
my @gray-squares;

# $toot_url will hold the url that we'll call to get the toot data.
my Str $toot_url;

# User can pass 2 types of links, either it will be the one when they
# view it from their local instance or the one they get from Algot's
# profile. We set $toot_url from it.
if $url.match("web/statuses") -> $match {
    $toot_url = $match.replace-with("api/v1/statuses");
} else {
    $toot_url = "https://mastodon.art/api/v1/statuses/" ~ $url.split("/")[*-1];
}

say "Fetching: $toot_url" if $verbose;

# jget just get's the url & decodes the json. We access the
# description field of 1st media attachment.
if (jget($toot_url)<media_attachments>[0]<description> ~~

    # This regex gets the puzzle in $match.
    / [[(\w [\*]?) \s*] ** 4] ** 4 $/) -> $match {

    # We have each character of the puzzle stored in $match. It's
    # assumed that it'll be a 4x4 grid.
    for 0 .. 3 -> $y {
        for 0 .. 3 -> $x {
            with $match[0][($y * 4) + $x].Str.lc -> $char {

                # If it ends with an asterisk then we push the
                # position to @gray-squares.
                if $char.ends-with("*") {
                    @puzzle[$y][$x] = $char.comb[0];
                    push @gray-squares, [$y, $x];
                } else {
                    @puzzle[$y][$x] = $char;
                }
            }
        }
    }
}

if $verbose {
    say "Gray squares: ", @gray-squares;
    say "Puzzle";
    "    $_".say for @puzzle;
}

# This for block loops over every word in the dictionary & searches
# the puzzle grid for it's presence.
word: for $dict.IO.lines -> $word {
    # We don't want words whose length is less than 7.
    next word unless $word.chars >= 7;

    # start-pos block loops over each starting position. In normal
    # case every position could be the start position but for Algot's
    # puzzle they're limited to a few blocks.
    start-pos: for @gray-squares -> $pos {

        # If the dictionary word doesn't start with the starting
        # position character then move on to the next start position.
        next start-pos unless $word.starts-with(
            @puzzle[$pos[0]][$pos[1]]
        );

        # Check if each letter of word is present in puzzle grid.
        next word unless $word.comb ⊆ @puzzle[*;*];

        # Print the word if the search is successful.
        say $word if word-search(@puzzle, $pos[0], $pos[1], $word);
    }
}

# word-search performs a Depth-First search on @puzzle. word-search
# matches the word character by character.
sub word-search (
    @puzzle, Int $y, Int $x,

    # $count will keep the count of character's of $word present in
    # the puzzle.
    Str $word, Int $count = 1,
    @visited? is copy
     --> Bool
) {
    # If the number of character's we've found is equal to the length
    # of $word then return True because we've found the whole word.
    return True if $count == $word.chars;

    # For each neighbor, we perform a Depth-First search to find the
    # word.
    neighbor: for neighbors(@puzzle, $y, $x).List -> $pos {

        # Move on to next neighbor if we've already visited this one.
        # This is because we cannot reuse a grid.
        next neighbor if @visited[$pos[0]][$pos[1]];

        if @puzzle[$pos[0]][$pos[1]] eq $word.comb[$count] {

            # This explains why we have to mark this position as False
            # if the search fails:
            #
            # Here we're marking this position as True. This approach
            # might cause us to miss possible solutions. If the puzzle
            # is like so:
            #
            # a b e
            # c a f
            #
            # And the word we're looking for is "cabefa". Then let's
            # say that we go through the other 'a' first (bottom-mid
            # 'a') & at this point it would be marked as True but the
            # search would fail (correctly so).
            #
            # And after that failure we move to next neighbor which is
            # top-left 'a'. The search goes on until we reach 'f' &
            # get the list of f's neighbors which would return 'e' &
            # bottom-mid 'a'. Now 'e' would be discarded because it
            # was marked as visited but 'a' also has been marked as
            # visited & it too would be discarded.
            #
            # This would cause us to miss solutions. So we just make
            # it False again if the word wasn't found with this
            # neighbor. After making it False, we move on to the next
            # neighbor.

            @visited[$pos[0]][$pos[1]] = True;

            # Call word-search recursively & increment $count as we
            # find each character. If the search was successful then
            # return True.
            if word-search(
                @puzzle, $pos[0], $pos[1],
                $word, $count + 1,
                @visited
            ) {
                return True;
            } else {
                # Mark this as not visited if the search was
                # unsuccessful and move on to next neighbor.
                @visited[$pos[0]][$pos[1]] = False;
                next neighbor;
            }
        }
    }

    # return False if no neighbor matches the character.
    return False;
}

# neighbors returns the neighbors of given index. Neighbors are cached
# in @neighbors array. This way we don't have to compute them
# everytime neighbors subroutine is called for the same position.
sub neighbors (
    @puzzle, Int $y, Int $x --> List
) {
    state Array @neighbors;

    if @puzzle[$y][$x] {

        # If we've already computed the neighbors then no need to do
        # it again.
        unless @neighbors[$y][$x] {
            my Int $pos-x;
            my Int $pos-y;

            # Starting from the intital position of $y, $x we move to
            # each direction according to the values specified in
            # @directions array. In this case we're just trying to
            # move in 4 directions (top, bottom, left & right).
            DIRECTION: for @directions -> $direction {
                $pos-y = $y + $direction[0];
                $pos-x = $x + $direction[1];

                # If movement in this direction is out of puzzle grid
                # boundary then move on to next direction.
                next DIRECTION unless @puzzle[$pos-y][$pos-x];

                # If neighbors exist in this direction then add them
                # to @neighbors[$y][$x] array.
                push @neighbors[$y][$x], [$pos-y, $pos-x];
            }
        }
    } else {
        # If it's out of boundary then return no neighbor.
        @neighbors[$y][$x] = [];
    }

    return @neighbors[$y][$x];
}
