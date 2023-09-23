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
using ABMSim: ABMSimulator
using ABMSim: attach_agent_step!, step!

include("./abmsimspec.jl")

@assert ABMSIMVERSION == v"0.6.1"
init_abmsim()  # reset agents id counter

# Try without a simulator!
const simulator =
    ABMSimulator(dt=1//1, starttime=2020//1, finishtime=2030//1, seed = 1, setupEnabled=false)

# Construct the model

const pars = DemographyPars(initialPop = 10000)
const data = DemographyData()
const ukmap = declare_UK_map()
#const model = SimpleABMS{Person,DemographicMap}(ukmap)
const model = DemographicABMSim(pars,data,ukmap)


# declaration of model components
declare_population!(model,simulator)

# Initialzation of model
init_kinship!(model)
init_housing!(model)

# Step functions

# attach_agent_step!(simulator,age_step!)

# step

# step!(model,simulator)
# add_agent_pos!

# Run
