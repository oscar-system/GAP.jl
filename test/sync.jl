function run_timed(script :: String, timeout :: Int)
  cmd = Cmd(Base.julia_cmd();
    env = merge(ENV, Dict("JULIA_NUM_THREADS" => "2")))
  push!(cmd.exec, "-e", script)
  process = open(cmd)
  task = @async begin
    wait(process)
  end
  for t in 1:(timeout*10)
    sleep(0.1)
    if task.state == :done
      return process.exitcode == 0
    end
  end
  kill(process, 9)
  return false
end

@testset "sync" begin
  @test run_timed("""
  using GAP
  Threads.@threads for i = 1:20000
    GAP.Globals.SymmetricGroup(7)
  end
  """, 10)
  @test run_timed("""
  using GAP
  function test()
    perm = @gap "()"
    Threads.@threads for i = 1:2000
      perm *= GAP.evalstr("(\$(i), \$(i+1))")
    end
  end
  test()
  """, 10)
end
