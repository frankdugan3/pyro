defmodule Pyro.Design.Skill.WriterRoundTripTest do
  use ExUnit.Case, async: false

  alias Pyro.Design.Skill.Writer

  @namespace "rt"
  @design_dir Path.join(Writer.root(), "#{@namespace}-design")
  @sentinel Path.join(@design_dir, "STALE.md")

  setup_all do
    File.rm_rf!(@design_dir)

    code = """
    defmodule Pyro.Test.Design.WithSkills do
      use Pyro.Design, generate_skills?: true

      config do
        namespace #{inspect(@namespace)}
      end

      design do
        color :bg, "#ffffff"
        dimension :gap, 1.0, :rem
      end
    end
    """

    Code.eval_string(code)
    on_exit(fn -> File.rm_rf!(@design_dir) end)

    {:ok, mod: Pyro.Test.Design.WithSkills}
  end

  test "persists generate_skills? on the design module", %{mod: mod} do
    assert Pyro.Design.Info.generate_skills?(mod) == true
  end

  test "compiles all four files to disk under the namespaced design dir", %{mod: mod} do
    expected = Writer.build(mod)

    for {rel, content} <- expected do
      path = Path.join(Writer.root(), rel)
      assert File.exists?(path), "missing file at #{path}"
      assert File.read!(path) == content
    end
  end

  test "rewrites cleanly within its own design dir on each call", %{mod: mod} do
    File.write!(@sentinel, "leftover")

    Writer.write(mod)

    refute File.exists?(@sentinel), "stale file inside design dir survived rewrite"
    assert File.exists?(Path.join(@design_dir, "SKILL.md"))
  end

  test "does not touch sibling skills under .claude/skills/", %{mod: mod} do
    sibling_dir = Path.join(Writer.root(), "unrelated-skill")
    sibling = Path.join(sibling_dir, "SKILL.md")
    File.mkdir_p!(sibling_dir)
    File.write!(sibling, "hands off")

    Writer.write(mod)

    assert File.read!(sibling) == "hands off"
  after
    File.rm_rf!(Path.join(Writer.root(), "unrelated-skill"))
  end

  test "when generate_skills? is false (default), writes nothing to disk" do
    code = """
    defmodule Pyro.Test.Design.WithoutSkills do
      use Pyro.Design

      config do
        namespace "noskills"
      end

      design do
        color :bg, "#ffffff"
      end
    end
    """

    Code.eval_string(code)
    target = Path.join(Writer.root(), "noskills-design")
    File.rm_rf!(target)

    assert :ok = Writer.write(Pyro.Test.Design.WithoutSkills)

    refute File.exists?(target)
  end
end
