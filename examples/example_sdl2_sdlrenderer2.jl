# Reference: https://github.com/ocornut/imgui/tree/master/examples/example_sdl2_sdlrenderer2

module Editor
    using CImGui
    using CImGui.CSyntax
    using CImGui.CSyntax.CStatic
    using CImGui: ImVec2, ImVec4, IM_COL32, ImS32, ImU32, ImS64, ImU64
    using SimpleDirectMediaLayer
    const SDL2 = SimpleDirectMediaLayer
    global sdlVersion = "2.0.0"
    global sdlRenderer = C_NULL

    include(joinpath("..", "src", "imgui_impl_sdl2.jl"))
    include(joinpath("..", "src", "imgui_impl_sdlrenderer2.jl"))

    function run()
        if SDL2.SDL_Init(SDL2.SDL_INIT_VIDEO | SDL2.SDL_INIT_TIMER | SDL2.SDL_INIT_GAMECONTROLLER) < 0
            println("failed to init: ", unsafe_string(SDL2.SDL_GetError()));
        end
        SDL2.SDL_SetHint(SDL2.SDL_HINT_IME_SHOW_UI, "1")

        window = SDL2.SDL_CreateWindow(
        "Example window", SDL2.SDL_WINDOWPOS_CENTERED, SDL2.SDL_WINDOWPOS_CENTERED, 1024, 768,
        SDL2.SDL_WINDOW_SHOWN | SDL2.SDL_WINDOW_OPENGL | SDL2.SDL_WINDOW_RESIZABLE | SDL2.SDL_WINDOW_ALLOW_HIGHDPI
        )
        if window == C_NULL 
            println("Failed to create window: ", unsafe_string(SDL2.SDL_GetError()))
            return -1
        end

        renderer = SDL2.SDL_CreateRenderer(window, -1, SDL2.SDL_RENDERER_ACCELERATED)
        global sdlRenderer = renderer
        if (renderer == C_NULL)
            println("Failed to create renderer: ", unsafe_string(SDL2.SDL_GetError()))
        end

        ver = pointer(SDL2.SDL_version[SDL2.SDL_version(0,0,0)])
        SDL2.SDL_GetVersion(ver)
        global sdlVersion = string(unsafe_load(ver).major, ".", unsafe_load(ver).minor, ".", unsafe_load(ver).patch)
        println("SDL version: ", sdlVersion)
        sdlVersion = parse(Int32, replace(sdlVersion, "." => ""))

        ctx = CImGui.CreateContext()
        
        io = CImGui.GetIO()
        io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_DockingEnable | CImGui.ImGuiConfigFlags_NavEnableKeyboard | CImGui.ImGuiConfigFlags_NavEnableGamepad

        io.BackendPlatformUserData = C_NULL
        ImGui_ImplSDL2_InitForSDLRenderer(window, renderer)
        ImGui_ImplSDLRenderer2_Init(renderer)
        
        # setup Dear ImGui style #Todo: Make this a setting
        CImGui.StyleColorsDark()
        # CImGui.StyleColorsClassic()
        # CImGui.StyleColorsLight()
        
        showDemoWindow = true
        clear_color = Cfloat[0.45, 0.55, 0.60, 0.01]

        quit = false
            try
                while !quit
                    event_ref = Ref{SDL2.SDL_Event}()
                    while Bool(SDL2.SDL_PollEvent(event_ref))
                        evt = event_ref[]
                        ImGui_ImplSDL2_ProcessEvent(evt)
                        evt_ty = evt.type
                        if evt_ty == SDL2.SDL_QUIT
                            quit = true
                            break
                        elseif evt_ty == SDL2.SDL_KEYDOWN
                            scan_code = evt.key.keysym.scancode
                            if scan_code == SDL2.SDL_SCANCODE_W || scan_code == SDL2.SDL_SCANCODE_UP
                                break
                            elseif scan_code == SDL2.SDL_SCANCODE_A || scan_code == SDL2.SDL_SCANCODE_LEFT
                                break
                            elseif scan_code == SDL2.SDL_SCANCODE_S || scan_code == SDL2.SDL_SCANCODE_DOWN
                                break
                            elseif scan_code == SDL2.SDL_SCANCODE_D || scan_code == SDL2.SDL_SCANCODE_RIGHT
                                break
                            else
                                break
                            end
                        end
                    end
                        
                    #     // start imgui frame
                    ImGui_ImplSDLRenderer2_NewFrame()
                    ImGui_ImplSDL2_NewFrame();
                    CImGui.NewFrame()

                    CImGui.igDockSpaceOverViewport(C_NULL, C_NULL, CImGui.ImGuiDockNodeFlags_PassthruCentralNode, C_NULL) # Creating the "dockspace" that covers the whole window. This allows the child windows to automatically resize.
                    CImGui.ShowDemoWindow(Ref{Bool}(true))

                    @cstatic begin
                        CImGui.Begin("Controls")  
                        CImGui.Text("Test Text")
                        CImGui.NewLine()
                        CImGui.End()
                    end

                    CImGui.Render()

                    SDL2.SDL_RenderSetScale(renderer, unsafe_load(io.DisplayFramebufferScale.x), unsafe_load(io.DisplayFramebufferScale.y));
                    SDL2.SDL_SetRenderDrawColor(renderer, (UInt8)(round(clear_color[1] * 255)), (UInt8)(round(clear_color[2] * 255)), (UInt8)(round(clear_color[3] * 255)), (UInt8)(round(clear_color[4] * 255)));
                    SDL2.SDL_RenderClear(renderer);
                    ImGui_ImplSDLRenderer2_RenderDrawData(CImGui.GetDrawData());
                    SDL2.SDL_RenderPresent(renderer);
                end
            catch e
                @warn "Error in renderloop!" exception=e
                Base.show_backtrace(stderr, catch_backtrace())
            finally
                ImGui_ImplSDLRenderer2_Shutdown();
                ImGui_ImplSDL2_Shutdown();

                CImGui.DestroyContext(ctx)
                SDL_DestroyRenderer(renderer);
                SDL2.SDL_DestroyWindow(window);
                SDL2.SDL_Quit()
        end
    # ================ CUT OFF
    SDL2.SDL_Quit()
    # ================ CUT OFF
    end
end
Editor.run()