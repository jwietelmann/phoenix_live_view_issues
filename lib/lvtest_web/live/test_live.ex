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
    |> Enum.sort(fn a, b ->
      if a.counter == b.counter do
        a.id <= b.id
      else
        a.counter < b.counter
      end
    end)
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
  use Phoenix.HTML
  alias LvtestWeb.{Nodes, Node}

  def render(assigns) do
    ~L"""
    <h2>Challenges with LiveView and lists</h2>
    <p>
      In the example below, the parent LiveView contains a list of Node IDs, ordered by the Nodes' counters.
      It contains child LiveViews that fetch and render their respective Nodes.
    </p>
    <p>
      Incrementing a Node's counter can cause this order to change.
      Whenever the order changes, the list of IDs updates.
      Whenever the list of IDs updates, <em>every single child view gets re-mounted and fully re-rendered</em>.
    </p>
    <p>
      The more child views in the list, and the larger the HTML they render, the bigger the problem becomes.
    </p>
    <p>
      <%= link "nodes++", to: "#", phx_click: "create", phx_value: Enum.count(@node_ids) + 1 %>
    </p>
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

  def handle_event("create", id_string, socket) do
    {id, _} = Integer.parse(id_string)
    Nodes.create(id)

    {:noreply, socket}
  end
end

defmodule LvtestWeb.NodeLive do
  use Phoenix.LiveView
  use Phoenix.HTML
  alias LvtestWeb.{Nodes, Node}

  def render(%{node: node} = assigns) do
    # IO.inspect(assigns) # WHY DOES THIS MAKE A JS ERROR HAPPEN WHEN THE NODES SWITCH ORDER???
    ~L"""
    <li id="node-<%= @node.id %>">
      <span>id: <%= @node.id %></span>,
      <span>counter: <%= @node.counter %></span>,
      <span>just_mounted?: <%= assigns[:just_mounted?] || false %></span>,
      <span><%= link "counter++", to: "#", phx_click: "inc", phx_value: @node.id %></span>
    </li>
    """
  end

  def mount(%{node_id: node_id} = session, socket) do
    if connected?(socket), do: Nodes.subscribe(node_id)

    socket =
      socket
      |> assign(just_mounted?: true, node: Nodes.get(node_id))
      |> configure_temporary_assigns([:just_mounted?])

    {:ok, socket}
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
