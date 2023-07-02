use Octans::Puzzle;
use Octans::WordSearch;
use Octans::Puzzle::Get;
use Octans::GenerateFrame;

proto MAIN(|) is export { unless so @*ARGS { say $*USAGE; exit }; {*} }

multi sub MAIN(
    Str $path, #= path to the crossword (file or url)
    Str :$dict = (%?RESOURCES<mwords/354984si.ngl> //
                  "/usr/share/dict/words").Str, #= dictionary file
    Int :$length = 7, #= minimum word length (default: 7)
    Bool :$visualize, #= produces a video output
    Bool :$verbose, #= increase verbosity
) is export {
    # @dict holds the sorted dictionary. Only consider words >= 7
    # chars by default.
    my Str @dict = $dict.IO.lines.grep(*.chars >= $length);

    my $puzzle = $path.IO.f
                  ?? Puzzle.new(grids => $path.IO.lines.map(*.lc.words.Array))
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

    constant $SIDE = 128;
    my Int %meta = :rows($puzzle.grids.elems), :cols($puzzle.grids[0].elems);
    my Int %canvas = :width(%meta<cols> * $SIDE), :height(%meta<rows> * $SIDE);

    my IO() $output = "%s/octans-%s".sprintf(
        '/tmp', ('a'...'z', 'A'...'Z', 0...9).roll(8).join
    );
    if $visualize {
        mkdir $output;
        put "Output: $output";
        die "Output directory doesn't exist" unless $output.d;
    }

    my Int $iter = 0;
    # start-pos block loops over each starting position.
    start-pos: for $puzzle.gray-squares -> $pos {
        # gather all the words that word-search finds starting from
        # $pos.
        word: for gather word-search(
            @dict, $puzzle.grids, $pos[0], $pos[1], :$visualize
        ) -> (
            # word-search returns the word along with @visited which
            # holds the list of all grids that were visited when the
            # word was found.
            $word, @visited
        ) {
            if $visualize {
                generate-frame(
                    :%canvas, :side($SIDE), :puzzle($puzzle.grids), :@visited, :%meta,
                    :out("%s/%08d.png".sprintf: $output, $iter++), :found($word ne "")
                );
                next word;
            }

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

    if $visualize {
        put "Creating a slideshow.";
        my Str $log-level = $verbose ?? "info" !! "error";
        run «ffmpeg -loglevel "$log-level" -r 1.5 -i "$output/\%08d.png"
                    -vf 'tpad=stop_mode=clone:stop_duration=1'
                    -vcodec libx264 -crf 24 -pix_fmt yuv420p "$output/solution.mp4"»;
        put "Video Solution: $output/solution.mp4";
    }
}

multi sub MAIN(
    Bool :$version #= print version
) { say "Octans v" ~ $?DISTRIBUTION.meta<version>; }
