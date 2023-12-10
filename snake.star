load("render.star", "render")
load("http.star", "http")

""" CONSTANTS """
FRAMES = 10000
WIDTH = 64
HEIGHT = 32
INITIAL_SNAKE_LENGTH = 3 
UP = (0, 1)
DOWN = (0, -1)
LEFT = (-1, 0)
RIGHT = (1, 0)
ALL_BOARD_LOCATIONS = [ (col, row) for col in range(WIDTH) for row in range(HEIGHT) ]

YELLOW = "#dde810"
GREEN = "#168a37"
RED = "#a6320f"
BLACK = "#000"

""" GLOBAL STATE """
def main():
    # Starlark does not support randomness, so we just query random.org. We don't need that many random numbers, 
    # so this should be OK. Ref: https://www.random.org/clients/http/
    def random(lower, upper):
    	response = http.get("https://www.random.org/integers/?num=1&min=%d&max=%d&col=1&base=10&format=plain&rnd=new" % (lower, upper-1))
        if response.status_code != 200:
    		fail("Cannot fetch random number, request failed with status %d", response.status_code)
    	return int(response.body().strip())

    def create_apple():
        valid_locations = [ (col, row) for (col, row) in ALL_BOARD_LOCATIONS if not (col, row) in snake_locations]
        return valid_locations[random(0, len(valid_locations))]

    def pixel(color):
        return render.Box(
            color=color,
            width=1,
            height=1,
        )

    def display():
        screen = [ [ pixel(BLACK) for _ in range(WIDTH) ] for _ in range(HEIGHT) ]
        screen[snake_locations[0][1]][snake_locations[0][0]] = pixel(YELLOW)
        screen[apple_location[1]][apple_location[0]] = pixel(RED)

        for (col, row) in snake_locations[1:]:
            screen[row][col] = pixel(GREEN)

        return render.Column(children = [ render.Row(row) for row in screen ])

    snake_direction = [ UP, DOWN, LEFT, RIGHT ][random(0, 4)]
    snake_head = random(INITIAL_SNAKE_LENGTH, WIDTH - INITIAL_SNAKE_LENGTH), random(INITIAL_SNAKE_LENGTH, HEIGHT - INITIAL_SNAKE_LENGTH)
    snake_locations = [ (snake_head[0] - i * snake_direction[0], snake_head[1] - i * snake_direction[1]) for i in range(INITIAL_SNAKE_LENGTH)]
    apple_location = create_apple()
    frames = []
    i = 0

    def step(direction):
        # Wraparound if we've hit a wall
        (head_col, head_row) = snake_locations[0]
        new_head_col = (head_col + direction[0] + WIDTH) % WIDTH
        new_head_row = (head_row + direction[1] + HEIGHT) % HEIGHT
        new_head = (new_head_col, new_head_row)
        return new_head

    def manhattan(a, b):
        return (abs(a[0] - b[0]) + abs(a[1] - b[1]))

    while i < FRAMES:
        # Tick
        new_head = step(snake_direction)
        
        # Check if apple is eaten 
        if new_head == apple_location:
            apple_location = create_apple()
            snake_locations = [ new_head ] + snake_locations
        else:
            snake_locations = [ new_head ] + snake_locations[:-1]

        # Determine whether we should turn
        next = step(snake_direction)
        best = manhattan(next, apple_location)
        for direction in [ UP, DOWN, LEFT, RIGHT ]:
            if direction == snake_direction:
                continue
            distance = manhattan(step(direction), apple_location)
            if distance < best:
                best = distance
                snake_direction = direction

        frames.append(display())
        i += 1

    return render.Root(
        delay = 20,
        child = render.Animation(
            children=frames,
        )
    )