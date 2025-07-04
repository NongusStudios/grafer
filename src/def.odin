package main

import rl "vendor:raylib"

// This file defines globals and mesc types
Point :: [2]f64

Equation_Mode :: enum {
    XIN,
    YIN,
}

Settings :: struct {
    width:  i32,
    height: i32,      // 0 = min, 1 = max
    graph_dimensions: Point,
    background_colour: rl.Color,
}

settings: Settings

main_camera: rl.Camera2D
graph_camera: rl.Camera2D
graph_render_texture: rl.RenderTexture2D

PROGRAM_TABLE_SIZE :: 256
program_table: [PROGRAM_TABLE_SIZE]Program
program_table_free: [dynamic]int
variable_table: Variable_Table

program_string_buf: []u8
program_string: cstring
program_id: int = 0