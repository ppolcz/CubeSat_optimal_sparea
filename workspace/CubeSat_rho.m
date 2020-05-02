function rho = CubeSat_rho(t)
%% CubeSat_rho
%  
%  File: CubeSat_rho.m
%  Directory: 1_PhD_projects/98_CubeSat
%  Author: Peter Polcz (ppolcz@gmail.com) 
%  
%  Created on 2019. December 17. (2019b)
%

t = t(:);

% Period:
P = 5400; 

% Time elapsed in the actual period
time = mod(t, 5400);

% Logical value, whether t is in a certain interval of the period
time_in_P2 = 1351 < time & time <= 4051;
time_in_P23 = 1351 < time;
time_in_P12 = time <= 4051;

rho1 = cos(2*pi*t/P);
rho2 = abs(sin(2*pi*t/P));
rho4 = sin(2*pi*t/P);

rho1(time_in_P2) = 0;
rho2(time_in_P12) = 0;
rho4(time_in_P23) = 0;

rho = [ rho1 rho2 rho4 ];

end