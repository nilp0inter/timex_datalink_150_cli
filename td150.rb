require "timex_datalink_client"
require "json"
require "time"
require "optparse"

require "timex_datalink_client/helpers/crc_packets_wrapper"


class TimexDatalinkClient
  class Protocol3
    class Beep
      prepend Helpers::CrcPacketsWrapper
      def packets
        [ [0x23, 0x04, 0x3e, 0xa6, 0x01, 0xc7, 0x00, 0x28, 0x81] ]
      end
    end
  end
end

# Function to parse the JSON data
def parse_json_data(file_path)
  return {} unless file_path && File.exist?(file_path)

  file = File.read(file_path)
  JSON.parse(file)
rescue JSON::ParserError
  {}
end

# Function to parse command line options
def parse_options
  options = {
    sound_theme: nil,
    wrist_app: nil,
    serial_device: "/dev/ttyACM0",
    verbose: false,
    no_appointments: false,
    no_anniversaries: false,
    no_phone_numbers: false,
    no_lists: false,
    no_alarms: false,
    no_time: false,
    sync_length: 150,
    start_beep: false,
  }

  OptionParser.new do |opts|
    opts.banner = "Usage: timex.rb [options] [JSON_FILE]"

    opts.on("--sound-theme SPC_FILE", "Specify a sound theme SPC file") do |spc_file|
      options[:sound_theme] = spc_file
    end

    opts.on("--wrist-app ZAP_FILE", "Specify a wrist app ZAP file") do |zap_file|
      options[:wrist_app] = zap_file
    end

    opts.on("--serial-device DEVICE", "Specify a serial device (default: /dev/ttyACM0)") do |device|
      options[:serial_device] = device
    end

    opts.on("--verbose", "Enable verbose mode") do
      options[:verbose] = true
    end

    opts.on("--no-appointments", "Skip creating appointments") do
      options[:no_appointments] = true
    end

    opts.on("--no-anniversaries", "Skip creating anniversaries") do
      options[:no_anniversaries] = true
    end

    opts.on("--no-phone-numbers", "Skip creating phone numbers") do
      options[:no_phone_numbers] = true
    end

    opts.on("--no-lists", "Skip creating lists") do
      options[:no_lists] = true
    end

    opts.on("--no-alarms", "Skip creating alarms") do
      options[:no_alarms] = true
    end

    opts.on("--no-time", "Skip creating time models") do
      options[:no_time] = true
    end

    opts.on("--sync-length LENGTH", Integer, "Specify the sync length (default: 150)") do |length|
      options[:sync_length] = length
    end

    opts.on("--start-beep", "Send a start beep") do
      options[:start_beep] = true
    end
  end.parse!

  options[:json_file] = ARGV[0] # The remaining argument should be the JSON file, if provided

  options
end

options = parse_options

# Read data from JSON file or use empty data if file is not provided
data = parse_json_data(options[:json_file])

# Create appointments
appointments = []
if data["appointments"] && !options[:no_appointments]
  appointments = data["appointments"].map do |appointment|
    TimexDatalinkClient::Protocol3::Eeprom::Appointment.new(
      time: Time.parse(appointment["time"]),
      message: appointment["message"]
    )
  end
end

# Create anniversaries
anniversaries = []
if data["anniversaries"] && !options[:no_anniversaries]
  anniversaries = data["anniversaries"].map do |anniversary|
    TimexDatalinkClient::Protocol3::Eeprom::Anniversary.new(
      time: Time.parse(anniversary["time"]),
      anniversary: anniversary["anniversary"]
    )
  end
end

# Create phone numbers
phone_numbers = []
if data["phone_numbers"] && !options[:no_phone_numbers]
  phone_numbers = data["phone_numbers"].map do |phone_number|
    TimexDatalinkClient::Protocol3::Eeprom::PhoneNumber.new(
      name: phone_number["name"],
      number: phone_number["number"],
      type: phone_number["type"]
    )
  end
end

# Create lists
lists = []
if data["lists"] && !options[:no_lists]
  lists = data["lists"].map do |list|
    TimexDatalinkClient::Protocol3::Eeprom::List.new(
      list_entry: list["list_entry"],
      priority: list["priority"]
    )
  end
end

# Create time models
time_models = []
if !options[:no_time]
  time1 = Time.now
  time2 = time1.dup.utc

  time_models = [
    TimexDatalinkClient::Protocol3::Time.new(
      zone: 1,
      time: time1,
      is_24h: true,
      date_format: "%_d-%m-%y"
    ),
    TimexDatalinkClient::Protocol3::Time.new(
      zone: 2,
      time: time2,
      is_24h: true,
      date_format: "%y-%m-%d"
    ),
  ]
end

# Create alarms
alarms = []
if data["alarms"] && !options[:no_alarms]
  alarms = data["alarms"].map do |alarm|
    TimexDatalinkClient::Protocol3::Alarm.new(
      number: alarm["number"],
      audible: alarm["audible"],
      time: Time.new(0, 1, 1, alarm["hour"], alarm["minute"]),
      message: alarm["message"]
    )
  end
end

# SoundOptions and Appointment Notification Minutes
sound_options_data = data["sound_options"] || {}
sound_options = if sound_options_data.empty?
                   nil
                 else
                   TimexDatalinkClient::Protocol3::SoundOptions.new(
                     hourly_chime: sound_options_data.fetch("hourly_chime", false),
                     button_beep: sound_options_data.fetch("button_beep", false)
                   )
                 end
appointment_notification_minutes = data["appointment_notification_minutes"] || 0

# Send a start beep
start_beep = []
if options[:start_beep]
  start_beep = [TimexDatalinkClient::Protocol3::Beep.new]
end

models = [
  TimexDatalinkClient::Protocol3::Sync.new(length: options[:sync_length]),
  TimexDatalinkClient::Protocol3::Start.new,
] + start_beep + time_models + alarms

models << TimexDatalinkClient::Protocol3::Eeprom.new(
  appointments: appointments,
  anniversaries: anniversaries,
  lists: lists,
  phone_numbers: phone_numbers,
  appointment_notification_minutes: appointment_notification_minutes
) unless appointments.empty? && anniversaries.empty? && lists.empty? && phone_numbers.empty?

# Optional Sound Theme
if options[:sound_theme]
  models << TimexDatalinkClient::Protocol3::SoundTheme.new(spc_file: options[:sound_theme])
end

# Optional Wrist Apps
if options[:wrist_app]
  models << TimexDatalinkClient::Protocol3::WristApp.new(zap_file: options[:wrist_app])
end

models << sound_options if sound_options
models << TimexDatalinkClient::Protocol3::End.new

timex_datalink_client = TimexDatalinkClient.new(
  serial_device: options[:serial_device],
  models: models,
  verbose: options[:verbose]
)

timex_datalink_client.write
