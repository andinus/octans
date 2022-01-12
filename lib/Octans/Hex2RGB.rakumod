# This module has been adapted from Fornax::Hex2RGB.

#| Takes hex value and returns RGB equivalent.
sub hex2rgb(Str $hex --> List) is export {
    # Skip the first character, group each by 2 and parse as base 16.
    # Divide by 255 to return value between 0, 1.
    $hex.comb.skip.rotor(2).map(
        *.join.parse-base(16) / 255
    )>>.Rat
}
