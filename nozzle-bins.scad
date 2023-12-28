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
gridx = 2;
// number of bases along y-axis
gridy = 4;
// bin height. See bin height information and "gridz_define" below.
gridz = 3; // [2:1:6]

/* [Nozzle Holder Features] */
Min_Z = 4; // [0:1:4]

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

nozzle_d = 6.4;
nozzle_thread_ht = 16;
nozzle_separation = 5.7;

min_z = Min_Z;

slop = 0.01;

// Modules //

function gf_height() = height(gridz, gridz_define, style_lip, enable_zsnap);

function nozzle_count(grid) = floor(((l_grid * grid) - d_wall2 * 2) / (nozzle_d + nozzle_separation));

module nozzle_polygon() {
    // translate([0, 0, slop])
    mirror([0, 0, 1])
    cylinder(h=nozzle_thread_ht * 2, d=nozzle_d, center=true);
    // cylinder(h=(23.6 - nozzle_thread_ht), d=(nozzle_d + 2.0));
}

module nozzle_cut(grid_x, grid_y) {
    ncx = nozzle_count(grid_x);
    ncy = nozzle_count(grid_y);
    align_z = 3;
    ht = (gridz - align_z) * 7;
    cut_sz_x = (ncx - 1) * (nozzle_d + nozzle_separation);
    cut_sz_y = (ncy - 1) * (nozzle_d + nozzle_separation);
    base_adj = h_base - (0.2 * 8);
    translate([0, 0, -ht - base_adj])
    for (nx = [0:1:ncx - 1], ny = [0:1:ncy - 1])
    translate([-cut_sz_x / 2, -cut_sz_y / 2, 0])
    union() {
        translate([
            (nozzle_d + nozzle_separation) * nx + 0*nozzle_separation,
            (nozzle_d + nozzle_separation) * ny + 0*nozzle_separation,
            0
        ])
        union() {
            nozzle_polygon();
            translate([0, 0, ((min_z - align_z) * 7) + base_adj + 0.2 + slop])
            mirror([0, 0, 1])
            #cylinder(h=2, d2=nozzle_d, d1=nozzle_d + 2);
        }
    }
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
    color("lightsteelblue", 0.8) {
        difference() {
            union() {
                gridfinityInit(gridx, gridy, ht, height_internal) {
                    if (gridz > min_z) {
                        cut_height = height(min_z + 1, gridz_define, style_lip, enable_zsnap);
                        translate([0, 0, (min_z - 1) * 7])
                        cut(0, 0, gridx, gridy, 5, 0);
                    }
                }
                gridfinityBase(gridx, gridy, l_grid, div_base_x, div_base_y, style_hole, only_corners=only_corners);
            }
            stubInit(gridx, gridy, ht, height_internal) {
                for (x = [0:1:gridx-1], y = [0:1:gridy-1])
                cut_move(x, y, 1, 1) {
                    nozzle_cut(1, 1);
                }
            }
        }
    }
}

main();

if (0)
intersection() {
    main();
    linear_extrude(height=50)
    translate([3, 3])
    square(23);
}
