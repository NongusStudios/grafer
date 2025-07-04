package main

import "core:fmt"
import m "core:math"
import "core:strings"

import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

init :: proc() {
    using rl

    init_program_table()

    InitWindow(settings.width, settings.height, "grafer")
    SetTargetFPS(60)

    di := i32(settings.graph_dimensions[1] - settings.graph_dimensions[0])
    graph_render_texture = LoadRenderTexture(di, di)

    main_camera.zoom = 1.0

    graph_camera.zoom = 4.0
    graph_camera.target = {f32(settings.graph_dimensions[0]/4), f32(settings.graph_dimensions[0]/4)}

    program_string_buf = make([]u8, 255)
    program_string = cstring(raw_data(program_string_buf))
}

cleanup :: proc() {
    using rl
    UnloadRenderTexture(graph_render_texture)
    CloseWindow()

    free_program_table()
}

// Makes an array of points using a compiled equation. 'f' is an equation id
calculate_graph :: proc(f: int) -> [dynamic]rl.Vector2 {
    using settings

    STEP :: 1

    points := make([dynamic]rl.Vector2, 0, int((graph_dimensions[1]-graph_dimensions[0]) / STEP))

    for p := graph_dimensions[0]; p <= graph_dimensions[1]; p += STEP {
        variable_table.x = p
        variable_table.y = p
        eval_equation(f, &variable_table)
        append(&points, rl.Vector2{f32(variable_table.x), f32(variable_table.y)})
    }

    return points
}

run :: proc() {
    using rl

    PADDING := f32(settings.width - i32(settings.graph_dimensions[1]*2))

    program_id = add_equation("y=x")

    for !WindowShouldClose() {
        BeginDrawing()
            ClearBackground(settings.background_colour)
            
            points := calculate_graph(program_id)
            defer delete(points)

            // Draw graph to texture
            BeginTextureMode(graph_render_texture)
                ClearBackground(settings.background_colour)
                draw_graph(points[:])
            EndTextureMode()

            BeginMode2D(main_camera)
                DrawTexture(graph_render_texture.texture, i32(PADDING), 0, WHITE)
                draw_gui(PADDING)
            EndMode2D()
            
        EndDrawing()
    }
}

main :: proc() {
    using settings

    width = 1280
    height = 1080

    graph_dimensions = {-f64(height/2), f64(height/2)}

    background_colour = {220, 220, 220, 255}

    init()
    defer cleanup()

    run()
}