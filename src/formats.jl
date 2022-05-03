#=
This file defines some simple formatting functions that may be used
in a [`Field`](#) by passing it as a `formatfn`.
=#

"""
    string_format(str)

Ensure that a string is shown with double quotes.

```julia-repl
julia> string_format("hi")
"\"hi\""
"""
string_format(x) = sprint(io -> show(io, string(x)))


code_format(x) = Markdown.parse("`$x`")

md_format(x) = Markdown.parse(x)

type_format(::T) where T = "$(T.name.name)"

@testset "Formatting functions" begin
    @testset "string_format" begin
        @test string_format("hi") == "\"hi\""

    end
    @testset "code_format" begin
        @test code_format("hi") == Markdown.parse("`hi`")
    end
end
