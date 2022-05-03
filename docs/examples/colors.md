# Example: Named colors in Colors.jl

[Colors.jl](https://github.com/JuliaGraphics/Colors.jl) is a package that provdides not just color types, but also a set of named colors. Here we create a [`Registry`](#) that lists all the named colors in Colors.jl.

{cell}
```julia
using Colors, FeatureRegistries, FixedPointNumbers, ImageInTerminal
using FeatureRegistries: Registry, Field

colors = Registry((;
        name = Field(String, name = "Name", description = "The name of the color"),
        color = Field(Color, name = "Color", description = "The color value"),
    ),
    name = "Colors", id = :name,)

for name in sort(collect(keys(Colors.color_names)))
    val = Colors.color_names[name]
    push!(colors, (
        name = name,
        color = RGB{N0f8}((val ./ 255)...)))
end

colors
```

We can select a single entry using its ID:

{cell}
```julia
colors["antiquewhite"]
```

And get a summary of fields in the registry:

{cell}
```julia
info(colors)
```

When in an environment that does not support HTML output, registries will be printed to the terminal:

{cell}
```julia
show(colors)
```