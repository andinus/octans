unit module Octans::Puzzle;

use WWW;

# get-puzzle returns the @puzzle along with it's @gray-squares.
sub get-puzzle (
    Str $path,

    # @puzzle will hold the puzzle grid.
    @puzzle,

    # @gray-squares will hold the position of gray squares. Algot
    # marks them with an asterisk ("*") after the character.
    @gray-squares
) is export {
    # @raw_puzzle will hold the puzzle before parsing.
    my @raw-puzzle;

    # Read the puzzle from file if it exists.
    if $path.IO.f {
        @raw-puzzle = $path.IO.lines.words;
    } else {
        # $url will hold the url that we'll call to get the toot data.
        my Str $url;

        # User can pass 2 types of links, either it will be the one
        # when they view it from their local instance or the one they
        # get from Algot's profile. We set $url from it.
        if $path.match("web/statuses") -> $match {
            $url = $match.replace-with("api/v1/statuses");
        } else {
            $url = "https://mastodon.art/api/v1/statuses/" ~ $path.split("/")[*-1];
        }

        # jget just get's the url & decodes the json. We access the
        # description field of 1st media attachment.
        if (jget($url)<media_attachments>[0]<description> ~~

            # This regex gets the puzzle in $match.
            / [[(\w [\*]?) \s*] ** 4] ** 4 $/) -> $match {

            @raw-puzzle = $match[0];
        }
    }
    parse-puzzle(@raw-puzzle, @puzzle, @gray-squares);
}

# parse-puzzle parses the puzzle from @raw-puzzle. It's assumed to be
# a 4x4 grid.
sub parse-puzzle (
    @raw-puzzle, @puzzle, @gray-squares
) is export {
    # @gray-squares should be empty.
    @gray-squares = ();

    # We have each character of the puzzle stored in @raw-puzzle.
    for 0 .. 3 -> $y {
        for 0 .. 3 -> $x {
            with @raw-puzzle[($y * 4) + $x].Str.lc -> $char {

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
