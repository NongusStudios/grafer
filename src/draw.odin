package main

import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

import "core:fmt"
import "core:strings"
import "core:mem"

draw_gui :: proc(padding: f32) {
    using rl

    if GuiTextBox({width = padding, height = 128, x=0, y=0}, program_string, 24, true) {
        fmt.println(string(program_string))
        recompile_equation(program_id, string(program_string))
    }
}

draw_grid :: proc() {
    using rl

    CELL_SIZE :: 10.0

    min := settings.graph_dimensions[0]
    max := settings.graph_dimensions[1]

    segments := (max - min) / CELL_SIZE
    grid_size := segments/2.0 * CELL_SIZE

    xcoord := f32(segments/4.0 * CELL_SIZE - max/2.0)
    ycoord := segments/4.0 * CELL_SIZE
    
    BeginMode2D(graph_camera)
        // top half
        rlgl.PushMatrix()
            rlgl.Translatef(xcoord, f32(ycoord - max/2.0), 0.0)
            rlgl.Rotatef(90.0, 1.0, 0.0, 0.0)
            DrawGrid(i32(segments), CELL_SIZE)
        rlgl.PopMatrix()

        // second half
        rlgl.PushMatrix()
            rlgl.Translatef(xcoord, f32(ycoord + max/2.0), 0.0)
            rlgl.Rotatef(90.0, 1.0, 0.0, 0.0)
            DrawGrid(i32(segments), CELL_SIZE)
        rlgl.PopMatrix()

        DrawLine(0, i32(min), 0, i32(max), BLACK)
        DrawLine(i32(min), 0, i32(max), 0, BLACK)
     EndMode2D()
}

draw_graph :: proc(points: []rl.Vector2) {
    using rl

    draw_grid()
    BeginMode2D(graph_camera)
        rlgl.SetLineWidth(2.0)
        DrawLineStrip(raw_data(points), i32(len(points)), RED)
    EndMode2D(); rlgl.SetLineWidth(1.0)
}