/*
 * Gridfinity Material Swatches Holder V2
 * By smkent (GitHub) / bulbasaur0 (Printables)
 *
 * MIT License (see LICENSE file)
 *
 * Material Swatches by Ryan:
 * https://www.printables.com/model/2256-material-swatches
 */

include <gridfinity-rebuilt-openscad/gridfinity-rebuilt-utility.scad>;

/* [Setup Parameters] */
$fa = 8;
$fs = 0.25;

/* [General Settings] */
// number of bases along x-axis
gridx = 1;
// number of bases along y-axis
gridy = 3;
// bin height. See bin height information and "gridz_define" below.
gridz = 6; // [1:1:6]

/* [Wire Holder Features] */
Min_Z = 1.77; // [0:0.01:4]

/* [Height] */
// determine what the variable "gridz" applies to based on your use case
gridz_define = 0; // [0:gridz is the height of bins in units of 7mm increments - Zack's method,1:gridz is the internal height in millimeters, 2:gridz is the overall external height of the bin in millimeters]
// overrides internal block height of bin (for solid containers). Leave zero for default height. Units: mm
height_internal = 0;
// snap gridz height to nearest 7mm increment
enable_zsnap = false;

/* [Features] */
// how should the top lip act
style_lip = 0; //[0: Regular lip, 1:remove lip subtractively, 2: remove lip and retain height]
// only cut magnet/screw holes at the corners of the bin to save unneccesary print time
only_corners = false;

/* [Base] */
style_hole = 3; // [0:no holes, 1:magnet holes only, 2: magnet and screw holes - no printable slit, 3: magnet and screw holes - printable slit]
// number of divisions per 1 unit of base along the X axis. (default 1, only use integers. 0 means automatically guess the right division)
div_base_x = 0;
// number of divisions per 1 unit of base along the Y axis. (default 1, only use integers. 0 means automatically guess the right division)
div_base_y = 0;

stacking_tabs = true;

module __end_customizer_options__() { }

// Constants //

swatch_length = 35;
swatch_width = 35;
swatch_thickness = 3.5;

swatch_separation = 1.586;

sw_l = swatch_length;
sw_w = swatch_width;
sw_t = swatch_thickness;

// min_z = Min_Z;
pivot_z = 4;
min_z = gridz >= pivot_z ? 1.77 : 0.94;
slop = 0.01;

// Modules //

function gf_height() = height(gridz, gridz_define, style_lip, enable_zsnap);

function swatch_row_count(grid_y) = floor(((l_grid * grid_y) - d_wall2 * 2) / (sw_t + swatch_separation));

module swatch_shape() {
    polygon([
        [0.6, 0],
        [0, 0.6],
        [0, sw_w - 0.6],
        [0.6, sw_w],
        [sw_t - 0.6, sw_w],
        [sw_t, sw_w - 0.6],
        [sw_t, 0.6],
        [sw_t - 0.6, 0]
    ]);
}

module swatch_polygon() {
    translate([0, -sw_l / 2, -sw_w / 2])
    translate([0, 0, -sw_t])
    linear_extrude(height=sw_l)
    swatch_shape();
}

module swatch_cut(grid_x, grid_y) {
    ht = gf_height();
    swatch_count = swatch_row_count(grid_y);
    all_swatches_depth = sw_t * swatch_count + swatch_separation * (swatch_count - 1);
    translate([0, 0, h_bot - ht + (gridz >= pivot_z ? 2 : -3)])
    union() {
        rotate([0, 0, 90])
        translate([-all_swatches_depth/2, 0, sw_w / 2])
        for (i = [0:1:swatch_count-1]) {
            translate([(sw_t + swatch_separation) * i, 0, 0])
            swatch_polygon();
        }
    }
}

module side_cut(grid_x, grid_y) {
    ht = gf_height();
    zz = (gridz - min_z) * 7;
    xx = grid_x * 42 + 10;
    yy = grid_y * 42 - 10;
    translate([0, 0, -zz / 2 + 0.202])
    for (rot = [0, 90])
    rotate([0, 0, rot])
    rotate([90, 0, 0])
    linear_extrude(height=xx, center=true)
    offset(r=5)
    offset(r=-5)
    translate([-yy / 2, -zz / 2])
    square([yy, zz - 3.3]);
    // cube([xx, yy, zz], center=true);

}


module stubInit(gx, gy, h, h0 = 0, l = l_grid) {
    $gxx = gx;
    $gyy = gy;
    $dh = h;
    $dh0 = h0;
    children();
}

module main() {
    ht = gf_height();
    color("lemonchiffon") {
        stubInit(gridx, gridy, ht, height_internal) {
            difference() {
                union() {
                    gridfinityInit(gridx, gridy, ht, height_internal) {
                        if (gridz > min_z) {
                            swcut = 0.02;
                            cut_height = height(min_z + 1, gridz_define, style_lip, enable_zsnap);
                            translate([0, 0, (min_z - 1) * 7])
                            cut(swcut, swcut, gridx - swcut * 2, gridy - swcut * 2, 5, 0);
                        }
                    }
                    gridfinityBase(gridx, gridy, l_grid, div_base_x, div_base_y, style_hole, only_corners=only_corners);
                }
                if (style_hole == 0 && gridz < pivot_z) {
                    for (x = [0:1:gridx - 1], y = [0:1:gridy - 1]) {
                        cut_move(x, y, 1, 1) {
                            swatch_cut(1, 1);
                        }
                    }
                } else {
                    for (x = [0:1:gridx - 1]) {
                        cut_move(x, 0, 1, gridy) {
                            swatch_cut(1, gridy);
                        }
                    }
                }
                for (x = [0:1:gridx - 1], y = [0:1:gridy - 1]) {
                    cut_move(x, y, 1, 1) {
                        side_cut(1, 1);
                    }
                }
            }
        }
    }
    echo(
        str(
            gridx, "x", gridy, " bin capacity: ", gridx * swatch_row_count(gridy),
            " swatches (",  swatch_row_count(gridy), " per column)"
        )
    );
}

main();
