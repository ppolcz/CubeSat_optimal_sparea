%%
%  File: CubeSat_plot_simulation.m
%  Directory: workspace
%  Author: Peter Polcz (ppolcz@gmail.com) 
% 
%  Created on 2020. May 01. (2019b)
% 

%%

t = linspace(0,4*P,4*P)';

lambda = lambdaStar;

u = [ 0 + 0*t , lambda + 0*t , CubeSat_rho(t) ];

u_ode = @(time) interp1(t,u,time)';
f_ode = @(t,x) CubeSat_StateFcn(x,[CubeSat_targetMV_computed(t) lambda CubeSat_rho(t)]',lambdaStar);

[tt,xx] = ode45(f_ode,t([1,end]),x0);

figure(2),
ax(1) = subplot(211); hold off
plot(tt / P,xx(:,1:6)), grid on, hold on
plot(tt / P,xx(:,7), 'LineWidth', 3)
legend T1 T2 T3 T4 T5 T6 Tt

ax(2) = subplot(212); hold off
plot(tt / P, CubeSat_rho(tt)), grid on

linkaxes(ax,'x')
