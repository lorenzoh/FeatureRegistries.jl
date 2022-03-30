

"""
    info(registry)

Show additional information about a registry.
"""
function info end


function info(io::IO, registry::Registry)
    n = length(registry.data)
    println(io,
        "FeatureRegistry() \"",
        registry.name,
        "\" with ", n, n == 1 ? " entry" : " entries",
        " and fields:",
    )

    fs = registry.fields

    data = reduce(vcat, [
            reshape([f.name, ":$k", f.T, f.description], 1, :)
            for (k, f) in pairs(fs)
        ])
    pretty_table(
        io,
        data,
        alignment=:l,
        vlines = :all,
        hlines = :none,
        vcrop_mode=:middle,
        tf=PrettyTables.tf_borderless,
        header = ["Name", "Key", "Type", "Description"]
    )
end
info(registry::Registry) = info(stdout, registry)
