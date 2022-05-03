#=
This file implements pretty printing of feature registries as tables,
both using rich terminal text (ANSI codes) and as HTML.
=#

#=
To ensure that the values in table cells are displayed nicely, we
define a wrapper [`RichCell`](#) that ensures the richest mimetype is used
to display values, with some defaults for common values like `missing`,
`Bool`s and images.
=#


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
        print(io, "$(crayon"green")✔$(crayon"reset")")
    else
        print(io, "$(crayon"red")⨯$(crayon"reset")")
    end
end

# Printing of `Markdown.MD` adds some indentation and a newline by default,
# we `strip` this for more compact tables.
function Base.show(io::IO, cell::RichCell{Markdown.MD})
    iobuf = IOBuffer()
    display(TextDisplay(IOContext(iobuf, cell.iocontext...)), cell.val)

    s = String(take!(iobuf)) |> strip
    print(io, s)
end



# HTML

const IMAGE_MIMES = [
    MIME("image/jpeg"),
    MIME("image/png"),
]

# fallback
function Base.show(io::IO, mime::MIME"text/html", cell::RichCell)
    if showable(mime, cell.val)
        show(io, mime, cell.val)
    elseif showable(MIME("image/svg+xml"), cell.val)
        show(io, MIME("image/svg+xml"), cell.val)
    elseif any(showable(m, cell.val) for m in IMAGE_MIMES)
        @show showable.(IMAGE_MIMES, cell.val)
        ImageShow.show_element(io, cell.val)
    else
        print(io, cell.val)
    end
end




function Base.show(io::IO, ::MIME"text/html", cell::RichCell{Bool})
    if cell.val
        print(io, """<span style="color:green;">✔</span>""")
    else
        print(io, """<span style="color:red;">⨯</span>""")
    end
end


function Base.show(io::IO, ::MIME"text/html", ::RichCell{Missing})
    print(io, """<span style="color:lightgray;">missing</span>""")
end

function Base.show(io::IO, ::MIME"text/html", cell::RichCell{String})
    print(io, cell.val)
end


# ## `show` methods


function registrytable(registry::Registry)
    data, fields = getdata(registry), getfields(registry)
    names = [f.name for f in fields]
    cols = [":$k" for k in keys(fields)]

    tabledata = if length(data) > 0
        reduce(vcat, map(data) do row
            reshape([formatfieldvalue(field, row[key]) for (key, field) in pairs(fields)], 1, :)
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


_title(registry) = getfield(registry, :name)

function Base.show(io::IO, registry::Registry)
    tabledata, kwargs = registrytable(registry)
    pretty_table(
        io,
        map(c -> AnsiTextCell(string(RichCell(c))), tabledata);
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
        print(io, c)
    end
    return String(take!(io))
end


formatfieldvalue(field, value) = field.formatfn(value)
formatfieldvalue(_, ::Missing) = missing

function _showentry(io::IO, entry::RegistryEntry)
    row = getfield(entry, :row)
    registry = getfield(entry, :registry)
    print(io, "(")

    rows = [reshape([
            "   $col",
            "=",
            AnsiTextCell(
                string(
                    RichCell(
                        formatfieldvalue(field, row[col]),
                        (:color => true, :displaysize => (10,50))))),
            AnsiTextCell("$(crayon"dark_gray")($(_fieldtype(field)))")
            ], 1, :)
        for (col, field) in pairs(registry.fields)]
    pretty_table(
        io, reduce(vcat, rows);
        alignment=[:r, :c, :l, :l], vlines=:none, hlines=:none,
        vcrop_mode=:middle,
        tf=PrettyTables.tf_compact,
        header = ["", "", "", ""],
        autowrap=true
    )
    print(io, ")")
end



function Base.show(io::IO, entry::RegistryEntry)
    print(io, "RegistryEntry")
    _showentry(io, entry)
end


@testset "Printing" begin

    @testset "text" begin
        richstring(x) = sprint(io -> show(io, MIME("text/plain"), RichCell(x)))

        @test richstring("hi") == "hi"
        @test richstring(Markdown.parse("hi")) |> strip == "hi"
        @test richstring(Markdown.parse("**hi**")) |> strip == "\e[1mhi\e[22m"
        @test richstring(true) == "\e[32m✔\e[0m"
        @test richstring(false) == "\e[31m⨯\e[0m"
        @test richstring(missing) == "\e[90mmissing"
    end

    @testset "html" begin
        richstring(x) = sprint(io -> show(io, MIME("text/html"), RichCell(x)))

        @test richstring("hi") == "hi"
        @test richstring(Markdown.parse("hi")) == """<div class="markdown"><p>hi</p>\n</div>"""
        @test richstring(Markdown.parse("**hi**")) == """<div class=\"markdown\"><p><strong>hi</strong></p>\n</div>"""
        @test richstring(true) == "<span style=\"color:green;\">✔</span>"
        @test richstring(false) == "<span style=\"color:red;\">⨯</span>"

    end
end
