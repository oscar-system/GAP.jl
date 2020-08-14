module Sync

    @enum SyncMode mutex pin disabled

    const gap_lock = ReentrantLock()
    const pinned_thread = Ref{Int}(1)

    @inline function lock()
        Base.lock(gap_lock)
    end

    @inline function unlock()
        Base.unlock(gap_lock)
    end

    @inline function check_lock()
        @assert gap_lock.locked_by === Base.current_task()
    end

    @inline function check_pinned()
        @assert Threads.threadid() == pinned_thread[]
    end

    # To switch between multi-threaded and single-threaded mode, we
    # define functions that install the appropriate handlers for sync()
    # etc.
    #
    # This is necessary because otherwise precompilation would fix
    # the mode at whatever state it was during precompilation. Thus,
    # initially loading GAP.jl in single-threaded mode would also keep
    # synchronization off in multi-threaded mode.
    #
    # However, Julia tracks function dependencies. If a function changes
    # upon which another depends, both are being recompiled. Thus,
    # by installing the proper version during __init__(), we force
    # selective recompilation of the affected functions as needed.

    function _mode_mutex()
        Sync.eval(:(@inline function sync(f::Function)
            try
                lock()
                f()
            finally
                unlock()
            end
        end))
        Sync.eval(:(@inline function sync_noexcept(f::Function)
            lock()
            t = f()
            unlock()
            t
        end))
        Sync.eval(:(@inline function check_sync(f::Function)
            check_lock()
            f()
        end))
    end

    function _mode_pinned()
        Sync.eval(:(@inline function sync(f::Function)
            check_pinned()
            f()
        end))
        Sync.eval(:(@inline function sync_noexcept(f::Function)
            check_pinned()
            f()
        end))
        Sync.eval(:(@inline function check_sync(f::Function)
            check_pinned()
            f()
        end))
    end

    function _mode_nosync()
        Sync.eval(:(@inline function sync(f::Function)
            f()
        end))
        Sync.eval(:(@inline function sync_noexcept(f::Function)
            f()
        end))
        Sync.eval(:(@inline function check_sync(f::Function)
            f()
        end))
    end

    function switch(mode::SyncMode)
        stack = stacktrace()
        file = stack[1].file
        for frame in stack[2:end]
            if frame.func in [ :sync, :sync_noexcept ] && frame.file == file
                @error "trying to change sync mode within critical region"
            end
        end
        if mode == pin
            _mode_pinned()
        elseif mode == mutex
            _mode_mutex()
        else # mode == disabled
            _mode_nosync()
        end
    end

    # Initialization is tricky. __init__() can be called from within the
    # first sync() call if the module has already been precompiled. Thus,
    # we default to enabling synchronization during precompilation and
    # then set the actual sync mode during __init__(). Dropping back from
    # synchronization being enabled to being disabled is safe, but not the
    # other way round.

    _mode_pinned()

    function __init__()
        if Threads.nthreads() == 1
            _mode_nosync()
        else
            _mode_pinned()
        end
    end
end

macro sync(expr)
    :( Sync.sync(()->$(esc(expr))) )
end

macro sync_noexcept(expr)
    :( Sync.sync_noexcept(()->$(esc(expr))) )
end

macro check_sync(expr)
    :( Sync.check_sync(()->$(esc(expr))) )
end
