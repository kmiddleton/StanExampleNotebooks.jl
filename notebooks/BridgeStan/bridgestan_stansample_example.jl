### A Pluto.jl notebook ###
# v0.19.25

using Markdown
using InteractiveUtils

# ╔═╡ eedbb8c6-2e87-4712-a9ce-cad9382d06a1
begin
    using BridgeStan
	using StanSample
	using DataFrames
end

# ╔═╡ fad8949e-4e14-44f3-bd52-8e4e4fb99bc2
md" ## BridgeStan example notebook."

# ╔═╡ 6a5a6122-08d1-44da-8881-48b23450dc83
html"""
<style>
	main {
		margin: 0 auto;
		max-width: 3000px;
    	padding-left: max(1px, 5%);
    	padding-right: max(160px, 38%);
	}
</style>
"""

# ╔═╡ abe21911-c908-4a35-88b0-b4646a74c63e
md" ##### Run the Stan Language program"

# ╔═╡ 0fc6fa0d-268a-4b0e-b1eb-4b228761c96b
bernoulli = "
data { 
  int<lower=1> N; 
  int<lower=0,upper=1> y[N];
} 
parameters {
  real<lower=0,upper=1> theta;
} 
model {
  theta ~ beta(1,1);
  y ~ bernoulli(theta);
}
";

# ╔═╡ a976cf4b-6f49-4141-a56a-132f358fb4c4
data = Dict("N" => 10, "y" => [0, 1, 0, 1, 0, 0, 0, 0, 0, 1])

# ╔═╡ 7c2c46d0-b61e-41ca-8ba4-8fe31640d41e
begin
	sm = SampleModel("bernoulli", bernoulli)
	rc = stan_sample(sm; data, save_warmup=true)
end;

# ╔═╡ 0d7465c2-71d5-47d8-af54-2e73b2a30236
get_bridgestan_path()

# ╔═╡ fb80c073-4821-4056-ac25-c1256234c08d
haskey(ENV, "BRIDGESTAN") ? ENV["BRIDGESTAN"] : ""

# ╔═╡ acccac71-e62d-4a1d-8fb4-ebb379ee572d
chain_dict = available_chains(sm)

# ╔═╡ 77321ebd-fe28-4e97-a81f-c59d9906f096
md" ##### Create the BridgeStan model library"

# ╔═╡ b3d88396-fcb9-44ed-8e6a-16030c9d4f36
begin
	chain_id = 2
	smb = BridgeStan.StanModel(;
		stan_file = joinpath(pwd(), "bernoulli.stan"),
	    stanc_args=["--warn-pedantic --O1"],
    	make_args=["CXX=clang++", "STAN_THREADS=true"],
		data = joinpath(pwd(), "bernoulli_data_$(chain_id).json"),
        seed = 204
    )
end;

# ╔═╡ 28f3e693-fbe0-4cc1-af2c-65e3b6cef254
pwd()

# ╔═╡ 0f43e4c5-6c4b-4a2b-bcf3-fee8862b28fd
md" ###### Model name:"

# ╔═╡ 4023e439-8af1-46e7-b484-24544c7dda8f
BridgeStan.name(smb)

# ╔═╡ 04f05b74-9b3e-4c49-b752-e6260eac1096
md" ###### Number of model parameters:"

# ╔═╡ 76dc6325-54a6-4fbd-bf67-80b738f49d4f
BridgeStan.param_num(smb)

# ╔═╡ 924c7420-9bef-4a30-b36c-e647e90c5a56
md" ###### Compute log_density and gradient at a random observation"

# ╔═╡ 6d31bc0d-321a-42d1-b851-dc6aed4aa6eb
let
	x = rand(BridgeStan.param_unc_num(smb))
	q = @. log(x / (1 - x)); # unconstrained scale
	ld, grad = BridgeStan.log_density_gradient(smb, q, jacobian = false)
	(log_density=ld, gradient=grad)
end

# ╔═╡ b24643c0-262d-4c96-b07a-b5196ce5c60a
md" ###### Or a range of densities"

# ╔═╡ ce23ee24-d13b-4e79-9dfb-9dcdd6b8f599
if typeof(smb) == BridgeStan.StanModel
    x = rand(BridgeStan.param_unc_num(smb))
    q = @. log(x / (1 - x))        # unconstrained scale

    function sim(smb::BridgeStan.StanModel, x=LinRange(0.1, 0.9, 100))
        q = zeros(length(x))
        ld = zeros(length(x))
        g = Vector{Vector{Float64}}(undef, length(x))
        for (i, p) in enumerate(x)
            q[i] = @. log(p / (1 - p)) # unconstrained scale
            ld[i], g[i] = BridgeStan.log_density_gradient(smb, q[i:i],
                jacobian = 0)
        end
        return DataFrame(x=x, q=q, log_density=ld, gradient=g)
    end

  sim(smb)
end

# ╔═╡ e5fd63fd-f08e-46a8-94dc-9edf59ed9929
md" ###### Check the BridgeStan model library has been created in the tmpdir"

# ╔═╡ 0554224d-f04c-4cfb-825f-38974792f7c8
readdir(sm.tmpdir)

# ╔═╡ ab7e3867-a6d6-4be5-a64a-7b974964e391
smb

# ╔═╡ Cell order:
# ╟─fad8949e-4e14-44f3-bd52-8e4e4fb99bc2
# ╠═6a5a6122-08d1-44da-8881-48b23450dc83
# ╠═eedbb8c6-2e87-4712-a9ce-cad9382d06a1
# ╟─abe21911-c908-4a35-88b0-b4646a74c63e
# ╠═0fc6fa0d-268a-4b0e-b1eb-4b228761c96b
# ╠═a976cf4b-6f49-4141-a56a-132f358fb4c4
# ╠═7c2c46d0-b61e-41ca-8ba4-8fe31640d41e
# ╠═0d7465c2-71d5-47d8-af54-2e73b2a30236
# ╠═fb80c073-4821-4056-ac25-c1256234c08d
# ╠═acccac71-e62d-4a1d-8fb4-ebb379ee572d
# ╟─77321ebd-fe28-4e97-a81f-c59d9906f096
# ╠═b3d88396-fcb9-44ed-8e6a-16030c9d4f36
# ╠═28f3e693-fbe0-4cc1-af2c-65e3b6cef254
# ╟─0f43e4c5-6c4b-4a2b-bcf3-fee8862b28fd
# ╠═4023e439-8af1-46e7-b484-24544c7dda8f
# ╟─04f05b74-9b3e-4c49-b752-e6260eac1096
# ╠═76dc6325-54a6-4fbd-bf67-80b738f49d4f
# ╟─924c7420-9bef-4a30-b36c-e647e90c5a56
# ╠═6d31bc0d-321a-42d1-b851-dc6aed4aa6eb
# ╟─b24643c0-262d-4c96-b07a-b5196ce5c60a
# ╠═ce23ee24-d13b-4e79-9dfb-9dcdd6b8f599
# ╟─e5fd63fd-f08e-46a8-94dc-9edf59ed9929
# ╠═0554224d-f04c-4cfb-825f-38974792f7c8
# ╠═ab7e3867-a6d6-4be5-a64a-7b974964e391
