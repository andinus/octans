use Octans::Puzzle;
use Octans::WordSearch;
use Octans::Puzzle::Get;

proto MAIN(|) is export { unless so @*ARGS { say $*USAGE; exit }; {*} }

multi sub MAIN(
    Str $path, #= path to the crossword (file or url)
    Str :$dict = (%?RESOURCES<mwords/354984si.ngl> //
                  "/usr/share/dict/words").Str, #= dictionary file
    Int :$length = 7, #= minimum word length (default: 7)
    Bool :$verbose, #= increase verbosity
) is export {
    # @dict holds the sorted dictionary. Only consider words >= 7
    # chars by default.
    my Str @dict = $dict.IO.lines.grep(*.chars >= $length);

    my $puzzle = $path.IO.f
    ?? Puzzle.new(grids => $path.IO.lines.map(*.words.Array))
    !! get-puzzle($path);

    if so $verbose {
        # Don't print path if using the dictionary included with the
        # program.
        unless $dict.Str eq %?RESOURCES<mwords/354984si.ngl>.Str {
            say "Dictionary: " ~ $dict.Str;
        }

        say "Gray squares: ", $puzzle.gray-squares;
        say "Puzzle";
        "    $_".say for $puzzle.grids;
    }

    # start-pos block loops over each starting position.
    start-pos: for $puzzle.gray-squares -> $pos {
        # gather all the words that word-search finds starting from
        # $pos.
        word: for gather word-search(
            @dict, $puzzle.grids, $pos[0], $pos[1],
        ) -> (
            # word-search returns the word along with @visited which
            # holds the list of all grids that were visited when the
            # word was found.
            $word, @visited
        ) {
            printf "%s$word\n", $verbose ?? "\n" !! "";
            next word unless so $verbose;

            # Print the puzzle, highlighting the path.
            for ^$puzzle.grids.elems -> $y {
                print " " x 3;
                for ^$puzzle.grids[$y].elems -> $x {
                    printf " {$puzzle.grids[$y][$x]}%s",
                    @visited[$y][$x]
                     # visited gray squares get marked with "*",
                     # visited squares with "/" & unvisited with " ".
                     ?? ($puzzle.is-gray-square($y, $x) ?? "*" !! "/")
                     !! " ";
                }
                print "\n";
            }
        }
    }
}

multi sub MAIN(
    Bool :$version #= print version
) { say "Octans v" ~ $?DISTRIBUTION.meta<version>; }
