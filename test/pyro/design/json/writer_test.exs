defmodule Pyro.Design.JSON.WriterTest do
  use ExUnit.Case, async: true

  alias Pyro.Design.JSON.Writer

  defmodule Fixture do
    use Pyro.Design

    config do
      namespace "jw"
    end

    design do
      color :bg, "#ffffff", description: "Default surface", deprecated: "use surface instead"

      group :color do
        color :brand, "#0066cc"
      end

      ref :primary, "#/color/brand"

      dimension :xs, 0.25, :rem
      number :z, 10

      shadow :card do
        color "#0003"
        offset_x(0, :px)
        offset_y(1, :px)
        blur(2, :px)
        spread(0, :px)
      end
    end
  end

  setup do
    {:ok, json: Writer.build(Fixture) |> JSON.decode!()}
  end

  test "scalar color emits $type and $value", %{json: json} do
    assert json["bg"]["$type"] == "color"
    assert is_binary(json["bg"]["$value"])
  end

  test "dimension emits DTCG object form", %{json: json} do
    assert json["xs"]["$value"] == %{"value" => 0.25, "unit" => "rem"}
  end

  test "number emits as a JSON number", %{json: json} do
    assert json["z"]["$value"] == 10.0
  end

  test "tokens nest under their groups", %{json: json} do
    assert get_in(json, ["color", "brand", "$type"]) == "color"
  end

  test "ref token emits $ref pointing at the original target", %{json: json} do
    assert json["primary"] == %{"$ref" => "#/color/brand"}
  end

  test "description and deprecated propagate to the JSON token", %{json: json} do
    assert json["bg"]["$description"] == "Default surface"
    assert json["bg"]["$deprecated"] == "use surface instead"
  end

  test "composite token value is a nested object", %{json: json} do
    assert json["card"]["$type"] == "shadow"
    assert json["card"]["$value"]["offset_x"] == %{"value" => 0.0, "unit" => "px"}
    assert json["card"]["$value"]["offset_y"] == %{"value" => 1.0, "unit" => "px"}
  end
end
