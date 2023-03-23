<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a name="readme-top"></a>

# Earthquake Map Applet for Tidbyt

## Description
Displays global earthquake data for, up to, the last 30 days. Applet preferences allow the user to filter the display on a minimum earthquake magnitude and on different time scales. Additionally, the user can select the central meredian of the map to be on the Prime Merdian, International Date Line, or the user's home location.

![Earthquake Map for Tidbyt][app-gif]

## Event Legend

| Color                                                    | Magnitude |
|----------------------------------------------------------|-----------|
| ![#00b5b8](https://placehold.co/15x15/00b5b8/00b5b8.png) | 0         |
| ![#bf40bf](https://placehold.co/15x15/bf40bf/bf40bf.png) | 1         |
| ![#08e8de](https://placehold.co/15x15/08e8de/08e8de.png) | 2         |
| ![#0000ff](https://placehold.co/15x15/0000ff/0000ff.png) | 3         |
| ![#00ff00](https://placehold.co/15x15/00ff00/00ff00.png) | 4         |
| ![#fff000](https://placehold.co/15x15/fff000/fff000.png) | 5         |
| ![#ffaa1d](https://placehold.co/15x15/ffaa1d/ffaa1d.png) | 6         |
| ![#ff0000](https://placehold.co/15x15/ff0000/ff0000.png) | 7+        |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## About Tidbyt

Check out the [Tidybt][tidbyt-url] for an awesome information display for your home. If you are intereasted in developing for the Tidbyt, check out the [Tidbyt Developers Page][tidbyt-dev-url].

[Tidbyt][tidbyt-dev-url] has a process where a contributor forks the community development repository, creates a branch in the contributor's own fork, and then runs a pull request against their development branch. I am maintaining development in this repository and then copying code that is ready into a branch of the fork for the pull request.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- LICENSE -->
## License

Tidbyt has a specific license agreement for including an application in their community apps called the [Tidbyt Individual Contributor License Agreement][tidbyt-lic-url].

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ROADMAP -->
## Roadmap

See the [open issues][repository-issues] for a list of proposed features (and known issues).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- Built With -->
## Built With

* [Tidbyt][Tidbyt-url]
* [Tidbyt Dev/Pixlet][Tidbyt-dev-url]
* [USGS GeoJSON Feed][Usgs-feed-url]
* [Python Pillow][python-pillow-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->
## Contact

Brian McLaughlin - bjmclaughlin@gmail.com

Project Link: [https://github.com/SpinStabilized/tidbyt-earthquakemap_dev][repository-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

* The [Tidbyt Team][tidbyt-url]
* The Tidbyt [community of developers][tidbyt-community-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>

[repository-issues]: https://github.com/SpinStabilized/tidbyt-earthquakemap_dev/issues
[repository-url]: https://github.com/SpinStabilized/tidbyt-earthquakemap_dev
[python-pillow-url]: https://python-pillow.org/
[tidbyt-community-url]: https://tidbyt.dev/docs/engage/community
[tidbyt-url]: https://tidbyt.com/
[tidbyt-dev-url]: https://tidbyt.dev/
[tidbyt-lic-url]: https://github.com/tidbyt/community/blob/main/docs/CLA.md
[tidbyt-community-repo]:[https://github.com/tidbyt/community]
[usgs-feed-url]: https://earthquake.usgs.gov/earthquakes/feed/v1.0/geojson.php
[app-gif]: ./earthquake_map.gif