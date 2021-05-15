defmodule Livebook.LiveMarkdown.MarkdownHelpers do
  @doc """
  Reformats the given markdown document.
  """
  @spec reformat(String.t()) :: String.t()
  def reformat(markdown) do
    markdown
    |> EarmarkParser.as_ast()
    |> elem(1)
    |> markdown_from_ast()
  end

  @doc """
  Extracts plain text from the given AST ignoring all the tags.
  """
  @spec text_from_ast(EarmarkParser.ast()) :: String.t()
  def text_from_ast(ast)

  def text_from_ast(ast) when is_list(ast) do
    ast
    |> Enum.map(&text_from_ast/1)
    |> Enum.join("")
  end

  def text_from_ast(ast) when is_binary(ast), do: ast
  def text_from_ast({_, _, ast, _}), do: text_from_ast(ast)

  @doc """
  Renders Markdown string from the given `EarmarkParser` AST.
  """
  @spec markdown_from_ast(EarmarkParser.ast()) :: String.t()
  def markdown_from_ast(ast) do
    build_md([], ast)
    |> IO.iodata_to_binary()
    |> String.trim()
  end

  defp build_md(iodata, ast)

  defp build_md(iodata, []), do: iodata

  defp build_md(iodata, [string | ast]) when is_binary(string) do
    string
    |> append_inline(iodata)
    |> build_md(ast)
  end

  defp build_md(iodata, [{tag, attrs, lines, %{verbatim: true}} | ast]) do
    render_html(tag, attrs, lines)
    |> append_block(iodata)
    |> build_md(ast)
  end

  defp build_md(iodata, [{"em", _, content, %{}} | ast]) do
    render_emphasis(content)
    |> append_inline(iodata)
    |> build_md(ast)
  end

  defp build_md(iodata, [{"strong", _, content, %{}} | ast]) do
    render_strong(content)
    |> append_inline(iodata)
    |> build_md(ast)
  end

  defp build_md(iodata, [{"del", _, content, %{}} | ast]) do
    render_strikethrough(content)
    |> append_inline(iodata)
    |> build_md(ast)
  end

  defp build_md(iodata, [{"code", _, content, %{}} | ast]) do
    render_code_inline(content)
    |> append_inline(iodata)
    |> build_md(ast)
  end

  defp build_md(iodata, [{"a", attrs, content, %{}} | ast]) do
    render_link(content, attrs)
    |> append_inline(iodata)
    |> build_md(ast)
  end

  defp build_md(iodata, [{"img", attrs, [], %{}} | ast]) do
    render_image(attrs)
    |> append_inline(iodata)
    |> build_md(ast)
  end

  defp build_md(iodata, [{:comment, _, lines, %{comment: true}} | ast]) do
    render_comment(lines)
    |> append_block(iodata)
    |> build_md(ast)
  end

  defp build_md(iodata, [{"hr", attrs, [], %{}} | ast]) do
    render_ruler(attrs)
    |> append_block(iodata)
    |> build_md(ast)
  end

  defp build_md(iodata, [{"br", _, [], %{}} | ast]) do
    render_line_break()
    |> append_inline(iodata)
    |> build_md(ast)
  end

  defp build_md(iodata, [{"p", _, content, %{}} | ast]) do
    render_paragraph(content)
    |> append_block(iodata)
    |> build_md(ast)
  end

  defp build_md(iodata, [{"h" <> n, _, content, %{}} | ast])
       when n in ["1", "2", "3", "4", "5", "6"] do
    n = String.to_integer(n)

    render_heading(n, content)
    |> append_block(iodata)
    |> build_md(ast)
  end

  defp build_md(iodata, [{"pre", _, [{"code", attrs, [content], %{}}], %{}} | ast]) do
    render_code_block(content, attrs)
    |> append_block(iodata)
    |> build_md(ast)
  end

  defp build_md(iodata, [{"blockquote", [], content, %{}} | ast]) do
    render_blockquote(content)
    |> append_block(iodata)
    |> build_md(ast)
  end

  defp build_md(iodata, [{"table", _, content, %{}} | ast]) do
    render_table(content)
    |> append_block(iodata)
    |> build_md(ast)
  end

  defp build_md(iodata, [{"ul", _, content, %{}} | ast]) do
    render_unordered_list(content)
    |> append_block(iodata)
    |> build_md(ast)
  end

  defp build_md(iodata, [{"ol", _, content, %{}} | ast]) do
    render_ordered_list(content)
    |> append_block(iodata)
    |> build_md(ast)
  end

  defp append_inline(md, iodata), do: [iodata, md]
  defp append_block(md, iodata), do: [iodata, "\n", md, "\n"]

  # Renderers

  # https://www.w3.org/TR/2011/WD-html-markup-20110113/syntax.html#void-element
  @void_elements ~W(area base br col command embed hr img input keygen link meta param source track wbr)

  defp render_html(tag, attrs, []) when tag in @void_elements do
    "<#{tag} #{attrs_to_string(attrs)} />"
  end

  defp render_html(tag, attrs, lines) do
    inner = Enum.join(lines, "\n")
    "<#{tag} #{attrs_to_string(attrs)}>\n#{inner}\n</#{tag}>"
  end

  defp render_emphasis(content) do
    inner = markdown_from_ast(content)
    "*#{inner}*"
  end

  defp render_strong(content) do
    inner = markdown_from_ast(content)
    "**#{inner}**"
  end

  defp render_strikethrough(content) do
    inner = markdown_from_ast(content)
    "~~#{inner}~~"
  end

  defp render_code_inline(content) do
    inner = markdown_from_ast(content)
    "`#{inner}`"
  end

  defp render_link(content, attrs) do
    caption = markdown_from_ast(content)
    href = get_attr(attrs, "href", "")
    "[#{caption}](#{href})"
  end

  defp render_image(attrs) do
    alt = get_attr(attrs, "alt", "")
    src = get_attr(attrs, "src", "")
    title = get_attr(attrs, "title", "")

    if title == "" do
      "![#{alt}](#{src})"
    else
      ~s/![#{alt}](#{src} "#{title}")/
    end
  end

  defp render_comment([line]) do
    line = String.trim(line)
    "<!-- #{line} -->"
  end

  defp render_comment(lines) do
    lines =
      lines
      |> Enum.drop_while(&blank?/1)
      |> Enum.reverse()
      |> Enum.drop_while(&blank?/1)
      |> Enum.reverse()

    Enum.join(["<!--" | lines] ++ ["-->"], "\n")
  end

  defp render_ruler(attrs) do
    class = get_attr(attrs, "class", "thin")

    case class do
      "thin" -> "---"
      "medium" -> "___"
      "thick" -> "***"
    end
  end

  defp render_line_break(), do: "\\\n"

  defp render_paragraph(content), do: markdown_from_ast(content)

  defp render_heading(n, content) do
    title = markdown_from_ast(content)
    String.duplicate("#", n) <> " " <> title
  end

  defp render_code_block(content, attrs) do
    language = get_attr(attrs, "class", "")
    "```#{language}\n#{content}\n```"
  end

  defp render_blockquote(content) do
    inner = markdown_from_ast(content)

    inner
    |> String.split("\n")
    |> Enum.map(&("> " <> &1))
    |> Enum.join("\n")
  end

  defp render_table([{"thead", _, [head_row], %{}}, {"tbody", _, body_rows, %{}}]) do
    alignments = alignments_from_row(head_row)
    cell_grid = cell_grid_from_rows([head_row | body_rows])
    column_widths = max_length_per_column(cell_grid)
    [head_cells | body_cell_grid] = Enum.map(cell_grid, &pad_whitespace(&1, column_widths))
    separator_cells = build_separator_cells(alignments, column_widths)
    cell_grid_to_md_table([head_cells, separator_cells | body_cell_grid])
  end

  defp render_table([{"tbody", _, body_rows, %{}}]) do
    cell_grid = cell_grid_from_rows(body_rows)
    column_widths = max_length_per_column(cell_grid)
    cell_grid = Enum.map(cell_grid, &pad_whitespace(&1, column_widths))
    cell_grid_to_md_table(cell_grid)
  end

  defp cell_grid_from_rows(rows) do
    Enum.map(rows, fn {"tr", _, columns, %{}} ->
      Enum.map(columns, fn {tag, _, content, %{}} when tag in ["th", "td"] ->
        markdown_from_ast(content)
      end)
    end)
  end

  defp alignments_from_row({"tr", _, columns, %{}}) do
    Enum.map(columns, fn {tag, attrs, _, %{}} when tag in ["th", "td"] ->
      style = get_attr(attrs, "style", nil)

      case style do
        "text-align: left;" -> :left
        "text-align: center;" -> :center
        "text-align: right;" -> :right
      end
    end)
  end

  defp build_separator_cells(alignments, widths) do
    alignments
    |> Enum.zip(widths)
    |> Enum.map(fn
      {:left, length} -> String.duplicate("-", length)
      {:center, length} -> ":" <> String.duplicate("-", length - 2) <> ":"
      {:right, length} -> String.duplicate("-", length - 1) <> ":"
    end)
  end

  defp max_length_per_column(cell_grid) do
    cell_grid
    |> List.zip()
    |> Enum.map(&Tuple.to_list/1)
    |> Enum.map(fn cells ->
      cells
      |> Enum.map(&String.length/1)
      |> Enum.max()
    end)
  end

  defp pad_whitespace(cells, widths) do
    cells
    |> Enum.zip(widths)
    |> Enum.map(fn {cell, width} ->
      String.pad_trailing(cell, width, " ")
    end)
  end

  defp cell_grid_to_md_table(cell_grid) do
    cell_grid
    |> Enum.map(fn cells ->
      "| " <> Enum.join(cells, " | ") <> " |"
    end)
    |> Enum.join("\n")
  end

  defp render_unordered_list(content) do
    marker_fun = fn _index -> "* " end
    render_list(content, marker_fun, "  ")
  end

  defp render_ordered_list(content) do
    marker_fun = fn index -> "#{index + 1}. " end
    render_list(content, marker_fun, "   ")
  end

  defp render_list(items, marker_fun, indent) do
    spaced? = spaced_list_items?(items)
    item_separator = if(spaced?, do: "\n\n", else: "\n")

    items
    |> Enum.map(fn {"li", _, content, %{}} -> markdown_from_ast(content) end)
    |> Enum.with_index()
    |> Enum.map(fn {inner, index} ->
      [first_line | lines] = String.split(inner, "\n")

      first_line = marker_fun.(index) <> first_line

      lines =
        Enum.map(lines, fn
          "" -> ""
          line -> indent <> line
        end)

      Enum.join([first_line | lines], "\n")
    end)
    |> Enum.join(item_separator)
  end

  defp spaced_list_items?([{"li", _, [{"p", _, _content, %{}} | _], %{}} | _items]), do: true
  defp spaced_list_items?([_ | items]), do: spaced_list_items?(items)
  defp spaced_list_items?([]), do: false

  # Helpers

  defp get_attr(attrs, key, default) do
    Enum.find_value(attrs, default, fn {attr_key, attr_value} ->
      attr_key == key && attr_value
    end)
  end

  defp attrs_to_string(attrs) do
    attrs
    |> Enum.map(fn {key, value} -> ~s/#{key}="#{value}"/ end)
    |> Enum.join(" ")
  end

  defp blank?(string), do: String.trim(string) == ""
end
