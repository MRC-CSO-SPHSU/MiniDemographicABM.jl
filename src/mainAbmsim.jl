"""
a demographic simulation using ABMSim.jl package

Run this script from shell as
#  julia <script-name.jl>

or within REPL

julia> include("script-name.jl")
"""

include("util.jl")
add_to_loadpath!(pwd() * "/../../ABMSim.jl")

using ABMSim: ABMSIMVERSION, init_abmsim
using ABMSim: FixedStepSim
using ABMSim: attach_agent_step!, step!, run!

include("./abmsimspec.jl")

@assert ABMSIMVERSION == v"0.7.2"
init_abmsim()  # reset agents id counter

# Try without a simulator!
const simulator =
    FixedStepSim(dt=1//365, starttime=2020//1, finishtime=2030//1, seed = 0)

# Construct the model
const pars = DemographyPars(initialPop = 10_000)
const data = DemographyData()
const ukmap = declare_UK_map()
const model = DemographicABMSim(pars,data,ukmap)

# declaration of model components
declare_population!(model,simulator)

# Initialzation of model
init_kinship!(model)
init_housing!(model)

# Step functions
function asteps!(person,model,sim)
    age_step!(person,model,sim)
    death!(person,model,sim)
    divorce!(person,model,sim)
end

function msteps!(model,sim)
    dobirths!(model,sim)
    domarriages!(model,sim)
end

# step
#step!(model,asteps!,simulator)

# add_agent_pos!
@time run!(model,asteps!,msteps!,simulator)

#=
Some stats
deadpeople = [ p for p in allagents(model) if !isalive(p) ]
@show length(deadpeople)

singleParents = [ p for p in allagents(model) if issingle(p) && has_children(p) ] ;
@show length(singleParents)

marriedParents = [ p for p in allagents(model) if !issingle(p) && has_children(p) ] ;
@show length(marriedParents)
=#

# Run
