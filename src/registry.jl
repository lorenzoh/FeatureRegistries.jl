
struct Field{T}
    name
    description
    computefn
    transformfn
    createfn
    formatfn
    filterfn
end

Base.show(io::IO, field::Field{T}) where T = print(io, "Field{", T, "}(name = \"", field.name, "\")")


"""
    struct Field(T, name; kwargs...)

A field defines what data will be stored in one column of a [`Registry`](#).

## Keyword arguments

- `description::String = ""`: More information on the field contents and how they
    can be used. May contain Markdown formatting.
- `optional = false`: Whether a registry entry can be entered without alue
    in this field.
- `default = missing`: The default value used if `optional === true`. If a
    non-`missing` value is passed, the value of `optional` is ignored and
    the field is treated as optional.
- `defaultfn = (row, key) -> default`: Function to compute dynamically compute
    a default value from an entry. If passed, the value of `default` is ignored.

## Examples

A simple `Field` with entries of type `String`:

```
Field(String, "My Field")
```
"""
function Field(
        T;
        name = "",
        description = "",
        default = missing,
        optional = !ismissing(default),
        defaultfn = optional ? ((row, key) -> default) : ((row, key) -> throw(RequiredKeyMissingError(key))),
        computefn = (row, key) -> haskey(row, key) ? get(row, key, nothing) : defaultfn(row, key),
        U = optional ? Union{typeof(default), T} : T,
        transformfn = x -> convert(U, x),
        containerfn = () -> U[],
        formatfn = identity,
        filterfn = nothing,
    )
    Field{T}(name, description, computefn, transformfn, containerfn, formatfn, filterfn)
end


struct RequiredKeyMissingError <: Exception
    key
end

Base.showerror(e::RequiredKeyMissingError) = print(io,
    "RequiredKeyMissingError: Key `", e.key, "` is not optional")



@testset "Field" begin
    @testset "default" begin
        field = Field(String, name = "Field")
        @test field.computefn((; field = 1,), :field) == 1
        @test_throws RequiredKeyMissingError field.computefn((;), :field)
    end

    @testset "optional" begin
        field = Field(String, name = "Field", optional = true)
        @test field.computefn((; field = 1,), :field) == 1
        @test field.computefn((;), :field) === missing

        field2 = Field(String, name = "Field", optional = true, default = nothing)
        @test field2.computefn((; field = 1,), :field) == 1
        @test field2.computefn((;), :field) === nothing

        field2 = Field(String, name = "Field", optional = true, defaultfn = (row, key) -> key)
        @test field2.computefn((; field = 1,), :field) == 1
        @test field2.computefn((;), :field) === :field
    end

    @testset "container" begin
        @test Field(String, name = "Field").createfn() isa Vector{String}
        @test Field(String, name = "Field", optional=true).createfn() isa Vector{Union{Missing, String}}
    end
end


struct Registry{F<:NamedTuple, N, S<:StructArray, D<:Dict}
    fields::F
    id::NTuple{N, Symbol}
    data::S
    index::D
    name
    description
    loadfn
    # hidecols: columns to be hidden from printing
end

"""
    struct RegistryEntry(row, registry)

An entry in a feature registry `registry` with values `row`.
Returned when indexing into a `FeatureRegistry`, i.e.
`registry[id]`.
"""
struct RegistryEntry
    row
    registry::Registry
end


Base.getproperty(entry::RegistryEntry, sym::Symbol) =
    getproperty(getfield(entry, :row), sym)

Base.propertynames(entry::RegistryEntry) =
    propertynames(getfield(entry, :row))


Base.NamedTuple(entry::RegistryEntry) = NamedTuple(getfield(entry, :row))

"""
    load(entry)
    load(registry[id])

Load a feature represented by a registry entry. The behavior depends on
the `Registry`.
"""
load(entry::RegistryEntry; kwargs...) = getfield(entry, :registry).loadfn(getfield(entry, :row); kwargs...)


getdata(registry::Registry) = getfield(registry, :data)
getfields(registry::Registry) = getfield(registry, :fields)


