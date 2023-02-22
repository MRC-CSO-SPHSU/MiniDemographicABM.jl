"""
Run this script from shell as
#  julia <script-name.jl> 

or within REPL

julia> include("script-name.jl")
"""

using Test

@testset "MiniDemographicABM Testing" begin

    include("./test/runtests.jl")
    include("./test/death_test.jl")
    include("./test/divorce_test.jl")
    include("./test/birth_test.jl")
    include("./test/marriage_test.jl")

end
