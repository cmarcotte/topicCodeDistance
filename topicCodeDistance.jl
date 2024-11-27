module topicCodeDistance

# not quite right
function new_digits(x::T)::NTuple{4,T} where {T<:Integer}
	return ntuple(i -> divrem(x, 10^(i-1))[2], 4)
end

# this is an integer-only topic tree distance calculation; no allocations, 3.5-9ns
function topicTreeDist(a::T, b::T)::T where {T <: Integer}
	_a = new_digits(a); _b = new_digits(b); d = zero(T);
	if _a[3] != _b[3]
		d += 2				# if 100, 200 -> up+down
		if _a[2] != 0
			d += 1			# if next digit is non-zero, extra step
		end
		if _b[2] != 0
			d += 1			# if next digit is non-zero, extra step
		end
	else
		if _a[2] != _b[2]		# if 110, 120 ...
			if _a[1] != 0
				d += 1		# up
			end
			if _b[1] != 0
				d += 1		# down
			end
		end
	end 
	return d
end

#=
DigitsIterator copied from https://discourse.julialang.org/t/slow-custom-digits-iterator/31367; non-allocating, very fast (<1ns); to use it, we need to adapt topicTreeDist to operate on a pair of iterators like zip(DigitsIterator(10,a), DigitsIterator(10,b))
=#
struct RadixIterator
    radix::Int
    n::Int
end
@inline Base.iterate(it::RadixIterator) = it.n == 0 ? (0,0) : iterate(it,it.n)
@inline Base.iterate(it::RadixIterator,el) = el == 0 ? nothing : reverse(divrem(el,it.radix))
Base.length(it::RadixIterator) = ndigits(it.n,base=it.radix)
Base.eltype(::Type{RadixIterator}) = Int

struct DigitIterator
	n::Int
end
@inline Base.iterate(it::DigitIterator) = it.n == 0 ? (0,0) : iterate(it,it.n)
@inline Base.iterate(it::DigitIterator,el) = el == 0 ? nothing : reverse(divrem(el,10))
Base.length(it::DigitIterator) = ndigits(it.n,base=10)
Base.eltype(::Type{DigitIterator}) = Int

end
