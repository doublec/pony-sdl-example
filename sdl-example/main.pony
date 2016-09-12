use "lib:SDL2"
use "time"

use @SDL_Init[I32](flags: U32)
use @SDL_CreateWindow[Pointer[_SDLWindow]](title: Pointer[U8] tag, x: I32, y: I32, w: I32, h: I32, flags: U32)
use @SDL_CreateRenderer[Pointer[_SDLRenderer]](window: Pointer[_SDLWindow], index: I32, flags: U32)
use @SDL_DestroyRenderer[None](renderer: Pointer[_SDLRenderer])
use @SDL_DestroyWindow[None](window: Pointer[_SDLWindow])
use @SDL_RenderClear[I32](renderer: Pointer[_SDLRenderer])
use @SDL_RenderPresent[None](renderer: Pointer[_SDLRenderer])
use @SDL_SetRenderDrawColor[I32](renderer: Pointer[_SDLRenderer], r: U8, g: U8, b: U8, a: U8)
use @SDL_RenderFillRect[I32](renderer: Pointer[_SDLRenderer], rect: MaybePointer[_SDLRect])

struct _SDLRect
  var x: I32 = 0
  var y: I32 = 0
  var w: I32 = 0
  var h: I32 = 0

  new create(x1: I32, y1: I32, w1: I32, h1: I32) =>
    x = x1
    y = y1
    w = w1
    h = h1

primitive _SDLWindow
primitive _SDLRenderer


primitive SDL2
  fun init_video(): U32 => 0x00000020
  fun window_shown(): U32 => 0x00000004
  fun renderer_accelerated(): U32 => 0x00000002
  fun renderer_presentvsync(): U32 => 0x00000004

actor Game
  let window: Pointer[_SDLWindow]
  let renderer: Pointer[_SDLRenderer]
  let timers: Timers = Timers
  let render_loop: Timer tag

  new create() =>
    window = @SDL_CreateWindow("Hello World!".cstring(), 100, 100, 640, 480, SDL2.window_shown())
    renderer = @SDL_CreateRenderer(window, -1, SDL2.renderer_accelerated() or SDL2.renderer_presentvsync())

    let quitter = Timer(object iso
                          let _game:Game = this
                          fun ref apply(timer:Timer, count:U64):Bool =>
                            _game.quit()
                            false
                        fun ref cancel(timer:Timer) => None
                      end, 1_000_000_000 * 5, 0) // 5 Second timeout
    timers(consume quitter)

    let timer = Timer(object iso
                        let _game:Game = this
                        fun ref apply(timer:Timer, count:U64):Bool =>
                          _game.loop()
                          true
                        fun ref cancel(timer:Timer) => None
                      end, 0, 100_000_000) // 100ms timeout
    render_loop = timer
    timers(consume timer)

  be loop() =>
   @SDL_RenderClear(renderer)

   @SDL_SetRenderDrawColor(renderer, 0, 0, 255, 255)
   @SDL_RenderFillRect(renderer, MaybePointer[_SDLRect].none())

   @SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255)
   let rect = _SDLRect(100, 100, 200, 200)
   @SDL_RenderFillRect(renderer, MaybePointer[_SDLRect](rect))

   @SDL_RenderPresent(renderer)
    
  be quit() =>
    dispose()

  be dispose() =>
    timers.cancel(render_loop)
    @SDL_DestroyRenderer(renderer)
    @SDL_DestroyWindow(window)
  
actor Main
  new create(env:Env) =>
    @SDL_Init(SDL2.init_video())
    let game = Game
 
