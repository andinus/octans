# range-starts-with returns a subset of given @dict list that start
# with $str. It should be faster than:
#
#   @dict.grep: *.starts-with($str)
#
# @dict should be a sorted list of words. It performs binary lookup on
# the list.
sub range-starts-with(
    @dict, Str $str --> List
) is export {
    # $lower, $upper hold the lower and upper index of the range
    # respectively.
    my Int ($lower, $upper);

    # Lookup the whole dictionary.
    my Int ($start, $end) = (0, @dict.end);

    # Loop until we end up on the lower index of range.
    while $start < $end {
        # Divide the list into 2 parts.
        my Int $mid = ($start + $end) div 2;

        # Check if $mid word is le (less than or equal to) $str. If
        # true then discard the bottom end of the list, if not then
        # discard the top end.
        if $str le @dict[$mid].substr(0, $str.chars).lc {
            $end = $mid;
        } else {
            $start = $mid + 1;
        }
    }

    # Found the lower index.
    $lower = $start;

    # Set $end to the end of list but keep $start at the lower index.
    $end = @dict.end;

    # Loop until we end up on the upper index of range.
    while $start < $end {
        # Divide the list into 2 parts. Adds 1 because we have to find
        # the upper index in this part. `div' performs Interger
        # division, output is floor'ed.
        my Int $mid = (($start + $end) div 2) + 1;

        # Check if $mid word is lt (less than) $str. If true then
        # discard the bottom end of the list, if not then discard the
        # top end.
        if $str lt @dict[$mid].substr(0, $str.chars).lc {
            $end = $mid - 1;
        } else {
            $start = $mid;
        }
    }

    # Found the upper index.
    $upper = $end;

    with @dict[$lower..$upper] -> @list {
        # Maybe the word doesn't exist in the list, in that case there
        # will be a single element in @list. We return an empty list
        # unless that single element starts with $str.
        if @list.elems == 1 {
            return () unless @list[0].starts-with($str);
        }
        return @list;
    }
}
