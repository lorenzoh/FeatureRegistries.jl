# FeatureRegistries.jl

[Documentation](http://lorenzoh.github.io/FeatureRegistries.jl/dev/i)

A Julia package to create registries of your own package's features, letting your users discover and use them more easily.

FeatureRegistries.jl lets you create tables that list package features so that

- users can explore and discover features,
- users can search features through a consistent interface; and
- developers of third-party packages can transparently add functionality

But what are "features"? Features can be any group of package functionality with some attributes in common that you want users to be able to discover and use. For example, a registry could store

- datasets with metadata and documentation that a user can download,
- machine learning architectures that a user can instantiate; or
- a set of remotely stored images


Read on in the [documentation](http://lorenzoh.github.io/FeatureRegistries.jl/dev/i) for more information on [how to use registries](docs/using.md) and [examples of such registries](docs/examples.md).
