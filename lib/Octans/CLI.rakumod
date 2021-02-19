use Octans::Puzzle;
use Octans::WordSearch;

# If no arguments are passed then run USAGE & exit.
proto MAIN (|) is export {unless so @*ARGS {USAGE(); exit;}; {*}}

multi sub MAIN (Bool :$version) is hidden-from-USAGE {
    say "Octans v" ~ $?DISTRIBUTION.meta<version>;
}

multi sub MAIN (
    Str $path?, #= path to the crossword (file or url)
    Str :$dict = (%?RESOURCES<mwords/354984si.ngl> //
                  "/usr/share/dict/words").Str, #= dictionary file
    Int :$length = 7, #= minimum word length (default: 7)
    Bool :s($sample), #= run the sample puzzle
    Bool :v($verbose), #= increase verbosity
    Bool :$version, #= print version
) {
    # Print usage & exit if both sample & path are not passed.
    unless ($sample or $path) {
        USAGE();
        exit;
    }

    # @dict holds the sorted dictionary. Only consider words >= 7
    # chars by default.
    my Str @dict = $dict.IO.lines.grep(*.chars >= $length);

    # @puzzle holds the puzzle.
    #
    # @gray-squares holds the list of indexes of valid starting
    # positions in the puzzle.
    my (@puzzle, @gray-squares);

    # Set the sample puzzle if requested.
    if $sample {
        @puzzle = [
            [<n a t k>],
            [<i m e c>],
            [<a* r d e>],
            [<t* e c h>],
        ];
    }

    # Get the puzzle from $path if it's passed.
    with $path {
        if $path.IO.f {
            @puzzle = $path.IO.lines.map(*.words.cache.Array);
        } else {
            @puzzle = get-puzzle($path);
        }
    }

    # set-gray-squares also removes asterisks from @puzzle.
    @gray-squares = set-gray-squares(@puzzle); # ($y, $x)

    if $verbose {
        # Don't print path if using the dictionary included with the
        # program.
        say "Dictionary: ", $dict.Str
                             unless ($dict.Str
                                     eq %?RESOURCES<mwords/354984si.ngl>.Str);
        say "Gray squares: ", @gray-squares;
        say "Puzzle";
        "    $_".say for @puzzle;
    }

    # After the solution is found, the path is printed with these
    # fancy chars.
    my %𝒻𝒶𝓃𝒸𝓎-𝒸𝒽𝒶𝓇𝓈 = <a a̶ b b̶ c c̶ d d̶ e e̶ f f̶ g g̶ h h̶ i i̶ j j̶ k k̶ l l̶
                         m m̶ n n̶ o o̶ p p̶ q q̶ r r̶ s s̶ t t̶ u u̶ v v̶ w w̶
                         x x̶ y y̶ z z̶>;

    # start-pos block loops over each starting position.
    start-pos: for @gray-squares -> $pos {
        my DateTime $initial = DateTime.now;

        # gather all the words that word-search finds starting from
        # $pos.
        for gather word-search(
            @dict, @puzzle, $pos[0], $pos[1],
        ) -> (
            # word-search returns the word along with @visited which
            # holds the list of all grids that were visited when the
            # word was found.
            $word, @visited
        ) {
            # Print the word, along with the time taken (if $verbose).
            say ($verbose ??
                 "\n" ~ $word ~ " [" ~ DateTime.now - $initial ~ "𝑠]" !!
                 $word);

            # Print the puzzle, highlighting the path.
            if $verbose {
                for ^@puzzle.elems -> $y {
                    print " " x 3;
                    for ^@puzzle[$y].elems -> $x {
                        print " ", (
                        @visited[$y][$x] ??
                        (%𝒻𝒶𝓃𝒸𝓎-𝒸𝒽𝒶𝓇𝓈{@puzzle[$y][$x]} // @puzzle[$y][$x]) !!
                        @puzzle[$y][$x]
                    );
                    }
                    print "\n";
                }
            }
        }
    }
}

# Modify USAGE to include input file format.
sub USAGE {
    say $*USAGE;
    say "\nInput file format:

    n a t k
    i m e c
    a* r d e
    t* e c h";
}
