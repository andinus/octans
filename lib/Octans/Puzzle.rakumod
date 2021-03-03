class Puzzle is export {
    has @.grids;
    has @!gray-squares;

    submethod TWEAK() {
        for 0 .. @!grids.end -> $y {
            for 0 .. @!grids[$y].end -> $x {
                # Remove the markers from the puzzle & push the
                # positions to @!gray-squares.
                if @!grids[$y][$x].match("*") -> $match {
                    @!grids[$y][$x] = $match.replace-with("");
                    push @!gray-squares, ($y, $x);
                }
            }
        }
    }

    # Accessor for @!gray-squares.
    method gray-squares() { @!gray-squares; }
}
