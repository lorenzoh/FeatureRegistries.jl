
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
    print(io, "$(crayon"green")\"$(cell.val)\"")
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

# fallback

const IMAGE_MIMES = [
    MIME("image/jpeg"),
    MIME("image/png"),
    MIME("image/svg+xml"),
    MIME("image/webp"),
    MIME("image/gif"),
]

function Base.show(io::IO, mime::MIME"text/html", cell::RichCell)
    if showable(mime, cell.val)
        show(io, mime, cell.val)
    elseif any(showable(m, cell.val) for m in IMAGE_MIMES)
        _show_image_html(io, IMAGE_MIMES, cell.val)
    else
        print(io, cell)
    end
end

function Base.show(io::IO, ::MIME"text/html", cell::RichCell{String})
    print(io, """<span style="color:#073;">\"$(cell.val)\"</span>""")
end

# from https://github.com/JuliaImages/ImageShow.jl/pull/49
function _show_image_html(io, mimes::Vector{<:MIME}, x)
    for mime in mimes
        if showable(mime, x)
            _show_image_html(io, mime, x)
            break
        end
    end
end

function _show_image_html(io, mime::MIME{Name}, x) where Name
    buf = IOBuffer()
    show(buf, mime, x)
    print(io, """<img src="data:""", Name, ";base64,", Base64.base64encode(take!(buf)), "\" />")
end



function Base.show(io::IO, ::MIME"text/html", cell::RichCell{Bool})
    if cell.val
        print(io, """<span style="color:green;">✔</span>""")
    else
        print(io, """<span style="color:red;">⨯</span>""")
    end
end


# ## `show` methods


function registrytable(registry::Registry)
    data, fields = getdata(registry), getfields(registry)
    names = [f.name for f in fields]
    cols = [":$k" for k in keys(fields)]

    tabledata = if length(data) > 0
        reduce(vcat, map(data) do row
            reshape([field.formatfn(row[key]) for (key, field) in pairs(fields)], 1, :)
        end)
    else
        fill(missing, (1, length(fields)))
    end

    tabledata, (;
        header=(names, cols),
        alignment=:l,
        title=_title(registry),
        title_alignment=:l,
    )

end


#_title(registry) = "$(getfield(registry, :name)) (Registry() with $(length(getdata(registry))) entr$(length(getdata(registry)) == 1 ? "y" : "ies"))"
_title(registry) = getfield(registry, :name)

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


function Base.show(io::IO, ::MIME"text/html", registry::Registry)
    tabledata, kwargs = registrytable(registry)
    PrettyTables.pretty_table(
        io,
        map(_stringhtml, tabledata);
        backend = Val(:html),
        standalone=false,
        tf=tf_html_minimalist,
        allow_html_in_cells=true,
        linebreaks=true,
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
    print(io, "(")

    rows = [reshape([
            "   $col",
            "=",
            AnsiTextCell(string(field.formatfn(row[col]))),
            AnsiTextCell("$(crayon"dark_gray")($(_fieldtype(field)))")
            ], 1, :)
        for (col, field) in pairs(registry.fields)]
    pretty_table(
        io, reduce(vcat, rows);
        alignment=[:r, :c, :l, :l], vlines=:none, hlines=:none,
        vcrop_mode=:middle, tf=PrettyTables.tf_compact,
        header = ["", "", "", ""],
    )
    print(io, ")")
end


function Base.show(io::IO, entry::RegistryEntry)
    print(io, "RegistryEntry")
    _showentry(io, entry)
end
