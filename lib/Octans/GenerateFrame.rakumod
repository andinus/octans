# This module has been adapted from Fornax::GenerateFrame.

use Cairo;
use Octans::Hex2RGB;

# Colors.
constant %C = (
    bg-main => "#ffffff",

    red-subtle-bg => "#f2b0a2",
    blue-subtle-bg => "#b5d0ff",
    cyan-subtle-bg => "#c0efff",
    green-subtle-bg => "#aecf90",

    fg-main => "#000000",

    fg-special-cold => "#093060",
    fg-special-warm => "#5d3026",
    fg-special-mild => "#184034",
    fg-special-calm => "#61284f",
).map: {.key => hex2rgb(.value)};

enum IterStatus <Walking Blocked Completed>;

sub generate-frame(
    :%canvas, :$out, :$side, :@puzzle, :@visited, :%meta, :$found
) is export {
    given Cairo::Image.create(
        Cairo::FORMAT_ARGB32, %canvas<width>, %canvas<height>
    ) {
        given Cairo::Context.new($_) {
            # Paint the entire canvas white.
            .rgb: |%C<bg-main>;
            .rectangle(0, 0, %canvas<width>, %canvas<height>);
            .fill;

            # This seems to be slower than creating an intermediate
            # variable and assigning from that. Difference is not much
            # so we'll ignore it.
            for ^%meta<rows> X ^%meta<cols>  -> ($r, $c) {
                my Int @target = $c * $side, $r * $side,
                                 $side, $side;
                .rectangle: |@target;

                if @visited[$r][$c] {
                    .rgba: |%C<cyan-subtle-bg>, 0.72;
                    .rgba: |%C<green-subtle-bg>, 0.84 if $found;
                    .fill :preserve;
                }

                .select_font_face("Mono", Cairo::FONT_SLANT_NORMAL, Cairo::FONT_WEIGHT_NORMAL);
                .set_font_size(72.0);
                .move_to($c * $side + 32, ($r + 1) * $side - 28);

                .rgb: |%C<fg-main>;
                .show_text: @puzzle[$r][$c].uc;
                .stroke;
            }
        }
        .write_png($out);
        .finish;
    }
}
