using KernelAbstractions: get_backend, synchronize, @index, @kernel, @groupsize
using CUDA: CuArray
using BenchmarkTools

δ(d,::CartesianIndex{D}) where {D} = CartesianIndex(ntuple(j -> j==d ? 1 : 0, D))
@inline ∂(a,I::CartesianIndex{D},u::AbstractArray{T,n}) where {D,T,n} = u[I+δ(a,I),a]-u[I,a]
inside(a) = CartesianIndices(ntuple(i-> 2:size(a)[i]-1,ndims(a)))

# serial loop macro
macro loop(args...)
    ex,_,itr = args
    op,I,R = itr.args
    @assert op ∈ (:(∈),:(in))
    return quote
        for $I ∈ $R
            $ex
        end
    end |> esc
end
# KA-adapted loop macro
macro loopKA(args...)
    ex,_,itr = args
    _,I,R = itr.args; sym = []
    grab!(sym,ex)     # get arguments and replace composites in `ex`
    setdiff!(sym,[I]) # don't want to pass I as an argument
    @gensym kern      # generate unique kernel function name
    return quote
        @kernel function $kern($(rep.(sym)...),@Const(I0)) # replace composite arguments
            $I = @index(Global,Cartesian)
            $I += I0
            $ex
        end
        $kern(get_backend($(sym[1])),64)($(sym...),$R[1]-oneunit($R[1]),ndrange=size($R))
    end |> esc
end
function grab!(sym,ex::Expr)
    ex.head == :. && return union!(sym,[ex])      # grab composite name and return
    start = ex.head==:(call) ? 2 : 1              # don't grab function names
    foreach(a->grab!(sym,a),ex.args[start:end])   # recurse into args
    ex.args[start:end] = rep.(ex.args[start:end]) # replace composites in args
end
grab!(sym,ex::Symbol) = union!(sym,[ex])        # grab symbol name
grab!(sym,ex) = nothing
rep(ex) = ex
rep(ex::Expr) = ex.head == :. ? Symbol(ex.args[2].value) : ex

function divergence!(σ, u)
    for d ∈ 1:ndims(σ)
        @loop σ[I] += ∂(d, I, u) over I ∈ inside(σ)
    end
end
function divergenceKA!(σ, u)
    for d ∈ 1:ndims(σ)
        @loopKA σ[I] += ∂(d, I, u) over I ∈ inside(σ)
    end
end

N = (2^8, 2^8, 2^8)
# CPU serial arrays
σ_serial = zeros(N)
u_serial = rand(N..., length(N))
# CPU multi-threading arrays
σ_CPU = zeros(N)
u_CPU = copy(u_serial)
# GPU arrays
σ_GPU = zeros(N) |> CuArray
u_GPU = copy(u_serial) |> CuArray

# Benchmark warmup (force compilation) and validation
divergence!(σ_serial, u_serial)
divergenceKA!(σ_CPU, u_CPU)
divergenceKA!(σ_GPU, u_GPU)
@assert σ_serial ≈ σ_CPU ≈ σ_GPU |> Array

# Create and run benchmarks
suite = BenchmarkGroup()
suite["serial"] = @benchmarkable divergence!($σ_serial, $u_serial)
suite["CPU"] = @benchmarkable begin
    divergenceKA!($σ_CPU, $u_CPU)
    synchronize(get_backend($σ_CPU))
end
suite["GPU"] = @benchmarkable begin
    divergenceKA!($σ_GPU, $u_GPU)
    synchronize(get_backend($σ_GPU))
end
results = run(suite, verbose=true)