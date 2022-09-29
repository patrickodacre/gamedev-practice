package main

import "core:fmt"
import SDL "vendor:sdl2"

WINDOW_TITLE :: "Frame Rate and Movement Demo"
WINDOW_X : i32 = SDL.WINDOWPOS_UNDEFINED // centered
WINDOW_Y : i32 = SDL.WINDOWPOS_UNDEFINED
WINDOW_W : i32 = 960
WINDOW_H : i32 = 540
// 60 FPS - 0.0167 or 1000/60
// 30 FPS - 0.033 or 1000/30
TARGET_FRAME_RATE :: 1000/60
VSYNC_ENABLED :: false

// https://pkg.odin-lang.org/vendor/sdl2/#WindowFlag
// WINDOW_FLAGS  :: SDL.WindowFlags{.SHOWN}
WINDOW_FLAGS  :: SDL.WINDOW_SHOWN

CTX :: struct
{
	window: ^SDL.Window,
	renderer: ^SDL.Renderer,

	player_1: SDL.Rect,
	player_2: SDL.Rect,
	player_3: SDL.Rect,
	player_4: SDL.Rect,

	delay_signal: SDL.Rect,

	moving_left_p1: bool,
	moving_right_p1: bool,
	moving_up_p1: bool,
	moving_down_p1: bool,

	moving_left_p2: bool,
	moving_right_p2: bool,
	moving_up_p2: bool,
	moving_down_p2: bool,

	moving_left_p3: bool,
	moving_right_p3: bool,
	moving_up_p3: bool,
	moving_down_p3: bool,

	moving_left_p4: bool,
	moving_right_p4: bool,
	moving_up_p4: bool,
	moving_down_p4: bool,
}

ctx := CTX{

	player_1 = SDL.Rect{100, 50, 20, 20},
	player_2 = SDL.Rect{100, 100, 20, 20},
	player_3 = SDL.Rect{100, 150, 20, 20},
	player_4 = SDL.Rect{100, 200, 20, 20},
	delay_signal = SDL.Rect{10, 10, 30, 30},
}

