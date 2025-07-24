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

create_mesh :: proc(vertices: []Vertex, indices: []Index) -> Mesh {
    mesh: Mesh

    bufs := [2]u32{}
    gl.CreateBuffers(2, raw_data(bufs[:]))
    mesh.vbuf = bufs[0]
    mesh.ibuf = bufs[1]

    gl.CreateVertexArrays(1, &mesh.va)

    gl.NamedBufferStorage(mesh.vbuf, len(vertices)*size_of(Vertex), raw_data(vertices), gl.DYNAMIC_STORAGE_BIT)
    gl.NamedBufferStorage(mesh.ibuf, len(indices)*size_of(Index),   raw_data(indices),  gl.DYNAMIC_STORAGE_BIT)

    gl.VertexArrayVertexBuffer(mesh.va, 0, mesh.vbuf, 0, size_of(Vertex))
    gl.VertexArrayElementBuffer(mesh.va, mesh.ibuf)

    gl.EnableVertexArrayAttrib(mesh.va, 0)
    gl.EnableVertexArrayAttrib(mesh.va, 1)

    gl.VertexArrayAttribFormat(mesh.va, 0, 2, gl.FLOAT, false, 0)
    gl.VertexArrayAttribFormat(mesh.va, 0, 2, gl.FLOAT, false, size_of(Vec2))

    gl.VertexArrayAttribBinding(mesh.va, 0, 0)
    gl.VertexArrayAttribBinding(mesh.va, 1, 0)

    return mesh
}

destroy_mesh :: proc(mesh: ^Mesh) {
    gl.DeleteVertexArrays(1, &mesh.va)
    gl.DeleteBuffers(1, &mesh.vbuf)
    gl.DeleteBuffers(1, &mesh.ibuf)
    mesh^ = {}
}

Frame :: struct {
    colour_buffer: u32,
    framebuffer: u32,
    dimensions: [2]i32,
}

create_frame :: proc(width, height: i32) -> Frame {
    frame: Frame
    frame.dimensions = {width, height}

    gl.CreateFramebuffers(1, &frame.framebuffer)

    gl.CreateTextures(gl.TEXTURE_2D, 1, &frame.colour_buffer)
    gl.TextureParameteri(frame.colour_buffer, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.TextureParameteri(frame.colour_buffer, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.TextureStorage2D(frame.colour_buffer, 1, gl.RGBA8, width, height)

    gl.NamedFramebufferTexture(frame.framebuffer, gl.COLOR_ATTACHMENT0, frame.colour_buffer, 0)

    return frame
}

resize_frame :: proc(frame: ^Frame, new_width, new_height: i32) {
    destroy_frame(frame)
    frame^ = create_frame(new_width, new_height)
}

destroy_frame :: proc(frame: ^Frame) {
    gl.DeleteFramebuffers(1, &frame.framebuffer)
    gl.DeleteTextures(1, &frame.colour_buffer)
    frame^ = {}
}

Gfx :: struct {
    quad_mesh: Mesh,
    graph_frame: Frame,
}

Vec2 :: m.Vector2f32
Mat4 :: m.Matrix4f32

Vertex :: struct {
    position: Vec2,
    uv:       Vec2,
}

Index :: u32

init_gfx :: proc() {
    using state.gfx

    graph_frame = create_frame(state.window_dimensions[0], state.window_dimensions[1])

    quad_vertices := []Vertex{
        Vertex{position={-1.0,  1.0}, uv={0.0, 0.0}}, // top left
        Vertex{position={ 1.0,  1.0}, uv={0.0, 0.0}}, // top right
        Vertex{position={ 1.0, -1.0}, uv={0.0, 0.0}}, // bottom right
        Vertex{position={-1.0, -1.0}, uv={0.0, 0.0}}, // bottom left
    }

    quad_indices := []Index{
        0, 1, 2, // tri #1
        0, 2, 3, // tri #2
    }
    quad_mesh = create_mesh(quad_vertices, quad_indices)

    state.graph_draw_queue = make(map[int]u8)
}

free_gfx :: proc() {
    using state.gfx

    destroy_mesh(&quad_mesh)
}

draw :: proc() {
    gl.ClearColor(0.8, 0.7, 0.7, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT)
}
