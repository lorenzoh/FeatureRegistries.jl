# ## Custom cell printing


function tablecell(o)
    return AnsiTextCell(
        io -> display(TextDisplay(io), o),
        context = (:color => true, :displaysize => (3, 40)))
end

function tablecell(s::String)
    return AnsiTextCell(s)#"$(crayon"green")\"$s\"")
end

function tablecell(::Missing)
    return AnsiTextCell("$(crayon"dark_gray")missing")
end

function tablecell(xs::Vector{String})
    return xs
end

tablecell(b::Bool) = AnsiTextCell(b ? "$(crayon"green")✔" : "$(crayon"red")⨯")



# ## `show` methods

function _showregistry(io, registry::Registry)
    data, fields = getdata(registry), getfields(registry)

    names = [f.name for f in fields]
    cols = [":$k" for k in keys(fields)]

    tabledata = if length(data) > 0
        reduce(vcat, map(data) do row
            reshape([tablecell(field.formatfn(row[key])) for (key, field) in pairs(fields)], 1, :)
        end)
    else
        fill(missing, (1, length(fields)))
    end

    title = "Registry($(getfield(registry, :name)), $(length(data)) entries)"

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

Base.show(io::IO, registry::Registry) = _showregistry(io, registry)




function _showentry(io::IO, entry::RegistryEntry)
    row = getfield(entry, :row)
    registry = getfield(entry, :registry)
    println(io, "(")

    fs = registry.fields

    data = reduce(vcat, [
            reshape([k, "=", tablecell(f.formatfn(row[k])), AnsiTextCell("$(crayon"dark_gray")($(f.T))")], 1, :)
            for (k, f) in pairs(fs)
        ])
    pretty_table(
        io,
        data,
        alignment=[:r, :c, :l, :l],
        vlines=:none,
        hlines=:none,
        vcrop_mode=:middle,
        tf=PrettyTables.tf_compact,
        header = ["", "", "", ""]
    )
    println()
    print(io, ")")
end


function Base.show(io::IO, entry::RegistryEntry)
    print(io, "RegistryEntry")
    _showentry(io, entry)
end
