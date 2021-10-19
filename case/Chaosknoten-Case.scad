// Case for Chaosknoten

$wall_thickness = 1.0;
$clip_width = 0.2;
$clip_length = 10;

$pcb_width = 65.0;
$pcb_depth = 50.0;
$pcb_thickness = 0.8;

$well_height = 4.5;
$bottom_thickness = 2 * $wall_thickness;
$post_diameter = 4.5;
$post_x = 4;
$pin_diameter = 2;

$switch_width = 7;
$switch_x = 3.1;
$switch_y = 10;

$fs = 0.5;

$text = "CHAOSKNOTEN";

use <roundedcube.scad>;

union() {
    difference() {
        roundedcube([2*$wall_thickness+$pcb_width, 2*$wall_thickness+$pcb_depth, $well_height+$pcb_thickness+$bottom_thickness], apply_to="zmin");
        translate([$wall_thickness, $wall_thickness, $bottom_thickness])
            cube([$pcb_width,$pcb_depth,10]);
        translate([$wall_thickness+$switch_x, $wall_thickness+$switch_y, -.1])
            cube([$switch_width,$switch_width,$bottom_thickness+.2]);
        translate([(2*$wall_thickness+$pcb_width)/2, (2*$wall_thickness+$pcb_depth)/2, -.1])
            linear_extrude($wall_thickness)
                scale(0.1)
                    import("Fairydust.dxf", center=true);
    }
    rotate([90, 0, 0]) {
        translate([(2*$wall_thickness+$pcb_width)/2, ($well_height+$pcb_thickness+$bottom_thickness)/2, 0]) {
            scale([0.5,0.5,1]) {
                linear_extrude(0.5) {
                    text(text=$text, font="Arial Black", halign="center", valign="center");
                }
            }
        }
    }
    // posts
    translate([$post_x+$wall_thickness, $post_x+$wall_thickness, $bottom_thickness]) {
        cylinder($well_height, $post_diameter/2, $post_diameter/2);
        cylinder($well_height+$pcb_thickness, $pin_diameter/2, $pin_diameter/2);
    }
    translate([$wall_thickness+$pcb_width-$post_x, $post_x+$wall_thickness, $bottom_thickness]) {
        cylinder($well_height, $post_diameter/2, $post_diameter/2);
        cylinder($well_height+$pcb_thickness, $pin_diameter/2, $pin_diameter/2);
    }
    translate([$post_x+$wall_thickness, $wall_thickness+$pcb_depth-$post_x, $bottom_thickness]) {
        cylinder($well_height, $post_diameter/2, $post_diameter/2);
        cylinder($well_height+$pcb_thickness, $pin_diameter/2, $pin_diameter/2);
    }
    translate([$wall_thickness+$pcb_width-$post_x, $wall_thickness+$pcb_depth-$post_x, $bottom_thickness]) {
        cylinder($well_height, $post_diameter/2, $post_diameter/2);
        cylinder($well_height+$pcb_thickness, $pin_diameter/2, $pin_diameter/2);
    }
    // clip
    translate([0, (2*$wall_thickness+$pcb_depth-$clip_length)/2, $bottom_thickness+$well_height+$pcb_thickness-$clip_width])
        cube([$wall_thickness+$clip_width, $clip_length, $clip_width]);
    translate([$wall_thickness+$pcb_width-$clip_width, (2*$wall_thickness+$pcb_depth-$clip_length)/2, $bottom_thickness+$well_height+$pcb_thickness-$clip_width])
        cube([$wall_thickness+$clip_width, $clip_length, $clip_width]);
}