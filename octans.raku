#!/usr/bin/env raku

use v6.d;
use lib 'lib';
use Puzzle;
use WordSearch;

unit sub MAIN (
    Str $url?, #= url for Algot's crossword
    Str :$dict = "/usr/share/dict/words", #= dictionary file
    Bool :v($verbose), #= increase verbosity
);

# @dict holds the sorted dictionary. Only consider words >= 7 chars.
my Str @dict = $dict.IO.lines.grep(*.chars >= 7);

# @puzzle holds the puzzle.
#
# @gray-squares holds the list of indexes of valid starting positions
# in the puzzle.
my (@puzzle, @gray-squares);
@puzzle = [
    [<n a t k>],
    [<i m e c>],
    [<a r d e>],
    [<t e c h>]
];
@gray-squares = [3, 0], [2, 0]; # $y, $x

# Get the puzzle from $url if it's passed.
get-puzzle($url, @puzzle, @gray-squares) with $url;

if $verbose {
    say "Gray squares: ", @gray-squares;
    say "Puzzle";
    "    $_".say for @puzzle;
}

# After the solution is found, the path is printed with these fancy chars.
my %𝒻𝒶𝓃𝒸𝓎-𝒸𝒽𝒶𝓇𝓈 = <a a̶ b b̶ c c̶ d d̶ e e̶ f f̶ g g̶ h h̶ i i̶ j j̶ k k̶ l l̶ m m̶
                     n n̶ o o̶ p p̶ q q̶ r r̶ s s̶ t t̶ u u̶ v v̶ w w̶ x x̶ y y̶ z z̶>;

# start-pos block loops over each starting position.
start-pos: for @gray-squares -> $pos {
    my DateTime $initial = DateTime.now;

    # gather all the words that word-search finds starting from $pos.
    for gather word-search(
        @dict, @puzzle, $pos[0], $pos[1],
    ) -> (
        # word-search returns the word along with @visited which holds
        # the list of all grids that were visited when the word was
        # found.
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
