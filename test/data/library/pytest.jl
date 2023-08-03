@test x == y
@test x == y

@testset "foo" begin
    @test 1 == 1
end

@test_throws AssertionError foo()
