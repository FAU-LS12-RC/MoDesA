@ECHO OFF

START "" matlab -nodesktop -nojvm -nosplash -logfile matlab_codegen.log -r "cd('../matlab/'),try, modesa_codegen('%1','%2','%3'); catch e, warning('MATLAB %s', e.message), quit, end, quit"

:LOOP
tasklist | find /i "MATLAB" >nul 2>&1
IF ERRORLEVEL 1 (
  GOTO CONTINUE
) ELSE (
  ECHO MATLAB generates code ...
  TIMEOUT /T 2 /Nobreak >nul 2>&1
  GOTO LOOP
)

:CONTINUE
ECHO MATLAB code generation done
