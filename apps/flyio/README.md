# Fly.io for Tidbyt

Displays the current status of the machines running on your [Fly.io Apps](https://fly.io/)

## Set up

1. Create a Fly.io API Key with: `fly tokens create readonly`
2. Include everything in the key, including the `FlyV1` at the beginning
3. Enter the name of your app, found on your Fly.io Dashboard

## Usage

This app will try to display all of the machines for the App you configure and a status indicator for them.

The machine names will be animated from right to left if there is overflow.

Right now all statuses [defined by Fly.io](https://fly.io/docs/machines/machine-states/) are supported:

> | Color | Status     | Description                                                            |
> | ----- | ---------- | ---------------------------------------------------------------------- |
> | 🔵    | created    | Initial status                                                         |
> | 🟡    | starting   | Transitioning from stopped or suspended to started                     |
> | 🟢    | started    | Running and network-accessible                                         |
> | 🟡    | stopping   | Transitioning from started to stopped                                  |
> | ⚪    | stopped    | Exited, either on its own or explicitly stopped                        |
> | 🟡    | suspending | Transitioning from started to suspended                                |
> | ⚪    | suspended  | Suspended to disk; will attempt to resume on next start                |
> | 🟡    | replacing  | User-initiated configuration change (image, VM size, etc.) in progress |
> | 🔴    | destroying | User asked for the Machine to be completely removed                    |
> | 🔴    | destroyed  | No longer exists                                                       |

## Examples

### Machines in Started/Starting states

![Started/Starting](screenshots/started-starting.png)

### Machines in Stopped/Destroyed states

![Stopped/Destroyed](screenshots/stopped-destroyed.png)

### No Machines were found

![No Machines](screenshots/no-machines.png)

### Error occured when fetching

![Error Fetching](screenshots/error.png)
