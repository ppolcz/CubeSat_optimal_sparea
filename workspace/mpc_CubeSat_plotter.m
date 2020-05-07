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
    
    % Dependent variables, which were not exported:
    Prediction_Time = Ts * N;
    
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
    
    CubeSat_plot_v5
    
    keyboard, 
    print(pdfname,'-dpdf')
    
    pdfcrop_cmd = strrep(sprintf('pdfcrop %s %s', pdfname,texname),':','\:');
    output = system(pdfcrop_cmd);
    
    % copyfile(pdfname,texname);
    
end