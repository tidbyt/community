"""
Applet: Sort
Summary: Show sorting algorithms
Description: Show various sorting algorithms.
Author: noahpodgurski
"""

load("random.star", "random")
load("render.star", "render")
load("time.star", "time")

DEFAULT_WHO = "world"

WHITE = "#ffffff"
BLACK = "#000000"
RED = "#ff0000"
GREEN = "#00ff00"
ORANGE = "#db8f00"

WIDTH = 64
HEIGHT = 32
N = 32

REFRESH_MILLISECONDS = 10

white_pixel = render.Box(
    width = 1,
    height = 1,
    color = WHITE,
)
green_pixel = render.Box(
    width = 1,
    height = 1,
    color = GREEN,
)
red_pixel = render.Box(
    width = 1,
    height = 1,
    color = RED,
)
orange_pixel = render.Box(
    width = 1,
    height = 1,
    color = ORANGE,
)
black_pixel = render.Box(
    width = 1,
    height = 1,
    color = BLACK,
)

def swap(arr, i, j):
    tmp = arr[i]
    arr[i] = arr[j]
    arr[j] = tmp

def random_shuffle(array):
    for i in range(len(array) - 1, 0, -1):
        j = random.number(0, i)
        swap(array, i, j)

def render_frame(arr):
    # cache?

    rows = [[black_pixel for c in range(WIDTH)] for r in range(HEIGHT)]

    for i in range(-1, N):
        x = arr[i]
        for y in range(HEIGHT):
            if HEIGHT - y <= x + 1:
                rows[y][i * 2] = white_pixel
                rows[y][i * 2 + 1] = white_pixel
    frame = render.Column(children = [render.Row(children = row) for row in rows])
    return frame

def render_frame_color(arr, _i, _j, type):
    # cache?
    rows = [[black_pixel for c in range(WIDTH)] for r in range(HEIGHT)]

    for i in range(-1, N):
        x = arr[i]
        for y in range(HEIGHT):
            if HEIGHT - y <= x + 1:
                if type == "bubble":
                    if i == 32 - _i:
                        rows[y][i * 2] = green_pixel
                        rows[y][i * 2 + 1] = green_pixel
                    elif i == _j:
                        rows[y][i * 2] = red_pixel
                        rows[y][i * 2 + 1] = red_pixel
                    else:
                        rows[y][i * 2] = white_pixel
                        rows[y][i * 2 + 1] = white_pixel
                elif type == "insertion":
                    if i == _i:
                        rows[y][i * 2] = green_pixel
                        rows[y][i * 2 + 1] = green_pixel
                    elif i == _j:
                        rows[y][i * 2] = red_pixel
                        rows[y][i * 2 + 1] = red_pixel
                    else:
                        rows[y][i * 2] = white_pixel
                        rows[y][i * 2 + 1] = white_pixel
                elif type == "radix":
                    if i == _i - 1:
                        rows[y][i * 2] = green_pixel
                        rows[y][i * 2 + 1] = green_pixel
                    elif i >= _i:
                        rows[y][i * 2] = red_pixel
                        rows[y][i * 2 + 1] = red_pixel
                    else:
                        rows[y][i * 2] = white_pixel
                        rows[y][i * 2 + 1] = white_pixel
    frame = render.Column(children = [render.Row(children = row) for row in rows])
    return frame

def insertionSort(arr):
    frames = []
    for i in range(1, N):
        key = arr[i]
        j = i - 1
        for j in range(i - 1, -1, -1):
            if key >= arr[j]:
                break
            swap(arr, j, j + 1)
            frames.append(render_frame_color(arr, i, j, "insertion"))

        # if j % 10 == 0:
        arr[j + 1] = key
    return frames

def bubbleSort(arr):
    frames = []
    for i in range(N):
        swapped = False
        for j in range(N - i - 1):
            if arr[j] > arr[j + 1]:
                swap(arr, j, j + 1)
                swapped = True
                frames.append(render_frame_color(arr, i, j + 1, "bubble"))
        if not swapped:
            break
    return frames

