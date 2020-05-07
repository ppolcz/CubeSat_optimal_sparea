%%
%  File: mpc_CubeSat_plotter.m
%  Directory: workspace
%  Author: Peter Polcz (ppolcz@gmail.com) 
% 
%  Created on 2020. May 05. (2019b)
% 

%%

Result = 'results/mpc_CubeSat-output-2020-05-05_22:09_id0109';

fileList = dir([Result filesep '*.mat']);

for i = 1:numel(fileList)
    
    [~,name,~] = fileparts(fileList(i).name);
    matname = [Result filesep fileList(i).name];
    pdfname = [Result filesep name '.pdf'];
    texname = ['/home/ppolcz/_/3_docs/98_CubeSat/SPIIRAS/Fig/MPC_new/Setup' num2str(i) '.pdf'];
    
    load(matname);
    
    % MPC results:
    lambda = MPC_desing.lambda;
    t = MPC_desing.t;
    u = [ MPC_desing.u MPC_desing.u*0 + lambda ];
    x = MPC_desing.x;
    
    % Simulation results:
    u_SIM = 1;
    tt = Simulation.t;
    uu = Simulation.u;
    xx = Simulation.x;
    
    % Dependent variables, which were not exported:
    Prediction_Time = Ts * N;    
    Sim_Max = max(xx(tt >= t(p1),7));
    Sim_Min = min(xx(tt >= t(p1),7));
    OverShoot = +Sim_Max - Tt_Max;
    UnderShoot = -Sim_Min + Tt_Min;
    
    ou = {};
    if UnderShoot > 0
        ou = [ou {sprintf('undershoot:\\,$%g$\\,K', round(UnderShoot,2))}];
    end
    if OverShoot > 0
        ou = [ou {sprintf('overshoot:\\,$%g$\\,K', round(OverShoot,2))}];
    end
    ou = strjoin(ou,', ');
    
    
    % Shoot = [
    %     Sim_Max OverShoot
    %     Sim_Min UnderShoot
    %     ];
    
    fprintf('The simulated tank temperature satisfies $\\TT(t) \\in [%g,%g]\\,\\mathrm{K}$ for all $t \\in [%d \\mathrm{s},4P]$, ',...
        round(Sim_Min,2),round(Sim_Max,2),...
        t(p1))
    fprintf('i.e., the overshoot and undershoot are $%g\\,\\mathrm{K}$ and $%g\\,\\mathrm{K}$, respectively.\n',...
        round(OverShoot,2),round(UnderShoot,2))
    
    
    CubeSat_plot_v5
    
    keyboard, 
    print(pdfname,'-dpdf')
    
    pdfcrop_cmd = strrep(sprintf('pdfcrop %s %s', pdfname,texname),':','\:');
    output = system(pdfcrop_cmd);
    
    % copyfile(pdfname,texname);
    
end