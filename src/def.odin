package main

import "vendor:glfw"

TABLE_SIZE :: 256

Settings :: struct {
    width:  i32,
    height: i32,      // 0 = min, 1 = max
}

State :: struct {
    window: glfw.WindowHandle,
    window_dimensions: [2]i32,
    
    program_table: [TABLE_SIZE]Program,
    program_table_free: [dynamic]int,

    graph_table: [TABLE_SIZE]Graph,
    graph_table_free: [dynamic]int,
    variable_table: Variable_Table,

    graph_draw_queue: map[int]u8,
    gfx: Gfx,
}

settings: Settings
state: State