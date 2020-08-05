module Sync
    mutable struct LockStatus
        nested :: Int
	owner :: Union{Task, Nothing}
    end

    const mutex = ReentrantLock()
    const lock_status = LockStatus(0, nothing)

    @inline is_locked() = lock_status.owner == Base.current_task()

    @inline function lock()
        if is_locked()
	  lock_status.nested += 1
	else
	  Base.lock(mutex)
	  lock_status.nested = 1
	  lock_status.owner = Base.current_task()
	end
    end

    @inline function unlock()
        @assert is_locked()
	lock_status.nested -= 1
	if lock_status.nested == 0
	  lock_status.owner = nothing
	  Base.unlock(mutex)
	end
    end

    @inline function check_lock()
        @assert is_locked()
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
