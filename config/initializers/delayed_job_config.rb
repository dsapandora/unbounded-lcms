if defined? Delayed
  Delayed::Worker.max_run_time = 10.hours
end
