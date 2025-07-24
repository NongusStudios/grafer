package main

import "core:fmt"
import m "core:math"
import "core:strings"

import "vendor:glfw"
import gl "vendor:OpenGL"

on_window_size_changed :: proc "c" (window: glfw.WindowHandle, w, h: i32) {
    state.window_dimensions = {w, h}
}

init_window :: proc() -> string {
    using state
    
    if !glfw.Init() {
        return "failed to initialise GLFW"
    }

    GL_MAJOR  :: 3
    GL_MINROR :: 3

    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINROR)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, glfw.TRUE)

    glfw.WindowHint(glfw.RESIZABLE, glfw.FALSE)

    window = glfw.CreateWindow(settings.width, settings.height, "grafer", nil, nil)

    glfw.SetFramebufferSizeCallback(window, on_window_size_changed)

    glfw.MakeContextCurrent(window)
    glfw.SwapInterval(1)

    gl.load_up_to(GL_MAJOR, GL_MINROR, glfw.gl_set_proc_address)

    w, h := glfw.GetFramebufferSize(window)
    gl.Viewport(0, 0, w, h)

    return ""
}

init :: proc() -> bool {
    e := init_window()

    if e != "" {
        fmt.eprintln(e)
        return false
    }

    init_gfx()
    init_program_table()
    init_graph_table()

    return true
}

cleanup :: proc() {
    using state

    free_graph_table()
    free_program_table()
    free_gfx()
    glfw.DestroyWindow(window)
    glfw.Terminate()
}

run :: proc() {
    using state

    g := add_graph("x=y*2")
    graph_draw_queue[g] = 0

    for !glfw.WindowShouldClose(window) {
        glfw.PollEvents()
        draw()
        glfw.SwapBuffers(window)
    }
}

main :: proc() {
    using settings

    width = 1024
    height = 1024

    if !init(){return}
    defer cleanup()

    run()
}