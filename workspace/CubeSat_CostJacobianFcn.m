function [G,Gmv,Ge] = CubeSat_CostJacobianFcn(x,u,e,data,params)
%% CubeSat_CostJacobianFcn
%  
%  File: CubeSat_CostJacobianFcn.m
%  Directory: 1_PhD_projects/98_CubeSat/nmpc_gyakorlas
%  Author: Peter Polcz (ppolcz@gmail.com) 
%  
%  Created on 2019. December 18. (2019b)
%

p = data.PredictionHorizon;
Nx = data.NumOfStates;
Nmv = length(data.MVIndex);

G = zeros(p,Nx);
Gmv = zeros(p,Nmv);
Ge = 0;

% 2020.04.29. (április 29, szerda), 17:56
% Eddig hibasan ``Gmv(1,1) = -1'' szerepelt.
Gmv(1,2) = -1;

end