# Sowify - Serial Over Wi-Fy 

## Project description

The purpose of this project is to facilitate the troubleshooting while working with serial signals - such as reading data from sensors. 
It eliminates the need for carrying various equipment and setting up cables in spaces with difficult access. 
The project consists of two separate parts:
1. A Raspberry Pi (aka RPi) with a MOXA uPort1150 serial-to-USB adapter - used to send the data over the network.
2. iOS mobile app that will receive the data and visualise it.
 
_(RPi Model 3B+ was used in this project but any other RPi with USB Type A port should do the job)_

The RPi will be battery powered, serial signal will be read and sent over the wi-fi to an iOS device that has the Sowify app installed on it (iPhone, iPad).
All devices must be connected to the same network(wi-fi or ad-hoc)

* Read / Write commands from / to the equipment are supported.
* The preferred interface can be selected from the Sowify mobile app and that will change the configuration of the uPort
* RS232/422/485 serial standarts can be selected
* MODBUS communication is not supported yet.

The following installation instructions apply to the mobile app - Sowify. More information about the mobile app an its usage can be found in a [separate section](https://github.com/bacataBorisov/Sowify_RPi/blob/master/README.md)

## Installation

The following installation instructions are valid for a fresh out of the box RPi. If you already have a device set-up and you are an advanced user you can ommit some of the steps.

1. Get a RPi and install Raspberry Pi OS - [How to install a Raspberry Pi OS?](https://www.raspberrypi.com/documentation/computers/getting-started.html#install-an-operating-system)
2. Install MOXA uPort 1150 Linux Drivers - the following kernels are supported by MOXA -> Kernel 6.x, 5.x, 4.x, 3.x, 2.6.x, and 2.4.x
  - [Download Drivers](https://cdn-cms.azureedge.net/getmedia/c7a1d4ee-ff6f-46fe-b707-e6e2c6fcc152/moxa-uport-1100-series-linux-kernel-6.x-driver-v6.0.tgz)
  - [Instructions for drivers installation](https://moxa.com/getmedia/a2924269-6076-4c8f-9c1e-7268e235dde1/moxa-uport-1100-series-manual-v9.0.pdf)
  - install **setserial** - `sudo apt-get install -y setserial`
  - install **pip3** - `sudo apt install python3-pip`
  - install **pyserial** - `sudo pip3 install pyserial`
3. Install and setup the Mosquitto MQTT Server on the RPi. There are different ways how to do that depending on your choice and the RPi operating system.
[I used this guide and I find it pretty well explained](https://forums.raspberrypi.com/viewtopic.php?t=196010)

## Usage

### **NB!** Check the configuration file of the MQTT server before starting it.

In order to make the server for public use you have to specify listener.
The following two lines of code need to be added to a custom configuration file: /etc/mosquitto/**filename**.conf, where
“filename” is the name of the file given by you:

```
#specify listener and port
listener 1883
#auth method
allow_anonymous true
```

If you want to set additional authentication method, you can check the documents here:
https://mosquitto.org/documentation/authentication-methods/

Start the server using the new configuration:
`sudo mosquito -v -c filename.conf`

- Download and save the mediator.py and sowify_client.py on the RPi (typically your home directory)
- make them executable `chmod +x sowify_client.py && chmod +x mediator.py`
- Start both scripts - `./sowify_client && ./mediator.py &`

With those steps completed you can now go to the [Sowify-iOS App Section](https://github.com/bacataBorisov/Sowify-iOS-App) and follow the instructions how to use the app and start seeing some serial data (make sure you have the uPort 1150 plugged in and a serial data source, otherwise you will get the relevant warning messages in the app)

### **TIP:** You can have your scripts running on start-up using some of the following methods [described in this link](https://www.dexterindustries.com/howto/run-a-program-on-your-raspberry-pi-at-startup/)

The "mediator.py" is solely responsible for rebooting and shutting down the RPi if anything goes wrong with the "sowify_client.py" or if you just want to reboot / power off your device remotely.

### **NOTE:** If you want to use the logging function, logs folder needs to be created individually by modifying the following line in the sowify_client.py
logging.basicConfig(filename=f"**your-log-dir-name-goes-here**/{log_timestamp}.log"

## **License**

Project Title is released under the MIT License. See the **[LICENSE](https://github.com/bacataBorisov/Sowify_RPi/blob/master/LICENSE.txt)** file for details.

## **Authors and Acknowledgment**

Sowify was created by **[Vasil Borisov](https://github.com/bacataBorisov)**.

Following resources have been used while developing project
- [PySerial](https://pypi.org/project/pyserial/)
- [MQTT](https://mqtt.org)
- [setserial](https://github.com/Distrotech/setserial)

## **Changelog**

- **0.1.0:** Initial release

## **Contact**

If you have any questions or comments about Sowify, please contact **[bacata.borisov](vasil.borisovv@gmail.com)**.


