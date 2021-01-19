unit module Puzzle;

use WWW;

# get-puzzle returns the @puzzle along with it's @gray-squares.
sub get-puzzle (
    Str $url,

    # @puzzle will hold the puzzle grid.
    @puzzle,

    # @gray-squares will hold the position of gray squares. Algot
    # marks them with an asterisk ("*") after the character.
    @gray-squares
) is export {
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

    # @gray-squares should be empty.
    @gray-squares = ();

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
}
