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
using ABMSim: ABMSimulator, SimpleABMS
include("./modelspec.jl")

@assert ABMSIMVERSION == v"0.6.1"
init_abmsim()  # reset agents id counter

const simulator =
    ABMSimulator(dt=1, starttime=2020//1, finishtime=2030//1, seed = 1, setupEnabled=false)

const ukmap = declare_UK_map()
const model = SimpleABMS{Person,DemographicMap}(ukmap)
