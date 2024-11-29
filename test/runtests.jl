module test_suite

include("../topicCodeDistance.jl"); using .topicCodeDistance

using Test, PrettyChairMarks


function test_f(f)
	a = 110
	for (b,d) in zip((100,120,200,210,1415),(1,2,3,4,5))
		@test f(a, b) == d
	end
	return nothing
end

@test_f(topicCodeDistance.topicTreeDist)
@test_f(topicCodeDistance.topicCodeTreeDistance)

end	#test_suite
