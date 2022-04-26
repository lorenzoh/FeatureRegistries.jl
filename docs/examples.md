# Examples

## Colors.jl

{cell}
```julia
using Colors, FeatureRegistries, FixedPointNumbers, ImageInTerminal

colors = Registry("Colors", (;
    name = Field(String, "ID", description = "The name of the color"),
    color = Field(Color, "Color"),
), id = :name,)

for name in sort(collect(keys(Colors.color_names)))
    val = Colors.color_names[name]
    push!(colors, (name = name, color = RGB{N0f8}((val ./ 255)...)))
end

show(colors)
```

{cell}
```julia
info(colors)
```

## TestImages.jl

TODO