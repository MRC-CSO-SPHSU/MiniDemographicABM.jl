"""
Run this script from shell as
#  julia <script-name.jl>

or within REPL

julia> include("script-name.jl")
"""

using Test

@testset "MiniDemographicABM + stepping functions Testing" begin

    include("./basic_tests.jl")
    include("./death_test.jl")
    include("./divorce_test.jl")
    include("./birth_test.jl")
    include("./marriage_test.jl")

end
