using Agents
using Test
using Plots

include("../src/modelspec.jl")

pars = DemographyPars{Daily}(initialPop = 10_000)
testDeathModel = UKDemographicABM(pars)
seed!(testDeathModel,floor(Int,time()))
println("Performance with IP = $(testDeathModel.initialPop)")
println("declare_population:")
@time declare_population!(testDeathModel)

function age_death_step!(agent,model)
    age_step!(agent,model)
    death_step!(agent,model)
end


@testset "testing stepping functions" begin
    println("evaluating # of alive people:")
    @time nalive = length([person for person in allagents(testDeathModel) if isalive(person) ])
    idx = rand(1:nagents(testDeathModel))
    person = testDeathModel[idx]
    println("one step death_step!:")
    @time ret = death_step!(person, testDeathModel)
    @test ret == !isalive(person)
    println("exectuing one year of death+age steps on a daily basis:")
    @time run!(testDeathModel,age_death_step!,365)
    nalive = length([person for person in allagents(testDeathModel) if isalive(person) ])
    println("# of alive people after 1 year :$nalive")
    ndecade = 0
    while nalive > 0
        run!(testDeathModel,age_death_step!,365*10)
        nalive = length([person for person in allagents(testDeathModel) if isalive(person) ])
        ndecade += 1
        println("# of alive people after $(ndecade) decades :$nalive")
    end
    @test ndecade < 15
end

println("\n==========================================\n")
