include("./helpers.jl")

testBirthModel = create_demographic_model(Daily,10_000,initKinship=true, initHousing=true)

function age_birth_step!(agent,model)
    age_step!(agent,model)
    birth!(agent,model)
end

function age_death_step!(agent,model)
    age_step!(agent,model)
    death!(agent,model)
end

function dobirths_step!(model)
    metastep!(model)
    return dobirths!(model)
end

@testset "testing birth functions" begin

    npeople = nagents(testBirthModel)
    rWomen = [woman for woman in allagents(testBirthModel) if can_give_birth(woman)]
    rwoman = rand(rWomen)
    println("one agent step birth!:")
    @time ret = birth!(rwoman, testBirthModel)
    while ret != true
        rwoman = rand(rWomen)
        ret = birth!(rwoman, testBirthModel)
    end
    ageRwoman = age(rwoman)
    @test testBirthModel[10001] === youngest_alive_child(rwoman)

    println("one model step dobirth:")
    @time dobirths!(testBirthModel)

    println("executing one year of birth + agestep")
    @time run!(testBirthModel,age_birth_step!,metastep!,365)
    @test ageRwoman + 1 == age(rwoman)
    @test currstep(testBirthModel) == 2021
    @test nagents(testBirthModel) > npeople

    println("executing one year of dobirth + agestep")
    @time run!(testBirthModel,age_step!,dobirths_step!,365)
    @test nagents(testBirthModel) > npeople

    println("executing one year of dobirth + dodeath agestep")
    @time run!(testBirthModel,age_death_step!,dobirths_step!,365)
    ndeads = length([person for person in allagents(testBirthModel) if !isalive(person)] )
    @test ndeads > 0

    # no marriages , so the population will certainly vanish

    nalive = length([person for person in allagents(testBirthModel) if isalive(person) ])
    println("# of alive people after 1 year :$nalive")
    ndecades = 0
    println("10 years of age_death / dobirths executions:")
    while nalive > 0
        @time run!(testBirthModel,age_death_step!,dobirths_step!,365*10)
        nalive = length([person for person in allagents(testBirthModel) if isalive(person) ])
        ndecades += 1
        println("# of alive people after $(ndecades) decades :$nalive")
    end
    @test ndecades < 15
end

println("\n==========================================\n")
