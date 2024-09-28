"""
Applet: Git Commit Humor
Summary: Displays funny Git commits
Description: Displays humorous Github Commits in a scrolling fashion using the whatthecommit API. The app will rotate through fonts and color based on commit text length.
Author: Zach Schmidt
"""

load("http.star", "http")
load("random.star", "random")
load("render.star", "render")

# List of font styles and colors
fonts = ["5x8", "6x13", "tom-thumb"]  # Sorted by size: largest to smallest
colors = ["#099", "#65d0e6", "#f00", "#0f0", "#00f"]

def main():
    # Fetch commit message with caching for 1 hour
    resp = http.get("https://whatthecommit.com/index.txt", ttl_seconds = 3600)
    commit_message = resp.body().strip()

    # Randomly select a color
    selected_color = colors[random.number(0, len(colors) - 1)]

    # Dynamically select font size based on text length
    if len(commit_message) > 50:
        selected_font = fonts[2]  # Smallest font for long messages
    elif len(commit_message) > 20:
        selected_font = fonts[1]  # Medium font for medium-length messages
    else:
        selected_font = fonts[0]  # Largest font for short messages

    # Add padding to the message for centering effect
    padded_message = " " + commit_message + " "

    # Layout for the scrolling text, centered within the available space
    return render.Root(
        child = render.Box(
            width = 64,
            height = 30,
            child = render.Marquee(
                # Add scrolling text
                width = 64,  # Adjust width for scrolling
                child = render.Text(
                    content = padded_message,
                    font = selected_font,
                    color = selected_color,
                ),
            ),
        ),
    )
