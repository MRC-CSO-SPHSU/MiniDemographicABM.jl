include("./src/modelspec.jl")

 """
 properties can be accessed in models.jl
 Other clock options: Monthly, Hourly
 """
const properties = DemographicABMProp{Daily}(initialPop = 10_000)
const model = UKDemographicABM(properties)
seed!(model,floor(Int,time()))  # really random
declare_population!(model)
init_kinship!(model) # the kinship among population
init_housing!(model) # housing assoication to population

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

# proceed simulation for 10 years
@time run!(model,agent_steps!,model_steps!,365*10)
nothing
