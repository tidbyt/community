# Copyright 2023 Google LLC

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""
Applet: Stop Hitting Mets
Summary: Dashboard for Mets HBP
Description: Answers "Can we please stop hitting the Mets?" using canweplease.stophittingthemets.info data.
Author: ahedberg
"""

load("http.star", "http")
load("render.star", "render")

def main():
    response = http.get("https://canweplease.stophittingthemets.info/tidbyt")
    if response.status_code != 200:
        fail("Can We Please Stop Hitting The Mets request failed with status %d", response.status_code)

    answer = response.body().removesuffix("\n")
    return render.Root(
        child = render.Box(
            color = "#002D72",
            child = render.Column(
                children = [
                    render.WrappedText(
                        content = "Can we please stop hitting the Mets?",
                        font = "tom-thumb",
                        align = "center",
                        color = "#FF5910",
                    ),
                    render.Text(
                        content = answer,
                        font = "6x13",
                        offset = 1,
                    ),
                ],
                cross_align = "center",
            ),
        ),
    )
