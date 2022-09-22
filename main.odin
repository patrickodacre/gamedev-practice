package main

import "core:fmt"
import SDL "vendor:sdl2"

WINDOW_TITLE :: "Some Game Title"
WINDOW_X : i32 = SDL.WINDOWPOS_UNDEFINED // centered
WINDOW_Y : i32 = SDL.WINDOWPOS_UNDEFINED
WINDOW_W : i32 = 960
WINDOW_H : i32 = 540

// https://pkg.odin-lang.org/vendor/sdl2/#WindowFlag
// WINDOW_FLAGS  :: SDL.WindowFlags{.SHOWN}
WINDOW_FLAGS  :: SDL.WINDOW_SHOWN

CTX :: struct
{
	window: ^SDL.Window,
	renderer: ^SDL.Renderer,
	player_1: SDL.Rect,
	player_2: SDL.Rect,

	moving_left_p1: bool,
	moving_right_p1: bool,
	moving_up_p1: bool,
	moving_down_p1: bool,

	moving_left_p2: bool,
	moving_right_p2: bool,
	moving_up_p2: bool,
	moving_down_p2: bool,
}

ctx := CTX{

	player_1 = SDL.Rect{100, 100, 20, 20},
	player_2 = SDL.Rect{100, 150, 20, 20},
}

main :: proc()
{
    SDL.Init(SDL.INIT_VIDEO)

    ctx.window = SDL.CreateWindow(WINDOW_TITLE, WINDOW_X, WINDOW_Y, WINDOW_W, WINDOW_H, WINDOW_FLAGS)
    ctx.renderer = SDL.CreateRenderer(
    	ctx.window,
    	-1,
    	// SDL.RENDERER_SOFTWARE // vsync off, movement will be faster!
    	SDL.RENDERER_PRESENTVSYNC
    	// SDL.RENDERER_PRESENTVSYNC | SDL.RENDERER_ACCELERATED | SDL.RENDERER_TARGETTEXTURE
	)

	ctx.moving_right_p1 = true
	ctx.moving_right_p2 = true

	now_perf := f64(SDL.GetPerformanceCounter()) / f64(SDL.GetPerformanceFrequency())
	prev_perf : f64
	delta_perf : f64

	now_ticks := f64(SDL.GetTicks())
	prev_ticks : f64
	delta_ticks : f64

	event : SDL.Event

	counter : int
	game_loop: for
	{


    	if counter > 10
    	{
			// fmt.println("Target seconds per frame", ctx.target_seconds_per_frame)
    		// break game_loop
    	}

    	counter += 1

    	prev_perf = now_perf
		now_perf = f64(SDL.GetPerformanceCounter())  / f64(SDL.GetPerformanceFrequency())
		delta_perf = (now_perf - prev_perf) * 1000

		prev_ticks = now_ticks
		now_ticks = f64(SDL.GetTicks())
		delta_ticks = now_ticks - prev_ticks

		if SDL.PollEvent(&event)
    	{
    		if event.type == SDL.EventType.QUIT
    		{
    			break game_loop
    		}

    		if event.type == SDL.EventType.KEYDOWN
    		{

				#partial switch event.key.keysym.scancode
				{
					case .L:

						// with vsync on, these are pretty much the same
						// with vsync OFF, perf is usually MUCH faster, and with wider swings in values
						fmt.println("Delta Ticks vs Delta Perf", delta_ticks, " vs ", delta_perf)
				}
			}

    	}


    	// fmt.println("deltas ticks vs perf", delta_ticks, " vs ",  delta_perf)



		/// CONCLUSION:
		// with delta_ticks, the movement of the entity is consistent whether vsync is on or off
		// with delta_perf, the delta is a much smaller number (faster perf), so the movement slows down when vsync is off


		// WINNER :: best to get delta using GetTicks()
		/// END

		// Method :: Target Pixels per Frame
    	// steps := i32(delta_ticks * 1)

    	fixed_time_step := 0.033

    	// steps_p1 := i32(fixed_time_step * 1) + 1
    	// steps_p2 := i32(fixed_time_step * 1) + 1

    	steps_p1 := i32(delta_ticks * 2)
    	steps_p2 := i32(delta_perf * 2)

    	// steps := i32(delta_ticks * 1)
    	// steps := i32(1)
    	// steps := i32(( delta_perf * 1000 ) * 1)
    	// steps := i32(ctx.delta_time * 1)
    	// steps : i32 = 5
    	// steps : i32 = i32(0.0025 * ctx.target_pixels_per_second)

    	// fmt.println(ctx.delta_time * ctx.target_pixels_per_second)

    	/// back and forth
    	// P1
    	{

	    	if ctx.player_1.x <= 0
	    	{
	    		ctx.moving_left_p1 = false
	    		ctx.moving_right_p1 = true
	    	}
	    	else if ctx.player_1.x >= ( WINDOW_W - 30)
	    	{
	    		ctx.moving_left_p1 = true
	    		ctx.moving_right_p1 = false
	    	}

	    	if ctx.moving_left_p1
	    	{
	    		ctx.player_1.x -= steps_p1
	    	}
	    	if ctx.moving_right_p1
	    	{
	    		ctx.player_1.x += steps_p1
	    	}

			SDL.SetRenderDrawColor(ctx.renderer, 255, 0, 0, 100)
			SDL.RenderFillRect(ctx.renderer, &ctx.player_1)
    	}

    	// p2
    	{

	    	if ctx.player_2.x <= 0
	    	{
	    		ctx.moving_left_p2 = false
	    		ctx.moving_right_p2 = true
	    	}
	    	else if ctx.player_2.x >= ( WINDOW_W - 30)
	    	{
	    		ctx.moving_left_p2 = true
	    		ctx.moving_right_p2 = false
	    	}

	    	if ctx.moving_left_p2
	    	{
	    		ctx.player_2.x -= steps_p2
	    	}
	    	if ctx.moving_right_p2
	    	{
	    		ctx.player_2.x += steps_p2
	    	}

			SDL.SetRenderDrawColor(ctx.renderer, 0, 255, 255, 100)
			SDL.RenderFillRect(ctx.renderer, &ctx.player_2)
    	}



    	// a reliable SDL.Delay(), though this eats up cpu resources
    	// for ctx.delta_time < ctx.target_seconds_per_frame
    	// {
	    	// now := f64(SDL.GetPerformanceCounter()) / f64(SDL.GetPerformanceFrequency())
	    	// ctx.delta_time = now - ctx.prev_time
    	// }

		// actual flipping / presentation of the copy
		// read comments here :: https://wiki.libsdl.org/SDL_RenderCopy
		SDL.RenderPresent(ctx.renderer)

		// clear the old renderer
		// clear after presentation so we remain free to call RenderCopy() throughout our update code / wherever it makes the most sense
		SDL.SetRenderDrawColor(ctx.renderer, 0, 0, 0, 100)
		SDL.RenderClear(ctx.renderer)

	} // end loop


	SDL.DestroyWindow(ctx.window)
	SDL.Quit()

}
