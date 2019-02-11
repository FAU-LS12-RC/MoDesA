function rtwTargetInfo(cm)

cm.registerTargetInfo(@loc_register_crl);

function this = loc_register_crl

this(1) = RTW.TflRegistry;
this(1).Name = 'MoDesA replacement lib';
this(1).TableList = {'crl_table_modesa'};
this(1).BaseTfl = '';
this(1).TargetHWDeviceType = {'*'};
this(1).Description = 'This library offers implementation alternatives to unsupported HLS functions';
end
end
