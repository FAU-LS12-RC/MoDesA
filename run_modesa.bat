@ECHO OFF
:: start the MATLAB MoDesA function
START "" matlab -nodesktop -nojvm -nosplash -logfile matlab_codegen.log -r "cd('../matlab/'),try, modesa_codegen('%1','%2','%3'); catch e, warning('MATLAB %s', e.message), quit, end, quit"
:: extract the PID of just started process
for /f "tokens=2" %%a in ('tasklist^|find /i "MATLAB"') do (set MyPID=%%a)
:: check the PID every two seconds if code generation is done
:LOOP
tasklist | find /i "%MyPID%" >nul 2>&1
IF ERRORLEVEL 1 (
  GOTO CONTINUE
) ELSE (
  ECHO MATLAB generates code ...
  TIMEOUT /T 2 /Nobreak >nul 2>&1
  GOTO LOOP
)

:CONTINUE
ECHO MATLAB code generation done
