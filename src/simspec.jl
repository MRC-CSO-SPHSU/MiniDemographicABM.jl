include("./basictypes.jl")
include("./spec/models.jl")
include("./spec/declare.jl")
include("./spec/initialize.jl")
include("./spec/stepping.jl")


#############################################################
# model declaration, initializtaion and stepping definitions
#############################################################
#  Suggested agent_steps and model_steps for ABM Simulation
#


function declare_initialized_UKmodel(clock,properties)
    model = UKDemographicABM(properties)
    declare_population!(model)
    init_kinship!(model) # the kinship among population
    init_housing!(model) # housing assoication to population
    return model
end

function agent_steps!(person,model)
    age_step!(person,model)
    death!(person,model)
    divorce!(person,model)
end

function model_steps!(model)
    metastep!(model) # incrementing time
    dobirths!(model)
    domarriages!(model)
end
