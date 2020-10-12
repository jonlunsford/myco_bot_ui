defmodule MycoBotUiWeb.Components.Humidifier do
  use MycoBotUiWeb, :live_component

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("device-change", %{"value" => state} = _params, socket) do
    value = if state == "on", do: 1, else: 0

    :telemetry.execute([:myco_bot_ui, :device, :update], %{new_value: value}, socket.assigns)

    send(self(), {:device_changed, %{socket.assigns | value: value}})

    {:noreply, socket}
  end

  @impl true
  def handle_event("device-change", %{"setting" => value} = _params, socket) do
    {int, _other} = Integer.parse(value)

    int = if int >= 100, do: 100, else: int
    int = if int < 0, do: 0, else: int

    :telemetry.execute([:myco_bot_ui, :device, :update], %{new_setting: int}, socket.assigns)

    send(self(), {:device_changed, %{socket.assigns | setting: int}})

    {:noreply, socket}
  end
end
