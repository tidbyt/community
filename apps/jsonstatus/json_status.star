"""
Applet: JSON Status
Summary: Items from JSON status
Description: Retrieve one or more items from a JSON file available via a public URL and show it on your Tidbyt.
Author: wojciechka
"""

load('encoding/json.star', 'json')
load('http.star', 'http')
load('render.star', 'render')
load('cache.star', 'cache')
load('schema.star', 'schema')
load('math.star', 'math')

# display defaults and colors
C_DISPLAY_WIDTH = 64
C_ANIMATION_DELAY = 32
C_BACKGROUND = [0, 0, 0]
C_TEXT_COLOR = [255, 255, 255]

# number of animation frames
C_ANIMATION_FRAMES = 60
C_ITEM_FRAMES = 15
C_END_FRAMES = 15

# configuration for infinite (no progress information) animation
C_INFINITE_PROGRESS_PAD_FRAMES = 50
C_INFINITE_PROGRESS_PAD_SCALE = 10.0
C_INFINITE_PROGRESS_PAD_PIXELS = int(C_INFINITE_PROGRESS_PAD_FRAMES / C_INFINITE_PROGRESS_PAD_SCALE)
C_INFINITE_PROGRESS_FRAMES = C_INFINITE_PROGRESS_PAD_FRAMES * 2 - 2

C_MIN_WIDTH = 2
C_HEIGHT = 8
C_PADDING = 0

# cache timeout ins econds
C_CACHE_TTL = 60

# URL parameter and its default value
P_URL = 'url'
DEFAULT_URL = 'https://raw.githubusercontent.com/tidbyt/community/main/apps/jsonstatus/example-status.json'

# convert color specification from JSON to hex string
def to_rgb(color, combine = None, combine_level = 0.5):
  # default to white color in case of error when parsing color
  (r, g, b) = (255, 255, 255)

  if str(type(color)) == 'string':
    # parse various formats of colors as string
    if len(color) == 7:
      # color is in form of #RRGGBB
      r = int(color[1:3], 16)
      g = int(color[3:5], 16)
      b = int(color[5:7], 16)
    elif len(color) == 6:
      # color is in form of RRGGBB
      r = int(color[0:2], 16)
      g = int(color[2:4], 16)
      b = int(color[4:6], 16)
    elif len(color) == 4:
      # color is in form of #RGB
      r = int(color[1:2], 16) * 0x11
      g = int(color[2:3], 16) * 0x11
      b = int(color[3:4], 16) * 0x11
    elif len(color) == 3:
      # color is in form of RGB
      r = int(color[0:1], 16) * 0x11
      g = int(color[1:2], 16) * 0x11
      b = int(color[2:3], 16) * 0x11
  elif str(type(color)) == 'list' and len(color) == 3:
    # otherwise assume color is an array of R, G, B tuple
    r = color[0]
    g = color[1]
    b = color[2]

  if combine != None:
    combine_color = lambda v0, v1, level : min(max(int(math.round(v0 + float(v1 - v0) * float(level))), 0), 255)
    r = combine_color(r, combine[0], combine_level)
    g = combine_color(g, combine[1], combine_level)
    b = combine_color(b, combine[2], combine_level)

  return '#' + str('%x' % ((1 << 24) + (r << 16) + (g << 8) + b))[1:]

# helper to report JSON URL error as JSON that can be rendered
def json_url_error(msg):
  return {
    'items': [
      {'color': '#f88', 'label': 'JSON URL error'},
      {'color': '#fff', 'label': msg}
    ]
  }

# retrieves progress data, potentially caching it for specified TTL
def get_progress_data(config):
  url = config.str(P_URL, DEFAULT_URL)
  cache_id = 'data:' + url
  body = cache.get(cache_id)
  json_data = {}
  if body == None:
    response = http.get(url)
    # handle HTTP errors that can be detected via status code
    if response.status_code >= 400:
      return json_url_error('HTTP code: ' + str(response.status_code))

    body = response.body()

    # TODO: if possible, better validation of JSON content
    if body.strip()[0:1] != '{':
      return json_url_error('Not a valid JSON')

    cache.set(cache_id, body, ttl_seconds = C_CACHE_TTL)

  # TODO: if possible, catch decode errors and show user friendly error
  json_data = json.decode(body)
  return json_data

