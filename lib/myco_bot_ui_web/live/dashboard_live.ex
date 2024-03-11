defmodule MycoBotUiWeb.DashboardLive do
  require Logger
  use MycoBotUiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MycoBotUi.PubSub, "mycobot-live", link: true)
      :telemetry.execute([:myco_bot_ui, :dashboard, :mounted], %{}, %{})
    end

    {:ok,
     assign(socket,
       page_title: "Grow Tent",
       temperature: 0.0,
       humidity: 0.0,
       lux: 0.0,
       white_level: 0.0,
       error: nil,
       refreshing_devices: false,
       environment: %{foo: 1},
       devices: []
     )}
  end

  @impl true
  def handle_info(:update_chart, socket) do
    time = DateTime.utc_now()

    points = %{
      humidity: socket.assigns.humidity,
      temperature: socket.assigns.temperature,
      timestamp: "#{time.minute}:#{time.second}"
    }

    {:noreply, socket |> push_event("data-updated", points)}
  end

  @impl true
  def handle_info(%{event: [:myco_bot, resource, :error]} = payload, socket) do
    Logger.debug("[MYCOBOTUI] #{inspect(payload)}")

    {:noreply, assign(socket, :error, "#{resource} error: #{payload.meta.error}")}
  end

  @impl true
  def handle_info(%{event: [:myco_bot, _sensor, :read]} = payload, socket) do
    Logger.debug("[MYCOBOTUI] #{inspect(payload)}")

    schedule_chart_update()

    {:noreply,
     assign(socket, %{
       temperature: payload.measurements.temperature,
       humidity: payload.measurements.humidity,
       error: nil
     })}
  end

  @impl true
  def handle_info(%{event: [:myco_bot, :veml7700, :read]} = payload, socket) do
    Logger.debug("[MYCOBOTUI] #{inspect(payload)}")

    {:noreply,
     assign(socket, %{
       lux: payload.measurements.lux,
       white_level: payload.measurements.white,
       error: nil
     })}
  end

  @impl true
  def handle_info(%{event: [:myco_bot, :environment, :sync]} = payload, socket) do
    Logger.debug("[MYCOBOTUI] #{inspect(payload)}")

    {:noreply, assign(socket, :environment, payload.meta.config)}
  end

  @impl true
  def handle_info(%{event: [:myco_bot, :gpio, :sync]} = payload, socket) do
    Logger.debug("[MYCOBOTUI] #{inspect(payload)}")

    {:noreply, assign(socket, %{devices: payload.meta.devices, refreshing_devices: false})}
  end

  @impl true
  def handle_info(%{event: [:myco_bot, :gpio, :up]} = payload, socket) do
    Logger.debug("[MYCOBOTUI] #{inspect(payload)}")

    device = payload.meta

    {:noreply, assign(socket, :devices, update_devices(device, socket))}
  end

  @impl true
  def handle_info(%{event: [:myco_bot, :gpio, :down]} = payload, socket) do
    Logger.debug("[MYCOBOTUI] #{inspect(payload)}")

    device = payload.meta

    {:noreply, assign(socket, :devices, update_devices(device, socket))}
  end

  @impl true
  def handle_info(%{event: [:myco_bot, :gpio, :toggle]} = payload, socket) do
    Logger.debug("[MYCOBOTUI] #{inspect(payload)}")

    device = payload.meta

    {:noreply, assign(socket, :devices, update_devices(device, socket))}
  end

  @impl true
  def handle_info({:device_changed, device}, socket) do
    :telemetry.execute(
      [:myco_bot_ui, :device, :change],
      %{},
      Map.take(device, [:pin, :direction, :value, :type, :status])
    )

    {:noreply, assign(socket, :devices, update_devices(device, socket))}
  end

  @impl true
  def handle_info(payload, socket) do
    Logger.debug("[MYCOBOTUI] unhandled info: #{inspect(payload)}")

    {:noreply, assign(socket, :results, payload)}
  end

  @impl true
  def handle_event("refresh-devices", _params, socket) do
    Logger.debug("[MYCOBOTUI] requesting refresh devices")

    :telemetry.execute([:myco_bot_ui, :device, :refresh], %{}, %{})

    {:noreply, assign(socket, :refreshing_devices, true)}
  end

  @impl true
  def handle_event("environment-change", %{"_target" => [attr]} = params, socket) do
    Logger.debug("[MYCOBOTUI] requesting environment update for #{attr} to #{params[attr]}")

    key = String.to_atom(attr)

    value =
      case Integer.parse(params[attr]) do
        :error -> nil
        {integer, _rest} -> integer
      end

    :telemetry.execute([:myco_bot_ui, :environment, :change], %{}, %{key: key, value: value})

    {:noreply, socket}
  end

  @impl true
  def handle_event(event, params, socket) do
    Logger.warn("No event handler for: #{event}")
    Logger.debug("#{inspect(params)}")
    {:noreply, socket}
  end

  defp update_devices(device, socket) do
    devices = socket.assigns.devices
    index = Enum.find_index(devices, fn d -> d.pin == device.pin end)
    List.replace_at(devices, index, device)
  end

  defp schedule_chart_update, do: self() |> Process.send_after(:update_chart, 1000)
end
