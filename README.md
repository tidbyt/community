# Community Apps
![Main Workflow](https://github.com/tidbyt/community/actions/workflows/main.yml/badge.svg)

Community Apps is a publishing platform for apps developed by the [Tidbyt community][3] 🚀 

This repo is for publishing apps to all Tidbyt users. Interested in developing apps? Check out [Pixlet][2] and follow the [Hello, World!][4] tutorial. When your app is ready to publish, follow our guide below.

![Banner Image](docs/assets/banner.jpg)

📸  [Fuzzy Clock](apps/fuzzyclock/fuzzy_clock.star) by [Max Timkovich][5], photographed  by [Tidbyt][1].

## ⚠️⚠️⚠️ BETA Notice ⚠️⚠️⚠️
Hello! If you're reading this, we've invited you to check out this repo and would _love_ if you add your apps here and **provide feedback** for how it goes through a GitHub issue on the repo. We plan to make this repo public for all in the next week or so, but we wanted to work out a few kinks before we did.

The biggest gotcha is the `get_schema` method inside of the applet. Schema is how we populate the config values from the mobile app. We know we need to open source our schema but it's going to take a few more days to do so. To get around that in the short term, leave the method to return an empty list and we'll follow up with a PR to populate it.

One thing you should note - there is a special config value of `$tz` that we populate from the location of the device. To use it, do the following:

```starlark
DEFAULT_TIME_ZONE = "America/New_York"

def main(config):
    tz = config.get("$tz", DEFAULT_TIME_ZONE)
    now = time.now().in_location(tz)
```

The final note, we may have to do a few refactors so please bear with us until we make this repo public 😅

## Quick Start
You should really read our [contributions guide](docs/CONTRIBUTING.md), our guide on [Publishing Apps](docs/guides/publishing_apps.md), and the section below before diving in. But if you just want to go for it, run the following to generate all the code you need:
```
make app
```

## Contributing Changes
First off, we're over the moon that you're here and want to share what you've been working on with the broader Tidbyt user base 🎉.

For all contributions, please see our [contributions guide](docs/CONTRIBUTING.md) for our
code of conduct, policies, and legal info.

**Do you want to publish an app?**
- Wahoo! Check out our guide on [Publishing Apps](docs/guides/publishing_apps.md)!

**Did you find a bug?**
- Do **not** open up a GitHub issue if the bug is a security vulnerability, and instead to refer to our [security policy](docs/SECURITY.md).
- Ensure the bug was not already reported by searching on GitHub under [Issues](https://github.com/tidbyt/community/issues).
- If you have not found an issue, please [create an issue](https://github.com/tidbyt/community/issues/new).

**Did you write a patch that fixes a bug?**
- Thank you!! 🙏 please submit a pull request.

**Do you intend to add a new feature or change an existing one?**
- Check out our guide on [modifying apps](docs/guides/modifying_apps.md) before you make a pull request.

## Thanks
Thanks so much for your interest in contributing to Community Apps. We deeply value contributions of any size. It takes an army to support the deeply specialized use cases of the Tidbyt community and we can't thank you enough.

Rohan, Mats, and Mark @ Tidbyt ❤️

[1]: https://tidbyt.com
[2]: https://github.com/tidbyt/pixlet
[3]: https://discuss.tidbyt.com/
[4]: https://github.com/tidbyt/pixlet#hello-world
[5]: https://github.com/mtimkovich
