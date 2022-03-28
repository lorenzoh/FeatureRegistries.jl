
function showentries(io, registry::Registry)
    data, fields = getdata(registry), getfields(registry)

    names = [f.name for f in fields]
    cols = [":$k" for k in keys(fields)]
    types = collect(map(f -> f.T, values(fields)))

    tabledata = if length(data) > 0
        reduce(vcat, map(data) do row
            reshape([RichCell(field.formatfn(row[key])) for (key, field) in pairs(fields)], 1, :)
        end)
    else
        fill(missing, (1, length(fields)))
    end

    title = "$(getfield(registry, :name)) (FeatureRegistry, $(length(data)) entries)"

    pretty_table(
        io,
        tabledata,
        header=(names, cols),
        maximum_columns_width=40,
        alignment=:l,
        hlines=:all,
        vlines=[:begin, :end],
        title=title,
        title_alignment=:l,
        vcrop_mode=:middle,
        title_same_width_as_table=true,
        tf=PrettyTables.tf_borderless
    )
end

const _missing = """$(crayon"light_gray")missing"""

function RichCell(o)
    return AnsiTextCell(
        io -> display(TextDisplay(io), o),
        context = (:color => true, :displaysize => (3, 40)))
end

function RichCell(s::String)
    return AnsiTextCell(s)
end

function RichCell(::Missing)
    return AnsiTextCell("$(crayon"dark_gray")missing")
end

function RichCell(xs::Vector{String})
    return xs
end

RichCell(b::Bool) = AnsiTextCell(b ? "$(crayon"green")✔" : "$(crayon"red")✖️️")

Base.show(io::IO, registry::Registry) = showentries(io, registry)


1
