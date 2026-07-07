using TOML

notebooks = isempty(ARGS) ? sort(filter(f -> endswith(f, ".jl") && startswith(read(f, String), "### A Pluto.jl notebook ###"), readdir(pwd()))) : ARGS
isempty(notebooks) && error("No notebooks provided or discovered")

const MIN_RUST_TOOLCHAIN = v"0.1.8"

function extract_block(text, var)
    m = match(Regex(var * " = \"\"\"\n(.*?)\n\"\"\"", "s"), text)
    m === nothing && error("missing $var")
    return m.captures[1] * "\n"
end

function first_dep(manifest, name)
    deps = get(manifest, "deps", Dict{String,Any}())
    haskey(deps, name) || error("manifest missing dependency $name")
    entries = deps[name]
    isempty(entries) && error("manifest dependency $name has no entries")
    return entries[1]
end

for nb in notebooks
    text = read(nb, String)
    project = TOML.parse(extract_block(text, "PLUTO_PROJECT_TOML_CONTENTS"))
    manifest = TOML.parse(extract_block(text, "PLUTO_MANIFEST_TOML_CONTENTS"))

    sources = get(project, "sources", Dict{String,Any}())
    tensor_source = get(sources, "Tensor4all", nothing)
    tensor_source isa Dict || error("$nb: Tensor4all is not declared in [sources]")
    get(tensor_source, "rev", nothing) == "main" || error("$nb: Tensor4all source is not rev=main")

    rust = first_dep(manifest, "RustToolChain")
    rust_version = VersionNumber(rust["version"])
    rust_version >= MIN_RUST_TOOLCHAIN || error("$nb: RustToolChain $rust_version < $MIN_RUST_TOOLCHAIN")

    tensor = first_dep(manifest, "Tensor4all")
    get(tensor, "repo-rev", nothing) == "main" || error("$nb: Tensor4all manifest is not repo-rev=main")

    println("✅ $nb: RustToolChain=$rust_version Tensor4all=$(get(tensor, "repo-rev", "?"))@$(get(tensor, "git-tree-sha1", "?")[1:12])")
end
