"""
Run this script from shell as
# JULIA_LOAD_PATH="/path/to/MiniDemographicABM.jl/src:\$JULIA_LOAD_PATH" julia RunTests.jl

or within REPL

julia> push!(LOAD_PATH,"/path/to/MiniDemographicABM.jl")
julia> include("runtests.jl")
"""

using Agents
using Test
include("src/models.jl")


@testset "MiniDemographicABM Testing" begin

    towns = [ Town("A", 0.9, (1,1), House[]),
                    Town("B", 0.3, (10,5), House[]),
                    Town("C", 0.5, (4,6), House[]),
                    Town("D", 0.7, (2,2), House[]) ]

    maxTownGridDim = 10
    space = DemographicMap("WaqWaq",maxTownGridDim,towns)

    model = DemographicABM(space,DemographyPars(initialPop=100))
    seed!(model,floor(Int,time()))
    nhouses = 100
    houses = add_empty_houses!(space,nhouses)

    @testset verbose=true "exploring Agents.jl functionalities" begin
        @test typeof(model) <: ABM
        @test length(positions(model)) == 100
        @test model.initialPop == 100

        person1 = add_agent_pos!(Person(1,houses[1]),model)
        @test home(person1) == houses[1]

        add_agent!(Person(nextid(model),UNDEFINED_HOUSE),houses[2],model)
        @test home(model[2]) == houses[2]

        add_agent!(model)
        @test !ishomeless(model[3])

        add_agent!(model)
        @test nagents(model) == 4

        add_agent!(houses[3],model)
        @test home(model[5]) == houses[3]
        @test length(allagents(model)) == 5

        kill_agent!(model[1],model)
        @test_throws KeyError model[1] == person1
        kill_agent!(2,model)
        @test nagents(model) == 3

        @test model[4].id == 4
        @test random_agent(model).id in [3,4,5]
        @test sum(allids(model)) == 12

        @test length(positions(model)) == 100
        @test has_empty_positions(model)
        @test !undefined(random_position(model))
    end # Exploring Agents.jl


    @testset verbose=true "exploring foo[!](model,*)" begin

        @test !undefined(random_town(model))

    end

end #
