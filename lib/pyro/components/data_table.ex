defmodule Pyro.Components.DataTable do
  use Pyro.Component

  import Pyro.Components.Core

  @doc """
  A complex data table component, featuring streams, multi-column sorting, etc.

  It is a functional component, so all emitted events are to be handled by the parent LiveView.
  """
  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :id, :string, required: true
  attr :class, :css_classes, overridable: true, required: true

  attr :row_id, :any,
    default: nil,
    doc: "the function for generating the row id"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  attr :rows, :list, required: true

  attr :page_info_label, :string, default: "records"
  attr :page_limit_options, :list, default: [10, 25, 50, 100, 250, 500, 1_000]
  attr :page, :map, required: true
  attr :sort, :list, required: true

  slot :col, required: true do
    attr :label, :string
    attr :width, :string
    attr :class, :string
    attr :sort_key, :atom
  end

  slot :header, doc: "the slot for a header above the table"
  slot :header_action, doc: "the slot for showing user actions in the last table column header"
  slot :action, doc: "the slot for showing user actions in the last table column"

  def data_table(assigns) do
    assigns = assign_overridables(assigns)

    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table id={@id} class={@class}>
      <thead>
        <tr>
          <.sort :for={col <- @col} table_id={@id} sort={@sort} {col} />
        </tr>
      </thead>
      <tbody>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <.cell :for={col <- @col} class={col[:class]}>
            <%= render_slot(col, @row_item.(row)) %>
          </.cell>
          <.cell
            :if={@action != []}
            class="grid grid-flow-col items-center justify-center px-1 gap-1 select-none"
          >
            <%= render_slot(@action, @row_item.(row)) %>
          </.cell>
        </tr>
      </tbody>
      <tfoot>
        <tr>
          <td colspan={length(@col) + if @action != [], do: 1, else: 0}>Footer</td>
        </tr>
      </tfoot>
    </table>
    """
  end

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :table_id, :string, required: true
  attr :sort, :list, required: true
  attr :label, :string, required: true
  attr :width, :string, default: "auto"
  attr :class, :css_classes, overridable: true
  attr :sort_key, :atom, default: nil

  defp sort(%{sort_key: sort_key} = assigns) when is_atom(sort_key) do
    assigns = assign_overridables(assigns)
    sort = assigns[:sort]

    {direction, position} =
      Enum.reduce_while(sort, {nil, 0}, fn
        {k, direction}, {_, i} when k == sort_key -> {:halt, {direction, i + 1}}
        _, {_, i} -> {:cont, {nil, i + 1}}
      end)

    assigns =
      assigns
      |> assign(:direction, direction)
      |> assign(:position, if(length(sort) > 1, do: position, else: 0))

    ~H"""
    <th class={@class}>
      <button
        id={"#{@table_id}-#{@label}"}
        phx-click={
          JS.dispatch("phx:scroll-top", detail: %{id: @table_id})
          |> JS.push("change-sort", page_loading: true)
        }
        phx-value-sort-key={@sort_key}
        phx-value-table-id={@table_id}
      >
        <%= @label %>
        <.sort_icon direction={@direction} position={@position} />
      </button>
    </th>
    """
  end

  defp sort(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <th id={"#{@table_id}-#{@label}"} class={@class}>
      <%= @label %>
    </th>
    """
  end

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :class, :css_classes, overridable: true
  attr :highlighted, :boolean, default: false
  slot :inner_block, required: true

  defp cell(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <td class={@class}>
      <%= render_slot(@inner_block) %>
    </td>
    """
  end

  # def data_table(assigns) do
  #   assigns =
  #     assign_overridables(assigns)
  #     |> with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
  #       assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
  #     end

  #   ~H"""
  #   <div
  #     id={@id}
  #     class={@class}
  #     style={grid_layout(@col, @action)}
  #     phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
  #   >
  #     <div id={"#{@id}-header"} class="col-span-full">
  #       <%= render_slot(@header) %>
  #     </div>
  #     <.sort :for={col <- @col} table_id={@id} sort={@sort} {col} />
  #     <div
  #       id={"#{@id}-header-actions"}
  #       class="z-10 sticky top-0 border-b border-slate-50/25 border-solid backdrop-blur grid gap-1 justify-center items-center select-none"
  #     >
  #       <%= render_slot(@header_action) %>
  #     </div>
  #     <div :for={row <- @rows} id={@row_id && @row_id.(row)} class="group contents">
  #       <.cell :for={col <- @col} class={col[:class]}>
  #         <%= render_slot(col, @row_item.(row)) %>
  #       </.cell>
  #       <.cell
  #         :if={@action != []}
  #         class="grid grid-flow-col items-center justify-center px-1 gap-1 select-none"
  #       >
  #         <%= render_slot(@action, @row_item.(row)) %>
  #       </.cell>
  #     </div>
  #     <.footer
  #       table_id={@id}
  #       sort={@sort}
  #       page={@page}
  #       page_info_label={@page_info_label}
  #       page_limit_options={@page_limit_options}
  #     />
  #   </div>
  #   """
  # end

  # attr(:table_id, :string, required: true)
  # attr(:page_info_label, :string, default: "records")
  # attr(:page_limit_options, :list, default: [10, 25, 50, 100, 250, 500, 1_000])
  # attr(:page, :map, required: true)
  # attr(:sort, :list, required: true)

  # defp footer(assigns) do
  #   ~H"""
  #   <footer
  #     id={@table_id <> "-footer"}
  #     class="fixed bottom-2 left-2 backdrop-blur flex flex-wrap items-center col-span-full gap-4 rounded-lg border border-slate-50/25 border-solid px-2 py-2 max-w-fit select-none"
  #   >
  #     <div class="grid grid-flow-col justify-center items-center gap-1">
  #       <.button
  #         class="p-0 grid justify-center items-center"
  #         disabled={!prev_page?(@page)}
  #         color="sky"
  #         title="First Page"
  #         phx-click={
  #           JS.dispatch("phx:scroll-top", detail: %{id: @table_id})
  #           |> JS.push("change-page-number", page_loading: true)
  #         }
  #         phx-value-table-id={@table_id}
  #         phx-value-page-number={0}
  #       >
  #         <.icon name="hero-chevron-double-left-solid" class="h-6 w-6" />
  #       </.button>
  #       <.button
  #         class="p-0 grid justify-center items-center"
  #         disabled={!prev_page?(@page)}
  #         color="sky"
  #         title="Previous Page"
  #         phx-click={
  #           JS.dispatch("phx:scroll-top", detail: %{id: @table_id})
  #           |> JS.push("change-page-number", page_loading: true)
  #         }
  #         phx-value-table-id={@table_id}
  #         phx-value-page-number={prev_page(@page)}
  #       >
  #         <.icon name="hero-chevron-left-solid" class="h-6 w-6" />
  #       </.button>
  #       <.button
  #         class="p-0 grid justify-center items-center"
  #         disabled={!next_page?(@page)}
  #         color="sky"
  #         title="Next Page"
  #         phx-click={
  #           JS.dispatch("phx:scroll-top", detail: %{id: @table_id})
  #           |> JS.push("change-page-number", page_loading: true)
  #         }
  #         phx-value-table-id={@table_id}
  #         phx-value-page-number={next_page(@page)}
  #       >
  #         <.icon name="hero-chevron-right-solid" class="h-6 w-6" />
  #       </.button>
  #       <.button
  #         class="p-0 grid justify-center items-center"
  #         disabled={!next_page?(@page)}
  #         color="sky"
  #         title="Last Page"
  #         phx-click={
  #           JS.dispatch("phx:scroll-top", detail: %{id: @table_id})
  #           |> JS.push("change-page-number", page_loading: true)
  #         }
  #         phx-value-table-id={@table_id}
  #         phx-value-page-number={page_count(@page)}
  #       >
  #         <.icon name="hero-chevron-double-right-solid" class="h-6 w-6" />
  #       </.button>
  #     </div>
  #     <form phx-change="change-page-limit" class="grid grid-flow-col gap-1 items-center">
  #       <input type="hidden" name="data_table_form[table_id]" value={@table_id} />
  #       <label>Limit:</label>
  #       <select
  #         name="data_table_form[limit]"
  #         class="appearance-none bg-sky-500/50 text-black dark:text-white rounded border-none py-0 p-2 pr-8 outline-none focus:outline-none w-22 text-right"
  #       >
  #         <option selected value={@page.limit}><%= delimit_integer(@page.limit) %></option>
  #         <option :for={limit <- @page_limit_options} value={limit}>
  #           <%= delimit_integer(limit) %>
  #         </option>
  #       </select>
  #     </form>
  #     <span><%= page_info(@page, @page_info_label) %></span>
  #     <div class="grid grid-flow-col justify-center items-center gap-1">
  #       <.button
  #         color="white"
  #         variant="outline"
  #         case="normal-case"
  #         title="Reset Page/Filter/Sort"
  #         phx-click={
  #           JS.dispatch("phx:scroll-top", detail: %{id: @table_id})
  #           |> JS.push("reset-page", page_loading: true)
  #         }
  #         phx-value-table-id={@table_id}
  #       >
  #         Reset Page
  #       </.button>
  #       <.button
  #         color="white"
  #         variant="outline"
  #         case="normal-case"
  #         title="Scroll to top of page"
  #         phx-click={JS.dispatch("phx:scroll-top", detail: %{id: @table_id})}
  #         phx-value-table-id={@table_id}
  #       >
  #         <.icon name="hero-chevron-double-up-solid" />
  #       </.button>
  #     </div>
  #   </footer>
  #   """
  # end

  # attr :table_id, :string, required: true
  # attr :sort, :list, required: true
  # attr :label, :string, required: true
  # attr :width, :string, default: "auto"
  # attr :class, :string, default: ""
  # attr :sort_key, :atom, default: nil

  # defp sort(%{sort_key: sort_key} = assigns) when is_atom(sort_key) do
  #   sort = assigns[:sort]

  #   {direction, position} =
  #     Enum.reduce_while(sort, {nil, 0}, fn
  #       {k, direction}, {_, i} when k == sort_key -> {:halt, {direction, i + 1}}
  #       _, {_, i} -> {:cont, {nil, i + 1}}
  #     end)

  #   assigns =
  #     assigns
  #     |> assign(:direction, direction)
  #     |> assign(:position, if(length(sort) > 1, do: position, else: 0))

  #   ~H"""
  #   <button
  #     id={"#{@table_id}-#{@label}"}
  #     class={@class}
  #     phx-click={
  #       JS.dispatch("phx:scroll-top", detail: %{id: @table_id})
  #       |> JS.push("change-sort", page_loading: true)
  #     }
  #     phx-value-sort-key={@sort_key}
  #     phx-value-table-id={@table_id}
  #   >
  #     <%= @label %>
  #     <.sort_icon direction={@direction} position={@position} />
  #   </button>
  #   """
  # end

  # defp sort(assigns) do
  #   ~H"""
  #   <div id={"#{@table_id}-#{@label}"} class={@class}>
  #     <%= @label %>
  #   </div>
  #   """
  # end

  # attr :class, :string, default: nil
  # attr :highlighted, :boolean, default: false
  # slot :inner_block, required: true

  # defp cell(assigns) do
  #   ~H"""
  #   <div class={@class}>
  #     <%= render_slot(@inner_block) %>
  #   </div>
  #   """
  # end

  attr :direction, :atom, required: true
  attr :position, :integer, required: true
  defp sort_icon(%{direction: nil} = assigns), do: ~H""

  defp sort_icon(%{position: 0} = assigns) do
    ~H"""
    <.icon name={sort_icon_name(@direction)} class="align-super select-none" />
    """
  end

  defp sort_icon(assigns) do
    ~H"""
    <.icon name={sort_icon_name(@direction)} class="align-super select-none" />
    <span class="bg-blue-500 text-white text-[.65rem] px-[.3rem] py-[.1rem] text-center rounded-full align-super select-none">
      <%= @position %>
    </span>
    """
  end

  defp sort_icon_name(direction) do
    case direction do
      :asc -> "hero-chevron-up-solid"
      :asc_nils_last -> "hero-chevron-up-solid"
      :asc_nils_first -> "hero-chevron-double-up-solid"
      :desc -> "hero-chevron-down-solid"
      :desc_nils_first -> "hero-chevron-down-solid"
      :desc_nils_last -> "hero-chevron-double-down-solid"
    end
  end

  # defp grid_layout(cols, actions) do
  #   cols =
  #     if actions != [] do
  #       cols ++ [%{}]
  #     else
  #       cols
  #     end

  #   template = Enum.map_join(cols, " ", fn col -> col[:width] || "auto" end)
  #   "grid-template-columns: #{template};"
  # end

  # defp prev_page?(%{offset: 0}), do: false
  # defp prev_page?(%{offset: offset}) when is_integer(offset), do: true

  # defp prev_page?(_), do: raise("Need to implement keyset pagination!")

  # defp prev_page(%{offset: _} = page) do
  #   page
  #   |> page_number()
  #   |> Kernel.-(1)
  #   |> max(0)
  # end

  # defp prev_page(_), do: raise("Need to implement keyset pagination!")

  # defp next_page?(%{offset: offset} = page) when is_integer(offset) do
  #   if page_number(page) < page_count(page) do
  #     true
  #   else
  #     false
  #   end
  # end

  # defp next_page?(_), do: raise("Need to implement keyset pagination!")

  # defp next_page(%{offset: _} = page) do
  #   page
  #   |> page_number()
  #   |> Kernel.+(1)
  #   |> min(page_count(page))
  # end

  # defp next_page(_), do: raise("Need to implement keyset pagination!")

  # defp page_number(%{offset: 0}), do: 0

  # defp page_number(%{offset: offset, limit: limit}) do
  #   if rem(offset, limit) == 0 do
  #     div(offset, limit)
  #   else
  #     div(offset, limit) + 1
  #   end
  # end

  # defp page_number(_), do: raise("Need to implement keyset pagination!")

  # defp page_count(%{count: 0}), do: 0

  # defp page_count(%{count: count, limit: limit}) do
  #   if rem(count, limit) == 0 do
  #     div(count, limit)
  #   else
  #     div(count, limit) + 1
  #   end
  #   |> Kernel.-(1)
  # end

  # defp page_count(_), do: raise("Need to implement keyset pagination!")

  # defp page_info(page, label) do
  #   n =
  #     page
  #     |> page_number()
  #     |> Kernel.+(1)
  #     |> delimit_integer()

  #   c =
  #     page
  #     |> page_count()
  #     |> Kernel.+(1)
  #     |> delimit_integer()

  #   t = delimit_integer(page.count)
  #   "Page #{n} of #{c} (#{t} #{label})"
  # end

  # defp delimit_integer(number), do: floor(number)

  def encode_sort(sort) do
    sort
    |> Enum.map_join(",", fn
      {k, :asc} -> "#{k}"
      {k, :asc_nils_last} -> "#{k}"
      {k, :asc_nils_first} -> "++#{k}"
      {k, :desc} -> "-#{k}"
      {k, :desc_nils_first} -> "-#{k}"
      {k, :desc_nils_last} -> "--#{k}"
    end)
  end

  def toggle_sort(sort, sort_key, ctrl?, shift?) do
    sort =
      Enum.map(sort, fn
        {k, v} when is_atom(k) -> {Atom.to_string(k), v}
        {k, v} -> {k, v}
      end)

    case Enum.find(sort, fn {k, _v} -> k == sort_key end) do
      nil ->
        added = [{sort_key, :asc}]
        if shift?, do: sort ++ added, else: added

      {_key, order} ->
        if shift? && length(sort) > 1 do
          sort
          |> Enum.map(fn
            {k, order} when sort_key == k ->
              {k, toggle_sort_order(order, ctrl?, shift?)}

            other ->
              other
          end)
          |> Enum.filter(fn {_key, order} -> order != nil end)
        else
          [{sort_key, toggle_sort_order(order, ctrl?, false)}]
        end
    end
    |> encode_sort()
  end

  # args: column, change_nil_position?, multiple_columns?
  # don't change nil position, single sort
  defp toggle_sort_order(order, false, false) do
    case order do
      :asc -> :desc
      :asc_nils_last -> :desc
      :asc_nils_first -> :desc_nils_last
      :desc -> :asc
      :desc_nils_first -> :asc
      :desc_nils_last -> :asc_nils_first
    end
  end

  # don't change nil position, multi sort
  defp toggle_sort_order(order, false, true) do
    case order do
      :asc -> :desc
      :asc_nils_last -> :desc
      :asc_nils_first -> :desc_nils_last
      :desc -> nil
      :desc_nils_first -> nil
      :desc_nils_last -> nil
    end
  end

  # change nil position, any sort
  defp toggle_sort_order(order, true, _) do
    case order do
      :asc -> :asc_nils_first
      :asc_nils_last -> :asc_nils_first
      :asc_nils_first -> :asc
      :desc -> :desc_nils_last
      :desc_nils_first -> :desc_nils_last
      :desc_nils_last -> :desc
    end
  end
end
