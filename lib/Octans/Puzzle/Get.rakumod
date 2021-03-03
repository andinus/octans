use WWW;
use Octans::Puzzle;

# get-puzzle returns Puzzle.new() given input path.
sub get-puzzle(
    Str $path
) is export {
    my @grids;

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

    # grids capture grids of a row.
    my token grids { \S \*? }
    # rows capture rows of the puzzle.
    my token rows { <grids> ** 2..* % \h }

    # jget just get's the url & decodes the json. We access the
    # description field of 1st media attachment.
    if (jget($url)<media_attachments>[0]<description> ~~
        / \n\n <rows>+ % \n /
       ) -> $match {
        for 0 .. $match<rows>.end -> $y {
            for 0 .. $match<rows>[$y]<grids>.end -> $x {
                @grids[$y][$x] = $match<rows>[$y]<grids>[$x].lc;
            }
        }
    }
    return Puzzle.new(grids => @grids);
}
