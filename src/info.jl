

"""
    info(registry)

Show information about a registry, specifically its name, description
and fields.

## Examples

{cell}
```julia
using FeatureRegistries: exampleregistry, info
registry = exampleregistry()
info(registry)
```
"""
function info end

struct RegistryInfo
    registry::Registry
end

function Base.show(io::IO, registryinfo::RegistryInfo)
    registry = registryinfo.registry
    println(io,
        "Information on registry ",
        crayon"underline", getfield(registry, :name), crayon"reset", "\n\n",
        "$(crayon"bold")Fields$(crayon"reset"): ")

    fs = registry.fields
    data = reduce(vcat, [
            reshape([
                f.name,
                AnsiTextCell(k in getfield(registry, :id) ? "$(crayon"red bold"):$k (ID)" : ":$k"),
                AnsiTextCell("$(crayon"dark_gray")$(_fieldtype(f))"),
                f.description],
            1, :)
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
        header = ["Name", "Column", "Type", "Description"]
    )

    if !isempty(registry.description)
        println(io, "\n$(crayon"bold")Description$(crayon"reset"): ")
        show(io, RichCell(Markdown.parse(registry.description)))
    end
end

_fieldtype(::Field{T}) where T = T
info(registry::Registry) = RegistryInfo(registry)
