# Trace operations
using Test
using Dates: Second, now
using Statistics
using Seis
import SAC

@testset "Operations" begin
    @testset "Cut" begin
        let t = Trace(0, 0.01, rand(200)), t′ = deepcopy(t), b = rand(), e = b+rand()
            @test_throws ArgumentError cut(t, e, b)
            @test_throws ArgumentError cut(t, missing, e)
            @test cut(t, t.b, endtime(t)) == t
            @test cut(t, t.b-1, endtime(t)+1, warn=false) == t
            @test_logs (:warn,
                "Beginning cut time -1.0 is before start of trace.  Setting to 0.0.")
                (:warn,
                "End cut time 2.99 is after end of trace.  Setting to 1.99.")
                cut(t, t.b-1, endtime(t)+1)
            @test_logs cut(t, t.b-1, endtime(t)+1, warn=false)
            @test cut!(t′, b, e) == cut(t, b, e)
            @test t′ == cut(t, b, e)
            @test t′.b ≈ b atol=t.delta/2
            @test endtime(t′) ≈ e atol=t.delta/2
            time_now = now()
            t.evt.time = time_now
            @test cut(t, time_now, time_now + Second(1)) == cut(t, 0, 1)
            add_pick!(t, 1, "Test pick")
            @test cut(t, "Test pick", 0, "Test pick", 0.5) == cut(t, 1, 1.5)
            @test cut(t, "Test pick", 0, 0.5) == cut(t, 1, 1.5)
        end
    end

    @testset "Decimate" begin
        let n = rand(10:1000), t = Trace(1, 0.5, rand(n)), t′ = deepcopy(t)
            # Without antialiasing
            @test_throws ArgumentError decimate(t, 0, antialias=false)
            @test decimate(t, 1, antialias=false) == t
            @test nsamples(decimate(t, 5, antialias=false)) == length((1:n)[1:5:end])
            @test decimate(t, 3, antialias=false).delta == t.delta*3
            decimate!(t, 4, antialias=false)
            @test t == decimate(t′, 4, antialias=false)
        end
    end

    @testset "Remove mean" begin
        let t = Trace(0, 0.01, [i%2 for i in 1:1000]), t′ = deepcopy(t)
            atol = eps(eltype(trace(t)))
            @test mean(trace(remove_mean(t))) ≈ 0.0 atol=atol
            remove_mean!(t)
            @test t == remove_mean(t′)
        end
    end

    @testset "Remove trend" begin
        let t = Trace(0, 0.1, 1:100), t′ = deepcopy(t)
            atol = 1000eps(eltype(trace(t)))
            @test all(isapprox.(trace(remove_trend(t)), 0.0, atol=atol))
            remove_trend!(t)
            @test t == remove_trend(t′)
        end
    end

    @testset "Normalisation" begin
        let t = Trace(0, 1, rand(5)), val=rand(1:20), t′ = deepcopy(t)
            @test maximum(abs, trace(normalise(t, val))) ≈ val
            @test maximum(abs, trace(normalise(t))) ≈ 1
            normalise!(t)
            @test t == normalise(t′)
        end
    end
end
