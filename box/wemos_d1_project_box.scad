// ============================================================
// Project box: Wemos D1 mini (header-mounted, rotated 90 deg, left side)
// + female RJ45 jack (right side, opening facing UP) on a 46 x 29 mm PCB.
//
// Set `part` to "cover", "bottom", "both" (print layout) or "preview".
// All units mm.
// ============================================================

part = "both";            // "box" | "cover" | "both" | "preview"

/* [PCB] */
pcb_x        = 46.5;      // PCB length, horizontal (X)
pcb_y        = 31.6;      // PCB width,  vertical   (Y)
pcb_t        = 1.6;       // PCB thickness
pcb_clear    = 0.5;       // gap around PCB (each side)

/* [Wemos D1 mini] */
mini_w       = 25.6;      // module width  (across X, since it is rotated)
mini_l       = 31.6;      // module length (along Y, USB end at one side)
mini_x_off   = 1.5;       // gap from PCB left edge to module's left edge
mini_ant_off = 6;         // antenna shift

usb_side     = "front";   // "front" (Y=0 wall) or "back" (Y=max wall)

/* [RJ45 jack - opening faces up through the cover top] */
rj45_w       = 16;        // jack width  (along Y, plan view)
rj45_d       = 15;        // jack depth  (along X, plan view)
rj45_h       = 1;         // jack height above PCB (top face of the jack)
rj45_y_off   = -3;        // shift jack centre from PCB centre (+Y / -Y)
rj45_x_inset = 1.7;       // distance from PCB right edge to jack's right side
rj45_tol     = 0.6;       // extra opening clearance (total, per axis)

/* [Heights] */
under_pcb    = 3;         // space below PCB (solder joints / pin tails)
above_pcb_min = 13.5;     // min space above PCB top (header ~8.5 + D1 mini + margin)
above_pcb    = max(above_pcb_min, rj45_h + 1);   // grows automatically to fit the jack

/* [Box] */
wall         = 1.5;
plate_t      = 1.5;       // bottom plate thickness (also the friction-fit depth)
plate_l      = 1;         // brim on bottom plate
top_t        = 1.5;       // cover top thickness
corner_r     = 2;

/* [Standoffs] */
standoff_d   = 5;
standoff_lip = 3;         // overlap onto PCB corner (retention ledge)

/* [USB-C opening] */
// USB-C receptacle is ~9 x 3.3 mm; the opening is sized for the cable's plug
// overmould (~12 x 6.5 mm) so a normal cable can be pushed all the way in.
usb_w        = 10;        // opening width (along X)
usb_h        = 4;         // opening height
usb_x_offset = 0;         // shift left/right from module centre
usb_z        = 6;         // bottom of opening above PCB top (centre ~11 = header 8.5 + module 1 + half connector)

/* [Ventilation (cover top, over the D1 mini)] */
vent_slots   = 5;
vent_slot_w  = 1.6;
vent_slot_l  = 16;
vent_pitch   = 4;

/* [Fit] */
fit_gap      = 0;         // plate-to-cover clearance (tune for your printer)

/* [Misc] */
$fn          = 48;
explode      = 12;

// ---------------- derived values ----------------
overhang = max(0, mini_l - pcb_y);
in_w   = pcb_x + 2 * pcb_clear;
in_l   = pcb_y + 2 * pcb_clear + overhang;
in_h   = under_pcb + pcb_t + above_pcb;
out_w  = in_w + 2 * wall;
out_l  = in_l + 2 * wall;
cover_h = plate_t + in_h + top_t;          // z=0 is the open rim of the cover

px0 = wall + pcb_clear;
py0 = wall + pcb_clear + (usb_side == "front" ? overhang : 0);
pcb_top_z = plate_t + under_pcb + pcb_t;

// ---------------- helpers ----------------
module rounded_box(w, l, h, r) {
    translate([r, r, 0])
        hull()
            for (x = [0, w - 2 * r], y = [0, l - 2 * r])
                translate([x, y, 0]) cylinder(r = r, h = h);
}

