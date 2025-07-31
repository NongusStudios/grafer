package main

import "core:fmt"
import "core:strings"
import "core:strconv"
import m "core:math"



/* Details for math notation
    -- variables
        User defined variables are single letter expressions ('a', 'b')
    -- builtin variables
        - 'x' evaluates to the current x-coordinate
        - 'y' evaluates to the current y-coordinate
    -- operators
        - '=' assignment
        - '+' addition
        - '-' subtraction/negation
        - '*' multiplication
        - '/' division
        - '^' power
    -- builtin functions
        - 'sin(x)' sine of x
        - 'cos(x)' cosine of x
        - 'tan(x)' tangent of x
        - 'asin(x)' inverse sine of x
        - 'acos(x)' inverse cosine of x
        - 'atan(x)' inverse tangent of x
        - 'sqrt(x)' square root of x
        - 'log(x)' log base 10 of x
    -- syntax
        - '(...)' groups list of expressions
        - ',' for separating arguments
*/

/*
 ====================
 -- Tokenizer Impl --
 ====================
*/

Value :: f64

Token_Type :: enum {
    Var,   // variable, built-in or user defined
    Op,    // operator
    Func,  // function, builtin or user defined
    Value, // numerical value
    Open_Bracket,
    Close_Bracket,
    Comma,
}

Token :: struct {
    type:    Token_Type,
    content: string,
    pos:     int,
}

is_digit :: proc(ch: u8) -> bool {
    if ch >= '0' && ch <= '9' {
        return true
    }
    return false
}

is_alpha :: proc(ch: u8) -> bool {
    if (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') {
        return true
    }
    return false
}

tokenise_equation :: proc(equation: string) -> [dynamic]Token {
    tokens := make([dynamic]Token)

    for pos := 0; pos < len(equation); {
        ch := equation[pos]
        if ch != ' ' { switch ch {
            case '+','-','*','/','^','=': append(&tokens, Token{.Op, equation[pos:pos+1], pos})
            case '(': append(&tokens, Token{.Open_Bracket, equation[pos:pos+1], pos})
            case ')': append(&tokens, Token{.Close_Bracket, equation[pos:pos+1], pos})
            case ',': append(&tokens, Token{.Comma, equation[pos:pos+1], pos})
            case: {
                // parse numerical value
                if is_digit(ch) || ch == '.' {
                    start := pos
                    has_dot := ch == '.'
                    pos += 1
                    for pos < len(equation) {
                        ch = equation[pos]
                        if ch == '.' && !has_dot { has_dot = true; pos += 1; continue }
                        else if !is_digit(ch) { break }
                        
                        pos += 1
                    }
                    append(&tokens, Token{.Value, equation[start:pos], start})
                    continue
                }

                // parse alpha token (disregarding functions for now)
                if is_alpha(ch) {
                    n := pos
                    //for ;is_alpha(equation[pos+1]); {pos += 1}
                    append(&tokens, Token{.Var, equation[pos:pos+1], n})
                }
            }
        }}
        pos += 1
    }

    return tokens
}

/*
 ==============
 -- AST Impl --
 ==============
*/

Ast_Type :: enum {
    Binary_Op,
    Unary_Op,
    Value,
    Var,
}

Ast_Node :: struct {
    type: Ast_Type,
    data: string,

    left: ^Ast_Node,
    right: ^Ast_Node,
}

init_ast_node :: proc() -> ^Ast_Node {
    root := new(Ast_Node)
    return root
}

free_ast_node :: proc(node: ^Ast_Node) {
    if node == nil { return }
    
    free_ast_node(node.left)
    free_ast_node(node.right)

    free(node)
}

str_is :: proc(s: string, checks: ..string) -> bool {
    for check in checks {
        if s == check { return true }
    }

    return false
}

parse_binary_op :: proc(tokens: ^[dynamic]Token, left: ^Ast_Node, next_precedent: proc(^[dynamic]Token) -> (^Ast_Node, string)) -> (^Ast_Node, string) {
    e: string
    op := pop_front(tokens)

    n := init_ast_node()
    n.type = .Binary_Op
    n.data = op.content

    n.left = left
    n.right, e = next_precedent(tokens)

    if e != "" {
        free_ast_node(n)
        return nil, e
    }

    return n, ""
}

// Lowest precedent
parse_equation :: proc(tokens: ^[dynamic]Token) -> (^Ast_Node, string) {
    node, e := parse_expression(tokens)
    if e != "" {
        free_ast_node(node)
        return nil, e
    }

    for len(tokens) > 0 && tokens[0].type == .Op && str_is(tokens[0].content, "=") {
        node, e = parse_binary_op(tokens, node, parse_expression)
        if e != "" {
            return nil, e
        }
    }

    return node, ""
}

