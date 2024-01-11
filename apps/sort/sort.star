"""
Applet: Sort
Summary: Show sorting algorithms
Description: Show various sorting algorithms.
Author: noahpodgurski
"""

load("random.star", "random")
load("render.star", "render")
load("time.star", "time")

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
            frames.append(render_frame_color(arr, i, j + 1, "insertion"))
            swap(arr, j, j + 1)

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
            frames.append(render_frame_color(arr, minIndex, j + 1, "insertion"))
            if arr[j] < arr[minIndex]:
                minIndex = j

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

def shellSort(arr):
    frames = []

    # Rearrange elements at each n/2, n/4, n/8, ... intervals
    interval = N // 2

    #while interval > 0:
    for _ in range(9999):
        if interval <= 0:
            break
        for i in range(interval, N):
            frames.append(render_frame_color(arr, i, i, "insertion"))
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

def render_frame_merge(arr, _i, _j, step):
    rows = [[black_pixel for c in range(WIDTH)] for r in range(HEIGHT)]

    for i in range(-1, N):
        x = arr[i]
        for y in range(HEIGHT):
            # split
            if step == 1:
                if HEIGHT - y <= x + 1:
                    if i <= _j:
                        rows[y][i * 2] = red_pixel
                        rows[y][i * 2 + 1] = red_pixel
                    else:
                        rows[y][i * 2] = white_pixel
                        rows[y][i * 2 + 1] = white_pixel

                # compare
            elif step == 2:
                if HEIGHT - y <= x + 1:
                    if i == _i:
                        rows[y][i * 2] = red_pixel
                        rows[y][i * 2 + 1] = red_pixel
                    elif i == _j:
                        rows[y][i * 2] = red_pixel
                        rows[y][i * 2 + 1] = red_pixel
                    else:
                        rows[y][i * 2] = white_pixel
                        rows[y][i * 2 + 1] = white_pixel

                # add from left stack
            elif step == 3:
                if HEIGHT - y <= x + 1:
                    if i == _i:
                        rows[y][i * 2] = green_pixel
                        rows[y][i * 2 + 1] = green_pixel
                    elif i == _j:
                        rows[y][i * 2] = red_pixel
                        rows[y][i * 2 + 1] = red_pixel
                    else:
                        rows[y][i * 2] = white_pixel
                        rows[y][i * 2 + 1] = white_pixel

                # add from right stack
            elif step == 4:
                if HEIGHT - y <= x + 1:
                    if i == _i:
                        rows[y][i * 2] = red_pixel
                        rows[y][i * 2 + 1] = red_pixel
                    elif i == _j:
                        rows[y][i * 2] = green_pixel
                        rows[y][i * 2 + 1] = green_pixel
                    else:
                        rows[y][i * 2] = white_pixel
                        rows[y][i * 2 + 1] = white_pixel

    frame = render.Column(children = [render.Row(children = row) for row in rows])
    return frame

# difficult to return rendered frames in recursive code, do merge sort in iterative/hacky way
def mergeSort(arr):
    frames = []

    # show splitting?
    # split - while j > 1
    # for _ in range(999):
    #     if j == 1:
    #         break
    #     frames.append(render_frame_merge(arr, i, j, 1))
    #     j //= 2

    for half in range(0, 17, 16):
        for quarter in range(0, 9, 8):
            #merge quarter
            newFrames = merge(arr, half + quarter, 4)
            for frame in newFrames:
                frames.append(frame)
            newFrames = merge(arr, half + quarter + 4, 4)
            for frame in newFrames:
                frames.append(frame)
            newFrames = merge(arr, half + quarter, 8)
            for frame in newFrames:
                frames.append(frame)

        #merge half
        newFrames = merge(arr, half, 16)
        for frame in newFrames:
            frames.append(frame)

    #merge all
    newFrames = merge(arr, 0, 32)
    for frame in newFrames:
        frames.append(frame)

    return frames

