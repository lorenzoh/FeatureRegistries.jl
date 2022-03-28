
"""
    find(registry, (; filters...))

Find entries in a registry that match a set of filters. Filters
"""
function find(registry::Registry; filters...)
    keep = trues(length(getdata(registry)))
    data = getdata(registry)
    fields = getfields(registry)

    for (key, filter) in pairs(filters)
        filterfn = getfilterfn(fields[key], filter)
        getproperty(data, key)
        keep .&= map(x -> x !== missing && filterfn(x), getproperty(data, key))
    end

    return withdata(registry, @view data[keep])
end

_fmap(f, ::Missing) = missing
_fmap(f, x) = f(x)
_fmap(f) = x -> _fmap(f, x)

export find

getfilterfn(field::Field, query) = getfilterfn(field.T, query)
getfilterfn(::Type{String}, query::String) = s -> occursin(query, s)
getfilterfn(::Type{String}, query::Regex) = s -> match(query, s) !== nothing
getfilterfn(type::Type{T}, query::T) where T = (==)(query)
getfilterfn(type::Type{T}, f) where T = f



@testset "find" begin
    function testregistry()
        registry = Registry("Test registry", (
            id = Field(String, "ID"),
            name = Field(String, "name"),
        ))
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
end
