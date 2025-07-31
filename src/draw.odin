package main

import "core:fmt"
import "core:strings"
import "core:mem"
import m "core:math/linalg"

import "vendor:glfw"
import gl "vendor:OpenGL"

Mesh :: struct {
    vbuf: u32,
    ibuf: u32,
    va:   u32,
}

Gfx :: struct {
    quad_mesh: Mesh,
    
    prgm_draw_framebuffer: u32,
    prgm_draw_equation:    u32,
    prgm_draw_graph_lines: u32,
}

Vec2 :: m.Vector2f32
Mat4 :: m.Matrix4f32

Vertex :: struct {
    position: Vec2,
    uv:       Vec2,
}

Index :: u32

quad_vertices :: [4]Vertex{
    Vertex{position={-1.0,  1.0}, uv={0.0, 0.0}}, // top left
    Vertex{position={ 1.0,  1.0}, uv={0.0, 0.0}}, // top right
    Vertex{position={ 1.0, -1.0}, uv={0.0, 0.0}}, // bottom right
    Vertex{position={-1.0, -1.0}, uv={0.0, 0.0}}, // bottom left
}

quad_indices :: [6]Index{
    0, 1, 2, // tri #1
    0, 2, 3, // tri #2
}

init_gfx :: proc() {
}

free_gfx :: proc() {

}

draw :: proc() {
    gl.ClearColor(0.8, 0.7, 0.7, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT)
}
