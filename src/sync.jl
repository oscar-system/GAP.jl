module Sync
    const mutex = ReentrantLock()
    const sync_level = repeat([ 0 ], Threads.nthreads())

    @inline is_locked() = sync_level[Threads.threadid()] > 0

    @inline function lock()
        tid = Threads.threadid()
        if sync_level[tid] == 0
            Base.lock(mutex)
        end
        sync_level[tid] += 1
    end

    @inline function unlock()
        tid = Threads.threadid()
        sync_level[tid] -= 1
        if sync_level[tid] == 0
            Base.unlock(mutex)
        end
    end

    @inline function check_lock()
        assert(is_locked())
    end
end

macro sync(expr)
    if Threads.nthreads() > 1
        quote
            try
                Sync.lock()
                $(esc(expr))
            finally
                Sync.unlock()
            end
        end
    else
        :( $(esc(expr)) )
    end
end

macro sync_noexcept(expr)
    if Threads.nthreads() > 1
        quote
            Sync.lock()
            local t = $(esc(expr))
            Sync.unlock()
            t
        end
    else
        :( $(esc(expr)) )
    end
end

macro check_sync(expr)
    if Threads.nthreads() > 1
        quote
            Sync.check_lock()
            $(esc(expr))
        end
    else
        :( $(esc(expr)) )
    end
end
