include("../src/preparephi.jl")
include("../src/henon_heiles.jl")
include("dataprep_u0.jl")
using Test

# these 3 functions come from old version with sin and cos computation
# to test the new version
function filtredfct( u, s, c )
    a = c*u[1] + s*u[3]
    b = 2 * u[2] * a
    return [ s*b, u[4], -c*b, -u[2] - a^2 + u[2]^2 ]
end
function filtredfctgen2( u::Array{Array{T,1},1}, s, c, n_tau ) where T <: Number
    f = filtredfct.( u, s, c)
    # convert an array of vector to a matrix
    f = collect(transpose(reshape(collect(Iterators.flatten(f)), 4, n_tau)))
    return f
end
function filtredfctgen( uMat::Array{T,2}, s, c, n_tau ) where T <: Number
    return filtredfctgen2(reshape(mapslices(x->[x],uMat,dims = (2,)), n_tau), s, c, n_tau)
end

function test_tau_A()
    epsilon = big"0.5"
    n_tau = 64
    A = [0 0 1 0; 0 0 0 0; -1 0 0 0; 0 0 0 0]
    parphi = PreparePhi(epsilon, n_tau, A, henon_heiles)
    tol= 1e-77
    @testset "preparephi tau_A" begin
        for i = 1:n_tau
            s,c = setprecision(precision(BigFloat)+32) do
                v = (i-1)*2big(pi)/n_tau
                sin(v), cos(v)
            end

            res_ref = one(zeros(BigFloat,4,4))
            res_ref[1,1] = res_ref[3,3] = c
            res_ref[1,3] = s
            res_ref[3,1]= -res_ref[1,3]
            @test isapprox(res_ref, convert(Matrix, parphi.tau_A[i]), atol=tol)
            res_ref[3,1], res_ref[1,3] = res_ref[1,3], res_ref[3,1]
            @test isapprox(res_ref, convert(Matrix, parphi.tau_A_inv[i]), atol=tol)
        end
    end
end
function test_fct()
    epsilon = big"0.5"
    n_tau = 64
    A = [0 0 1 0; 0 0 0 0; -1 0 0 0; 0 0 0 0]
    parphi = PreparePhi(epsilon, n_tau, A, henon_heiles)
    tol= 1e-76
    @testset "preparephi fct" begin
        for i = 1:n_tau
            s,c = setprecision(precision(BigFloat)+32) do
                v = (i-1)*2big(pi)/n_tau
                sin(v), cos(v)
            end
            u0 = rand(BigFloat,4)
            res_ref = filtredfct(u0, s, c)
            res = filtred_f(u0,parphi.tau_A_inv[i],henon_heiles, parphi.tau_A[i])
            @test isapprox(res_ref, res, atol=tol)
        end
    end
end

function testpreparephi0()
 
    epsilon = big"0.5"
    n_tau = 64
    tol=1e-76
    @time @testset "preparephi and function for all tau" begin
        parphi = PreparePhi(
    epsilon, 
    n_tau,
    [0 0 1 0; 0 0 0 0; -1 0 0 0; 0 0 0 0],
    henon_heiles
)
        u_mat = rand(BigFloat, 4, n_tau)
        u_mat_tr = collect(transpose(u_mat))
        tau = LinRange(zero(BigFloat), one(BigFloat), n_tau + 1)[1:end - 1]
        s = sinpi.(2tau)
        c = cospi.(2tau)
        old_m = collect(transpose(filtredfctgen(u_mat_tr, s, c, n_tau)))
        new_m = filtredfct(parphi,u_mat)
        println("norm=$(norm(old_m-new_m))")
        @test isapprox(old_m, new_m, atol=tol)
    end
end

function testpreparephi()
    @time @testset "phi and prepare u0" begin
        tab_ref = setprecision(1024) do
            get_prepare_u0_for_test()
        end
        for i_prec=1:3
            prec = 256*2^(i_prec-1)
            tol=max((1e-77)^i_prec, 1e-200)
            setprecision(prec) do
                epsilon = big"1"/256
                n_tau = 32
                parphi = PreparePhi(
    epsilon, 
    n_tau, 
    [0 0 1 0; 0 0 0 0; -1 0 0 0; 0 0 0 0],
    henon_heiles
)
                u0 = BigFloat.([0.125, 0.140625, 0.15625, 0.171875])
                for ord=2:10
            #     paru0 = PrepareU0(parphi, ord, u0, 1024)
                    paru0 = PrepareU0(parphi, ord, u0)
 #                   println("prec=$prec ord=$ord norm=$(norm(tab_ref[:, :, ord]- paru0.ut0))")
                    @test isapprox(tab_ref[:, :, ord], paru0.ut0, atol=tol, rtol=tol)
                end
            end
        end
    end
end
test_tau_A()
test_fct()
testpreparephi0()
testpreparephi()