"""
    Registry(fields; kwargs...)

Create a feature registry with columns of [`Field`](#)s.

## Keyword arguments

- `name::String`: A descriptive name.
- `fields::NamedTuple`:
- `description::String = ""`: Description text for the registry. Shown when `info(registry)`
    is called.
- `loadfn = identity`: Function to apply over a row when [`load`](#) is called. For example,
    calling `load(registry["id"])` will call `loadfn`.
"""
function Registry(fields::NamedTuple; name = "", loadfn = identity, description = "", id = (:id,))
    id = id isa Symbol ? (id,) : id
    data = StructArray(NamedTuple(key => field.createfn() for (key, field) in pairs(fields)))
    index = Dict{Any, Int}()

    for id_ in id
        hasproperty(fields, id_) || throw(ArgumentError("ID field $id_ does not exist!"))
    end

    return Registry(fields, id, data, index, name, description, loadfn)
end

function makerow(fields, row::NamedTuple)
    NamedTuple(
        key => field.transformfn(field.computefn(row, key))
        for (key, field) in pairs(fields)
    )
end


struct DuplicateIDError <: Exception
    key
end


Base.showerror(io::IO, e::DuplicateIDError) = print(
    io, "DuplicateIDError: ID `", e.key, "` already registered!")


function Base.push!(registry::Registry, entry::NamedTuple)
    row = makerow(getfield(registry, :fields), entry)

    # check unique ID
    id = Tuple(row[id] for id in getfield(registry, :id))
    haskey(registry, id) && throw(DuplicateIDError(id))

    # enter row data and update index
    push!(getfield(registry, :data), row)
    index = getfield(registry, :index)
    index[id] = length(getfield(registry, :data))

    return row
end

# ### `Base` interface for `Registry`

function Base.getindex(registry::Registry, idx)
    return RegistryEntry(
        parent(getfield(registry, :data))[getfield(registry, :index)[_index_key(registry, idx)]],
        registry)
end

function Base.getindex(registry::Registry, ::Colon, sym::Symbol)
    return getproperty(getdata(registry), sym)
end

Base.length(registry::Registry) = length(registry.data)

Base.haskey(registry::Registry, idx) =
    haskey(getfield(registry, :index), _index_key(registry, idx))

Base.sort(registry::Registry, col::Symbol; rev = false) =
    withdata(
        registry,
        view(getdata(registry), sortperm(getproperty(getdata(registry), col); rev)))

Base.view(registry::Registry, inds...) = withdata(registry, view(getdata(registry), inds...))

_index_key(registry::Registry, nt::NamedTuple) =
    Tuple(nt[i] for i in getfield(registry, :id))

function _index_key(registry::Registry, id)
    length(getfield(registry, :id)) == 1 || throw(KeyError("Registry has a multi-column ID `$(getfield(registry, :id))`, please pass in a named tuple."))
    return (id,)
end

_index_key(::Registry, t::Tuple) = t

function withdata(registry::Registry, data)
    reg = Setfield.@set registry.data = data

    # recreate index
    index = Dict{Any, Int}()
    for (i, row) in enumerate(data)
        id = Tuple(row[id] for id in getfield(registry, :id))
        index[id] = i
    end
    reg = Setfield.@set reg.index = index

    return reg
end


# ### Tests for `Registry`

@testset "Registry" begin
    testregistry() = Registry((
        id = Field(String, name = "ID"),
    ), name = "Test registry")
    @test_nowarn testregistry()

    @testset "push!" begin
        registry = testregistry()
        @test_nowarn push!(registry, (; id = "myid"))
    end

    @testset "push! duplicate" begin
        registry = testregistry()
        push!(registry, (; id = "myid"))
        @test_throws DuplicateIDError push!(registry, (; id = "myid"))
    end

    @testset "getindex" begin
        @testset "get row" begin
            registry = testregistry()
            push!(registry, (; id = "myid"))
            @test_nowarn registry["myid"]
            @test NamedTuple(registry["myid"]) == (; id = "myid")
            @test_nowarn registry[("myid",)]
            @test_nowarn registry[(id = "myid",)]
        end

        @testset "get column" begin
            registry = testregistry()
            push!(registry, (; id = "myid"))
            @test_nowarn registry[:, :id]
            @test registry[:, :id] == ["myid"]
        end
    end

    @testset "length" begin
        registry = testregistry()
        @test length(registry) == 0
        push!(registry, (; id = "myid"))
        @test length(registry) == 1
    end
end
