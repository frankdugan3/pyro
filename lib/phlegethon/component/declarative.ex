# Original file: declarative.ex from Phoenix LiveView (https://github.com/phoenixframework/phoenix_live_view/blob/master/lib/phoenix_component/declarative.ex)
# Modifications: Extended to add the "overridable" prop and "class" type, documentation changes, etc.
# Copyright 2023 Frank Dugan III
# Licensed under the MIT license

defmodule Phlegethon.Component.Declarative do
  @moduledoc false
  @configured_overrides Application.compile_env(:phlegethon, :overrides, [
                          Phlegethon.Overrides.Default
                        ])

  import Phoenix.Component.Declarative,
    only: [__reserved__: 0]

  @reserved_assigns [:__stored_classes__ | __reserved__()]

  @doc false
  defmacro def(expr, body) do
    quote do
      Kernel.def(unquote(annotate_def(:def, expr)), unquote(body))
    end
  end

  @doc false
  defmacro defp(expr, body) do
    quote do
      Kernel.defp(unquote(annotate_def(:defp, expr)), unquote(body))
    end
  end

  defp annotate_def(kind, expr) do
    case expr do
      {:when, meta, [left, right]} -> {:when, meta, [annotate_call(kind, left), right]}
      left -> annotate_call(kind, left)
    end
  end

  defp annotate_call(kind, {name, meta, [{:\\, default_meta, [left, right]}]}),
    do: {name, meta, [{:\\, default_meta, [annotate_arg(kind, left), right]}]}

  defp annotate_call(kind, {name, meta, [arg]}),
    do: {name, meta, [annotate_arg(kind, arg)]}

  defp annotate_call(_kind, left),
    do: left

  defp annotate_arg(kind, {:=, meta, [{name, _, ctx} = var, arg]})
       when is_atom(name) and is_atom(ctx) do
    {:=, meta, [var, quote(do: unquote(__MODULE__).__pattern__!(unquote(kind), unquote(arg)))]}
  end

  defp annotate_arg(kind, {:=, meta, [arg, {name, _, ctx} = var]})
       when is_atom(name) and is_atom(ctx) do
    {:=, meta, [quote(do: unquote(__MODULE__).__pattern__!(unquote(kind), unquote(arg))), var]}
  end

  defp annotate_arg(kind, {name, meta, ctx} = var) when is_atom(name) and is_atom(ctx) do
    {:=, meta, [quote(do: unquote(__MODULE__).__pattern__!(unquote(kind), _)), var]}
  end

  defp annotate_arg(kind, arg) do
    quote(do: unquote(__MODULE__).__pattern__!(unquote(kind), unquote(arg)))
  end

  @doc false
  @valid_opts [:global_prefixes]
  def __setup__(module, opts) do
    {prefixes, invalid_opts} = Keyword.pop(opts, :global_prefixes, [])

    prefix_matches =
      for prefix <- prefixes do
        unless String.ends_with?(prefix, "-") do
          raise ArgumentError,
                "global prefixes for #{inspect(module)} must end with a dash, got: #{inspect(prefix)}"
        end

        quote(do: {unquote(prefix) <> _, true})
      end

    if invalid_opts != [] do
      raise ArgumentError, """
      invalid options passed to #{inspect(__MODULE__)}.
      The following options are supported: #{inspect(@valid_opts)}, got: #{inspect(invalid_opts)}
      """
    end

    Module.register_attribute(module, :__overridables__, accumulate: true)
    Module.register_attribute(module, :__slot_overridables__, accumulate: true)
    Module.register_attribute(module, :__attrs__, accumulate: true)
    Module.register_attribute(module, :__slot_attrs__, accumulate: true)
    Module.register_attribute(module, :__slots__, accumulate: true)
    Module.register_attribute(module, :__slot__, accumulate: false)
    Module.register_attribute(module, :__components_calls__, accumulate: true)
    Module.put_attribute(module, :__components__, %{})
    Module.put_attribute(module, :on_definition, __MODULE__)
    Module.put_attribute(module, :before_compile, __MODULE__)

    if prefix_matches == [] do
      []
    else
      prefix_matches ++ [quote(do: {_, false})]
    end
  end

  @doc false
  def __overridable__!(module, name, type, opts, line, file)
      when is_atom(name) and is_list(opts) do
    ensure_used!(module, line, file)
    slot = Module.get_attribute(module, :__slot__)

    if name in @reserved_assigns do
      compile_error!(
        line,
        file,
        "cannot define overridable called #{name}"
      )
    end

    {doc, opts} = Keyword.pop(opts, :doc, nil)

    unless is_binary(doc) or is_nil(doc) or doc == false do
      compile_error!(line, file, ":doc must be a string or false, got: #{inspect(doc)}")
    end

    {required, opts} = Keyword.pop(opts, :required, false)

    unless is_boolean(required) do
      compile_error!(line, file, ":required must be a boolean, got: #{inspect(required)}")
    end

    {assign_new, opts} = Keyword.pop(opts, :assign_new, false)

    if assign_new && type == :class do
      compile_error!(
        line,
        file,
        ":class type overridables can't be assign_new since they probably have dependencies on other dynamic assigns"
      )
    end

    if Keyword.has_key?(opts, :default) do
      compile_error!(
        line,
        file,
        ":overridable types don't need a default because the override is the default"
      )
    end

    key = if slot, do: :__slot_overridables__, else: :__overridables__
    type = validate_overridable_type!(module, key, slot, name, type, line, file)

    # validate_overridable_opts!(slot, name, opts, line, file)

    # TODO: can validate that non-functions match the assigned type
    # if Keyword.has_key?(opts, :values) do
    #   validate_attr_values!(name, type, opts[:values], line, file)
    # end

    # if Keyword.has_key?(opts, :examples) do
    #   validate_attr_examples!(name, type, opts[:examples], line, file)
    # end

    overridable = %{
      name: name,
      type: type,
      required: required,
      opts: opts,
      doc: doc,
      line: line,
      assign_new: assign_new
    }

    Module.put_attribute(module, :__overridables__, overridable)
    :ok
  end

  @builtin_types ~w[class boolean integer float string atom list map]a
  @valid_types [:any] ++ @builtin_types
  defp validate_overridable_type!(module, key, slot, name, type, line, file) when is_atom(type) do
    attrs = Module.get_attribute(module, key) || []
    overridables = Module.get_attribute(module, key) || []

    cond do
      Enum.find(attrs, fn attr -> attr.name == name end) ->
        compile_error!(line, file, """
        an attribute with name #{overridable_slot(name, slot)} already exists\
        """)

      Enum.find(overridables, fn overridable -> overridable.name == name end) ->
        compile_error!(line, file, """
        a duplicate overridable with name #{overridable_slot(name, slot)} already exists\
        """)

      true ->
        :ok
    end

    case Atom.to_string(type) do
      "Elixir." <> _ -> {:struct, type}
      _ when type in @valid_types -> type
      _ -> bad_type!(slot, name, type, line, file)
    end
  end

  defp validate_overridable_type!(_module, _key, slot, name, type, line, file) do
    bad_type!(slot, name, type, line, file)
  end

  defp bad_type!(slot, name, type, line, file) do
    compile_error!(line, file, """
    invalid type #{inspect(type)} for overridable #{overridable_slot(name, slot)}. \
    The following types are supported:
      * any Elixir struct, such as URI, MyApp.User, etc
      * one of #{Enum.map_join(@builtin_types, ", ", &inspect/1)}
      * :any for all other types
    """)
  end

  defp overridable_slot(name, nil), do: "#{inspect(name)}"
  defp overridable_slot(name, slot), do: "#{inspect(name)} in slot #{inspect(slot)}"

  defmacro __pattern__!(kind, arg) do
    {name, 1} = __CALLER__.function
    {_slots, attrs, overridables} = register_component!(kind, __CALLER__, name, true)

    fields =
      for %{name: name, required: true, type: {:struct, struct}} <- overridables ++ attrs do
        {name, quote(do: %unquote(struct){})}
      end

    if fields == [] do
      arg
    else
      quote(do: %{unquote_splicing(fields)} = unquote(arg))
    end
  end

  @doc false
  def __on_definition__(env, kind, name, args, _guards, body) do
    check? = not String.starts_with?(to_string(name), "__")

    cond do
      check? and length(args) == 1 and body == nil ->
        register_component!(kind, env, name, false)

      check? ->
        overridables = pop_overridables(env)

        validate_misplaced_props!(overridables, env.file, fn ->
          case length(args) do
            1 ->
              "could not define overridables for function #{name}/1. " <>
                "Please make sure that you have `use Phlegethon.Component` and that the function has no default arguments"

            arity ->
              "cannot declare overridables for function #{name}/#{arity}. Components must be functions with arity 1"
          end
        end)

        attrs = pop_attrs(env)

        validate_misplaced_props!(attrs, env.file, fn ->
          case length(args) do
            1 ->
              "could not define attributes for function #{name}/1. " <>
                "Please make sure that you have `use Phlegethon.Component` and that the function has no default arguments"

            arity ->
              "cannot declare attributes for function #{name}/#{arity}. Components must be functions with arity 1"
          end
        end)

        slots = pop_slots(env)

        validate_misplaced_props!(slots, env.file, fn ->
          case length(args) do
            1 ->
              "could not define slots for function #{name}/1. " <>
                "Components cannot be dynamically defined or have default arguments"

            arity ->
              "cannot declare slots for function #{name}/#{arity}. Components must be functions with arity 1"
          end
        end)

      true ->
        :ok
    end
  end

  @doc false
  def assign_function_overrides(assigns, []), do: assigns

  def assign_function_overrides(assigns, [{name, {override, assign_new}} | overrides]) do
    value =
      if Map.has_key?(assigns, name) do
        assigns[name]
      else
        case override do
          function when is_function(function, 1) -> apply(function, [assigns])
          other -> other
        end
      end

    if assign_new do
      assign_function_overrides(
        Phoenix.Component.assign_new(assigns, name, fn -> value end),
        overrides
      )
    else
      assign_function_overrides(
        Phoenix.Component.assign(assigns, name, value),
        overrides
      )
    end
  end

  @doc false
  def assign_class_overrides(assigns, []), do: assigns

  def assign_class_overrides(
        %{__stored_classes__: stored_classes} = assigns,
        [{name, override} | overrides]
      ) do
    # We need to store the original assign so we can merge the class with the original value on updates
    assigns =
      if Map.has_key?(stored_classes, name) do
        assigns
      else
        stored_classes = Map.put(stored_classes, name, assigns[name])
        Map.put(assigns, :__stored_classes__, stored_classes)
      end

    merged_class =
      Tails.classes([
        case override do
          function when is_function(function, 1) -> apply(function, [assigns])
          other -> other
        end,
        assigns[:__stored_classes__][name]
      ])

    assign_class_overrides(
      Phoenix.Component.assign(assigns, name, merged_class),
      overrides
    )
  end

  def assign_class_overrides(assigns, overrides),
    do: assign_class_overrides(Map.put(assigns, :__stored_classes__, %{}), overrides)

  @doc false
  defmacro __before_compile__(env) do
    overridables = pop_overridables(env)

    validate_misplaced_props!(overridables, env.file, fn ->
      "cannot define overridables without a related function component"
    end)

    attrs = pop_attrs(env)

    validate_misplaced_props!(attrs, env.file, fn ->
      "cannot define attributes without a related function component"
    end)

    slots = pop_slots(env)

    validate_misplaced_props!(slots, env.file, fn ->
      "cannot define slots without a related function component"
    end)

    components = Module.get_attribute(env.module, :__components__)
    components_calls = Module.get_attribute(env.module, :__components_calls__) |> Enum.reverse()

    names_and_defs =
      for {name, %{kind: kind, attrs: attrs, slots: slots, overridables: overridables}} <-
            components do
        {overridable_defaults, function_overrides} =
          overridables
          |> Enum.reduce({[], []}, fn
            %{name: name, opts: opts, type: type, assign_new: assign_new},
            {overridable_defaults, function_overrides}
            when type != :class ->
              case opts[:default] do
                function when is_function(function, 1) ->
                  {overridable_defaults,
                   function_overrides ++ [{name, {Macro.escape(function), assign_new}}]}

                other ->
                  {overridable_defaults ++ [{name, Macro.escape(other)}], function_overrides}
              end

            _, acc ->
              acc
          end)

        attr_defaults =
          for %{name: name, required: false, opts: opts} <- attrs,
              Keyword.has_key?(opts, :default),
              do: {name, Macro.escape(opts[:default])}

        slot_defaults =
          for %{name: name, required: false} <- slots do
            {name, []}
          end

        defaults = overridable_defaults ++ attr_defaults ++ slot_defaults

        {global_name, global_default} =
          case Enum.find(attrs, fn attr -> attr.type == :global end) do
            %{name: name, opts: opts} -> {name, Macro.escape(Keyword.get(opts, :default, %{}))}
            nil -> {nil, nil}
          end

        class_overrides =
          for %{name: name, opts: opts, type: type} when type == :class <-
                overridables,
              do: {name, Macro.escape(opts[:default])}

        overridable_names = for(overridable <- overridables, do: overridable.name)
        attr_names = for(attr <- attrs, do: attr.name)
        slot_names = for(slot <- slots, do: slot.name)
        known_keys = overridable_names ++ attr_names ++ slot_names ++ @reserved_assigns

        def_body =
          if global_name do
            quote do
              {assigns, caller_globals} = Map.split(assigns, unquote(known_keys))

              globals =
                case assigns do
                  %{unquote(global_name) => explicit_global_assign} -> explicit_global_assign
                  %{} -> Map.merge(unquote(global_default), caller_globals)
                end

              merged =
                %{unquote_splicing(defaults)}
                |> Map.merge(assigns)
                |> Map.put(:__given__, assigns)
                |> assign_function_overrides(unquote(function_overrides))
                |> assign_class_overrides(unquote(class_overrides))

              super(Phoenix.Component.assign(merged, unquote(global_name), globals))
            end
          else
            quote do
              merged =
                %{unquote_splicing(defaults)}
                |> Map.merge(assigns)
                |> Map.put(:__given__, assigns)
                |> assign_function_overrides(unquote(function_overrides))
                |> assign_class_overrides(unquote(class_overrides))

              super(merged)
            end
          end

        merge =
          quote do
            Kernel.unquote(kind)(unquote(name)(assigns)) do
              unquote(def_body)
            end
          end

        {{name, 1}, merge}
      end

    {names, defs} = Enum.unzip(names_and_defs)

    def_overridable =
      if names != [] do
        quote do
          defoverridable unquote(names)
        end
      end

    def_components_ast =
      quote do
        def __components__() do
          unquote(Macro.escape(components))
        end
      end

    def_components_calls_ast =
      if components_calls != [] do
        quote do
          @after_verify {__MODULE__, :__phoenix_component_verify__}

          @doc false
          def __phoenix_component_verify__(module) do
            # TODO: Add Phlegethon validations here!
            # unquote(__MODULE__).__verify__(module, unquote(Macro.escape(components_calls)))
          end
        end
      end

    {:__block__, [], [def_components_ast, def_components_calls_ast, def_overridable | defs]}
  end

  defp register_component!(kind, env, name, check_if_defined?) do
    slots = pop_slots(env)
    attrs = pop_attrs(env)

    overridables =
      env
      |> pop_overridables()
      |> Enum.map(fn overridable ->
        value =
          @configured_overrides
          |> Enum.reduce_while(nil, fn override_module, _ ->
            override_module.overrides()
            |> Map.fetch({{env.module, name}, overridable.name})
            |> case do
              {:ok, value} -> {:halt, value}
              :error -> {:cont, nil}
            end
          end)

        if overridable.required && is_nil(value) do
          compile_error!(overridable.line, env.file, """
          cannot find an override setting for :#{overridable.name}, please ensure you define one in a configured override module\
          """)
        end

        opts =
          Keyword.update(overridable.opts, :values, [], fn
            key when is_atom(key) ->
              @configured_overrides
              |> Enum.reduce_while(nil, fn override_module, _ ->
                override_module.overrides()
                |> Map.fetch({{env.module, name}, key})
                |> case do
                  {:ok, value} -> {:halt, value}
                  :error -> {:cont, nil}
                end
              end)

            list when is_list(list) ->
              list
          end)
          |> Keyword.put(:default, value)

        # TODO: Validate values

        Map.put(overridable, :opts, opts)
      end)

    cond do
      slots != [] or attrs != [] ->
        check_if_defined? and
          raise_if_function_already_defined!(env, name, slots, attrs, overridables)

        register_component_doc(env, kind, slots, attrs, overridables)

        for %{name: slot_name, line: line} <- slots,
            Enum.find(attrs, &(&1.name == slot_name)) do
          compile_error!(line, env.file, """
          cannot define a slot with name #{inspect(slot_name)}, as an attribute with that name already exists\
          """)
        end

        for %{name: slot_name, line: line} <- slots,
            Enum.find(overridables, &(&1.name == slot_name)) do
          compile_error!(line, env.file, """
          cannot define a slot with name #{inspect(slot_name)}, as an overridable with that name already exists\
          """)
        end

        for %{name: attribute_name, slot: slot, line: line} <- attrs,
            Enum.find(overridables, &(&1.name == attribute_name)) do
          compile_error!(line, env.file, """
          cannot define attribute with name #{overridable_slot(attribute_name, slot)}, as an overridable with that name already exists\
          """)
        end

        components =
          env.module
          |> Module.get_attribute(:__components__)
          # TODO: Original code says:
          # Sort by name as this is used when they are validated
          # -- Don't know if that really matters, will have to come to it later.
          # We don't because we want to preserve order for the functions,
          # in case they are linearly dependant.
          # |> Map.put(name, %{
          #   kind: kind,
          #   overridables: Enum.sort_by(overridables, & &1.name),
          #   attrs: Enum.sort_by(attrs, & &1.name),
          #   slots: Enum.sort_by(slots, & &1.name)
          # })
          |> Map.put(name, %{
            kind: kind,
            overridables: overridables,
            attrs: Enum.sort_by(attrs, & &1.name),
            slots: Enum.sort_by(slots, & &1.name)
          })

        Module.put_attribute(env.module, :__components__, components)
        Module.put_attribute(env.module, :__last_component__, name)
        {slots, attrs, overridables}

      Module.get_attribute(env.module, :__last_component__) == name ->
        %{slots: slots, attrs: attrs, overridables: overridables} =
          Module.get_attribute(env.module, :__components__)[name]

        {slots, attrs, overridables}

      true ->
        {[], [], []}
    end
  end

  # Documentation handling

  defp register_component_doc(env, :def, slots, attrs, overridables) do
    case Module.get_attribute(env.module, :doc) do
      {_line, false} ->
        :ok

      {line, doc} ->
        Module.put_attribute(
          env.module,
          :doc,
          {line, build_component_doc(doc, slots, attrs, overridables)}
        )

      nil ->
        Module.put_attribute(
          env.module,
          :doc,
          {env.line, build_component_doc(slots, attrs, overridables)}
        )
    end
  end

  defp register_component_doc(_env, :defp, _slots, _attrs, _overridables) do
    :ok
  end

  defp build_component_doc(doc \\ "", slots, attrs, overridables) do
    [left | right] = String.split(doc, "[INSERT LVATTRDOCS]")

    IO.iodata_to_binary([
      build_left_doc(left),
      build_component_docs(slots, attrs, overridables),
      build_right_doc(right)
    ])
  end

  defp build_left_doc("") do
    [""]
  end

  defp build_left_doc(left) do
    [left, ?\n]
  end

  defp build_component_docs(slots, attrs, overridables) do
    [
      build_overridables_docs(overridables),
      build_attrs_docs(attrs),
      build_slots_docs(slots)
    ]
    |> Enum.filter(&(&1 != nil))
    |> Enum.intersperse(?\n)
  end

  defp build_overridables_docs([]), do: nil

  defp build_overridables_docs(overridables) do
    # Because we didn't sort them before (to preserve execution order of functions)
    overridables = Enum.sort_by(overridables, & &1.name)

    [
      "## Overridables\n",
      for overridable <- overridables,
          overridable.doc != false,
          overridable.type != :global,
          into: [] do
        [
          "\n* ",
          build_overridable_name(overridable),
          build_overridable_type(overridable),
          build_overridable_required(overridable),
          build_overridable_doc_and_default(overridable, "  "),
          build_overridable_values_or_examples(overridable, "  ")
        ]
      end
    ]
  end

  defp build_overridable_name(%{name: name}) do
    ["`", Atom.to_string(name), "` "]
  end

  defp build_overridable_type(%{type: {:struct, type}}) do
    ["`", inspect(type), "`"]
  end

  defp build_overridable_type(%{type: type}) do
    ["`", inspect(type), "`"]
  end

  defp build_overridable_required(%{required: true}) do
    [" (required)"]
  end

  defp build_overridable_required(_overridable), do: []

  defp build_overridable_doc_and_default(
         %{doc: doc, opts: opts, type: type, assign_new: assign_new},
         indent
       ) do
    case Keyword.fetch(opts, :default) do
      {:ok, default} ->
        label =
          cond do
            is_function(default, 1) and type == :class ->
              "Merges/assigns with "

            is_function(default, 1) and assign_new ->
              "`assign_new`: "

            is_function(default, 1) ->
              "`assign`: "

            type == :class ->
              "Merges with default "

            true ->
              "Defaults to "
          end

        if doc do
          [
            " - ",
            build_doc(doc, indent, true),
            ?\n,
            indent,
            "* ",
            label,
            build_literal(default),
            "."
          ]
        else
          [?\n, indent, "* ", label, build_literal(default), "."]
        end

      :error ->
        if doc, do: [build_doc(doc, indent, false)], else: []
    end
  end

  defp build_overridable_values_or_examples(%{opts: opts}, indent) do
    [
      case Keyword.get(opts, :values) do
        nil -> []
        [] -> []
        values -> [?\n, indent, "* Must be one of ", build_literals_list(values, "or"), ?.]
      end,
      case Keyword.get(opts, :examples) do
        nil -> []
        examples -> [?\n, indent, "* Examples include ", build_literals_list(examples, "and"), ?.]
      end
    ]
  end

  defp build_slots_docs([]), do: nil

  defp build_slots_docs(slots) do
    [
      "## Slots\n",
      for slot <- slots, slot.doc != false, into: [] do
        slot_attrs =
          for slot_attr <- slot.attrs,
              slot_attr.doc != false,
              slot_attr.slot == slot.name,
              do: slot_attr

        [
          "\n* ",
          build_slot_name(slot),
          build_slot_required(slot),
          build_slot_doc(slot, slot_attrs)
        ]
      end
    ]
  end

  defp build_slot_name(%{name: name}) do
    ["`", Atom.to_string(name), "`"]
  end

  defp build_slot_required(%{required: true}) do
    [" (required)"]
  end

  defp build_slot_required(_slot) do
    []
  end

  defp build_slot_doc(%{doc: nil}, []) do
    []
  end

  defp build_slot_doc(%{doc: doc}, []) do
    [" - ", build_doc(doc, "  ", false)]
  end

  defp build_slot_doc(%{doc: nil}, slot_attrs) do
    [" - Accepts attributes:\n", build_slot_attrs_docs(slot_attrs)]
  end

  defp build_slot_doc(%{doc: doc}, slot_attrs) do
    [
      " - ",
      build_doc(doc, "  ", true),
      "Accepts attributes:\n",
      build_slot_attrs_docs(slot_attrs)
    ]
  end

  defp build_attrs_docs([]), do: nil

  defp build_attrs_docs(attrs) do
    [
      "## Attributes\n",
      if Enum.any?(attrs, &(&1.type == :global)) do
        "Global attributes are accepted."
      else
        ""
      end,
      for attr <- attrs, attr.doc != false, attr.type != :global, into: [] do
        [
          "\n* ",
          build_attr_name(attr),
          build_attr_type(attr),
          build_attr_required(attr),
          build_hyphen(attr),
          build_attr_doc_and_default(attr, "  "),
          build_attr_values_or_examples(attr)
        ]
      end
    ]
  end

  defp build_slot_attrs_docs(slot_attrs) do
    for slot_attr <- slot_attrs do
      [
        "\n  * ",
        build_attr_name(slot_attr),
        build_attr_type(slot_attr),
        build_attr_required(slot_attr),
        build_hyphen(slot_attr),
        build_attr_doc_and_default(slot_attr, "    "),
        build_attr_values_or_examples(slot_attr)
      ]
    end
  end

  defp build_attr_name(%{name: name}) do
    ["`", Atom.to_string(name), "` "]
  end

  defp build_attr_type(%{type: {:struct, type}}) do
    ["(`", inspect(type), "`)"]
  end

  defp build_attr_type(%{type: type}) do
    ["(`", inspect(type), "`)"]
  end

  defp build_attr_required(%{required: true}) do
    [" (required)"]
  end

  defp build_attr_required(_attr) do
    []
  end

  defp build_attr_doc_and_default(%{doc: doc, type: :global, opts: opts}, indent) do
    case Keyword.fetch(opts, :include) do
      {:ok, [_ | _] = inc} ->
        if doc do
          [build_doc(doc, indent, true), "Supports all globals plus: ", build_literal(inc), "."]
        else
          ["Supports all globals plus: ", build_literal(inc), "."]
        end

      _ ->
        if doc, do: [build_doc(doc, indent, false)], else: []
    end
  end

  defp build_attr_doc_and_default(%{doc: doc, opts: opts}, indent) do
    case Keyword.fetch(opts, :default) do
      {:ok, default} ->
        if doc do
          [build_doc(doc, indent, true), "Defaults to ", build_literal(default), "."]
        else
          ["Defaults to ", build_literal(default), "."]
        end

      :error ->
        if doc, do: [build_doc(doc, indent, false)], else: []
    end
  end

  defp build_doc(doc, indent, text_after?) do
    doc = String.trim(doc)
    [head | tail] = String.split(doc, ["\r\n", "\n"])
    dot = if String.ends_with?(doc, "."), do: [], else: [?.]

    tail =
      Enum.map(tail, fn
        "" -> "\n"
        other -> [?\n, indent | other]
      end)

    case tail do
      # Single line
      [] when text_after? ->
        [[head | tail], dot, ?\s]

      [] ->
        [[head | tail], dot]

      # Multi-line
      _ when text_after? ->
        [[head | tail], "\n\n", indent]

      _ ->
        [[head | tail], "\n"]
    end
  end

  defp build_attr_values_or_examples(%{opts: [values: values]}) do
    ["Must be one of ", build_literals_list(values, "or"), ?.]
  end

  defp build_attr_values_or_examples(%{opts: [examples: examples]}) do
    ["Examples include ", build_literals_list(examples, "and"), ?.]
  end

  defp build_attr_values_or_examples(_attr) do
    []
  end

  defp build_literals_list([literal], _condition) do
    [build_literal(literal)]
  end

  defp build_literals_list(literals, condition) do
    literals
    |> Enum.map_intersperse(", ", &build_literal/1)
    |> List.insert_at(-2, [condition, " "])
  end

  defp build_literal(literal) when is_function(literal, 1) do
    module = Function.info(literal)[:module]
    name = Function.info(literal)[:name]
    "[`#{name}/1`](`#{module}.#{name}/1`)"
  end

  defp build_literal(literal) do
    [?`, inspect(literal, charlists: :as_list), ?`]
  end

  defp build_hyphen(%{doc: doc}) when is_binary(doc) do
    [" - "]
  end

  defp build_hyphen(%{opts: []}) do
    []
  end

  defp build_hyphen(%{opts: _opts}) do
    [" - "]
  end

  defp build_right_doc("") do
    []
  end

  defp build_right_doc(right) do
    [?\n, right]
  end

  defp pop_overridables(env) do
    overridables = Module.delete_attribute(env.module, :__overridables__) || []
    Enum.reverse(overridables)
  end

  defp pop_attrs(env) do
    attrs = Module.delete_attribute(env.module, :__attrs__) || []
    Enum.reverse(attrs)
  end

  defp pop_slots(env) do
    slots = Module.delete_attribute(env.module, :__slots__) || []
    Enum.reverse(slots)
  end

  defp raise_if_function_already_defined!(env, name, slots, attrs, overridables) do
    if Module.defines?(env.module, {name, 1}) do
      {:v1, _, meta, _} = Module.get_definition(env.module, {name, 1})

      with [%{line: first_overridable_line} | _] <- overridables do
        compile_error!(first_overridable_line, env.file, """
        overridables must be defined before the first function clause at line #{meta[:line]}
        """)
      end

      with [%{line: first_attr_line} | _] <- attrs do
        compile_error!(first_attr_line, env.file, """
        attributes must be defined before the first function clause at line #{meta[:line]}
        """)
      end

      with [%{line: first_slot_line} | _] <- slots do
        compile_error!(first_slot_line, env.file, """
        slots must be defined before the first function clause at line #{meta[:line]}
        """)
      end
    end
  end

  defp validate_misplaced_props!(props, file, message_fun) do
    with [%{line: first_prop_line} | _] <- props do
      compile_error!(first_prop_line, file, message_fun.())
    end
  end

  defp compile_error!(line, file, msg) do
    raise CompileError, line: line, file: file, description: msg
  end

  defp ensure_used!(module, line, file) do
    if !Module.get_attribute(module, :__overridables__) do
      compile_error!(
        line,
        file,
        "you must `use Phlegethon.Component` to declare overridables. It is currently only imported."
      )
    end
  end
end
