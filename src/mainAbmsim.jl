"""
a demographic simulation using ABMSim.jl package

Run this script from shell as
#  julia <script-name.jl>

or within REPL

julia> include("script-name.jl")
"""

include("util.jl")
add_to_loadpath!(pwd() * "/../../ABMSim.jl")