# render a single item's progress
def render_progress(item, config, frame_info):
  # determine padding between progress bars; defaulting to one, disabling if 4 items
  padding = 2
  if frame_info['items'] >= 4:
    padding = 0

  stack_children = [
    render.Box(width = C_DISPLAY_WIDTH, height = C_HEIGHT + padding, color = to_rgb(C_BACKGROUND))
  ]

  label = item.get('label', '')
  color = item.get('color', [255, 255, 255])

  progress_value = item.get('progress', None)
  if progress_value != None:
    # render an item with progress indicated
    progress = float(progress_value)
    progress_percent = int(math.round(progress * 100))
    if label != '':
      label += ': '
    label += str(progress_percent) + '%'

    progress_width = C_MIN_WIDTH + int(math.round(float(C_DISPLAY_WIDTH - C_MIN_WIDTH) * progress * frame_info['progress']))

    stack_children += [
      render.Box(
        width = progress_width,
        padding = 1,
        color = to_rgb(color, combine = C_BACKGROUND, combine_level = 0.6),
        height = C_HEIGHT,
        child = render.Box(
          color = to_rgb(color, combine = C_BACKGROUND, combine_level = 0.8),
        )
      )
    ]
  else:
    # render an animated item without progress specified
    position = frame_info['frame'] % C_INFINITE_PROGRESS_FRAMES
    if position >= C_INFINITE_PROGRESS_PAD_FRAMES:
      position = C_INFINITE_PROGRESS_FRAMES - position
    position = int(math.round(position / C_INFINITE_PROGRESS_PAD_SCALE))
    stack_children += [
      render.Box(
        width = C_DISPLAY_WIDTH,
        padding = 1,
        color = to_rgb(color, combine = C_BACKGROUND, combine_level = 0.6),
        height = C_HEIGHT,
        child = render.Padding(
          pad = (C_INFINITE_PROGRESS_PAD_PIXELS - position, 0, position, 0),
          color = to_rgb(color, combine = C_BACKGROUND, combine_level = 0.8),
          child=render.Box(
            color = to_rgb(color, combine = C_BACKGROUND, combine_level = 0.7)
          )
        )
      )
    ]

  # stack the progress bar with label
  stack_children += [
    render.Row(
      expanded = True,
      main_align = 'space_evenly',
      cross_align = 'center',
      children = [
        render.Text(
          content = label,
          color = to_rgb(color, combine = C_TEXT_COLOR, combine_level=0.8),
          height = C_HEIGHT,
          offset = 1,
          font = 'tom-thumb'
        )
      ]
    )
  ]

  # render the entire row
  return render.Row(
    expanded = True,
    main_align = 'space_evenly',
    cross_align = 'center',
    children = [
      render.Stack(
        children = stack_children
      )
    ]
  )

# render a single animation frame of a single item, calculating current frame for animation purposes
def render_frame_item(items, i, config, fr):
  relative_frame = max(0, min(fr - i * C_ITEM_FRAMES, C_ANIMATION_FRAMES))
  progress = math.pow(math.sin(0.5 * math.pi * relative_frame / C_ANIMATION_FRAMES), 2)
  return render_progress(items[i], config, {
    'items': len(items),
    'frame': fr,
    'progress': progress
  })

# render a single animation frame
def render_frame(data, items, config, fr):
  children = [
    render_frame_item(items, i, config, fr)
    for i in range(len(items))
  ]

  return render.Column(
    main_align = 'space_between',
    cross_align = 'center',
    children = children,
  )

def main(config):
  data = get_progress_data(config)
  items = data.get('items', [])
  # determine number of frames so any items without progress are looping properly
  frames = C_END_FRAMES + C_ANIMATION_FRAMES + C_ITEM_FRAMES * (len(items) - 1)
  frames += (C_INFINITE_PROGRESS_FRAMES - (frames % C_INFINITE_PROGRESS_FRAMES)) % C_INFINITE_PROGRESS_FRAMES
  return render.Root(
    delay = C_ANIMATION_DELAY,
    child = render.Box(
      child = render.Animation(
        children = [
          render_frame(data, items, config, fr)
          for fr in range(frames)
        ]
      )
    )
  )

def get_schema():
  return schema.Schema(
    version = '1',
    fields = [
      schema.Text(
        id = P_URL,
        name = 'JSON URL',
        desc = 'URL to JSON file with progress to show',
        icon = 'gear',
        default = DEFAULT_URL
      )
    ]
  )