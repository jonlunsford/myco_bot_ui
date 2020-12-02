defmodule MycoBotUiWeb.Components.Device do
  require Logger

  use MycoBotUiWeb, :live_component

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("device-change", params, socket) do
    Logger.debug("[MYCOBOTUI] device-change: #{inspect(params)}")

    value = if params["value-#{socket.assigns.pin}"] == "on", do: :up, else: :down

    Logger.debug("[MYCOBOTUI] device-change value: #{value}")

    #:telemetry.execute([:myco_bot_ui, :device, :update], %{new_value: value}, socket.assigns)

    send(self(), {:device_changed, %{socket.assigns | value: value}})

    {:noreply, socket}
  end
end
