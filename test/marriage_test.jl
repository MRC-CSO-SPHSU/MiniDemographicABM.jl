include("./helpers.jl")

# agent_step
# model_step
# combinations
testMarriageModel = create_demographic_model(Daily,10_000,initKinship=true, initHousing=true)

function age_death_divorce_step!(agent,model)
    age_step!(agent,model)
    death!(agent,model)
    divorce!(agent,model)
end

function domarriages_step!(model)
    metastep!(model)
    domarriages!(model)
end

function dobirths_domarriages_step!(model)
    metastep!(model)
    dobirths!(model)
    domarriages!(model)
end

@testset "testing marriage functions" begin

    npeople = nagents(testMarriageModel)
    nSingles = length([person for person in allagents(testMarriageModel) if
        is_eligible_marriage(person)])

    println("one model step domarriages!:")
    @time ret = domarriages!(testMarriageModel)
    nSingles2 = length([person for person in allagents(testMarriageModel) if
        is_eligible_marriage(person)])
    @test ret * 2 == nSingles - nSingles2

    println("executing one year of domarriages + agestep")
    @time run!(testMarriageModel,age_step!,domarriages_step!,365)
    nSingles3 = length([person for person in allagents(testMarriageModel) if
        is_eligible_marriage(person)])
    #@test nSingles3 < nSingles2 # some childs start to become adults!

    println("executing one year of domarriages/births / age_death_divorce_step")
    @time run!(testMarriageModel,age_death_divorce_step!,dobirths_domarriages_step!,365)
    nSingles4 = length([person for person in allagents(testMarriageModel) if
        is_eligible_marriage(person)])
    @test nSingles4 != nSingles3

    # The population shall not vanish after 15 decades

    nalive = length([person for person in allagents(testMarriageModel) if isalive(person) ])
    ndeads = length([person for person in allagents(testMarriageModel) if !isalive(person) ])
    println("# of alive people after 1 year :$nalive, deadpeople after 1 year :$ndeads")
    ndecades = 0
    println("10 years of age_death_divorce / dobirths-domarriages executions:")
    while ndecades < 15
        @time run!(testMarriageModel,age_death_divorce_step!,dobirths_domarriages_step!,365*10)
        nalive = length([person for person in allagents(testMarriageModel) if isalive(person) ])
        ndeads = length([person for person in allagents(testMarriageModel) if !isalive(person) ])
        println("# of alive people :$nalive, deadpeople : $ndeads after $(ndecades+1) decades")
        oldestDeadAge =
            maximum([age(person) for person in allagents(testMarriageModel) if !isalive(person)])
        @show date2yearsmonths(oldestDeadAge)[1]
        ndecades += 1
    end
    @test ndeads > 10_000
    oldestDeadAge =
        maximum([age(person) for person in allagents(testMarriageModel) if !isalive(person)])
    @test oldestDeadAge < 150
    @show date2yearsmonths(oldestDeadAge)[1]
end

println("\n==========================================\n")
