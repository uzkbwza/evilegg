local bench = {}

function bench.start_bench(name)
	if not debug.enabled then return end
	bench.benchmark_names = bench.benchmark_names or {}
	bench.benchmark_names[name] = bench.benchmark_names[name] or {}
	bench.benchmark_names[name].start_time = love.timer.getTime()
end

function bench.end_bench(name)
	if not debug.enabled then return end
	bench.benchmark_names[name].end_time = love.timer.getTime()
	bench.benchmark_names[name].time_taken = bench.benchmark_names[name].end_time - bench.benchmark_names[name].start_time
	bench.print_bench(name)
end

function bench.print_bench(name)
	if not debug.enabled then return end
	print(string.format("%s took %.10f seconds", name, bench.benchmark_names[name].time_taken))
end

return bench
