using Pluto
import Pluto: ServerSession, WorkspaceManager, load_notebook_nobackup, update_run!

notebooks = isempty(ARGS) ? sort(filter(f -> endswith(f, ".jl") && startswith(read(f, String), "### A Pluto.jl notebook ###"), readdir(pwd()))) : ARGS
isempty(notebooks) && error("No notebooks provided or discovered")

session = ServerSession()
session.options.server.disable_writing_notebook_files = true

# Keep Pluto's default workspace isolation. Running notebooks in a separate
# workspace is closer to real Pluto usage and avoids cross-notebook package-state
# contamination.

failed = String[]

function cell_label(cell)
    id = try
        Pluto.cell_id(cell)
    catch
        getfield(cell, :cell_id)
    end
    string(id)
end

for nb_path in notebooks
    println("::group::Run $(nb_path)")
    notebook = nothing
    try
        notebook = load_notebook_nobackup(nb_path)
        notebook.path = abspath(nb_path)
        update_run!(session, notebook, notebook.cells; save=false)
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
                WorkspaceManager.unmake_workspace((session, notebook); verbose=false)
            catch err
                @warn "Could not clean Pluto workspace" notebook=nb_path exception=(err, catch_backtrace())
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
