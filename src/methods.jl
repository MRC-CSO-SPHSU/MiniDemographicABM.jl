
"""
Common Computational problem types s.a. global / local sensitivity analysis with
    a subset of model parameters being specified as uncertain active parameters
"""

using Base.Threads

include("./util.jl")
include("./types/active_pars.jl")

abstract type ComputationProblem end
abstract type SAProblem <: ComputationProblem end
abstract type GSAProblem <: SAProblem end
abstract type LSAProblem <: SAProblem end

notimplemented(prob::ComputationProblem) = error("$(typeof(prob)) not implemented")

"""
Simulations of ABMs are not determinstic, i.e. different seeds lead to different
results. Thus, it might be useful to apply specific computational analysis multiple
number of times either by
i. executing the simulation function multiple times each with different seed number
   and taking the average result as input to the method
ii. executing the method multiple number of times each applied to different seed number

The better choice depends on the method runtime efficiency. The two choices are not
necessarily symmetric. Merging the two choices is also imaginable, i.e. executing the
method multiple number of times each on multiple evaluations of functions. To be implemented
if ever needed.
"""
abstract type RunMode end
struct SingleRun <: RunMode end   # default
abstract type MultiRun <: RunMode end
struct FuncMultiRun <: MultiRun end
struct MethodMultiRun <: MultiRun end

"generic API for solving a computational problem"
solve(prob::ComputationProblem, f, actpars::Vector{ActiveParameter{T}},
    ::RunMode=SingleRun();  #default
    kwargs...) where T = # method specific keyword arguments
        notimplemented(prob)

"generic API for executing a computational problem multiple number of times"
solve(prob::ComputationProblem, f, actpars::Vector{ActiveParameter{T}},
    ::MethodMultiRun; kwargs...) where T =
        notimplemented(prob)

"""
generic API for solving a computational analysis problem based on a non-determistic
    function. The outputs are averaged by executing the function multiple number of times
"""
function solve(prob::ComputationProblem, f, actpars::Vector{ActiveParameter{T}},
    ::FuncMultiRun;
    fruns, seednum, kwargs...) where T

    function nfabm(p)
        myseed!(seednum)
        y = fabm(p)

        # Multi-level multi-threading
        # addlock = ReentrantLock()
        # @threads
        for i in 2:fruns
            myseed!(seednum*i)
            y += fabm(p)
        end
        return y / fruns
    end

    return solve(prob,nfabm,actpars,SingleRun();seednum,kwargs...)
end
include("./methods/gsa.jl")     # GSA methods from GlobalSensitivity.jl
include("./methods/ofat.jl")    # One Factor At Time LSA method
include("./methods/oat.jl")     # One At Time derivative-based LSA Method
