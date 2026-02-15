---
layout: article
title: Porting WaterLily.jl into a backend-agnostic solver
date: 2023-05-07
tags: Julia GPU WaterLily Bernat
cover: /assets/images/research/waterlily-on-gpu/julia_2D.png
author: Bernat
aside:
  toc: true
---

[WaterLily.jl](https://github.com/weymouth/WaterLily.jl) is a simple and fast fluid simulator written in pure Julia. It solves the unsteady incompressible 2D or 3D [Navier-Stokes equations](https://en.wikipedia.org/wiki/Navier%E2%80%93Stokes_equations) on a Cartesian grid.
The pressure Poisson equation is solved with a [geometric multigrid](https://en.wikipedia.org/wiki/Multigrid_method) method.
Solid boundaries are modelled using the [Boundary Data Immersion Method](https://eprints.soton.ac.uk/369635/).

[v1.0](https://github.com/weymouth/WaterLily.jl/releases/tag/v1.0.0) has ported the solver from a serial CPU execution to a backend-agnostic execution including multi-threaded CPU and GPU from different vendors (NVIDIA and AMD) thanks to [KernelAbstractions.jl](https://github.com/JuliaGPU/KernelAbstractions.jl) (KA).
We have also recently published an extended abstract preprint with benchmarking details regarding this port (see [arXiv](https://arxiv.org/abs/2304.08159)).
In this post, we will review our approach to port the code together with the challenges we have faced.

### Introducing KernelAbstractions.jl

The main ingredient of this port is the [`@kernel`](https://juliagpu.gitlab.io/KernelAbstractions.jl/api/#KernelAbstractions.@kernel) macro from KA.
This macro takes a function definition and converts it into a kernel specialised for a given backend. KA can work with CUDA, ROCm, oneAPI, and Metal backends.

As example, consider the divergence operator for a 2D vector field $\vec{u}=(u, v)$.
In the finite-volume method (FVM) and using a Cartesian (uniform) grid with unit cells, this is defined as

$$
\begin{align}
\sigma=\unicode{x2230}(\nabla\cdot\vec{u})\,\mathrm{d}V = \unicode{x222F}\vec{u}\cdot\hat{n}\,\mathrm{d}S\rightarrow \sigma_{i,j} = (u_{i+1,j} - u_{i,j}) + (v_{i,j+1} - v_{i,j}),
\end{align}
$$

where $i$ and $j$ are the indices of the discretised staggered grid:

{:.text-align-center}
![](/assets/images/research/waterlily-on-gpu/divergence.svg#center){:width="40%" class="lightbox-ignore"}

In WaterLily, we define loops based on the `CartesianIndex` such that `I=(i,j,...)`, thus writing an n-dimensional solver in a very straight-forward way.
With this, to compute the divergence of a 2D vector field we can use
```julia
δ(d,::CartesianIndex{D}) where {D} = CartesianIndex(ntuple(j -> j==d ? 1 : 0, D))
@inline ∂(a,I::CartesianIndex{D},u::AbstractArray{T,n}) where {D,T,n} = u[I+δ(a,I),a] - u[I,a]
inside(a) = CartesianIndices(ntuple(i-> 2:size(a)[i]-1, ndims(a)))

N = (10, 10) # domain size
σ = zeros(N) # scalar field
u = rand(N..., length(N)) # 2D vector field with ghost cells

for d ∈ 1:ndims(σ), I ∈ inside(σ)
    σ[I] += ∂(d, I, u)
end
```
where a loop for each dimension `d` and each Cartesian index `I` is used.
The function `δ` provides a Cartesian step in the direction `d`, for example `δ(1, 2)` returns `CartesianIndex(1, 0)` and `δ(2, 3)` returns `CartesianIndex(0, 1, 0)`.
This is used in the derivative function `∂` to implement the divergence equation as described above.
`inside(σ)` provides the `CartesianIndices` of `σ` excluding the ghost elements, *ie.* a range of Cartesian indices starting at `(2, 2)` and ending at `(9, 9)` when `size(σ) == (10, 10)`.

Note that the divergence operation is independent for each `I`, and this is great because it means we can parallelize it!
This is where KA comes into place.
To be able to generate the divergence operator using KA, we need to write the divergence kernel which is just the divergence operator written in KA style.

We define the divergence kernel `_divergence!` and a wrapper `divergence!` as follows
```julia
using KernelAbstractions: get_backend, @index, @kernel

@kernel function _divergence!(σ, u, @Const(I0))
    I = @index(Global, Cartesian)
    I += I0
    σ_sum = zero(eltype(σ))
    for d ∈ 1:ndims(σ)
        σ_sum += ∂(d, I, u)
    end
    σ[I] = σ_sum
end
function divergence!(σ, u)
    R = inside(σ)
    _divergence!(get_backend(σ), 64)(σ, u, R[1]-oneunit(R[1]), ndrange=size(R))
end
```
Note that in the `_divergence!` kernel we operate again using Cartesian indices by calling `@index(Global, Cartesian)` from the KA [`@index`](https://juliagpu.github.io/KernelAbstractions.jl/stable/api/#KernelAbstractions.@index) macro.
The range of Cartesian indices is given by the `ndrange` argument in the wrapper function where we pass the `inside(σ)` Cartesian indices range, and the backend is inferred with the `get_backend` method.
Also note that we pass an additional (constant) argument `I0` which provides the offset index to apply to the indices given by `@index` naturally starting on `(1,1,...)`.
Using a workgroup size of `64` (size of the group of threads acting in parallel, see [terminology](https://juliagpu.github.io/KernelAbstractions.jl/stable/quickstart/#Terminology-1)), KA will parallelize over `I` by multi-threading in CPU or GPU.
In this regard, we just need to change the array type of `σ` and `u` from `Array` (CPU backend) to `CuArray` (NVIDIA GPU backend) or `ROCArray` (AMD GPU backend), and KA will specialise the kernel for the desired backend
```julia
using CUDA: CuArray

N = (10, 10)
σ = zeros(N) |> CuArray
u = rand(N..., length(N)) |> CuArray

divergence!(σ, u)
```

### Automatic loop and kernel generation

As a stencil-based CFD solver, WaterLily heavily uses `for` loops to iterate over the n-dimensional arrays.
To automate the generation of such loops, the macro `@loop` is defined
```julia
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
```
This macro takes an expression such as `@loop <expr> over I ∈ R` where `R` is a `CartesianIndices` range, and produces the loop `for I ∈ R <expr> end`.
For example, the serial divergence operator could now be simply defined using
```julia
for d ∈ 1:ndims(σ)
    @loop σ[I] += ∂(d, I, u) over I ∈ inside(σ)
end
```
which generates the `I ∈ inside(σ)` loop automatically.

Even though this could be seen as small improvement (if any), the nice thing about writing loops using this approach is that the computationally-demanding part of the code can be abstracted out of the main workflow.
For example, it is easy to add performance macros such as `@inbounds` and/or `@fastmath` to each loop by changing the quote block in the `@loop` macro
```julia
macro loop(args...)
    ex,_,itr = args
    op,I,R = itr.args
    @assert op ∈ (:(∈),:(in))
    return quote
        @inbounds for $I ∈ $R
            @fastmath $ex
        end
    end |> esc
end
```
And, even nicer, we can also use this approach to automatically generate KA kernels for every loop in the code!
To do so, we modify `@loop` to generate the KA kernel using `@kernel` and the wrapper function that sets the backend and the workgroup size
```julia
macro loop(args...)
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
```

The helper functions `grab!` and `rep` allow to extract the arguments required by the expression `ex` and the Cartesian index range that will be passed to the kernel.

The code generated by `@loop` and `@kernel` can be explored using `@macroexpand`. For example, for `d=1`
```julia
@macroexpand @loop σ[I] += ∂(1, I, u) over I ∈ inside(σ)
```
we can observe that the code for both CPU and GPU kernels is produced:
<details>
<summary>Generated code</summary>
<pre>
@macroexpand @loopKA σ[I] += ∂(1, I, u) over I ∈ inside(σ)
quote
    begin
        function var"cpu_##kern#339"(__ctx__, σ, u, I0; )
            let I0 = (KernelAbstractions.constify)(I0)
                $(Expr(:aliasscope))
                begin
                    var"##N#341" = length((KernelAbstractions.__workitems_iterspace)(__ctx__))
                    begin
                        for var"##I#340" = (KernelAbstractions.__workitems_iterspace)(__ctx__)
                            (KernelAbstractions.__validindex)(__ctx__, var"##I#340") || continue
                            I = KernelAbstractions.__index_Global_Cartesian(__ctx__, var"##I#340")
                            begin
                                I += I0
                                σ[I] += ∂(1, I, u)
                            end
                        end
                    end
                end
                $(Expr(:popaliasscope))
                return nothing
            end
        end
        function var"gpu_##kern#339"(__ctx__, σ, u, I0; )
            let I0 = (KernelAbstractions.constify)(I0)
                if (KernelAbstractions.__validindex)(__ctx__)
                    begin
                        I = KernelAbstractions.__index_Global_Cartesian(__ctx__)
                        I += I0
                        σ[I] += ∂(1, I, u)
                    end
                end
                return nothing
            end
        end
        begin
            if !($(Expr(:isdefined, Symbol("##kern#339"))))
                begin
                    $(Expr(:meta, :doc))
                    var"##kern#339"(dev) = begin
                            var"##kern#339"(dev, (KernelAbstractions.NDIteration.DynamicSize)(), (KernelAbstractions.NDIteration.DynamicSize)())
                        end
                end
                var"##kern#339"(dev, size) = begin
                        var"##kern#339"(dev, (KernelAbstractions.NDIteration.StaticSize)(size), (KernelAbstractions.NDIteration.DynamicSize)())
                    end
                var"##kern#339"(dev, size, range) = begin
                        var"##kern#339"(dev, (KernelAbstractions.NDIteration.StaticSize)(size), (KernelAbstractions.NDIteration.StaticSize)(range))
                    end
                function var"##kern#339"(dev::Dev, sz::S, range::NDRange) where {Dev, S <: KernelAbstractions.NDIteration._Size, NDRange <: KernelAbstractions.NDIteration._Size}
                    if (KernelAbstractions.isgpu)(dev)
                        return (KernelAbstractions.construct)(dev, sz, range, var"gpu_##kern#339")
                    else
                        return (KernelAbstractions.construct)(dev, sz, range, var"cpu_##kern#339")
                    end
                end
            end
        end
    end
    (var"##kern#339"(get_backend(σ), 64))(σ, u, (inside(σ))[1] - oneunit((inside(σ))[1]), ndrange = size(inside(σ)))
end
</pre></details>

The best feature we achieve when modifying `@loop` to produce KA kernels is that the divergence operator remains the same as before using KA
```julia
for d ∈ 1:ndims(σ)
    @loop σ[I] += ∂(d, I, u) over I ∈ inside(σ)
end
```
This exact approach is what has allowed WaterLily to have the same LOC as before using KA, just around 800!

### Benchmarking

Now that we have all the items in place, we can benchmark the speedup achieved by KA compared to the serial execution using [BenchmarkTools.jl](https://github.com/JuliaCI/BenchmarkTools.jl).
Let's now gather all the code we have used and create a small benchmarking MWE (see below or [download it here]({{ site.url }}/assets/codes/WaterLily_on_GPU.zip)).
In this code showcase, we will refer to the serial CPU execution as "serial", the multi-threaded CPU execution as "CPU", and the GPU execution as "GPU":
```julia
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
```

In this benchmark we have used a 3D array `σ` (scalar field) instead of the 2D array used before, hence demonstrating the n-dimensional capabilities of the current methodology.
For `N=(2^8,2^8,2^8)`, the following benchmark results are achieved on a 6-core laptop equipped with an NVIDIA GeForce GTX 1650 Ti GPU card
```
"CPU" => Trial(52.651 ms)
"GPU" => Trial(7.589 ms)
"serial" => Trial(234.347 ms)
```
The GPU executions yields a **30x** speed-up compared to the serial execution and 7x compared to the multi-threaded CPU execution. The multi-threaded CPU execution yields 4.5x speed-up compared to the serial execution (ideally should be 6x in the 6-core machine).
As a final note on this section, see that `synchronize` is used when running the KA benchmarks. If not used, we would only be measuring the time that it takes to launch a kernel but not to actually run it.

### Challenges

Porting the whole solver to GPU has been mostly a learning exercise.
With no previous experience on software development for GPUs, KA smoothens the learning curve, so it is a great way to get started.
Of course, a lot of stuff does not just work out of the box, and we have faced some challenges while doing the port. Here are some of them.

#### Offset indices in KA kernels
Offset indices are important for boundary-value problems where arrays may contain both the solution and the boundary conditions of a problem.
In the stencil-based finite-volume and finite-difference methods, the boundary elements are only accessed to compute the stencil, but not directly modified when looping through the solution elements of an array.
It is in this scenario where offset indices are important, for example.
KA `@index` macro only provides natural indices in Julia (starting at 1), and this minor missing feature initially derailed us into using [OffsetArrays.jl](https://github.com/JuliaArrays/OffsetArrays.jl).
Of course this added complexity to the code, and we even observed degraded performance in some kernels.
Some time after this (more than we would like to admit), the idea of manually passing the offset index into the KA kernel took shape and quickly yield a much cleaner solution.
Thankfully, this feature will be natively supported in KA in the future (see [KA issue #384](https://github.com/JuliaGPU/KernelAbstractions.jl/issues/384)).

#### To inline functions can be important in GPU kernels
In KA, GPU kernels are of course more sensitive than CPU kernels when it comes to functions that may be called within.
We have observed this sensitivity both at compilation time and at runtime.
For example, the `δ` function was originally implemented with multiple dispatch as
```julia
@inline δ(i,N::Int) = CartesianIndex(ntuple(j -> j==i ? 1 : 0, N))
δ(d,I::CartesianIndex{N}) where {N} = δ(d, N)
```
The main problem here is that this implementation is type-unstable, and without `@inline` the GPU kernel was complaining about a dynamic function (see [KA issue #392](https://github.com/JuliaGPU/KernelAbstractions.jl/issues/392)).
Another inline-related problem can be observed with the derivative function `∂`.
When removing the `@inline` macro from its definition, the GPU performance decays significantly, and the GPU benchmark gets even with the CPU one.
This demonstrates that the compiler can do performant tricks when the information on the required instructions is not nested on external functions to the kernel.

#### Popular functions may not work within kernels
Often we use functions such as the `norm2` from LinearAlgebra.jl to compute the norm of an array.
A surprise is that some of these do not work inside a kernel since the GPU compiler may not be equipped to do so. Hence, these need to be manually written in a suitable form.
In this case, we use `norm2(x) = √sum(abs2,x)`.
Another example is the `sum` function using generator syntax such as
```julia
@kernel function _divergence(σ, u)
    I = @index(Global, Cartesian)
    σ[I] = sum(u[I+δ(d),d]-u[I,d] for d ∈ 1:ndims(σ))
end
```
which errors during compilation for a GPU kernel.
Here a solution can be to use a different form of `sum`
```julia
@kernel function _divergence(σ, u)
    I = @index(Global, Cartesian)
    σ[I] = sum(j -> u[I+δ(j),j]-u[I,j], 1:ndims(σ), init=zero(eltype(σ)))
end
```
even though we have observed reduced performance in the latter version (more information in [Discourse post #96658](https://discourse.julialang.org/t/gpu-sum-closure-throwing-an-error/96658)).
There are efforts in KA directed towards providing a reduction interface for kernels (see [KA issue #234](https://github.com/JuliaGPU/KernelAbstractions.jl/issues/234)).

#### Limitations of the automatic kernel generation on loops
While the `@loop` macro that generates KA kernels is fairly general, it also has some limitations.
For example, it may have been noticed that we have not nested the loop over the dimensions `d ∈ 1:ndims(σ)` in the kernel.
The reason behind this is that even if turning
```julia
for d ∈ 1:ndims(σ)
    @loop σ[I] += ∂(d, I, u) over I ∈ inside(σ)
end
```
into
```julia
@loop σ[I] = sum(d->∂(d, I, u), 1:ndims(σ)) over I ∈ inside(σ)
```
would reduce the number of kernel evaluations, the limitation of the `sum` function mentioned before makes this approach not as performant as writing a kernel for each dimension.
Also related to this issue is the fact that passing more than one expression per kernel would reduce the overall number of kernel evaluations, but gluing expressions together can be not straight-forward with the current implementation of `@loop`.

#### Care for race conditions!
When moving from serial to parallel computations, race conditions are a recurring issue.
For WaterLily, this issue popped up for the linear solver used in the pressure Poisson equation.
Prior to the port, WaterLily relied on Successive Over Relaxation (SOR) method (a Gauss-Seidel-type solver) which uses (ordered) backsubstitution, hence not suitable for parallel executions.
The solution here was just to switch to a better suited solver such as the Conjugate-Gradient method.


### Acknowledgements

Special thanks to [Valentin Churavy](https://vchuravy.dev/) for creating [KernelAbstractions.jl](https://github.com/JuliaGPU/KernelAbstractions.jl) and revising this article. And, of course, [Gabriel D. Weymouth](https://weymouth.github.io/) for creating [WaterLily.jl](https://github.com/weymouth/WaterLily.jl) and for helping in the revising of this article too! :)
