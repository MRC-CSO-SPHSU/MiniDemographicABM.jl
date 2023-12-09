"""
Generic API for different computational analysis problem that share common features:
    - the function to be analysed in the form y = f(x)
    - the uncertain function inputs (or model parameters)
    - the demand for multiple (possibly excessive) number of executions (or simulations)

Current computation problems considered are local and glbal sensitivity analysis
"""

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

"""
generic API for solving a computational analysis problem based on a non-determistic
    function. The outputs are averaged by executing the function multiple number of times
    each with a different seed number
"""
function solve(prob::ComputationProblem, f, actpars::Vector{ActiveParameter{T}},
    ::FuncMultiRun;
    runpar::Bool, fruns, seednum, kwargs...) where T

    "run f fruns times in parallel"
    function parfn(p)
        myseed!(seednum)
        y = f(p)
        addlock = ReentrantLock()
        @threads for i in 2:fruns
            myseed!(seednum*i)
            tmp = f(p)
            @lock addlock y += tmp
        end
        return y / fruns
    end
    "run f fruns times sequentially"
    function seqfn(p)
        myseed!(seednum)
        y = f(p)
        for i in 2:fruns
            myseed!(seednum*i)
            y += f(p)
        end
        return y / fruns
    end
    # which method to choose
    fn(runpar::Bool) = runpar && nthreads() > 1 ? parfn : seqfn

    return solve(prob,fn(runpar),actpars,SingleRun();seednum,kwargs...)
end

"""
generic API for solving a computational analysis problem based on a non-determistic
    function. The outputs are averaged by executing the method multiple number of times
    each with a different seed number
"""
function solve(prob::ComputationProblem, f, actpars::Vector{ActiveParameter{T}},
    ::MethodMultiRun;
    runpar::Bool, mruns, seednum, kwargs...) where T

    ret = solve(prob, f, actpars, SingleRun(); seednum, kwargs...)

    if runpar && nthreads() > 1 # run the method mruns times in parallel
        addlock = ReentrantLock()
        @threads for i in 2:mruns
            tmp = solve(prob, f, actpars, SingleRun(); seednum = seednum*i, kwargs...)
            @lock addlock for sym in fieldnames(typeof(ret))
                setfield!(ret, sym, getfield(tmp,sym) + getfield(ret,sym))
            end
        end
    else # run the method mruns times sequentially
        for i in 2:mruns
            tmp = solve(prob, f, actpars, SingleRun(); seednum = seednum*i, kwargs...)
            for sym in fieldnames(typeof(ret))
                setfield!(ret, sym, getfield(tmp,sym) + getfield(ret,sym))
            end
        end
    end
    for sym in fieldnames(typeof(ret))
        setfield!(ret, sym, getfield(ret,sym) / mruns )
    end

    return ret
end
