using Pluto

notebooks = isempty(ARGS) ? sort(filter(f -> endswith(f, ".jl") && startswith(read(f, String), "### A Pluto.jl notebook ###"), readdir(pwd()))) : ARGS
isempty(notebooks) && error("No notebooks provided or discovered")

session = Pluto.ServerSession()
session.options.server.disable_writing_notebook_files = true
session.options.server.auto_reload_from_file = false

failed = String[]

function cell_label(cell)
    try
        string(Pluto.cell_id(cell))
    catch
        string(getfield(cell, :cell_id))
    end
end

for nb_path in notebooks
    println("::group::Run $(nb_path)")
    notebook = nothing
    try
        # Use Pluto's regular notebook-opening path and wait for the reactive run
        # to finish. This is close to how headless Pluto tooling such as
        # PlutoSliderServer opens notebooks, but without generating exports.
        notebook = Pluto.SessionActions.open(session, abspath(nb_path); run_async=false)
        errored = filter(cell -> cell.errored, notebook.cells)
        if isempty(errored)
            println("✅ $(nb_path) ran without Pluto cell errors")
        else
            println("❌ $(nb_path) has $(length(errored)) errored cell(s)")
            for cell in errored
                println("--- errored cell $(cell_label(cell)) ---")
                println(cell.code)
                try
                    show(stdout, MIME("text/plain"), cell.output)
                    println()
                catch err
                    println("Could not show cell output: ", err)
                end
            end
            push!(failed, nb_path)
        end
    catch err
        println("❌ $(nb_path) failed while loading/running")
        showerror(stdout, err, catch_backtrace())
        println()
        push!(failed, nb_path)
    finally
        if notebook !== nothing
            try
                Pluto.SessionActions.shutdown(session, notebook; keep_in_session=false, async=false, verbose=false)
            catch err
                @warn "Could not shut down Pluto notebook" notebook=nb_path exception=(err, catch_backtrace())
            end
        end
        println("::endgroup::")
    end
end

if !isempty(failed)
    println("Failing notebooks:")
    foreach(nb -> println("- ", nb), failed)
    exit(1)
end

println("All notebooks ran successfully.")
