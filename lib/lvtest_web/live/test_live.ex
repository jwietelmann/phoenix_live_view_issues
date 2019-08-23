defmodule LvtestWeb.Node do
  alias LvtestWeb.Node

  defstruct id: nil, counter: 0

  def new(id), do: %Node{id: id}
end

defmodule LvtestWeb.Nodes do
  alias LvtestWeb.Node

  @ets_table_name :nodes

  def create(id) do
    node = Node.new(id)
    put(node)
  end

  def get(id) do
    [{_, node}] = :ets.lookup(@ets_table_name, id)
    node
  end

  def put(%Node{id: id} = node) do
    try do
      :ets.new(@ets_table_name, [:named_table, :public])
    rescue _ ->
      nil
    end

    :ets.insert(@ets_table_name, {id, node})

    publish(node)
  end

  def increment(id) do
    node = get(id)
    put(%{node | counter: node.counter + 1})
  end

  def list_all() do
    :ets.tab2list(@ets_table_name)
    |> Enum.map(fn {_, v} -> v end)
    |> Enum.sort_by(&(&1.counter))
  end

  @pubsub_server Lvtest.PubSub

  def topic(%Node{id: id}), do: topic(id)
  def topic(id), do: "nodes/#{id}"

  def publish(%Node{} = node) do
    Phoenix.PubSub.broadcast(@pubsub_server, topic(node), node)
    Phoenix.PubSub.broadcast(@pubsub_server, topic(:all), node)
  end

  def subscribe(x) do
    Phoenix.PubSub.subscribe(@pubsub_server, topic(x))
  end
end

defmodule LvtestWeb.TestLive do
  use Phoenix.LiveView
  alias LvtestWeb.{Nodes, Node}

  def render(assigns) do
    ~L"""
    <ul>
      <%= for node_id <- @node_ids do %>
        <%= Phoenix.LiveView.live_render(@socket, LvtestWeb.NodeLive, child_id: node_id, session: %{node_id: node_id}) %>
      <% end %>
    </ul>
    """
  end

  def mount(session, socket) do
    Nodes.create(1)
    Nodes.create(2)

    if connected?(socket), do: Nodes.subscribe(:all)

    {:ok, update_node_ids(socket)}
  end

  defp update_node_ids(socket) do
    node_ids =
      Nodes.list_all()
      |> Enum.map(&(&1.id))

    assign(socket, node_ids: node_ids)
  end

  def handle_info(%Node{}, socket) do
    {:noreply, update_node_ids(socket)}
  end
end

defmodule LvtestWeb.NodeLive do
  use Phoenix.LiveView
  use Phoenix.HTML
  alias LvtestWeb.{Nodes, Node}

  def render(%{node: node} = assigns) do
    # IO.inspect(assigns) # WHY DOES THIS MAKE A JS ERROR HAPPEN WHEN THE NODES SWITCH ORDER???
    ~L"""
    <li>
      <span>id: <%= @node.id %></span>,
      <span>counter: <%= @node.counter %></span>,
      <span><%= link "++", to: "#", phx_click: "inc", phx_value: @node.id %></span>
    </li>
    """
  end

  def mount(%{node_id: node_id} = session, socket) do
    if connected?(socket), do: Nodes.subscribe(node_id)
    {:ok, assign(socket, node: Nodes.get(node_id))}
  end

  def handle_info(%Node{id: update_id} = node, %{assigns: %{node: %{id: my_id}}} = socket) when my_id == update_id do
    {:noreply, assign(socket, node: node)}
  end

  def handle_info(%Node{}, socket), do: {:noreply, socket}

  defp to_int(id_string) do
    {id, _} = Integer.parse(id_string)
    id
  end

  def handle_event("inc", id_string, socket) do
    id_string
    |> to_int()
    |> Nodes.increment()

    {:noreply, socket}
  end
end
