"""
    exampleregistry()

Create a [`Registry`](#) of mathematical functions for testing purposes.

## Examples

{cell}
```julia
using FeatureRegistries
registry = FeatureRegistries.exampleregistry()
```
"""
function exampleregistry()

    registry = Registry(
        (;
            id = Field(String, name = "ID"),
            category = Field(
                Symbol,
                name = "Category",
                description = "The category of mathematical function",
                optional = true,
            ),
            instance = Field(
                Function,
                name = "Function instance",
                description = "The Julia function object"
            ),
        ),
        name = "Mathematical functions",
        loadfn = row -> row.instance,
    )
    push!(registry, (id = "sin", instance = sin, category = :trigonometric))
    push!(registry, (id = "tan", instance = tan, category = :trigonometric))
    push!(registry, (id = "cos", instance = cos, category = :trigonometric))
    push!(registry, (id = "log2", instance = log2, category = :logarithmic))
    push!(registry, (id = "log", instance = log, category = :logarithmic))
    push!(registry, (id = "log1p", instance = log1p, category = :logarithmic))

    registry
end
