unit module Octans::Neighbors;

# neighbors returns the neighbors of given index. Neighbors are cached
# in @neighbors array. This way we don't have to compute them
# everytime neighbors subroutine is called for the same position.
sub neighbors (
    @puzzle, Int $y, Int $x --> List
) is export {
    # @directions is holding a list of directions we can move in. It's
    # used later for neighbors subroutine.
    state List @directions = (
        # $y, $x
        ( +1, +0 ), # bottom
        ( -1, +0 ), # top
        ( +0, +1 ), # left
        ( +0, -1 ), # right
    );

    # @neighbors holds the neighbors of given position.
    state Array @neighbors;

    if @puzzle[$y][$x] {

        # If we've already computed the neighbors then no need to do
        # it again.
        unless @neighbors[$y][$x] {
            my Int $pos-x;
            my Int $pos-y;

            # Starting from the intital position of $y, $x we move to
            # each direction according to the values specified in
            # @directions array. In this case we're just trying to
            # move in 4 directions (top, bottom, left & right).
            DIRECTION: for @directions -> $direction {
                $pos-y = $y + $direction[0];
                $pos-x = $x + $direction[1];

                # If movement in this direction is out of puzzle grid
                # boundary then move on to next direction.
                next DIRECTION unless @puzzle[$pos-y][$pos-x];

                # If neighbors exist in this direction then add them
                # to @neighbors[$y][$x] array.
                push @neighbors[$y][$x], [$pos-y, $pos-x];
            }
        }
    } else {
        # If it's out of boundary then return no neighbor.
        @neighbors[$y][$x] = [];
    }

    return @neighbors[$y][$x];
}
