# Using registries

{.subtitle}
This page gives an overview of how to use registries to list and search for features.

A feature registry is a [`Registry`](#) object that a package makes available to its users so that they can discover the package's features. Let's look at an example registry:

{cell}
```julia
using FeatureRegistries
registry = FeatureRegistries.exampleregistry()
```

Each entry in a field consists of multiple fields, one of which is a unique ID. We can get more information on a registry's fields using [`info`](#):

{cell}
```julia
info(registry)
```


We can see that the `:id` column gives each entry's unique ID.

## Loading features

We can index into the registry with a valid ID to get a [`RegistryEntry`](#):

{cell}
```julia
entry = registry["log"]
```

Each of the fields can be accessed using property syntax:

{cell}
```julia
entry.id, entry.category, entry.instance
```

For every kind of feature, there should be a canonical way to load that functionality for usage. For example, in a registry of datasets loading an entry could mean downloading and unpacking the data to return a local file path. Different registries will have different loading behavior which can be invoked by calling [`load`](#) on an entry.

In the above toy example, after finding a suitable function, we want to call it, so `load` returns the Julia object:

{cell}
```julia
fn = load(entry)
fn(ℯ)
```

## Searching for features

A large registry with many entries and columns can quickly become unwieldy when searching for features. Using [`find`](#) (or `filter`), we can quickly subset the features based on a registry's fields.


We can match fields against exact values:

{cell}
```julia
# All entries where the category matches the value
find(registry, category=:trigonometric)
```

And some types like `String` accept additional filters, like a `Regex`:

{cell}
```julia
find(registry, id = r"s")
```

We can always filter based on an arbitrary predicate:

{cell}
```julia
# Using arbitrary predicates
find(registry, id = id -> length(id) <= 3)
```