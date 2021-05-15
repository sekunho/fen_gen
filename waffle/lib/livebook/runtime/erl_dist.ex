defmodule Livebook.Runtime.ErlDist do
  @moduledoc false

  # This module allows for initializing nodes connected using
  # Erlang Distribution with modules and processes necessary for evaluation.
  #
  # To ensure proper isolation between sessions,
  # code evaluation may take place in a separate Elixir runtime,
  # which also makes it easy to terminate the whole
  # evaluation environment without stopping Livebook.
  # This is what both `Runtime.ElixirStandalone` and `Runtime.Attached` do
  # and this module contains the shared functionality they need.
  #
  # To work with a separate node, we have to inject the necessary
  # Livebook modules there and also start the relevant processes
  # related to evaluation. Fortunately Erlang allows us to send modules
  # binary representation to the other node and load them dynamically.

  # Modules to load into the connected node.
  @required_modules [
    Livebook.Evaluator,
    Livebook.Evaluator.IOProxy,
    Livebook.Evaluator.StringFormatter,
    Livebook.Completion,
    Livebook.Runtime.ErlDist,
    Livebook.Runtime.ErlDist.Manager,
    Livebook.Runtime.ErlDist.EvaluatorSupervisor,
    Livebook.Runtime.ErlDist.IOForwardGL
  ]

  @doc """
  Loads the necessary modules into the given node
  and starts the primary Livebook remote process.

  The initialization may be invoked only once on the given
  node until its disconnected.
  """
  @spec initialize(node()) :: :ok | {:error, :already_in_use}
  def initialize(node) do
    if initialized?(node) do
      {:error, :already_in_use}
    else
      load_required_modules(node)
      start_manager(node)

      :ok
    end
  end

  defp load_required_modules(node) do
    for module <- @required_modules do
      {_module, binary, filename} = :code.get_object_code(module)
      {:module, _} = :rpc.call(node, :code, :load_binary, [module, filename, binary])
    end
  end

  defp start_manager(node) do
    :rpc.call(node, Livebook.Runtime.ErlDist.Manager, :start, [])
  end

  defp initialized?(node) do
    case :rpc.call(node, Process, :whereis, [Livebook.Runtime.ErlDist.Manager]) do
      nil -> false
      _pid -> true
    end
  end

  @doc """
  Unloads the previously loaded Livebook modules from the caller node.
  """
  def unload_required_modules() do
    for module <- @required_modules do
      # If we attached, detached and attached again, there may still
      # be deleted module code, so purge it first.
      :code.purge(module)
      :code.delete(module)
    end
  end
end
