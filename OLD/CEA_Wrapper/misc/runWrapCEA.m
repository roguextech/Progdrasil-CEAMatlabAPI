function [ data ] = runWrapCEA( OF,pressure, supar, PcPe, fuel, fuelWt, fuelTemp, oxid, oxidWt, oxidTemp, folder_name,Debug)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Takes in as input information to write in wrapper.inp file
    % write wrapper.inp file
    % identify operating system
    % run PCEA2.out or PCEA2.exe depending on OS
    % open wrapper.out file created by CEA
    % read data in wrapper.out
    % close wrapper.out
    % return data in a table or struct 
    %
    % -----------INPUTS------------
    %   OF = oxidiser to fuel ratio [number]
    %   pressure = pressure initialy in PSI [number]
    %   supar = supersonic area ratio [number]
    %   PcPe = Pc/Pe    number]
    %   fuel = name of fuel(s) [cell array of strings]
    %   fuelwt = mass fraction percentage of fuel [array of numbers]
    %   fuelTemp = temperatures of fuel [array of numbers]
    %   oxid = name of oxidiser(s) [cell array of strings]
    %   oxidwt = mass fraction percentage of oxidizers [array of numbers]
    %   oxidTemp = temperature of oxidizers [array of numbers]
    %   folder_name = name of folder to add output file [string]
    %   Debug = to display time of computation of each major part of
    %   program [boolean]
    % 
    % fuel and fuelWt must always be of same size, same for oxid and oxidWt
    %
    % -----------OUTPUTS------------
    % data = struct with each row having the name of the property
    % other than OF, there are usually 4 values in order of :
    %       - CHAMBER
    %       - THROAT
    %       - EXIT
    %       - EXIT
    % -----------EXAMPLES------------
    % with one fuel and oxidiser
    %   data = runWrapCEA( 3 , 350 , 4.84 , 23.8 , 'paraffin' , 100, 298.15 , 'N2O', 100, 298.15, 'testDir',false)
    %
    % with multiple fuels and oxidizers
    %   data = runWrapCEA( 3 , 350 , 4.84 , 23.8 , {'paraffin' 'CH4' 'RP-1'} , [50 25 25], [298.15 298.15 298.15], {'N2O' 'O2(L)'}, [75 25],[298.15 90.1], 'testDir',true)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if nargin < 10
        Debug = false;
    end
    %%% Debug variables
    
%     clear all;
%     clc;
%     close all;
%     OF = 3;
%     pression = 350;
    presUnt = 'psia';
%     supar = 4.84;
%     PcPe = 23.8;
%     fuel = 'paraffin';
%     fuelWt = 100;
%     oxid = 'N2O';
%     oxidWt = 100;
    
    currentpath = which('runWrapCEA.m');
    [pathstr,~,~] = fileparts(currentpath);
    
    % verify wt percentages
    if sum(fuelWt)<=1
        fuelWt = fuelWt*100;
    end
    if sum(oxidWt)<=1
        oxidWt = oxidWt*100;
    end
    
    if Debug
        c1 = clock;
    end
    % Open wrapper.inp and overwrite
    IOinp = fopen(strcat(pathstr,'/wrapper.inp'),'w');
    
    % Write data in wrapper.inp
    fprintf(IOinp,'prob case=wrapper ro equilibrium \n\n');
    fprintf(IOinp,' ! iac problem \n');
    fprintf(IOinp,'o/f %g\n',OF);   %oxidiser to fuel ratio
    fprintf(IOinp,'p,%s  %g\n',presUnt,pressure); %pressure
    fprintf(IOinp,'supar %g\n',supar);  %supersonic area ratio
    fprintf(IOinp,'pip %g\n',PcPe);    %Pc/Pe
    fprintf(IOinp,'reac\n');
    if length(fuelWt)>1
        for i = 1:length(fuelWt)
            fprintf(IOinp,'  fuel  %s wt%%=%6.3f t,k=%6.2f\n',fuel{i},fuelWt(i),fuelTemp(i));
        end
    else
        fprintf(IOinp,'  fuel  %s wt%%=%g. t,k=%6.2f\n',fuel,fuelWt,fuelTemp);
    end
    if length(oxidWt)>1
        for i = 1:length(oxidWt)
            fprintf(IOinp,'  oxid  %s wt%%=%6.3f t,k=%6.2f\n',oxid{i},oxidWt(i),oxidTemp(i));
        end
    else
        fprintf(IOinp,'  oxid  %s wt%%=%g. t,k=%6.2f\n',oxid,oxidWt,oxidTemp);
    end
    fprintf(IOinp,'output    short\n');
    fprintf(IOinp,'output trace=1e-5\n');
    fprintf(IOinp,'end\n');
    
    % Close wrapper.inp
    fclose(IOinp);
    if Debug
        c1 = clock - c1;
        fprintf('time to write input file = %16.15e sec \n',c1(end))
    end

    if Debug
        c2 = clock;
    end
    % ID OS and run CEA acordingly
    if ismac
        [status,cmdout] = dos(strcat(pathstr,'/PCEA2.out'));
%         disp(status)
%         disp(cmdout)
    elseif isunix
        [status,cmdout] = dos(strcat(pathstr,'/PCEA2.out'));
%         disp(status)
%         disp(cmdout)
    elseif ispc
        [status,cmdout] = dos(strcat(pathstr,'\PCEA2.exe'));
%         disp(status)
%         disp(cmdout)
    else
        disp('Platform not supported')
    end  
    % wait until wrapper.dat exists
    while exist(strcat(pathstr,'/wrapper.dat'),'file')==0
    end
    
    if Debug
        c2 = clock - c2;
        fprintf('time to run CEA = %16.15e sec \n',c2(end))
    end
    
    if Debug
        c3 = clock;
    end
    % read output file and create struct
    data = ReadOutput(strcat(pathstr,'/wrapper.dat'));
    if Debug
        c3 = clock - c3;
        fprintf('time to read output file = %16.15e sec \n',c3(end))
    end
    
    if exist(folder_name,'dir') ~= 7
        mkdir(folder_name);
    end
    
    movefile(strcat(pathstr,'/wrapper.dat'),strcat(folder_name,'/OF',num2str(OF),'_P',num2str(pressure),'.dat'));


end

