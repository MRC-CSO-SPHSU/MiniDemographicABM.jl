
"""
Common Computational problem types s.a. global / local sensitivity analysis with
    a subset of model parameters being specified as uncertain active parameters
"""

include("./types/active_pars.jl")

abstract type ComputationProblem end
abstract type SAProblem <: ComputationProblem end
abstract type GSAProblem <: SAProblem end
abstract type LSAProblem <: SAProblem end

notimplemented(prob::ComputationProblem) = error("$(typeof(prob)) not implemented")

"""
Simulations of ABMs are not determinstic, i.e. different seeds lead to different
results. Thus, it might be useful to apply specific computational analysis to multiple runs
with different seed numbers and consider the avergae values of the results
"""
abstract type RunMode end
struct SingleRun <: RunMode end   # default
struct MultipleRun <: RunMode end

"generic API for solving a computational problem"
solve(prob::ComputationProblem, f, actpars::Vector{ActiveParameter{T}},
    ::SingleRun=SingleRun();  #default
    kwargs...) where T = # method specific keyword arguments
    notimplemented(prob)

"""
generic API for solving a computational analysis problem based on a non-determistic
    function. The outputs are averaged by executing the function multiple number of times
"""
function solve(prob::ComputationProblem, f, actpars::Vector{ActiveParameter{T}},
    ::MultipleRun;
    nruns, seednum, kwargs...) where T

    function nfabm(p)
        seednum == 0 ? Random.seed!(floor(Int,time())) : Random.seed!(seednum)
        y = fabm(p)

        # Multi-level multi-threading
        addlock = ReentrantLock()
        @threads for i in 2:nruns
            seednum == 0 ? Random.seed!(floor(Int,time())) : Random.seed!(seednum+i-1)
            #@show threadid()
            @lock addlock y += fabm(p)
        end
        return y / nruns
    end

    return solve(prob,nfabm,actpars,SingleRun();seednum,kwargs)
end
include("./methods/gsa.jl")     # GSA methods from GlobalSensitivity.jl
include("./methods/ofat.jl")    # One Factor At Time LSA method
include("./methods/oat.jl")     # One At Time derivative-based LSA Method
