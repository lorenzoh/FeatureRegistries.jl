# Example: images in TestImages.jl

[TestImages.jl](https://github.com/JuliaImages/TestImages.jl) collects images commonly used for testing computer vision algorithms. With little code, we can create a registry that displays nicely:

{cell}
```julia
using FeatureRegistries, ImageShow, TestImages
using FeatureRegistries: Registry, Field

images = Registry((;
        id = Field(String, name = "ID", description = "The name of the color"),
        image = Field(Any, name = "Image"),
    ),
    name = "Test images",
    loadfn = row -> row.image)

for id in TestImages.remotefiles[1:13]
    image = TestImages.testimage(id)
    isnothing(image) || prod(size(image)) > 500000 && continue
    push!(images, (; id, image))
end
images
```

When outside an environment that supports HTML output, like a terminal, the registry will be displayed as below:

{cell}
```julia
using ImageInTerminal
show(images)
```
