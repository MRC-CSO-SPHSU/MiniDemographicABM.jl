include("../src/modelspec.jl")

function create_demographic_model(clocktype::Type{T},ips = 10_000;
    initKinship = false, initHousing = false) where T <: Clock

    properties = DemographicABMProp{clocktype}(initialPop = ips)
    model = UKDemographicABM(properties)
    seed!(model,floor(Int,time()))
    println("\n==========================================\n")
    println("Performance with IP = $(model.initialPop)")
    println("declare_population:")
    @time declare_population!(model)
    if initKinship
        println("init_kinship!:")
        @time init_kinship!(model)
    end
    if initHousing
        println("init_housing!:")
        @time init_housing!(model)
    end
    return model
end
