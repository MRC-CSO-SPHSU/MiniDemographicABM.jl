include("./helpers.jl")

# agent_step
# model_step
# combinations
testDivorceModel = create_demographic_model(Daily,10_000,initKinship=true, initHousing=true)

function age_divorce_step!(agent,model)
    age_step!(agent,model)
    divorce!(agent,model)
end

function age_death_divorce_step!(agent,model)
    age_step!(agent,model)
    death!(agent,model)
    divorce!(agent,model)
end

function dobirths_step!(model)
    metastep!(model)
    dobirths!(model)
end

function dodivorces_step!(model)
    metastep!(model)
    dobirths!(model)
    dodivorces!(model)
end

@testset "testing divorce functions" begin

    npeople = nagents(testDivorceModel)
    isdivorcable(man) = ismale(man) && !issingle(man)   #  dead people are single
    dMen = [man for man in allagents(testDivorceModel) if isdivorcable(man)]
    nMarriedOld = length([person for person in allagents(testDivorceModel) if
        isalive(person) && !issingle(person)])
    man = rand(dMen)
    println("one agent step divorce!:")
    @time ret = divorce!(man, testDivorceModel)
    while ret != true
        man = rand(dMen)
        ret = divorce!(man, testDivorceModel)
    end
    ageMan = age(man)
    @test issingle(man)

    println("one model step dodivorces:")
    @time dobirths!(testDivorceModel)
    nMarriedNew = length([person for person in allagents(testDivorceModel) if
        isalive(person) && !issingle(person)])
    @test nMarriedNew < nMarriedOld

    println("executing one year of divorce + agestep")
    @time run!(testDivorceModel,age_divorce_step!,metastep!,365)
    @test ageMan + 1 == age(man)
    @test currstep(testDivorceModel) == 2021

    nMarriedNew2 = length([person for person in allagents(testDivorceModel) if
        isalive(person) && !issingle(person)])
    @test nMarriedNew2 < nMarriedNew

    println("executing one year of dodivorces + agestep")
    @time run!(testDivorceModel,age_step!,dodivorces_step!,365)
    nMarriedNew3 = length([person for person in allagents(testDivorceModel) if
        isalive(person) && !issingle(person)])
    @test nMarriedNew3 < nMarriedNew2

    println("executing one year of dobirths / age_death_divorce_step")
    @time run!(testDivorceModel,age_death_divorce_step!,dobirths_step!,365)
    ndeads = length([person for person in allagents(testDivorceModel) if !isalive(person)] )
    @test ndeads > 0

    # no marriages , so the population will certainly vanish
    nalive = length([person for person in allagents(testDivorceModel) if isalive(person) ])
    println("# of alive people after 1 year :$nalive")
    ndecades = 0
    println("10 years of age_death / dobirths executions:")
    while nalive > 0
        @time run!(testDivorceModel,age_death_divorce_step!,dobirths_step!,365*10)
        nalive = length([person for person in allagents(testDivorceModel) if isalive(person) ])
        ndecades += 1
        println("# of alive people after $(ndecades+1) decades :$nalive")
    end
    @test ndecades < 15
end

println("\n==========================================\n")