def merge(arr, start, size):
    frames = []
    i = start
    j = start + (size // 2)

    # compare 2 values
    if arr[i] > arr[i + 1]:
        # swap if unsorted
        swap(arr, i, i + 1)
    frames.append(render_frame_merge(arr, i, j, 2))
    if arr[j] > arr[j + 1]:
        # swap if unsorted
        swap(arr, j, j + 1)
    frames.append(render_frame_merge(arr, i, j, 2))

    newArr = []
    for x in range(999):
        #while i < size//2
        if i == start + size // 2:
            #append rest of j ->
            for __ in range(999):
                # while j < size
                if j == start + size:
                    break
                newArr.append(arr[j])
                frames.append(render_frame_merge(arr, i, j, 4))  #something here?
                j += 1
            break
        elif j == start + size:
            #append rest of i ->
            for __ in range(999):
                # while i < start+size//2
                if i == start + size // 2:
                    break
                newArr.append(arr[i])
                frames.append(render_frame_merge(arr, i, j, 3))
                i += 1
            break
            #otherwise, merge

        elif arr[i] < arr[j]:
            newArr.append(arr[i])
            frames.append(render_frame_merge(arr, i, j, 3))
            i += 1
        else:
            newArr.append(arr[j])
            frames.append(render_frame_merge(arr, i, j, 4))
            j += 1

    for x in range(start, start + size):
        arr[x] = newArr[x - start]

    return frames

def heapSort(arr):
    frames = []
    heapN = N

    for _ in range(9999):
        # while heapN > 0
        if heapN == 0:
            break

        # make max heap from bottom up non recursively
        i = 0
        for i in range(heapN // 2 - 1, -1, -1):
            left = None
            right = None
            if i * 2 + 1 < heapN:
                left = i * 2 + 1
            if i * 2 + 2 < heapN:
                right = i * 2 + 2

            if left and right:
                if arr[i] < arr[left] and arr[i] < arr[right]:
                    if arr[left] > arr[right]:
                        frames.append(render_frame_color(arr, left, i, "insertion"))
                        swap(arr, i, left)
                    else:
                        frames.append(render_frame_color(arr, right, i, "insertion"))
                        swap(arr, i, right)
                elif arr[i] < arr[left]:
                    frames.append(render_frame_color(arr, left, i, "insertion"))
                    swap(arr, i, left)
                elif arr[i] < arr[right]:
                    frames.append(render_frame_color(arr, right, i, "insertion"))
                    swap(arr, i, right)
            elif left:
                if arr[i] < arr[left]:
                    frames.append(render_frame_color(arr, left, i, "insertion"))
                    swap(arr, i, left)
            elif right:
                if arr[i] < arr[right]:
                    frames.append(render_frame_color(arr, right, i, "insertion"))
                    swap(arr, i, right)

        # pop off remove arr[0] from 'heap' and move to end
        frames.append(render_frame_color(arr, heapN, i, "insertion"))
        heapN -= 1
        swap(arr, i, heapN)

    return frames

def render_frame_quick(arr, _i, _j, _low, _pivot, _high):
    rows = [[black_pixel for c in range(WIDTH)] for r in range(HEIGHT)]

    for i in range(-1, N):
        x = arr[i]
        for y in range(HEIGHT):
            if HEIGHT - y <= x + 1:
                if i == _low:
                    rows[y][i * 2] = red_pixel
                    rows[y][i * 2 + 1] = red_pixel
                elif i == _pivot:
                    rows[y][i * 2] = green_pixel
                    rows[y][i * 2 + 1] = green_pixel
                elif i == _high:
                    rows[y][i * 2] = red_pixel
                    rows[y][i * 2 + 1] = red_pixel
                    # elif i >= _low and i <= _j:
                    #     rows[y][i * 2] = red_pixel
                    #     rows[y][i * 2 + 1] = red_pixel

                else:
                    rows[y][i * 2] = white_pixel
                    rows[y][i * 2 + 1] = white_pixel

    frame = render.Column(children = [render.Row(children = row) for row in rows])
    return frame

def partition(arr, low, high, _pivot):
    frames = []

    pivot = low

    i = low + 1
    j = 0
    for j in range(low + 1, high + 1):
        frames.append(render_frame_quick(arr, i, j, low, _pivot, high))
        if arr[j] <= arr[pivot]:
            swap(arr, i, j)
            i += 1

    # frames.append(render_frame_quick(arr, i - 1, j, low, _pivot, high))
    swap(arr, i - 1, low)
    return [i - 1, frames]

def partitionRand(arr, low, high):
    frames = []
    frames.append(render_frame_quick(arr, low, 0, low, (low + high) // 2, high))
    pivot = (low + high) // 2  #middle

    swap(arr, low, pivot)
    vals = partition(arr, low, high, pivot)
    for frame in vals[1]:
        frames.append(frame)
    vals[1] = frames
    return vals

def doQuickSort(arr, low, high):
    frames = []
    if low < high:
        values = partitionRand(arr, low, high)
        pi = values[0]
        frames += values[1]
        frames += doQuickSort(arr, low, pi - 1)
        frames += doQuickSort(arr, pi + 1, high)

    return frames

def quickSort(arr):
    return doQuickSort(arr, 0, N - 1)

sorts = [bubbleSort, insertionSort, selectionSort, radixSort, shellSort, mergeSort, heapSort, quickSort]
sortNames = ["Bubble", "Insertion", "Selection", "Radix", "Shell", "Merge", "Heap", "Quick"]

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
    # randomSortIndex = 7

    return render.Root(
        show_full_animation = True,
        # delay = REFRESH_MILLISECONDS,
        child = render.Stack(
            children = [
                animate(arr, randomSortIndex),
                render.Text(sortNames[randomSortIndex], font = "tom-thumb"),
            ],
        ),
    )
