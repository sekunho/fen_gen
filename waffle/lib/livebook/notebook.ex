defmodule Livebook.Notebook do
  @moduledoc false

  # Data structure representing a notebook.
  #
  # A notebook is just the representation and roughly
  # maps to a file that the user can edit.
  # A notebook *session* is a living process that holds a specific
  # notebook instance and allows users to collaboratively apply
  # changes to this notebook.
  #
  # A notebook is divided into a set of isolated *sections*.

  defstruct [:name, :version, :sections, :metadata]

  alias Livebook.Notebook.{Section, Cell}

  @type metadata :: %{String.t() => term()}

  @type t :: %__MODULE__{
          name: String.t(),
          version: String.t(),
          sections: list(Section.t()),
          metadata: metadata()
        }

  @version "1.0"

  @doc """
  Returns a blank notebook.
  """
  @spec new() :: t()
  def new() do
    %__MODULE__{
      name: "Untitled notebook",
      version: @version,
      sections: [],
      metadata: %{}
    }
  end

  @doc """
  Finds notebook section by id.
  """
  @spec fetch_section(t(), Section.id()) :: {:ok, Section.t()} | :error
  def fetch_section(notebook, section_id) do
    Enum.find_value(notebook.sections, :error, fn section ->
      section.id == section_id && {:ok, section}
    end)
  end

  @doc """
  Finds notebook cell by `id` and the corresponding section.
  """
  @spec fetch_cell_and_section(t(), Cell.id()) :: {:ok, Cell.t(), Section.t()} | :error
  def fetch_cell_and_section(notebook, cell_id) do
    for(
      section <- notebook.sections,
      cell <- section.cells,
      cell.id == cell_id,
      do: {cell, section}
    )
    |> case do
      [{cell, section}] -> {:ok, cell, section}
      [] -> :error
    end
  end

  @doc """
  Finds a cell being `offset` from the given cell (with regard to all sections).
  """
  @spec fetch_cell_sibling(t(), Cell.id(), integer()) :: {:ok, Cell.t()} | :error
  def fetch_cell_sibling(notebook, cell_id, offset) do
    all_cells = for(section <- notebook.sections, cell <- section.cells, do: cell)

    with idx when idx != nil <- Enum.find_index(all_cells, &(&1.id == cell_id)),
         sibling_idx <- idx + offset,
         true <- 0 <= sibling_idx and sibling_idx < length(all_cells) do
      {:ok, Enum.at(all_cells, sibling_idx)}
    else
      _ -> :error
    end
  end

  @doc """
  Inserts `section` at the given `index`.
  """
  @spec insert_section(t(), integer(), Section.t()) :: t()
  def insert_section(notebook, index, section) do
    sections = List.insert_at(notebook.sections, index, section)

    %{notebook | sections: sections}
  end

  @doc """
  Inserts `cell` at the given `index` within section identified by `section_id`.
  """
  @spec insert_cell(t(), Section.id(), integer(), Cell.t()) :: t()
  def insert_cell(notebook, section_id, index, cell) do
    sections =
      Enum.map(notebook.sections, fn section ->
        if section.id == section_id do
          %{section | cells: List.insert_at(section.cells, index, cell)}
        else
          section
        end
      end)

    %{notebook | sections: sections}
  end

  @doc """
  Deletes section with the given id.
  """
  @spec delete_section(t(), Section.id()) :: t()
  def delete_section(notebook, section_id) do
    sections = Enum.reject(notebook.sections, &(&1.id == section_id))

    %{notebook | sections: sections}
  end

  @doc """
  Deletes cell with the given id.
  """
  @spec delete_cell(t(), Cell.id()) :: t()
  def delete_cell(notebook, cell_id) do
    sections =
      Enum.map(notebook.sections, fn section ->
        %{section | cells: Enum.reject(section.cells, &(&1.id == cell_id))}
      end)

    %{notebook | sections: sections}
  end

  @doc """
  Updates cell with the given function.
  """
  @spec update_cell(t(), Cell.id(), (Cell.t() -> Cell.t())) :: t()
  def update_cell(notebook, cell_id, fun) do
    sections =
      Enum.map(notebook.sections, fn section ->
        cells =
          Enum.map(section.cells, fn cell ->
            if cell.id == cell_id, do: fun.(cell), else: cell
          end)

        %{section | cells: cells}
      end)

    %{notebook | sections: sections}
  end

  @doc """
  Updates section with the given function.
  """
  @spec update_section(t(), Section.id(), (Section.t() -> Section.t())) :: t()
  def update_section(notebook, section_id, fun) do
    sections =
      Enum.map(notebook.sections, fn section ->
        if section.id == section_id, do: fun.(section), else: section
      end)

    %{notebook | sections: sections}
  end

  @doc """
  Moves cell by the given offset.

  The cell may move to another section if the offset indicates so.
  """
  @spec move_cell(t(), Cell.id(), integer()) :: t()
  def move_cell(notebook, cell_id, offset) do
    # We firstly create a flat list of cells interspersed with `:separator`
    # at section boundaries. Then we move the given cell by the given offset.
    # Finally we split the flat list back into cell lists
    # and put them in the corresponding sections.

    separated_cells =
      notebook.sections
      |> Enum.map_intersperse(:separator, & &1.cells)
      |> List.flatten()

    idx =
      Enum.find_index(separated_cells, fn
        :separator -> false
        cell -> cell.id == cell_id
      end)

    new_idx = (idx + offset) |> clamp_index(separated_cells)

    {cell, separated_cells} = List.pop_at(separated_cells, idx)
    separated_cells = List.insert_at(separated_cells, new_idx, cell)

    cell_groups = group_cells(separated_cells)

    sections =
      notebook.sections
      |> Enum.zip(cell_groups)
      |> Enum.map(fn {section, cells} -> %{section | cells: cells} end)

    %{notebook | sections: sections}
  end

  defp group_cells(separated_cells) do
    separated_cells
    |> Enum.reverse()
    |> do_group_cells([])
  end

  defp do_group_cells([], groups), do: groups

  defp do_group_cells([:separator | separated_cells], []) do
    do_group_cells(separated_cells, [[], []])
  end

  defp do_group_cells([:separator | separated_cells], groups) do
    do_group_cells(separated_cells, [[] | groups])
  end

  defp do_group_cells([cell | separated_cells], []) do
    do_group_cells(separated_cells, [[cell]])
  end

  defp do_group_cells([cell | separated_cells], [group | groups]) do
    do_group_cells(separated_cells, [[cell | group] | groups])
  end

  defp clamp_index(index, list) do
    index |> max(0) |> min(length(list) - 1)
  end

  @doc """
  Moves section by the given offset.
  """
  @spec move_section(t(), Section.id(), integer()) :: t()
  def move_section(notebook, section_id, offset) do
    # We first find the index of the given section.
    # Then we find its' new index from given offset.
    # Finally, we move the section, and return the new notebook.

    idx =
      Enum.find_index(notebook.sections, fn
        section -> section.id == section_id
      end)

    new_idx = (idx + offset) |> clamp_index(notebook.sections)

    {section, sections} = List.pop_at(notebook.sections, idx)
    sections = List.insert_at(sections, new_idx, section)

    %{notebook | sections: sections}
  end

  @doc """
  Returns a list of `{cell, section}` pairs including all Elixir cells in order.
  """
  @spec elixir_cells_with_section(t()) :: list({Cell.t(), Section.t()})
  def elixir_cells_with_section(notebook) do
    for section <- notebook.sections,
        cell <- section.cells,
        cell.type == :elixir,
        do: {cell, section}
  end

  @doc """
  Returns a list of Elixir cells (each with section) that the given cell depends on.

  The cells are ordered starting from the most direct parent.
  """
  @spec parent_cells_with_section(t(), Cell.id()) :: list({Cell.t(), Section.t()})
  def parent_cells_with_section(notebook, cell_id) do
    notebook
    |> elixir_cells_with_section()
    |> Enum.take_while(fn {cell, _} -> cell.id != cell_id end)
    |> Enum.reverse()
  end

  @doc """
  Returns a list of Elixir cells (each with section) that depend on the given cell.

  The cells are ordered starting from the most direct child.
  """
  @spec child_cells_with_section(t(), Cell.id()) :: list({Cell.t(), Section.t()})
  def child_cells_with_section(notebook, cell_id) do
    notebook
    |> elixir_cells_with_section()
    |> Enum.drop_while(fn {cell, _} -> cell.id != cell_id end)
    |> Enum.drop(1)
  end

  @doc """
  Returns a forked version of the given notebook.
  """
  @spec forked(t()) :: t()
  def forked(notebook) do
    %{notebook | name: notebook.name <> " - fork"}
  end
end
