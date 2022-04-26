
Base.@kwdef struct RichCell{T}
    val::T
    iocontext = (:color => true,)
end

RichCell(val; kwargs...) = RichCell(; val, kwargs...)

# Text backend

function Base.show(io::IO, cell::RichCell)
    display(TextDisplay(IOContext(io, cell.iocontext...)), cell.val)
end

function Base.show(io::IO, cell::RichCell{String})
    print(io, cell.val)
end

function Base.show(io::IO, ::RichCell{Missing})
    print(io, "$(crayon"dark_gray")missing")
end

function Base.show(io::IO, cell::RichCell{Bool})
    if cell.val
        print(io, "$(crayon"green")✔")
    else
        print(io, "$(crayon"red")⨯")
    end
end


# HTML

function Base.show(io::IO, mime::MIME"text/html", cell::RichCell)
    if showable(mime, cell.val)
        show(io, mime, cell.val)
    elseif showable(MIME("image/png"), cell.val)
        buf = IOBuffer()
        show(buf, MIME("image/png"), cell.val)
        print(io, """<img src="data:image/png;base64,$(Base64.base64encode(take!(buf)))"/>""")
    elseif showable(MIME("image/svg+xml"), cell.val)
        buf = IOBuffer()
        show(buf, MIME("image/svg+xml"), cell.val)
        print(io, replace(String(take!(buf)), "\n" => ""))
    else
        print(io, cell)
    end
end



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


function registrytable(registry::Registry)
    data, fields = getdata(registry), getfields(registry)
    names = [f.name for f in fields]
    cols = [":$k" for k in keys(fields)]

    # TODO: don't do format-specific conversion
    tabledata = if length(data) > 0
        reduce(vcat, map(data) do row
            reshape([field.formatfn(row[key]) for (key, field) in pairs(fields)], 1, :)
        end)
    else
        fill(missing, (1, length(fields)))
    end

    title = "Registry($(getfield(registry, :name)), $(length(data)) entries)"

    tabledata, (;
        header=(names, cols),
        alignment=:l,
        title=title,
        title_alignment=:l,
    )

end

function Base.show(io::IO, registry::Registry)
    tabledata, kwargs = registrytable(registry)
    pretty_table(
        io,
        map(c -> c isa RichCell ? AnsiTextCell(io -> show(io, c)) : c, tabledata);
        backend = Val(:text),
        tf=PrettyTables.tf_borderless,
        hlines=:all,
        vlines=[:begin, :end],
        maximum_columns_width=40,
        vcrop_mode=:middle,
        title_same_width_as_table=true,
        kwargs...)
end


function Base.show(io::IO, mime::MIME"text/html", registry::Registry)
    tabledata, kwargs = registrytable(registry)
    PrettyTables.pretty_table(
        io,
        map(_stringhtml, tabledata);
        backend = Val(:html),
        standalone=false,
        tf=tf_html_minimalist,
        allow_html_in_cells=true,
        kwargs...)
end


function _stringhtml(c)
    io = IOBuffer()
    if showable(MIME("text/html"), c)
        show(io, MIME("text/html"), c)
    else
        show(io, c)
    end
    return String(take!(io))
end


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
