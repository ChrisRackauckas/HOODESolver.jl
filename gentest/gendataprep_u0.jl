include("../src/preparephi.jl")
include("../src/henon_heiles.jl")

using Printf


function _printnumstr( num::BigFloat)
    str = @sprintf("%1.200e", num)
    println("parse(")
    println("    BigFloat," )
    println("    \"$(str[1:70])\" *")
    println("    \"$(str[71:140])\" *")
    println("    \"$(str[141:end])\"")
    print(") ")
end

function print_for_test(
    order,
    u0,
    epsilon::Rational{BigInt}, 
    n_tau,
    matrix_A::Matrix,
    fct::Function,
)
    prec=precision(BigFloat)
    setprecision(1024)
    par = PreparePhi(BigFloat(epsilon), n_tau, matrix_A, fct)
    ordp1=order+1
    println("# PrepareU0 order=$order epsilon=$epsilon n_tau =$n_tau")

    println("# tab_u0 i prepared data for each order from 2 to order")
    println(" u0=$u0")
    println("# this file is generated by gendataprep_u0.jl file")
    println("function get_prepare_u0_for_test()")
    println("    tab_u0 = zeros(Complex{BigFloat}, $(par.size_vect), $n_tau, $ordp1)")
    for ord=2:ordp1
        up0 = PrepareU0(par, ord, BigFloat.(u), 2048)
        println("    tab_u0[ :, :, $ord] .= [")
        for i=1:par.size_vect
            res = view(par.tab_coef, i, :, j)
            for i_ell=1:n_tau
                print("    ")
                _printnumstr(real(res[i]))
                print("+ im * ")
                _printnumstr(imag(res[i]))
            end
            println("")
        end
        println("]")
    end
    println("    return tab_u")
    println("end")
    setprecision(prec)
end

print_for_test(
    15, 
    BigFloat.([0.125, 0.140625, 0.15625, 0.171875]), 
    big"1"/256,
    [0 0 1 0; 0 0 0 0; -1 0 0 0; 0 0 0 0], 
    henon_heiles,
)
