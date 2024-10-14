# Sowify - Serial Over Wi-Fy 

## Project description

This project aims to facilitate troubleshooting by eliminating the need for additional equipment and complex setups. It consists of two main components:

1. Raspberry Pi (RPi):

- Equipped with a MOXA uPort1150 for serial communication.
- Can use any RPi model having USB Type A (Model 3B+ used in this project).
- Battery-powered with serial signal conversion.

2. iOS Mobile App:

- Receives serial data sent by the RPi over Wi-Fi using an MQTT server.
- Devices must be on the same network (Wi-Fi or Ethernet).

### Features:

- Read/Write commands to/from equipment.
- Select preferred interface via Sowify app.
- Support for RS232/422/485 serial standards.
- MODBUS communication support (not yet implemented).

The following installation instructions apply to the mobile app - Sowify. 

More information about the Raspberry Pi setup an its usage can be found in a [separate section](https://github.com/bacataBorisov/Sowify_RPi/blob/master/README.md)

## Installation

1. Clone the repository in Xcode.
2. Build and run the app on a simulator or a real device.

### Note: The app is still in development and requires an Apple developer account. It can be used for 7 days with a free account or for 1 year with a paid developer subscription.

## Usage

Once all devices are connected to the same network, the app will automatically connect and display data.

*Operator panel*


<img width="400" alt="Screenshot 2024-10-13 at 9 56 58" src="https://github.com/user-attachments/assets/0ddd1e38-0d95-44da-bba4-5d9223da0708">

- Tap "IOIOI" button to select the serial interface type and mode
- Tap "Play / Pause" button to start the communication - you should be able to see the serial data. 
If everything is normal and connection has been established, the status bar shows the current configuration.

*Status Bar*


<img width="400" alt="status_bar" src="https://github.com/user-attachments/assets/00c7c804-dae5-4fdf-b179-4c2736b4a39e">

The app will update its status bar on top with the relevant warning message in case there are any. 

<img width="400" alt="warning_message" src="https://github.com/user-attachments/assets/6a1abb05-d067-4a3d-90ca-f0601224cf9c">

- "x" button clears the screen
- Last two buttons reboot or power off the Raspberry Pi. 
If you have your scripts configured to run on start-up, once the RPi has boot it will connect automatically to the app. 
Otherwise, you may need to start MQTT server, sowify_clien.py and mediator.py manually

### TIP: To add the scripts to run on start-up you can refer to that [article](https://www.dexterindustries.com/howto/run-a-program-on-your-raspberry-pi-at-startup/)

*Reading Serial Data (example of reading NMEA data from a GILL Windsonic wind sensor)*

<img width="400" alt="serial_data" src="https://github.com/user-attachments/assets/eaef1f76-b3b3-4c91-8b0c-fb2da812e22a">

*Send Write Command Terminal*

<img width="400" alt="terminal" src="https://github.com/user-attachments/assets/f731ad33-8fb4-4e16-be12-ad0c0752e085">

- terminal provides the option to send write command to the sensor or serial device attached to the RPi. 
Refer to its own datasheet and familiarize yourself with available commands (device dependable).

## **License**

Sowify is released under the MIT License. See the **[LICENSE](https://github.com/bacataBorisov/Sowify/blob/main/LICENSE)** file for details.

## **Authors and Acknowledgment**

Sowify was created by **[Vasil Borisov](https://github.com/bacataBorisov)**.

Following resources have been used while developing project
- [CocoaMQTT](https://cocoapods.org/pods/CocoaMQTT)
- [IQKeyboardManagerSwift](https://cocoapods.org/pods/IQKeyboardManagerSwift)
- [SwftTooltipKit](https://github.com/hendesi/SwiftTooltipKit)
- Various articles from StackOverflow, Github and others

## **Changelog**

- **1.0.0:** Initial release

## **Contact**

If you have any questions or comments about Sowify, please contact **[bacata.borisov](https://github.com/bacataBorisov)**.
Open to suggestions for improvement, new features, or collaborations.


