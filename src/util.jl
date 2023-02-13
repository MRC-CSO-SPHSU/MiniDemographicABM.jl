"convert date in rational representation to (years, months) as tuple"
function date2yearsmonths(date::Rational{Int})
    date < 0 ? throw(ArgumentError("Negative age")) : nothing
    12 % denominator(date) != 0 ? throw(ArgumentError("$(date) not in date/age format")) : nothing
    years  = trunc(Int, numerator(date) / denominator(date))
    months = trunc(Int, numerator(date) % denominator(date) * 12 / denominator(date) )
    return (years , months)
end

notimplemented(msg = "") = error("not implemeented" * msg)
notneeded(msg = "") = error("not needed" * msg)
