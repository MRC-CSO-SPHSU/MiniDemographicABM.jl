"""
Run this script from shell as
# JULIA_LOAD_PATH="/path/to/MiniDemographicABM.jl/src:\$JULIA_LOAD_PATH" julia RunTests.jl

or within REPL

julia> push!(LOAD_PATH,"/path/to/MiniDemographicABM.jl")
julia> include("runtests.jl")
"""

using Agents
using Test
include("../src/modelspec.jl")


@testset "MiniDemographicABM Testing" begin

    towns = [ Town("A", 0.9, (1,1), House[]),
              Town("B", 0.3, (10,5), House[]),
              Town("C", 0.5, (4,6), House[]),
              Town("D", 0.7, (2,2), House[]) ]

    maxTownGridDim = 10
    space = DemographicMap("WaqWaq",maxTownGridDim,towns)

    model = DemographicABM(space,DemographyPars{Monthly}(initialPop=100))
    seed!(model,floor(Int,time()))
    nhouses = 100
    houses = add_empty_houses!(space,nhouses)

    @testset verbose=true "exploring Agents.jl functionalities" begin
        @test typeof(model) <: ABM
        @test length(positions(model)) == 100
        @test model.initialPop == 100

        person1 = add_agent_pos!(Person(1,houses[1],random_gender(),20), model)
        @test home(person1) == houses[1]

        add_agent!(Person(nextid(model),UNDEFINED_HOUSE,random_gender(),31), houses[2], model)
        @test home(model[2]) == houses[2]

        add_agent!(model; age = 31)
        @test !ishomeless(model[3])

        add_agent!(model,age=40,gender=female)
        @test nagents(model) == 4

        add_agent!(houses[3],model,age=42)
        @test home(model[5]) == houses[3]
        @test length(allagents(model)) == 5

        kill_agent!(model[1],model)
        @test_throws KeyError model[1] == person1
        kill_agent!(2,model)
        @test nagents(model) == 3

        @test model[4].id == 4
        @test random_agent(model).id in [3,4,5]
        @test sum(allids(model)) == 12

        @test has_empty_positions(model)
        @test !undefined(random_position(model))
    end # Exploring Agents.jl

    @testset verbose=true "exploring some foo[!](model,*)" begin

        @test !undefined(random_town(model))
        @test length(empty_positions(model)) > 0
        @test !undefined(random_house(model))
        @test isempty(random_empty_house(model))

        nemptyhouses = length(empty_positions(model))
        add_empty_house!(model)
        @test length(empty_houses(model)) == nemptyhouses + 1

        add_empty_houses!(model,10)
        @test length(empty_houses(model)) == nemptyhouses + 1 + 10

        @test has_empty_positions(model)
        @test !undefined(random_empty(model))

    end # foo[!](model,*)

    pars = DemographyPars{Monthly}(initialPop = 1000)
    UKMonthlyModel = UKDemographicABM(pars)
    seed!(UKMonthlyModel,floor(Int,time()))

    @testset verbose=true "exploring component declaration" begin

        UKMap = declare_UK_map()
        @test length(UKMap.towns) > 0
        @test typeof(UKMonthlyModel) <: DemographicABM
        @test typeof(UKMonthlyModel) <: ABM
        @test UKMonthlyModel.initialPop == 1000

        println("\n==========================================\n")
        println("performance with IP = $(UKMonthlyModel.initialPop)")
        println("declaring population:")
        declare_population!(UKMonthlyModel)
        @test nagents(UKMonthlyModel) == UKMonthlyModel.initialPop

    end

    @testset verbose=true "exploring model initialization" begin

        println("init_kinship!:")
        @time init_kinship!(UKMonthlyModel)
        adultMen = [ man for man in allagents(UKMonthlyModel) if ismale(man) && isadult(man) ]
        marriedMen = [ man for man in adultMen if !issingle(man) ]
        @test length(marriedMen) / length(adultMen) > (model.startProbMarried - 0.1)

        @test verify_children_parents(UKMonthlyModel)
        @test verify_parentless_adults(UKMonthlyModel)
        @test verify_partnership(UKMonthlyModel)
        @test verify_homeless_population(UKMonthlyModel)

        println("init_housing!:")
        @time init_housing!(UKMonthlyModel)

        @test verify_all_have_home(UKMonthlyModel)
        @test length(empty_positions(UKMonthlyModel)) == 0
        @test verify_housing_consistency(UKMonthlyModel)
        @test verify_families_live_together(UKMonthlyModel)

    end

    @testset verbose=true "exploring stepping functions " begin

        idx = rand(1:nagents(UKMonthlyModel))
        person = UKMonthlyModel[idx]
        ageidx = age(person)

        step!(UKMonthlyModel,age_step!)
        @test ageidx - age(person) == -dt(UKMonthlyModel)

        step!(UKMonthlyModel,age_step!,3)
        @test ageidx - age(person) == -4*dt(UKMonthlyModel)

        println("running 40 age_steps")
        @time run!(UKMonthlyModel,age_step!, 40)
        @test ageidx - age(person) == -44*dt(UKMonthlyModel)

        step!(UKMonthlyModel,dummystep,population_age_step!)
        @test ageidx - age(person) == -45*dt(UKMonthlyModel)

        step!(UKMonthlyModel,age_step!,population_age_step!)
        @test ageidx - age(person)== -47*dt(UKMonthlyModel)
    end

    parshours = DemographyPars{Hourly}(initialPop = 10_000)
    UKHourlyModel = UKDemographicABM(parshours)
    seed!(UKHourlyModel,floor(Int,time()))

    println("\n==========================================\n")
    println("Performance with IP = $(UKHourlyModel.initialPop)")
    println("declare population:")
    @time declare_population!(UKHourlyModel)
    println("init_kinship!:")
    @time init_kinship!(UKHourlyModel)
    println("init_housing!:")
    @time init_housing!(UKHourlyModel)

    @testset "exploring hourly-ticking model" begin

        idx = rand(1:nagents(UKHourlyModel))
        person = UKHourlyModel[idx]
        ageidx = age(person)
        println("run!: running 1 month of age_steps in a hourly rate")
        @time run!(UKHourlyModel,age_step!, 30 * 24)
        @test ageidx - age(person) == -(30*24)*dt(UKHourlyModel)
        @test format_time(age(person) - ageidx,Daily()) == (0,0,30) # one day older
        run!(UKHourlyModel,age_step!, 24) # 24 hours
        @test format_time(age(person) - ageidx) == (0,1) # one month older

    end

    println("\n==========================================\n")

    include("./death_step_test.jl")

end #
nothing
