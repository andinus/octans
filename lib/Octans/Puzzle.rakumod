unit module Octans::Puzzle;

use WWW;

# get-puzzle returns the @puzzle given input path.
sub get-puzzle (
    Str $path
) is export {
    my @puzzle;

    # Read the puzzle from file if it exists.
    if $path.IO.f {
        @puzzle = $path.IO.lines.map(*.words.cache.Array);
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
            / ([(\w [\*]?) \s*?]+ \n)+  $/) -> $match {
            for 0 .. $match[0].end -> $y {
                for 0 .. $match[0][$y].words.end -> $x {
                    @puzzle[$y][$x] = $match[0][$y].words[$x].lc;
                }
            }
        }
    }
    return @puzzle;
}

# set-gray squares will set the @gray-squares array while removing the
# "*" in @puzzle. Algot marks them with an asterisk ("*") after the
# character.
sub set-gray-squares (
    @puzzle --> List
) is export {
    my List @gray-squares;

    for 0 .. @puzzle.end -> $y {
        for 0 .. @puzzle[$y].end -> $x {
            if @puzzle[$y][$x].ends-with("*") {
                @puzzle[$y][$x] .= chop;
                push @gray-squares, ($y, $x);
            }
        }
    }
    return @gray-squares;
}
