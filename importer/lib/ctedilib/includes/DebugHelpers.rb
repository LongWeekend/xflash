module DebugHelpers

  # <cf_style>Rockin it!</cf_style> - count run time of  bounded block and output it
  def tickcount(id="", verbose=$options[:verbose], tracking=false)
    from = Time.now
    prt "\nSTART: " + (id =="" ? "Anonymous Block" : id) + "\n" if verbose
    yield
    to = Time.now
    # track time stats?
    if tracking
      $ticks = {} if !$ticks
      if !$ticks[id]
        $ticks[id] = {}
        $ticks[id][:times] = 1
        $ticks[id][:total] = Float(to-from)
      else
        $ticks[id][:times] = $ticks[id][:times] + 1
        $ticks[id][:total] = ( ($ticks[id][:total] + Float(to-from)) / $ticks[id][:times] )
      end
      $ticks[id][:last] = {:from => from, :to => to}
    end
    if verbose
      prt "END: " + (id =="" ? "Anonymous Block" : id) + " time taken: #{(to-from).to_s} s"
      prt_dotted_line
    end
    return true
  end

  # "puts" clone that outputs nothing when verbose mode is false!
  def prt(str)
    puts(str) if $options[:verbose]
  end

  def prt_dotted_line(txt="")
    prt "---------------------------------------------------------------------#{txt}"
  end
  
  def exit_with_error(error, dump_me=nil)
    puts "ERROR! " + error
    pp dump_me if dump_me
    exit
  end

  # Loop counter to count aloud for you!
  def noisy_loop_counter(count, max=0, every=1000, item_name="records")
    count +=1
    if count % every == 0 || (max > 0 && count == max)
      prt "Looped #{count/atomicity} #{item_name}"
    end
    return count
  end
  
end