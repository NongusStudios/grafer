package main

import "vendor:glfw"

Settings :: struct {
    width:  i32,
    height: i32,      // 0 = min, 1 = max
}

settings: Settings
state: struct {
    window: glfw.WindowHandle,
    
    program_table: [PROGRAM_TABLE_SIZE]Program,
    program_table_free: [dynamic]int,
    variable_table: Variable_Table,

    program_id: int,

    gfx: Gfx,
}


PROGRAM_TABLE_SIZE :: 256