// footprint of the bottom plate (in cover coordinates)
module plate_footprint(w, l, h, r) {
    translate([wall + fit_gap, wall + fit_gap, 0]) cube([in_w - 2 * fit_gap, in_l - 2 * fit_gap, h]);
    translate([r, r, 0])
    hull()
    {
        for (x = [0, w - 2 * r], y = [0, l - 2 * r])
            translate([x, y, 0]) cylinder(r = r, h = plate_l);
            
    }
}

// ---------------- bottom ----------------
module bottom() {
    plate_footprint(out_w, out_l, plate_t, corner_r);
    // PCB corner standoffs, clipped to the plate footprint
    corners = [
        [px0,         py0,         1,  1],
        [px0 + pcb_x, py0,        -1,  1],
        [px0,         py0 + pcb_y, 1, -1],
        [px0 + pcb_x, py0 + pcb_y,-1, -1]
    ];
    intersection() {
        plate_footprint(out_w, out_l, plate_t+ under_pcb, corner_r);
        for (c = corners)
            translate([c[0] - c[2] * (standoff_d / 2 - standoff_lip),
                       c[1] - c[3] * (standoff_d / 2 - standoff_lip),
                       plate_t - 0.01])
                cylinder(d = standoff_d, h = under_pcb + 0.01);
    }
}

// ---------------- cover ----------------
module usb_cut() {
    cx = px0 + mini_x_off + mini_w / 2 + usb_x_offset;
    y0 = (usb_side == "front") ? -1 : out_l - wall - 1;
    translate([cx - usb_w / 2, y0, pcb_top_z + usb_z])
        cube([usb_w, wall + 2, usb_h]);
    
    translate([cx - usb_w / 2-1.5, y0, pcb_top_z + usb_z-2])
        cube([usb_w+3, 1+wall/2, usb_h+4]);    

}

module rj45_cut() {
    // opening through the cover top, over the jack
    cx = px0 + pcb_x - rj45_x_inset - rj45_d / 2;
    cy = py0 + pcb_y / 2 + rj45_y_off;
    translate([cx - (rj45_d + rj45_tol) / 2,
               cy - (rj45_w + rj45_tol) / 2,
               cover_h - top_t - 1])
        cube([rj45_d + rj45_tol, rj45_w + rj45_tol, top_t + 2]);
}

module cover() {
    vent_cx = px0 + mini_x_off + mini_w / 2;
    difference() {
        rounded_box(out_w, out_l, cover_h, corner_r);
        // cavity, open at z=0
        translate([wall, wall, -1]) cube([in_w, in_l, cover_h - top_t + 1]);
        usb_cut();
        rj45_cut();
        if (vent_slots > 0)
            for (i = [0 : vent_slots - 1]) {
                off = (i - (vent_slots - 1) / 2) * vent_pitch;
                translate([vent_cx - vent_slot_w / 2 + off,
                           out_l / 2 - vent_slot_l / 2 + mini_ant_off,
                           cover_h - top_t - 1])
                    cube([vent_slot_w, vent_slot_l, top_t + 2]);
            }
    }
}

module cover_flipped() {   // top-down on the print bed
    translate([0, out_l, cover_h]) rotate([180, 0, 0]) cover();
}

// ---------------- ghost parts for preview ----------------
module ghosts() {
    color("green", 0.5) translate([px0, py0, plate_t + under_pcb]) cube([pcb_x, pcb_y, pcb_t]);
    my0 = (usb_side == "front") ? py0 - overhang : py0;
    color("blue", 0.4) translate([px0 + mini_x_off, my0, pcb_top_z + 8.5]) cube([mini_w, mini_l, 5]);
    color("silver", 0.6)
        translate([px0 + pcb_x - rj45_x_inset - rj45_d, py0 + pcb_y / 2 + rj45_y_off - rj45_w / 2, pcb_top_z])
            cube([rj45_d, rj45_w, rj45_h]);
}

// ---------------- output ----------------
if (part == "box") {
    cover_flipped();
} else if (part == "bottom") {
    bottom();
} else if (part == "both") {
    cover_flipped();
    translate([out_w + explode, 0, 0]) bottom();
} else {
    cover();
    color("orange") bottom();
    ghosts();
}

echo(str("Outer size: ", out_w, " x ", out_l, " x ", cover_h, " mm"));