// Second precedent
parse_expression :: proc(tokens: ^[dynamic]Token) -> (^Ast_Node, string) {
    node, e := parse_term(tokens)
    if e != "" {
        free_ast_node(node)
        return nil, e
    }

    for len(tokens) > 0 && tokens[0].type == .Op && str_is(tokens[0].content, "+", "-") {
        node, e = parse_binary_op(tokens, node, parse_term)
        if e != "" {
            return nil, e
        }
    }

    return node, ""
}

// Third Precedent
parse_term :: proc(tokens: ^[dynamic]Token) -> (^Ast_Node, string) {
    node, e := parse_exponent(tokens)
    if e != "" {
        free_ast_node(node)
        return nil, e
    }

    for len(tokens) > 0 && tokens[0].type == .Op && str_is(tokens[0].content, "*", "/") {
        node, e = parse_binary_op(tokens, node, parse_exponent)
        if e != "" {
            return nil, e
        }
    }

    return node, ""
}

// Fourth Precedent
parse_exponent :: proc(tokens: ^[dynamic]Token) -> (^Ast_Node, string) {
    node, e := parse_factor(tokens)
    if e != "" {
        free_ast_node(node)
        return nil, e
    }
    
    for len(tokens) > 0 && tokens[0].type == .Op && str_is(tokens[0].content, "^") {
        node, e = parse_binary_op(tokens, node, parse_factor)
        if e != "" {
            return nil, e
        }
    }

    return node, ""
}

// Highest precedent
parse_factor :: proc(tokens: ^[dynamic]Token) -> (^Ast_Node, string) {
    if len(tokens) == 0 { return nil, "" }

    node: ^Ast_Node = nil
    e := ""

    token := pop_front(tokens)
    #partial switch token.type {
        case .Var: {
            node = init_ast_node()
            node.type = .Var
            node.data = token.content
            node.left = nil
            node.right = nil
        }
        case .Value: {
            node = init_ast_node()
            node.type = .Value
            node.data = token.content
            node.left = nil
            node.right = nil
        }
        case .Open_Bracket: {
            node, e = parse_expression(tokens)
            close := pop_front(tokens)
            if close.type != .Close_Bracket {
                return nil, "syntax error: expected closing bracket."
            }
        }
        case .Op: if str_is(token.content, "+", "-") {
            node = init_ast_node()
            node.type = .Unary_Op
            node.data = token.content

            node.left, e = parse_factor(tokens)
        }
    }

    return node, e
}

build_ast :: proc(equation: string) -> (^Ast_Node, string) {
    tokens := tokenise_equation(equation)
    defer delete(tokens)

    root, e := parse_equation(&tokens)
    if e != "" {
        free_ast_node(root)
        return nil, e
    }

    return root, e
}

print_ast :: proc(node: ^Ast_Node, depth: int) {
    if node == nil { return }

    for i := 0; i < depth; i += 1 { fmt.print("  ") }
    fmt.printfln("type: %v, content: %s", node.type, node.data)
    print_ast(node.left, depth+1)
    print_ast(node.right, depth+1)
}

/*===============*
 *-- Execution --*
 *===============*/

Variable_Table :: struct {
    // builtin
    x: f64,
    y: f64,     // name, value
    custom: map[string]f64,
}

init_vtab :: proc() -> Variable_Table {
    return Variable_Table{
        x = 0.0,
        y = 0.0,
        custom = make(map[string]f64)
    }
}

free_vtab :: proc(vtab: ^Variable_Table) {
    delete(vtab.custom)
}

vtab_get_ref :: proc(vtab: ^Variable_Table, name: string) -> ^f64 {
    using vtab
    switch name {
        case "x": return &vtab.x
        case "y": return &vtab.y
        case: if val, ok := &custom[name]; ok { return val }
    }

    return nil
}

vtab_get_value :: proc(vtab: ^Variable_Table, name: string) -> f64 {
    v := vtab_get_ref(vtab, name)
    if v == nil {
        return 0.0
    }

    return v^
} 

vtab_set_value :: proc(vtab: ^Variable_Table, name: string, value: f64) {
    v := vtab_get_ref(vtab, name)
    if v == nil {
        vtab.custom[name] = value
    }

    v^ = value
}

// Instructions
Push_Value :: struct{value: f64}
Push_Var   :: struct{name: string}
Set_Var    :: struct{name: string}
Binary_Op  :: struct{op: u8}
Unary_Op   :: struct{op: u8}

Instruction :: union{
    Push_Value,
    Push_Var,
    Set_Var,
    Binary_Op,
    Unary_Op,
}

