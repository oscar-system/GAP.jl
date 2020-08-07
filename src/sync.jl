module Sync

    const mutex = ReentrantLock()

    @inline function lock()
        Base.lock(mutex)
    end

    @inline function unlock()
        Base.unlock(mutex)
    end

    @inline function check_lock()
        @assert mutex.locked_by === Base.current_task()
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

    function enable_sync()
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

    function disable_sync()
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

    # Initialization is tricky. __init__() can be called from
    # within the first sync() call if the module has already
    # been precompiled. Thus, we default to enable_sync() for
    # precompilation and then set the actual sync mode during
    # __init__(). Dropping back from sync enabled to being
    # disabled is safe, but not the other way round.

    enable_sync()

    function __init__()
        if Threads.nthreads() > 1
            enable_sync()
        else
            disable_sync()
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
