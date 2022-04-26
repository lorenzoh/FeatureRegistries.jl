module FeatureRegistries


using InlineTest
using Markdown
using PrettyTables
using StructArrays

import Setfield


include("registry.jl")
export Field, Registry, load


include("find.jl")
export find

include("info.jl")
export info

include("printing.jl")


end  # module
