package main

import "core:fmt"
import "vendor:glfw"

POINT_STEP :: 2

Point :: [2]f64

Graph :: struct {
    equation: int,
    points:   [dynamic]Point,
}

init_graph_table :: proc() {
    state.graph_table_free = make([dynamic]int, TABLE_SIZE)
    for &i, index in state.graph_table_free {
        i = index
    }

    state.variable_table = init_vtab()
}

free_graph_table :: proc() {
    delete(state.graph_table_free)
    free_vtab(&state.variable_table)
}

add_graph :: proc(eq: string) -> int {
    graph: Graph
    
    graph.equation = add_equation(eq)
    if graph.equation == -1 { return -1 }
 
    w, h := glfw.GetFramebufferSize(state.window)
    point_count := w if w > h else h
    graph.points = make([dynamic]Point, point_count)

    idx := pop_front(&state.graph_table_free)
    state.graph_table[idx] = graph

    return idx
}

remove_graph :: proc(id: int) {
    if id < 0 && id > TABLE_SIZE {
        fmt.eprintfln("cannot remove graph[%i]: index out of range", id)
        return
    }

    graph := &state.graph_table[id]
    remove_equation(graph.equation)
    delete(graph.points)

    append(&state.graph_table_free, id)
}

graph_calculate_points :: proc(id: int) -> bool {
    if id < 0 && id > TABLE_SIZE {
        fmt.eprintfln("cannot access graph[%i]: index out of range", id)
        return false
    }

    di := state.window_dimensions
    graph := state.graph_table[id]
    clear(&graph.points)

    vtab := &state.variable_table
    for x := -di[0]/2; x < di[0]/2; x += POINT_STEP {
        vtab.x = f64(x)
        vtab.y = f64(x)
        e := eval_equation(graph.equation, vtab)
        if e != "" {
            fmt.eprintfln("error in graph[%i]: %s", id, e)
            return false
        }

        append(&graph.points, Point{vtab.x, vtab.y})
    }

    return true
}