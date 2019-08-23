defmodule LvtestWeb.PageView do
  use LvtestWeb, :view
  import Phoenix.LiveView, only: [sigil_L: 2]

  defdelegate live_content_tag(a, b), to: LvtestWeb.HTML.Tag, as: :content_tag
  defdelegate live_content_tag(a, b, c), to: LvtestWeb.HTML.Tag, as: :content_tag

  def render_count_from_eex_sigil(count) do
    ~E"""
    <div>Count from function using EEx sigil: <span><%= count %></span></div>
    """
  end

  def render_count_from_live_leex_sigil(count) do
    assigns = %{}
    ~L"""
    <div>Count from function using LEEx sigil: <span><%= count %></span></div>
    """
  end

  def test_class(name, count) do
    "#{name}#{count}"
  end

  defmacro inline_tag(name, do: block) when is_atom(name) do
    quote do
      unquote(block)
    end
  end

  defmacro sneaky(do: block) do
    IO.inspect(block)
    quote do
      unquote(block)
    end
  end

  def why(name, do: block) do
    assigns = %{name: name, block: block}
    ~L"""
    <<%= @name %>><%= @block %></<%= @name %>>
    """
  end
end
