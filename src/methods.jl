
"""
Common Computational problem types s.a. global / local sensitivity analysis
"""

include("./types/active_pars.jl")

abstract type ComputationProblem end
abstract type SAProblem <: ComputationProblem end
abstract type GSAProblem <: SAProblem end
abstract type LSAProblem <: SAProblem end

notimplemented(prob::ComputationProblem) = error("$(typeof(pr)) not implemented")

solve(prob::ComputationProblem, f, actpars::Vector{ActiveParameter{Float64}};
    kwargs...) = # method specific keyword arguments
    notimplemented(prob)

include("./methods/gsa.jl")
