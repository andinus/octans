class Puzzle is export {
    has @.grids;
    has @!gray-squares;

    submethod TWEAK() {
        for 0 .. @!grids.end -> $y {
            for 0 .. @!grids[$y].end -> $x {
                # Remove the markers from the puzzle & push the
                # positions to @!gray-squares.
                if @!grids[$y][$x].ends-with("*") {
                    @!grids[$y][$x] = @!grids[$y][$x].comb[0];
                    push @!gray-squares, ($y, $x);
                }
            }
        }
    }

    # Accessor for @!gray-squares.
    method gray-squares() { @!gray-squares; }

    # Given $y, $x where $y is row index & $x is column index,
    # is-gray-square returns if the square is a gray square.
    method is-gray-square(Int $y, Int $x) {
        return so @!gray-squares.grep(($y, $x));
    }
}
