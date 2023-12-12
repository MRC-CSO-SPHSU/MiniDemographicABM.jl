
"""
Common Computational problem types s.a. global / local sensitivity analysis with
    a subset of model parameters being specified as uncertain active parameters
"""

using Base.Threads

include("./util.jl")
include("./types/active_pars.jl")
include("./types/computation_problem.jl")
include("./methods/gsa.jl")     # GSA methods from GlobalSensitivity.jl
include("./methods/ofat.jl")    # One Factor At Time LSA method
include("./methods/oat.jl")     # One At Time derivative-based LSA Method
