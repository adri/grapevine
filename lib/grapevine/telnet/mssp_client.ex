defmodule Grapevine.Telnet.MSSPClient do
  @moduledoc """
  Callbacks for specifically checking MSSP data
  """

  require Logger

  alias Grapevine.Telnet
  alias Grapevine.Telnet.MSSP
  alias Grapevine.Telnet.MSSPClient.Check
  alias Grapevine.Telnet.MSSPClient.Record
  alias Grapevine.Telnet.Options

  @behaviour Telnet.Client

  @impl true
  def init(state, opts) do
    Process.send_after(self(), {:text_mssp_request}, 10_000)
    Process.send_after(self(), {:stop}, 20_000)
    generate_state(state, opts)
  end

  defp generate_state(state, opts) do
    case opts[:type] do
      :check ->
        Check.init(opts, state)

      :record ->
        Record.init(opts, state)
    end
  end

  @impl true
  def process_option(state, {:mssp, data}) do
    maybe_forward("mssp/received", data, state)
    state.module.record_option(state, data)
    :telemetry.execute([:grapevine, :telnet, :mssp, :option, :success], 1, state)

    Logger.debug("Shutting down MSSP check", type: :mssp)

    {:stop, :normal, state}
  end

  def process_option(state, _option), do: {:noreply, state}

  @impl true
  def receive(state, data) do
    state = Map.put(state, :mssp_buffer, Map.get(state, :mssp_buffer, "") <> data)

    case Options.text_mssp?(state.mssp_buffer) do
      true ->
        record_text_mssp(state)

      false ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:text_mssp_request}, state) do
    :gen_tcp.send(state.socket, "mssp-request\n")
    :telemetry.execute([:grapevine, :telnet, :mssp, :text, :sent], 1, state)

    {:noreply, Map.put(state, :mssp_buffer, <<>>)}
  end

  def handle_info({:stop}, state) do
    maybe_forward("mssp/terminated", %{}, state)
    state.module.record_fail(state)

    Telnet.record_no_mssp(state.host, state.port)
    :telemetry.execute([:grapevine, :telnet, :mssp, :failed], 1, state)

    {:stop, :normal, state}
  end

  @doc """
  Record MSSP data sent via plain text
  """
  def record_text_mssp(state) do
    case MSSP.parse_text(state.mssp_buffer) do
      :error ->
        {:noreply, state}

      data ->
        maybe_forward("mssp/received", data, state)
        state.module.record_text(state, data)
        :telemetry.execute([:grapevine, :telnet, :mssp, :text, :success], 1, state)

        {:stop, :normal, state}
    end
  end

  defp maybe_forward(event, message, state) do
    case Map.get(state, :channel) do
      nil ->
        :ok

      channel ->
        Web.Endpoint.broadcast("mssp:#{channel}", event, message)
    end
  end

  defmodule Record do
    @moduledoc """
    Record player counts from MSSP
    """

    alias Grapevine.Games
    alias Grapevine.Statistics

    def init(opts, state) do
      connection = Keyword.get(opts, :connection)

      state
      |> Map.put(:module, __MODULE__)
      |> Map.put(:connection, connection)
      |> Map.put(:game, connection.game)
      |> Map.put(:host, connection.host)
      |> Map.put(:port, connection.port)
    end

    def record_option(state, data) do
      Games.seen_on_mssp(state.game)
      Games.connection_has_mssp(state.connection)
      maybe_set_user_agent(state, data)

      players = String.to_integer(data["PLAYERS"])
      Statistics.record_mssp_players(state.game, players, Timex.now())
    end

    def record_text(state, data) do
      record_option(state, data)
    end

    def record_fail(state) do
      Games.connection_has_no_mssp(state.connection)
    end

    defp maybe_set_user_agent(state, data) do
      case Map.get(data, "CODEBASE") do
        nil ->
          :ok

        codebase ->
          Games.record_metadata(state.game, %{user_agent: codebase})
      end
    end
  end

  defmodule Check do
    @moduledoc """
    Check MSSP for a game
    """

    alias Grapevine.Telnet

    def init(opts, state) do
      state
      |> Map.put(:module, __MODULE__)
      |> Map.put(:host, Keyword.get(opts, :host))
      |> Map.put(:port, Keyword.get(opts, :port))
      |> Map.put(:channel, Keyword.get(opts, :channel))
    end

    def record_option(state, data) do
      Telnet.record_mssp_response(state.host, state.port, data)
    end

    def record_text(state, data) do
      Telnet.record_mssp_response(state.host, state.port, data)
    end

    def record_fail(_state) do
      :ok
    end
  end
end
