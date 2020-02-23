defmodule FibShifter do
    use GenServer

    ## Client Side

    def start_link() do
        GenServer.start_link(__MODULE__, :default, [])
    end

    def reset(pid) do
        GenServer.call(pid, :reset)
    end

    def get(pid) do
        GenServer.call(pid, :get)
    end

    def info(pid) do
        GenServer.call(pid, :info)
    end

    def next(pid, times \\ 1) do
        cond do
            (times >= 0) -> GenServer.call(pid, {:next, times}, :infinity)
            (times < 0) -> {:error, get(pid)}
        end
    end

    def previous(pid, times \\ 1) do
        cond do
            (times >= 0) -> GenServer.call(pid, {:previous, times}, :infinity)
            (times < 0) -> {:error, get(pid)}
        end
    end

    def set(pid, new_itr) do
        cond do
            (new_itr >= 0) -> GenServer.call(pid, {:set, new_itr}, :infinity)
            (new_itr < 0) -> {:error, get(pid)}
        end
    end

    ## Server Side
    
    @default_state {0, 1, 0}

    @impl true
    def init(:default) do
        {:ok, @default_state}
    end

    @impl true
    def handle_call(:reset, _from, _state) do
        {:reply, {:ok, 0}, @default_state}
    end

    @impl true
    def handle_call(:get, _from, state) do
        {curr, _next, _itr} = state
        {:reply, curr, state}
    end

    @impl true
    def handle_call(:info, _from, state = {curr, next, itr}) do
        reply = %{curr: curr, next: next, itr: itr}
        {:reply, reply, state}
    end

    @impl true
    def handle_call({:next, times}, _from, state) do
        new_state = {curr, _next, _itr} = shift_up(state, times)
        {:reply, {:ok, curr}, new_state}
    end

    @impl true
    def handle_call({:previous, _times}, _from, {curr, _next, _itr} = @default_state) do
        {:reply, {:error, curr}, @default_state}
    end

    @impl true
    def handle_call({:previous, times}, _from, state) do
        new_state = {curr, _next, _itr} = shift_down(state, times)
        {:reply, {:ok, curr}, new_state}
    end

    @impl true
    def handle_call({:set, new_itr}, _from, state = {_curr, _next, itr}) do
        diff = itr - new_itr
        new_state = {curr, _next, _itr} = cond do
            # Performance Improvement (viewer shifts)
            (diff >= 0) and (diff >= new_itr) -> shift_up(@default_state, new_itr)
            (diff >= 0) -> shift_down(state, diff)
            (diff < 0) -> shift_up(state, diff * -1)
        end
        {:reply, {:ok, curr}, new_state}
    end

    ## Server Helper Functions
    
    def shift_up(state, 0), do: state
    def shift_up({curr, next, itr}, times) when times >= 0 do
        shift_up({next, curr + next, itr + 1}, times - 1)
    end

    def shift_down(state, 0), do: state
    def shift_down({curr, next, itr}, times) when times >= 0 do
        shift_down({next - curr, curr, itr - 1}, times - 1)
    end
end