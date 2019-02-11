function hLib = crl_table_modesa


hLib = RTW.TflTable;
%---------- entry: memset ----------- 
hEnt = RTW.TflCFunctionEntry;
hEnt.setTflCFunctionEntryParameters( ...
          'Key', 'memset', ...
          'Priority', 100, ...
          'ImplementationName', 'dummy_memset');

% Conceptual Args

arg = hEnt.getTflArgFromString('y1','void*');
arg.IOType = 'RTW_IO_OUTPUT';
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('u1','void*');
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('u2','integer');
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('u3','size_t');
hEnt.addConceptualArg(arg);

% Implementation Args 

arg = hEnt.getTflArgFromString('y1','void*');
arg.IOType = 'RTW_IO_OUTPUT';
hEnt.Implementation.setReturn(arg); 

arg = hEnt.getTflArgFromString('u1','void*');
hEnt.Implementation.addArgument(arg);

arg = hEnt.getTflArgFromString('u2','integer');
hEnt.Implementation.addArgument(arg);

arg = hEnt.getTflArgFromString('u3','size_t');
hEnt.Implementation.addArgument(arg);

hLib.addEntry( hEnt ); 

end