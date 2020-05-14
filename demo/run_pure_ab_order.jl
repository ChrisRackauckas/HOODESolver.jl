
include("../src/interface.jl")
using LinearAlgebra
using Plots
using Random

function fctmain(n_tau, prec)
    Random.seed!(8900161)
    u0 = rand(BigFloat, 4)
    B = 2rand(BigFloat, 4, 4)-ones(BigFloat,4, 4)
    setprecision(prec)
    u0=BigFloat.(u0)
    B = BigFloat.(B)
    println("u0=$u0")
    println("B=$B")
    fct = u -> B*u
    t_max = big"1.0"
    epsilon=big"0.00000015"
    A = [0 0 1 0; 0 0 0 0;-1 0 0 0; 0 0 0 0]
    prob = HiOscODEProblem(fct,u0, (big"0.0",t_max), missing, A, epsilon, B)
    nbmaxtest=12
    ordmax=17
    debord=3
    pasord=1
    y = ones(Float64, nbmaxtest, div(ordmax-debord,pasord)+1 )
    x=zeros(Float64,nbmaxtest)
    ind=1
    for order=debord:pasord:ordmax
        nb = 100
        indc = 1
        labels=Array{String,2}(undef, 1, order-debord+1)
        resnorm=0
        resnormprec=1
        ordprep = min(order+2,10)
        ordprep = order+2
        println("preparation ordre $ordprep")
        while indc <= nbmaxtest
            @time res = solve(prob, nb_tau=n_tau, order=order, order_prep=ordprep, nb_t=nb, dense=false)
            sol = res[end]
            solref=getexactsol(res.par_u0.parphi, u0, t_max)
            println("solref=$solref")
            println("nb=$nb sol=$sol")
            diff=solref-sol
            x[indc] = 1.0/nb
            println("nb=$nb dt=$(1.0/nb) normInf=$(norm(diff,Inf)) norm2=$(norm(diff))")
            resnorm = norm(diff,Inf)
            y[indc,ind] = min(norm(diff,Inf), 1.1)
            println("result=$y")
            println("log2(y)=$(log2.(y))")
            nb *= 2
            indc += 1
        end
        for i=debord:pasord:order
            labels[1,(i-debord)÷pasord+1] = " eps,order=$(convert(Float32,epsilon)),$i "
        end
        p=Plots.plot(
                        x,
                        view(y,:,1:ind),
                        xlabel="delta t",
                        xaxis=:log,
                        ylabel="error",
                        yaxis=:log,
                        legend=:bottomright,
                        label=labels,
                        marker=2
                    )
        prec_v = precision(BigFloat)
        eps_v = convert(Float32,epsilon)
        Plots.savefig(p,"out/res2_$(prec_v)_$(eps_v)_$(order)_$(ordprep)_$(n_tau)_exact.pdf")
        if resnorm > resnormprec
            break
        end
        resnormprec = resnorm
        ind+= 1
    end
end

# testODESolver()

# for i=3:9
#     fctMain(2^i)
# end
fctmain(32, 512)
