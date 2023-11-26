
"""
Common Computational problem types s.a. global / local sensitivity analysis
"""

include("./types/active_pars.jl")

abstract type ComputationProblem end
abstract type SAProblem <: ComputationProblem end
abstract type GSAProblem <: SAProblem end
abstract type LSAProblem <: SAProblem end

notimplemented(prob::ComputationProblem) = error("$(typeof(prob)) not implemented")

solve(prob::ComputationProblem, f, actpars::Vector{ActiveParameter{T}};
    kwargs...) where T = # method specific keyword arguments
    notimplemented(prob)

include("./methods/gsa.jl")
include("./methods/ofat.jl")
include("./methods/oat.jl")
