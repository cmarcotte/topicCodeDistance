module topicCodeDistance

export topicCodeTreeDistance

function topicTreeDist(a::T, b::T)::T where {T <: Integer}
	_a = digits(a); _b = digits(b); d = zero(T);
	if _a[3] != _b[3]
		d += 2							# if 100, 200 -> up+down
		if _a[2] != 0
			d += 1						# if next digit is non-zero, extra step
		end
		if _b[2] != 0
			d += 1						# if next digit is non-zero, extra step
		end
	else
		if _a[2] != _b[2]		# if 110, 120 ...
			if _a[1] != 0
				d += 1					# up
			end
			if _b[1] != 0
				d += 1					# down
			end
		end
	end 
	return d
end
#=
	We can traverse the tree implicitly by rounding to zero with ever-decreasing 
	significant digits: e.g. 111 |> 110 |> 100 |> 0 is the repeated application of
		x <- Int(round(x, RoundToZero, sigdigits=(one less than currently in x)))
=#
struct TreeIterator
	n::Int
end
@inline Base.iterate(it::TreeIterator) = it.n == 0 ? (0, (0, it.n)) : iterate(it, (1, Int(round(it.n, RoundToZero, sigdigits=length(it)))))
@inline Base.iterate(it::TreeIterator, el) = el[2] == 0 ? (el[2], el) : (el[2], (el[1]+1, Int(round(el[2], RoundToZero, sigdigits=length(it)-el[1]))))
Base.length(it::TreeIterator) = ndigits(it.n)
Base.eltype(::Type{TreeIterator}) = Int

# and then the tree distance calculation is quite similar to:
function topicCodeTreeDistance(a::Int, b::Int)::Int
	d = zero(Int); __a = a;	__b = b;
	for (_a, _b) in zip(TreeIterator(a), TreeIterator(b))
		if _a != __a	# check for changes from the previous iteration
			d += one(Int)
			__a = _a
		end
		if _b != __b	# check for changes from the previous iteration
			d += one(Int)
			__b = _b
		end
		# if adapting this code you may find the following debug log useful,
		#@debug "$_a ($a => $(_a != a)) $_b ($b => $(_b != b)) $d"
		# but it increases the function time from 85ns to >300ns, even un-called.
		if _a == _b	
			return d
		end
	end
end

#=
The SIAM topic code tree looks like this:
							000
		 					 |
 ------------------------------------
 |			|			|			|			|		...		|
100		200		300		400		500				1600
 |			|			|			|			|					|
_____	_____	_____	_____	_____			_____
|...| |...|	|...|	|...|	|...|			|...|

For the tree the closest parent of a & b is given by the most significant digit
they share, followed by zeros... almost. 
With iterators over the digits of both a & b, you would go up until reaching 
that parent.
So for:	
	a = 110, b = 100: a.up = 100 == b									=> d = 1
	a = 110, b = 120:	a.up = 100 = b.up								=> d = 2
	a = 110, b = 200:	a.up.up = 000 == b.up 					=> d = 3
	a = 110, b = 210: a.up.up = 000 = b.up.up					=> d = 4
	a = 110, b =1415:	a.up.up = 000 = b.up.up.up			=> d = 5

However, the topicCodeTreeDistance function does not calculate these values.
The last case is incorrect with the TreeIterator, as it (correctly!) identifies
"14" as two sigfigs and not one, so it requires taking b all the way to zero:
		b = 1415 |> 1410	|> 1400 |> 1000 |> 0
		a = 110  |>  100	|> 0
whereas we were implicitly dropping the significance of the digit in the
thousands place, if the digits in the hundreds place is different for a & b.
This is not a correct mapping to the tree, but also kind of identifies that the
SIAM topic code tree, as designed, is silly and maybe it's worth keeping this
behavior.

The other issue is we have a limit on the number of digits in a topic code, and
adapting this to the general case is unclear... would overcount short codes:
	a = 10 		|> 0 		|> 0		|> 0	=> d = 3
	b = 1430 	|> 1400	|> 1000	|> 0	=> d = 3
would yield d = 6, when really we flatten the 14 to be a single "digit", so it's
a multi-radix number system.
=#

# this implementation is equivalent to the iterator-based approach above, but 
# slightly faster (65-80ns).
@inline roundmap(x::Int; sg::Int=4) = Int(round(x, RoundToZero, sigdigits=sg))
function dist(a::Int, b::Int)::Int
	d = zero(Int); __a = a; __b = b;
	@inbounds for n in 4:-1:0
		_a = roundmap(a; sg=n)
		_b = roundmap(b; sg=n)
		if _a != __a
			d += one(Int)
			__a = _a
		end
		if _b != __b
			d += one(Int)
			__b = _b
		end
		if _a == _b
			return d
		end
	end
end

end
