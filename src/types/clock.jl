"""
Basic data type and functions for realizing age, dates and step sizes of Rational type
"""

include("../util.jl")

abstract type Clock end

struct Centurly <: Clock end
struct Decadly <: Clock end
struct Yearly <: Clock end
struct Monthly <: Clock end
struct Daily <: Clock end
struct Hourly <: Clock end
struct Minutly <: Clock end
struct Secondly <: Clock end

num_ticks_year(::Clock) = notimplemented()
num_ticks_year(::Monthly) = 12
num_ticks_year(::Daily) = 365 # or 12 * 30.5
num_ticks_year(::Hourly) = 365 * 24
dt(clock::Clock) = 1 // num_ticks_year(clock)
stepsize(clock) = dt(clock)
instantaneous_probability(rate,clock) = -log(1-rate) / num_ticks_year(clock)

"convert date in rational representation to (years, months) as tuple"
function date2yearsmonths(date::Rational{Int})
    years  = trunc(Int, numerator(date) / denominator(date))
    months = trunc(Int,12 *(date - years))
    return (years , months)
end

format_time(t) = date2yearsmonths(t)
format_time(t,::Clock) = notimplemented()
format_time(t,::Monthly) = date2yearsmonths(t)
function format_time(t,::Daily)
    years, months = date2yearsmonths(t)
    days = trunc(Int,365 * (t - years) - 365 * months // 12)
    return (years, months, days)
end
