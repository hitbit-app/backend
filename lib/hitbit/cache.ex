defmodule Hitbit.Cache do
  use GenServer

  @type table :: atom
  @type filename :: atom | String.t()
  @type key :: number | atom | String.t()

  @spec new_table(table) :: :ok
  def new_table(table_name) do
    GenServer.call(__MODULE__, {:new_table, table_name})
  end

  @spec all(table) :: [{key, term}]
  def all(table_name) do
    GenServer.call(__MODULE__, {:all, table_name})
  end

  @spec insert([{key, term}] | %{required(key) => term}, table) :: :ok
  def insert(id_to_docs, table_name) do
    GenServer.cast(__MODULE__, {:insert, id_to_docs, table_name})
  end

  @spec insert(key, term, table) :: :ok
  def insert(doc_id, doc, table_name) do
    insert([{doc_id, doc}], table_name)
  end

  @spec lookup(key, table) :: term
  def lookup(doc_id, table_name) do
    GenServer.call(__MODULE__, {:lookup, doc_id, table_name})
  end

  @spec member(key, table) :: boolean
  def member(doc_id, table_name) do
    GenServer.call(__MODULE__, {:member, doc_id, table_name})
  end

  def to_file(filename, table_name, mode \\ :sync)

  @spec to_file(filename, table, :sync) :: :ok | {:error, term}
  def to_file(filename, table_name, :sync) do
    GenServer.call(__MODULE__, {:to_file, filename, table_name})
  end

  @spec to_file(filename, table, :async) :: :ok
  def to_file(filename, table_name, :async) do
    GenServer.cast(__MODULE__, {:to_file, filename, table_name})
  end

  def from_file(filename, table_name, mode \\ :sync)

  @spec from_file(filename, table, :sync) :: :ok | {:error, term}
  def from_file(filename, table_name, :sync) do
    GenServer.call(__MODULE__, {:from_file, filename, table_name})
  end

  @spec from_file(filename, table, :async) :: :ok
  def from_file(filename, table_name, :async) do
    GenServer.cast(__MODULE__, {:from_file, filename, table_name})
  end

  # Callbacks

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    {:ok, %{}}
  end

  # handle_call

  def handle_call({:new_table, table_name}, _from, state) do
    tid = :ets.new(table_name, [:set, :private])

    {:reply, :ok, Map.put(state, table_name, tid)}
  end

  def handle_call({:all, table_name}, _from, state) do
    docs =
      state
      |> Map.get(table_name)
      |> :ets.tab2list()

    {:reply, docs, state}
  end

  def handle_call({:lookup, doc_id, table_name}, _from, state) do
    doc =
      state
      |> Map.get(table_name)
      |> :ets.lookup(doc_id)
      |> Enum.map(&elem(&1, 1))
      |> List.first()

    {:reply, doc, state}
  end

  def handle_call({:member, doc_id, table_name}, _from, state) do
    tid = Map.get(state, table_name)

    {:reply, :ets.member(tid, doc_id), state}
  end

  def handle_call({:to_file, table_name, filename}, _from, state) do
    tid = Map.get(state, table_name)

    {:reply, :ets.tab2file(tid, filename), state}
  end

  def handle_call({:from_file, filename, table_name}, _from, state) do
    {:ok, tid} = :ets.file2tab(filename)

    {:reply, :ok, Map.put(state, table_name, tid)}
  end

  # handle_cast

  defp do_insert(id_to_docs, tid) when is_list(id_to_docs) do
    :ets.insert(tid, id_to_docs)
  end

  defp do_insert(id_to_docs, tid) when is_map(id_to_docs) do
    id_to_docs
    |> Map.to_list()
    |> do_insert(tid)
  end

  def handle_cast({:insert, id_to_docs, table_name}, state) do
    tid = Map.get(state, table_name)

    do_insert(id_to_docs, tid)

    {:noreply, state}
  end

  def handle_cast({:to_file, filename, table_name}, state) do
    state
    |> Map.get(table_name)
    |> :ets.tab2file(filename)

    {:noreply, state}
  end

  def handle_cast({:from_file, filename, table_name}, state) do
    {:ok, tid} = :ets.file2tab(filename)

    {:noreply, Map.put(state, table_name, tid)}
  end
end