main :: proc()
{
    SDL.Init(SDL.INIT_VIDEO)

    ctx.window = SDL.CreateWindow(WINDOW_TITLE, WINDOW_X, WINDOW_Y, WINDOW_W, WINDOW_H, WINDOW_FLAGS)

    if VSYNC_ENABLED
    {
	    ctx.renderer = SDL.CreateRenderer(
	    	ctx.window,
	    	-1,
	    	 SDL.RENDERER_PRESENTVSYNC
		)
    }
    else
    {

	    ctx.renderer = SDL.CreateRenderer(
	    	ctx.window,
	    	-1,
	    	SDL.RENDERER_SOFTWARE // vsync off, movement will be faster!
	    	 /* SDL.RENDERER_PRESENTVSYNC */
	    	// SDL.RENDERER_PRESENTVSYNC | SDL.RENDERER_ACCELERATED | SDL.RENDERER_TARGETTEXTURE
		)
    }

	ctx.moving_right_p1 = true
	ctx.moving_right_p2 = true
	ctx.moving_right_p3 = true
	ctx.moving_right_p4 = true

	now_perf := f64(SDL.GetPerformanceCounter())
	prev_perf : f64
	delta_perf : f64

	// NOTE:: cannot use u32 for GetTicks
	// our move_delay calcs will underflow at move_delay - delta_ticks
	// and create a HUGE delay rendering our player unable to move
	now_ticks := f64(SDL.GetTicks())
	prev_ticks : f64
	delta_ticks : f64

	// to cap our frame rate
	start : u32
	end : u32

	event : SDL.Event

	cap_frame_rate := true

	move_delay : f64 = 3
	render_player_1 := true
	render_player_2 := true
	render_player_3 := true
	render_player_4 := true
	add_one_to_perf := false

	game_loop: for
	{

		start = SDL.GetTicks()

    	prev_perf = now_perf
		now_perf = f64(SDL.GetPerformanceCounter())
		delta_perf = ((now_perf - prev_perf) * 1000) / f64(SDL.GetPerformanceFrequency())

		prev_ticks = now_ticks
		now_ticks = f64(SDL.GetTicks())
		delta_ticks = now_ticks - prev_ticks

		if cap_frame_rate
		{
			// green == ON
			SDL.SetRenderDrawColor(ctx.renderer, 0, 255, 0, 100)
		}
		else
		{
			// red == OFF
			SDL.SetRenderDrawColor(ctx.renderer, 255, 0, 0, 100)
		}

		SDL.RenderFillRect(ctx.renderer, &ctx.delay_signal)

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
						fmt.println("Log :: Delta Ticks : ", delta_ticks, " vs Delta Perf : ", delta_perf)

					case .C:
						cap_frame_rate = !cap_frame_rate

					case .NUM1:
						render_player_1 = !render_player_1
					case .NUM2:
						render_player_2 = !render_player_2
					case .NUM3:
						render_player_3 = !render_player_3
					case .NUM4:
						render_player_4 = !render_player_4
					case .A:
						add_one_to_perf = !add_one_to_perf

				}
			}

    	}

		/// CONCLUSION:
		// Player 1 & 2 - with delta_ticks the movement of the entity is consistent whether vsync is on or off.
		// Player 1 - with move_delay capping the frame rate has little effect on speed unless the move_delay is very large. With a large delay, though, movement is very choppy.
		// Player 2 - with delta motion Capping our Frame rate has no effect since movements are proportional to the frame time.
		// Player 3 - with delta_perf the delta is a much smaller number (so I multiply by 1000). Slows down when capping frame rate.
		// Player 4 - with fixed_time_step movement is smoother than delta_perf but it is noticeably less smooth than delta_ticks. Slows down with delay.
		// WINNER :: best to get delta using GetTicks()

    	// PLAYER 1
    	// delta motion and move_delay
    	{
			// back and forth
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

			move_delay = max(0, move_delay - delta_ticks)

			player_1_steps : i32 = 0

			// using our delay to enforce a frame_rate this moves faster than without (the delta_ticks are larger)
			if move_delay == 0
			{
				player_1_steps = i32(delta_ticks * 1)

		    	if ctx.moving_left_p1
		    	{
		    		ctx.player_1.x -= player_1_steps
		    	}
		    	if ctx.moving_right_p1
		    	{
		    		ctx.player_1.x += player_1_steps
		    	}

				// if we're enforcing a frame rate, then this delay has to be very large to slow down the player;
				// otherwise, the move_delay appears to have no effect.
				// further, this type of delay results in choppy movement that is very noticeable when framerate is longer
				move_delay = 3
			}

	    	if render_player_1
	    	{
	    		// purple
				SDL.SetRenderDrawColor(ctx.renderer, 200, 10, 255, 100)
				SDL.RenderFillRect(ctx.renderer, &ctx.player_1)
	    	}
    	}

    	// PLAYER 2 RED
    	// delta motion GetTicks()
    	{

	    	// No VSYNC :: delta_ticks will remain smooth even without +1 as the delta is usually 1
	    	// W/ Delay :: no noticeable change
	    	player_2_steps := i32(delta_ticks * 1)

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
	    		ctx.player_2.x -= player_2_steps
	    	}
	    	if ctx.moving_right_p2
	    	{
	    		ctx.player_2.x += player_2_steps
	    	}

	    	if render_player_2
	    	{
	    		// Red
				SDL.SetRenderDrawColor(ctx.renderer, 255, 0, 0, 100)
				SDL.RenderFillRect(ctx.renderer, &ctx.player_2)
	    	}
    	}

    	// PLAYER 3 BLUE
    	// delta motion GetPerformanceCounter
    	{

	    	// No VSYNC :: delta_perf will slow down and stutter badly unless + 1 to make sure movement is always >= 1
	    	// W/ Delay :: smoother and much more steady
	    	player_3_steps : i32

	    	if add_one_to_perf
	    	{
		    	player_3_steps = i32(delta_perf * 2) + 1
	    	}
	    	else
	    	{
		    	player_3_steps = i32(delta_perf * 2)
	    	}


	    	if ctx.player_3.x <= 0
	    	{
	    		ctx.moving_left_p3 = false
	    		ctx.moving_right_p3 = true
	    	}
	    	else if ctx.player_3.x >= ( WINDOW_W - 30)
	    	{
	    		ctx.moving_left_p3 = true
	    		ctx.moving_right_p3 = false
	    	}

	    	if ctx.moving_left_p3
	    	{
	    		ctx.player_3.x -= player_3_steps
	    	}
	    	if ctx.moving_right_p3
	    	{
	    		ctx.player_3.x += player_3_steps
	    	}

	    	if render_player_3
	    	{
	    		// Blue
				SDL.SetRenderDrawColor(ctx.renderer, 0, 255, 255, 100)
				SDL.RenderFillRect(ctx.renderer, &ctx.player_3)
	    	}
    	}

    	// No VSYNC :: Fixed time step will speed up and slow down at random
    	// W/ Delay :: slower and more steady
    	// You MUST use delay to get smooth movement
    	// PLAYER 4 YELLOW
    	// FIXED Time Step
    	{

	    	player_4_steps : i32 = 1

	    	// hard to see smoothness when moving slowly at only 1 pixel per tick
	    	if cap_frame_rate
	    	{
	    		player_4_steps = 18
	    	}

	    	if ctx.player_4.x <= 0
	    	{
	    		ctx.moving_left_p4 = false
	    		ctx.moving_right_p4 = true
	    	}
	    	else if ctx.player_4.x >= ( WINDOW_W - 30)
	    	{
	    		ctx.moving_left_p4 = true
	    		ctx.moving_right_p4 = false
	    	}

	    	if ctx.moving_left_p4
	    	{
	    		ctx.player_4.x -= player_4_steps
	    	}
	    	if ctx.moving_right_p4
	    	{
	    		ctx.player_4.x += player_4_steps
	    	}

	    	if render_player_4
	    	{
	    		// yellow
				SDL.SetRenderDrawColor(ctx.renderer, 255, 255, 0, 100)
				SDL.RenderFillRect(ctx.renderer, &ctx.player_4)
	    	}
    	}

    	// a reliable SDL.Delay(), though this eats up cpu resources
		end = SDL.GetTicks()
    	if cap_frame_rate
    	{
			for (end - start) < TARGET_FRAME_RATE
	    	{
		    	end = SDL.GetTicks()
	    	}
    	}

    	fmt.println("FPS : ", (end-start) / (1000/60) * 60)
    	fmt.println("Delta Ticks : ", delta_ticks)
    	fmt.println("Delta Perf : ", delta_perf)
    	fmt.println(start, "ms -> ", end, "ms")

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