PROGRAM_STACK_SIZE :: 128
Program :: struct {
    stack: [PROGRAM_STACK_SIZE]f64,
    stack_size: int,

    instructions: [dynamic]Instruction,
}

init_program_table :: proc() {
    using state

    program_table_free = make([dynamic]int, 0, PROGRAM_TABLE_SIZE)
    variable_table = init_vtab()
    for i := 0; i < PROGRAM_TABLE_SIZE; i += 1 {
        append(&program_table_free, i)
    }
}

free_program_table :: proc() {
    using state

    for program in program_table { free_program(program) }
    free_vtab(&variable_table)
    delete(program_table_free)
}

compile_ast_node :: proc(instructions: ^[dynamic]Instruction, node: ^Ast_Node) -> string {
    if node == nil { return "" }
    using node

    e: string
    if type == .Binary_Op && data == "=" { // if the current operation is an assignment, 
                                           // the left side must be a variable and only the right will be recursed through
        if left.type != .Var {
            return "expected variable before '=' operation"
        }

        e  = compile_ast_node(instructions, right)
        if e != "" {
            return e
        }
        append(instructions, Set_Var{name = left.data})
    } else {
        e  = compile_ast_node(instructions, left)
        if e != "" {
            return e
        }
        e = compile_ast_node(instructions, right)
        if e != "" {
            return e
        }
    }

    #partial switch node.type {
        case .Var: append(instructions, Push_Var{name = node.data})
        case .Value: append(instructions, Push_Value{value = strconv.atof(node.data)})
        case .Binary_Op: append(instructions, Binary_Op{op = data[0]})
        case .Unary_Op: append(instructions, Unary_Op{op = data[0]})
    }

    return ""
}

compile_equation :: proc(equation: string) -> (Program, string) {
    program := Program{}
    program.instructions = make([dynamic]Instruction, 0, 64)
    
    ast, e := build_ast(equation)
    if e != "" {
        delete(program.instructions)
        return program, e
    }
    defer free_ast_node(ast)

    compile_ast_node(&program.instructions, ast)

    return program, ""
}

free_program :: proc(program: Program) {
    delete(program.instructions)
}

push_program_stack :: proc(program: ^Program, value: f64){
    using program
    stack[stack_size] = value
    stack_size += 1
}

pop_program_stack :: proc(program: ^Program) -> f64 {
    using program
    stack_size -= 1
    return stack[stack_size]
}

/* 
 * Builds and stores an AST for 'equation'
 * - returns the handle to access the equation
*/
add_equation :: proc(equation: string) -> int {
    using state

    if len(program_table_free) == 0 { return -1 }

    e: string
    id := program_table_free[0]
    program_table[id], e = compile_equation(equation)
    if e != "" {
        fmt.eprintln(e)
        return -1
    }

    pop_front(&program_table_free)
    return id
}

recompile_equation :: proc(id: int, new_equation: string) {
    using state

    if id >= PROGRAM_TABLE_SIZE || id < 0 { return }

    free_program(program_table[id])
    
    e: string
    program_table[id], e = compile_equation(new_equation)
    if e != "" {
        fmt.eprintln(e)
        return
    }
}

remove_equation :: proc(id: int) {
    using state

    if id >= PROGRAM_TABLE_SIZE || id < 0 { return }

    free_program(program_table[id])
    program_table[id] = {}
    append(&program_table_free, id)
}

eval_equation :: proc(id: int, vtab: ^Variable_Table) -> string {
    using state

    if id >= PROGRAM_TABLE_SIZE || id < 0 { return "invalid id" }

    program := &program_table[id]

    using program
    for ins in instructions {
        switch op in ins {
            case Push_Value: push_program_stack(program, op.value)
            case Push_Var:   push_program_stack(program, vtab_get_value(vtab, op.name))
            case Set_Var:    vtab_set_value(vtab, op.name, pop_program_stack(program))
            case Binary_Op: {
                right := pop_program_stack(program)
                left  := pop_program_stack(program)

                switch op.op {
                    case '+': push_program_stack(program, left + right)
                    case '-': push_program_stack(program, left - right)
                    case '*': push_program_stack(program, left * right)
                    case '/': push_program_stack(program, left / right)
                    case '^': push_program_stack(program, m.pow_f64(left, right))
                    case: return "unknown binary operator"
                }
            }
            case Unary_Op: {
                switch op.op {
                    case '+': push_program_stack(program, +pop_program_stack(program))
                    case '-': push_program_stack(program, -pop_program_stack(program))
                    case: return "unknown unary operator"
                }
            }
        }
    }

    return ""
}
