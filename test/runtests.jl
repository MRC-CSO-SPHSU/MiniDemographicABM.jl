"""
Run this script from shell as
#  julia <script-name.jl>

or within REPL

julia> include("script-name.jl")
"""

using Test

@testset "MiniDemographicABM Testing" begin

    include("./basic_tests.jl")

end
