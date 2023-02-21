using Test


@testset "MiniDemographicABM Testing" begin

    include("./test/runtests.jl")
    include("./test/death_test.jl")
    include("./test/divorce_test.jl")
    include("./test/birth_test.jl")
    include("./test/marriage_test.jl")

end
