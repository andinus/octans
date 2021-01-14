#!/usr/bin/env raku

use v6.d;
use WWW;

unit sub MAIN (
    Str $url, #= url for Algot's crossword
    Str :$dict = "/usr/share/dict/words", #= dictionary file
    Bool :v($verbose), #= increase verbosity
);

my List @directions[4] = (
    # $y, $x
    ( +1, +0 ), # bottom
    ( -1, +0 ), # top
    ( +0, +1 ), # left
    ( +0, -1 ), # right
);

# my List @puzzle = (
#     <n a t k>,
#     <i m e c>,
#     <a r d e>,
#     <t e c h>
# );

# my List @gray-squares = (3, 0), (2, 0); # $y, $x

my @puzzle;
my @gray-squares;

my Str $toot_url;
if $url.match("web/statuses") -> $match {
    $toot_url = $match.replace-with("api/v1/statuses");
} else {
    $toot_url = "https://mastodon.art/api/v1/statuses/" ~ $url.split("/")[*-1];
}

say "Fetching: $toot_url" if $verbose;

if (jget($toot_url)<media_attachments>[0]<description> ~~
    # This regex gets the puzzle in $match.
    / [[(\w [\*]?) \s*] ** 4] ** 4 $/) -> $match {
    for 0 .. 3 -> $y {
        for 0 .. 3 -> $x {
            with $match[0][($y * 4) + $x].Str.lc -> $char {
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

word: for $dict.IO.lines -> $word {
    next word unless $word.chars >= 7;

    start-pos: for @gray-squares -> $pos {
        next start-pos unless $word.starts-with(
            @puzzle[$pos[0]][$pos[1]]
        );

        next word unless $word.comb ⊆ @puzzle[*;*];

        # Print the word if the search is successful.
        say $word if word-search(@puzzle, $pos[0], $pos[1], $word);
    }
}

# word-search performs a Depth-First search on @puzzle.
sub word-search (
    @puzzle, Int $y, Int $x,
    # $count will keep the count of character's of $word present in
    # the puzzle.
    Str $word, Int $count = 1,
    @visited? is copy
     --> Bool
) {
    return True if $count == $word.chars;

    # For each neighbor, we perform a Depth-First search to find the
    # word.
    neighbor: for neighbors(@puzzle, $y, $x).List -> $pos {
        next neighbor if @visited[$pos[0]][$pos[1]];

        if @puzzle[$pos[0]][$pos[1]] eq $word.comb[$count] {
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
            if word-search(
                @puzzle, $pos[0], $pos[1],
                $word, $count + 1,
                @visited
            ) {
                return True;
            } else {
                @visited[$pos[0]][$pos[1]] = False;
                next neighbor;
            }
        }
    }
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
        unless @neighbors[$y][$x] {
            my Int $pos-x;
            my Int $pos-y;

            DIRECTION: for @directions -> $direction {
                $pos-y = $y + $direction[0];
                $pos-x = $x + $direction[1];

                next DIRECTION unless @puzzle[$pos-y][$pos-x];
                push @neighbors[$y][$x], [$pos-y, $pos-x];
            }
        }
    } else {
        @neighbors[$y][$x] = [];
    }

    return @neighbors[$y][$x];
}
