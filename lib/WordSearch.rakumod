unit module WordSearch;

use Neighbors;
use RangeSearch;

# word-search walks the given grid & tries to find words in the
# dictionary. It walks in Depth-First manner (lookup Depth-First
# search).
sub word-search (
    # @dict holds the dictionary. @puzzle holds the puzzle.
    @dict, @puzzle,

    # $y, $x is the position of the current cell, we have to follow
    # this path. $str is the string we've looked up until now. If it's
    # not passed then assume that we're starting at $y, $x and take
    # @puzzle[$y][$x] as the string.
    #
    # $str should be passed in recursive calls, it's not required when
    # $y, $x is the starting position.
    Int $y, Int $x, $str? = @puzzle[$y][$x],

    # @visited holds the positions that we've already visited.
    @visited? is copy --> List
) is export {
    # If @visited was not passed then mark the given cell as visited
    # because it's the cell we're starting at.
    @visited[$y][$x] = True unless @visited;

    # neighbor block loops over the neighbors of $y, $x.
    neighbor: for neighbors(@puzzle, $y, $x).List -> $pos {
        # Move on to next neighbor if we've already visited this one.
        next neighbor if @visited[$pos[0]][$pos[1]];

        # Mark this cell as visited but only until we search this
        # path. When moving to next neighbor, mark it False.
        @visited[$pos[0]][$pos[1]] = True;

        # $word is the string that we're going to lookup in the
        # dictionary.
        my Str $word = $str ~ @puzzle[$pos[0]][$pos[1]];

        # range-starts-with returns a list of all words in the
        # dictionary that start with $word.
        with range-starts-with(@dict, $word) -> @list {
            if @list.elems > 0 {
                # If $word exist in the dictionary then it should be
                # the first element in the list.
                take @list[0], @visited if @list[0] eq $word;

                # Continue on this path because there are 1 or more
                # elements in @list which means we could find a word.
                word-search(
                    # Don't pass the whole dictionary for next search.
                    # Words that start with "ab" will always be a
                    # subset of words that start with "a", so keeping
                    # this in mind we pass the output of last
                    # range-starts-with (@list).
                    @list, @puzzle, $pos[0], $pos[1], $word, @visited
                );
            }
        }

        # We're done looking up this path, mark this cell as False &
        # move on to another neighbor.
        @visited[$pos[0]][$pos[1]] = False;
    }
}