def selectionSort(arr):
    frames = []
    for i in range(N):
        minIndex = i

        for j in range(i + 1, N):
            if arr[j] < arr[minIndex]:
                minIndex = j
                frames.append(render_frame_color(arr, i, j + 1, "insertion"))

        swap(arr, i, minIndex)
    return frames

def countingSort(arr, place):
    frames = []
    output = [0] * N
    count = [0] * 10

    # Calculate count of elements
    for i in range(0, N):
        index = arr[i] // place
        count[index % 10] += 1
        # frames.append(render_frame(arr))

    # Calculate cumulative count
    for i in range(1, 10):
        count[i] += count[i - 1]

    # Place the elements in sorted order
    i = N - 1

    #while i >= 0
    for _ in range(9999):
        if i < 0:
            break
        index = arr[i] // place
        output[count[index % 10] - 1] = arr[i]
        count[index % 10] -= 1
        i -= 1

    for i in range(N):
        frames.append(render_frame_color(arr, i, i, "radix"))

        # frames.append(render_frame(arr))
        arr[i] = output[i]
    return frames

def radixSort(arr):
    frames = []

    place = 1
    for _ in range(9999):
        if N // place <= 0:
            break
        frames += countingSort(arr, place)
        place *= 10
    return frames

def bucketSort(arr):
    frames = []
    bucket = []

    # Create empty buckets
    for i in range(N):
        bucket.append([])

    # Insert elements into their respective buckets
    for i in range(N):
        # index_b = int(10 * j)
        index_b = arr[i]
        bucket[index_b].append(arr[i])
        frames.append(render_frame_color(arr, i, i, "radix"))

    # Sort the elements of each bucket
    for i in range(N):
        frames.append(render_frame_color(arr, i, i, "bubble"))
        bucket[i] = sorted(bucket[i])

    # Get the sorted elements
    k = 0
    for i in range(N):
        for j in range(len(bucket[i])):
            arr[k] = bucket[i][j]
            frames.append(render_frame_color(arr, i, i, "insertion"))
            k += 1
    return frames

def shellSort(arr):
    frames = []

    # Rearrange elements at each n/2, n/4, n/8, ... intervals
    interval = N // 2

    #while interval > 0:
    for _ in range(9999):
        if interval <= 0:
            break
        for i in range(interval, N):
            temp = arr[i]
            j = i

            #while j >= interval and arr[j - interval] > temp:
            for _ in range(9999):
                if j < interval or arr[j - interval] <= temp:
                    break
                arr[j] = arr[j - interval]
                j -= interval
                frames.append(render_frame_color(arr, i, j, "insertion"))
            arr[j] = temp
        interval //= 2
    return frames

sorts = [bubbleSort, insertionSort, selectionSort, radixSort, bucketSort, shellSort]
sortNames = ["Bubble", "Insertion", "Selection", "Radix", "Bucket", "Shell"]

def animate(arr, randomSortIndex):
    frames = []
    for _ in range(10):
        frames.append(render_frame(arr))

    frames += sorts[randomSortIndex](arr)

    # add green finish frames
    for i in range(WIDTH // 2):
        frames.append(render_frame_color(arr, i, i, "insertion"))

    for _ in range(10):
        frames.append(render_frame(arr))

    return render.Animation(children = frames)

def main():
    random.seed(time.now().unix // 15)
    arr = [x for x in range(WIDTH // 2)]
    random_shuffle(arr)

    randomSortIndex = random.number(0, len(sorts)) - 1

    return render.Root(
        # delay = REFRESH_MILLISECONDS,
        child = render.Stack(
            children = [
                animate(arr, randomSortIndex),
                render.Text(sortNames[randomSortIndex], font = "tom-thumb"),
            ],
        ),
    )
