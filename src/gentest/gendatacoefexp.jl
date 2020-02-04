include("../src/coefexp_ab.jl")

using Printf


function _printnumstr( num::BigFloat)
    str = @sprintf("big\"%1.200e\"", num)
    println("parse(")
    println("    BigFloat," )
    println("    \"$(str[1:70])\" *")
    println("    \"$(str[71:140])\" *")
    println("    \"$(str[141:end])\"")
    print(") ")
end

function print_for_test(order, epsilon::Rational{BigInt}, n_tau, dt::Rational{BigInt})
    
    prec=precision(BigFloat)
    setprecision(1024)
    par = CoefExpAB(order, float(epsilon), n_tau, float(dt) )
    ind = div(order, 2)
    println("# CoefExpAB order=$order epsilon=$epsilon n_tau =$ntau dt=$dt")
    println("tab_res_coef is AB coefficient for each value from 1 to n_tau")
    println(" tab_res_coefAB = [")
    for i = 1:(order+1)
        print("    ")
        res = view(par.tab_coef,order+1,i,:)
        for j=1:n_tau
            _printnumstr(real(res[i]))
            print("+ im * ")
            _printnumstr(imag(res[i]))
        end
        println("")
    end
    println("]")
    setprecision(prec)
end

