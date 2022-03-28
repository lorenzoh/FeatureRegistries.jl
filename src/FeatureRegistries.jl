module FeatureRegistries


using InlineTest
using Markdown
using PrettyTables
using StructArrays

import Setfield


include("registry.jl")
export Field, Registry, DuplicateIDError


include("find.jl")
export find


include("printing.jl")

include("info.jl")
export info

end  # module
