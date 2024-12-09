# notify-batt - low battery notification manager

notify-batt is a project I began on Lubuntu. I was out of ideas for projects in
at the time, so I decided to create a notification manager that would trigger a
notification once the battery goes below a certain threshold.
Since then, I've switched to Ubuntu, which has a built-in low-battery
notification, so I've decided to push what I have here as a

I might finish this project in the future, but probably not.
I definitely will look at any and all pull requests, however.

This project would not be possible without [notify-send.sh].

[notify-send.sh]: https://github.com/vlevit/notify-send.sh/

## Usage

notify-batt was intended on being used as a recurring script ran by
`startup-notify-batt.sh`, which would by a return status, would know if a
notification was sent or not. I never got around to this return status handling.

Below is the help message for arguments:

    -h, --help                                  Show help message
    -i, --init                                  Initialize files
    -ic, --init-clean                           Same as init, but removes old files
    -wp=NUM, --warning-percentage=NUM           Set warning percentage (for debugging)
    -dwp=NUM, --default-warning-percentage=NUM  Set default warning percentage
    -cp=NUM, --critical-percentage=NUM          Set critical precentage (for debugging)
    -dcp=NUM, --default-critical-percentage=NUM Set critical percentage (lower than warning)
    -dwm=NUM, --default-warning-minutes=NUM     Set warning for minutes left
    -d, --dump                                  Dump all info

Some of these are incomplete, unfinished, or broken entirely.

This program was designed to work on Lubuntu, and may not work partially or at
all on other distributions.
