module Sync

    @enum SyncMode mutex pin disabled

    const gap_lock = ReentrantLock()
    const pinned_thread = Ref{Int}(1)

    @inline function _lock()
        Base._lock(gap_lock)
    end

    @inline function _unlock()
        Base._unlock(gap_lock)
    end

    @inline function check_lock()
        @assert gap_lock.locked_by === Base.current_task()
    end

    @inline function check_pinned()
        @assert Threads.threadid() == pinned_thread[]
    end

    # To switch between multi-threaded and single-threaded mode, we
    # define functions that install the appropriate handlers for lock()
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
        Sync.eval(:(@inline function lock(f::Function)
            try
                _lock()
                f()
            finally
                _unlock()
            end
        end))
        Sync.eval(:(@inline function lock_noexcept(f::Function)
            _lock()
            t = f()
            _unlock()
            t
        end))
        Sync.eval(:(@inline function check_lock(f::Function)
            check_lock()
            f()
        end))
    end

    function _mode_pinned()
        Sync.eval(:(@inline function lock(f::Function)
            check_pinned()
            f()
        end))
        Sync.eval(:(@inline function lock_noexcept(f::Function)
            check_pinned()
            f()
        end))
        Sync.eval(:(@inline function check_lock(f::Function)
            check_pinned()
            f()
        end))
    end

    function _mode_nolock()
        Sync.eval(:(@inline function lock(f::Function)
            f()
        end))
        Sync.eval(:(@inline function lock_noexcept(f::Function)
            f()
        end))
        Sync.eval(:(@inline function check_lock(f::Function)
            f()
        end))
    end

    # The switch() method allows GAP users to switch at runtime between
    # various modes:
    #
    # 1. Sync.pin pins the GAP interpreter to the current thread. It
    #    cannot be called from other threads. This is the default mode,
    #    as it combines best performance with thread safety.
    # 2. Sync.mutex serializes all GAP calls via a global mutex. This
    #    offers thread safety and the ability to call GAP from multiple
    #    threads, but has worse performance than pinning the GAP interpreter
    #    to a thread.
    # 3. Sync.nolock removes all thread-safety checks. It eliminates all
    #    overhead, but it is up to the user to ensure that no race
    #    conditions occur.

    function switch(mode::SyncMode)
        stack = stacktrace()
        file = stack[1].file
        for frame in stack[2:end]
            if frame.func in [ :lock, :lock_noexcept ] && frame.file == file
                @error "trying to change lock mode within critical region"
            end
        end
        if mode == pin
            _mode_pinned()
        elseif mode == mutex
            _mode_mutex()
        else # mode == disabled
            _mode_nolock()
        end
    end

    # Initialization is tricky. __init__() can be called from within the
    # first lock() call if the module has already been precompiled. Thus,
    # we default to enabling synchronization during precompilation and
    # then set the actual lock mode during __init__(). Dropping back from
    # synchronization being enabled to being disabled is safe, but not the
    # other way round.

    _mode_pinned()

    function __init__()
        if Threads.nthreads() == 1
            _mode_nolock()
        else
            _mode_pinned()
        end
    end
end

macro lock(expr)
    :( Sync.lock(()->$(esc(expr))) )
end

macro lock_noexcept(expr)
    :( Sync.lock_noexcept(()->$(esc(expr))) )
end

macro check_lock(expr)
    :( Sync.check_lock(()->$(esc(expr))) )
end
