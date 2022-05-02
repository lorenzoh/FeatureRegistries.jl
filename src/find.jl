"""
    find(registry, [; col = filter, ...])

Find entries in a registry that match a set of filters given as keyword
arguments. The keyword name must correspond to a field in `registry`,
while the value is a filter that is checked against each field value.

See [how to use registries](/documents/docs/using.md) for examples.
"""
function find(registry::Registry; filters...)
    mask = [matchesentry(getfield(registry, :fields), row; filters...)
            for row in getfield(registry, :data)]
    return view(registry, mask)
end

Base.filter(registry::Registry; kwargs...) = find(registry; kwargs...)

function Base.findfirst(registry::Registry; filters...)
    for row in getfield(registry, :data)
        if matchesentry(getfield(registry, :fields), row; filters...)
            return RegistryEntry(row, registry)
        end
    end
    nothing
end

function matchesentry(fields, row; filters...)
    return all(matchesentry(fields[col], row[col], f) for (col, f) in filters)
end

# The default for any function is to match against a value
matchesentry(f::Field, value, query) = isnothing(f.filterfn) ? value == query : f.filterfn(value, query)
matchesentry(field::Field, value::Missing, ::typeof(ismissing)) = true
matchesentry(field::Field, value::Missing, _) = false

# Passing a function as a query uses it as predicate
matchesentry(::Field, value, query::Function) = query(value)
matchesentry(::Field{<:Function}, value::Function, query::Function) = query(value)

# For strings, do fuzzy matching and allow regex
matchesentry(::Field, str::String, query::String) = occursin(query, str)
matchesentry(::Field, str::String, query::Regex) = match(query, str) !== nothing



# TODO: efficient `Base.findfirst`

@testset "find" begin
    function testregistry()
        registry = Registry((
                id = Field(String, name="ID"),
                name = Field(String, name="name"),
            ),
        name = "Test registry")
        push!(registry, (id = "id1", name = "name1"))
        push!(registry, (id = "id2", name = "name2"))
        return registry
    end
    @test_nowarn testregistry()
    registry = testregistry()

    @test length(find(registry, id = "id1")) == 1
    @test length(find(registry, id = "1")) == 1
    @test length(find(registry, id = r"1")) == 1
    @test length(find(registry, id = "id")) == 2
    @test length(find(registry, id = "id", name = "name")) == 2
    @test length(find(registry, id = x -> startswith(x, "id"), name = "name")) == 2

    @test NamedTuple(findfirst(registry, id = "id")) == (id = "id1", name = "name1")
    @test isnothing(findfirst(registry, id = "404"))

    @testset "filtering" begin
        @testset "Fallback: equality" begin
            @test matchesentry(Field(Symbol), :x, :x)
            @test !matchesentry(Field(Symbol), :x, :y)
        end

        @testset "Predicates" begin
            @test matchesentry(Field(Symbol), :x, ==(:x))
            @test matchesentry(Field(Function), sum, ==(sum))
        end

        @testset "Missing values" begin
            @test !matchesentry(Field(Symbol, optional = true), missing, :x)
            @test matchesentry(Field(Symbol, optional = true), missing, ismissing)
        end

        @testset "String" begin
            @test matchesentry(Field(String), "hello", "hel")
            @test !matchesentry(Field(String), "hello", "yo")
            @test matchesentry(Field(String), "hello", r"^h")
            @test !matchesentry(Field(String), "hello", r"^h$l")
        end

        @testset "Row" begin
            fields = (f1 = Field(String), f2 = Field(Symbol, optional = true))
            @test matchesentry(fields, (f1 = "", f2 = :x))
            @test matchesentry(fields, (f1 = "", f2 = :x), f2 = :x, f1 = "")
            @test !matchesentry(fields, (f1 = "", f2 = :s), f2 = :x, f1 = "")
            @test !matchesentry(fields, (f1 = "", f2 = :x), f2 = :x, f1 = "s")
        end
    end

end
