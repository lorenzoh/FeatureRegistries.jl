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
    push!(colors, (
        name = name,
        color = RGB{N0f8}((val ./ 255)...)))
end

show(colors)
```

{cell}
```julia
info(colors)
```
{cell}
```julia
colors
```

## TestImages.jl

{cell}
```julia
using FeatureRegistries, ImageShow, TestImages

images = Registry("Test images", (;
    id = Field(String, "ID", description = "The name of the color"),
    image = Field(Any, "Image"),
))

for id in TestImages.remotefiles[1:13]
    image = TestImages.testimage(id)
    isnothing(image) || prod(size(image)) > 500000 && continue
    push!(images, (; id, image))
end
images
```
