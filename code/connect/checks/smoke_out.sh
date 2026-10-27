echo "--- jobs dir ---"; ls -l ~/jobs 2>/dev/null | head -6
echo "--- smoke out ---"; cat ~/jobs/smoke_92384.out 2>/dev/null || echo "no .out"
echo "--- smoke err ---"; cat ~/jobs/smoke_92384.err 2>/dev/null || echo "no .err"
echo "--- sacct detail ---"; sacct -j 92384 --format=JobID,State,ExitCode,Elapsed,MaxRSS,NodeList -n 2>/dev/null | head -5
