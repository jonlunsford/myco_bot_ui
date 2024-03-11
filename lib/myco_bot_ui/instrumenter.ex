defmodule MycoBotUi.Instrumenter do
  require Logger

  def setup do
    events = [
      [:myco_bot, :started],

      [:myco_bot, :sht30, :error],
      [:myco_bot, :sht30, :read],
      [:myco_bot, :si7021, :error],
      [:myco_bot, :si7021, :read],
      [:myco_bot, :veml7700, :error],
      [:myco_bot, :veml7700, :read],

      [:myco_bot, :gpio, :error],
      [:myco_bot, :gpio, :opened],
      [:myco_bot, :gpio, :up],
      [:myco_bot, :gpio, :down],
      [:myco_bot, :gpio, :toggle],
      [:myco_bot, :gpio, :sync],

      [:myco_bot, :environment, :sync]
    ]

    :telemetry.attach_many(
      "mycobotui-instrumenter",
      events,
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event(event, measurements, meta, _config) do
    Phoenix.PubSub.broadcast(
      MycoBotUi.PubSub,
      "mycobot-live",
      %{
        event: event,
        measurements: measurements,
        meta: meta
      }
    )

    Logger.debug("[MYCOBOTUI] event: #{inspect(event)}")
    Logger.debug("[MYCOBOTUI] measurements: #{inspect(measurements)}")
    Logger.debug("[MYCOBOTUI] meta: #{inspect(meta)}")
  end
end
