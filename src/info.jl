

"""
    info(registry)
    info(registry, id)

Show additional information about a registry or one of its entries.
"""
function info end


function info(io::IO, registry::Registry)
    n = length(registry.data)
    println(io,
        "FeatureRegistry() \"",
        registry.name,
        "\" with ", n, n == 1 ? " entry" : " entries",
        " and fields ",
        Tuple(keys(registry.fields))
    )


    fs = registry.fields

    data = reduce(vcat, [reshape([f.name, ":$k"], 1, :) for (k, f) in pairs(fs)])
    pretty_table(
        io,
        data,
        alignment=:l,
        title = "Fields"
    )
end
info(registry::Registry) = info(stdout, registry)


function info(io, registry::Registry, id)
end

info(registry::Registry, id) = info(stdout, registry, id)
