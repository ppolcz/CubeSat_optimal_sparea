%%
%  File: mpc_CubeSat_1.m
%  Directory: 1_PhD_projects/98_CubeSat/CubeSat_MPC
%  Author: Peter Polcz (ppolcz@gmail.com)
%
%  Created on 2019. December 21. (2019b)
%  Modified on 2020. January 24. (2019b)
%
% Futtatasok:
% - 2019.12.21. (december 21, szombat), 06:20 [  OK  ]
% - 2020.01.24. (január 24, péntek), 04:16 [  OK  ]
% - 2020.01.29. (január 29, szerda), 04:45 [  OK  ]   --- lambda 0.7, 300 K

try c = evalin('caller','persist'); catch; c = []; end
persist = Persist(mfilename('fullpath'), c); clear c; 
persist.backup();
%clear persist

%% Simulation

%{ 

% 2020.01.29. (január 29, szerda), 04:44
lambdaStar = 0.5;

P = 5400;
t = linspace(0,4*P,4*P)';

lambda = lambdaStar;

u = [ 0 + 0*t , lambda + 0*t , CubeSat_rho(t) ];

u_ode = @(time) interp1(t,u,time)';
f_ode = @(t,x) CubeSat_StateFcn(x,u_ode(t),lambdaStar);

x0 = [
    310.0799
    300.4167
    298.4108
    255.9591
    253.7917
    253.7917
    276.1519
    ];

[tt,xx] = ode45(f_ode,t([1,end]),x0);

figure(2),
ax(1) = subplot(211); hold off
plot(tt / P,xx(:,1:6)), grid on, hold on
plot(tt / P,xx(:,7), 'LineWidth', 3)
legend T1 T2 T3 T4 T5 T6 Tt

ax(2) = subplot(212); hold off
plot(tt / P, CubeSat_rho(tt)), grid on

linkaxes(ax,'x')

%}

%%

lambdaStar = 1;
lambda_lims = [ 0 1 ];
Tt_Min = 290;
Tt_Max = 330;
Time_for_convergence = 1000; % seconds
dQc_Max = 1.069;

% Order of inputs:
% dQc = u(1);     (manipulated variable)
% lambda = u(2);  (manipulated CONSTANT variable)
% rho1 = u(3);    (measured disturbance)
% rho2 = u(4);    (measured disturbance)
% rho4 = u(5);    (measured disturbance)

nlobj = nlmpc(7,7,'MV',[1 2],'MD',[3 4 5]);

params = { lambdaStar };
nlobj.Model.NumberOfParameters = 1;
nlobj.Model.StateFcn = @CubeSat_StateFcn;
nlobj.Jacobian.StateFcn = @CubeSat_StateJacobianFcn;

nlobj.Optimization.CustomCostFcn = @(x,u,e,data,params) 1-u(1,2);
nlobj.Jacobian.CustomCostFcn = @CubeSat_CostJacobianFcn;

% Prediction horizon
T = 2*P;

% Samples per period
resolution = 20;

% Samples per prediction horizon
N = round(resolution * T/P);

% Sampling interval
Ts = T / N;

nlobj.Ts = Ts;
nlobj.PredictionHorizon = N;
nlobj.ControlHorizon = N;
nlobj.Model.IsContinuousTime = true;

p = nlobj.PredictionHorizon;

% Constraints for lambda (constant), between [0,1]
nlobj.Optimization.CustomEqConFcn = @(x,u,data,params) u(1:p+1,2) - u(1,2);
nlobj.ManipulatedVariables(2).Min = lambda_lims(1);
nlobj.ManipulatedVariables(2).Max = lambda_lims(2);

% Interval constraint for dQc
nlobj.ManipulatedVariables(1).Min = 0;
nlobj.ManipulatedVariables(1).Max = dQc_Max;

% Interval constraints for the tank temperature [version 2 - less strict]
% The interval constraints for the tank temperature is prescribed only
% after these transient steps.
p1 = ceil(Time_for_convergence / Ts)
nlobj.Optimization.CustomIneqConFcn = ...
    @(x,u,e,data,params) [ -x(p1:p+1,7)+Tt_Min ; x(p1:p+1,7)-Tt_Max ];

% Interval constraints for the tank temperature [version 1 - too strict]
% nlobj.Optimization.CustomIneqConFcn = ...
%     @(X,U,e,data,params) [ -U(1:p+1,1) ; -1 + U(1:p+1,1) ];


% Interval constraints for the tank temperature
% nlobj.States(7).Min = Tt_Min;
% nlobj.States(7).Max = Tt_Max;

% Check model
validateFcns(nlobj,x0,[1,1],[0,0,0],params)

t = 0:Ts:T;
ts = t(p1:p+1);
opt = nlmpcmoveopt;
opt.Parameters = params;
[mv,opt,info] = nlmpcmove(nlobj,x0,[0;0],[],CubeSat_rho(t),opt)

u = info.MVopt';
x = info.Xopt;

minu = min(nlobj.ManipulatedVariables(1).Min,round(min(u(1,:)),3));
maxu = max(nlobj.ManipulatedVariables(1).Max,round(max(u(1,:)),3));
if -1e-10 < minu
    minu = abs(minu);
end

lambda = min(u(2,:));
if lambda - max(u(2,:)) > 1e-10
    info.ExitFlag = -3;
end

figure(2), subplot(211), hold off
plot(t, x(:,end),'o-', 'LineWidth', 3, 'MarkerSize', 10),
axis([0 T 275 340]), grid on, hold on
shade(ts, Tt_Min + 0*ts, ts, Tt_Max + 0*ts, 'FillType', [1 2;2 1]);
plot([1 1]*t(p1), [Tt_Min Tt_Max], 'r', 'LineWidth',3);
title(sprintf('$\\lambda^* = %g,~ \\lambda = %g,~ T_t \\in [%d,%d],~ \\dot Q_c \\in [%g,%g]$. Feasible: %g', ...
    lambdaStar, round(lambda,3), [Tt_Min Tt_Max], minu, maxu,...
    info.ExitFlag), 'Interpreter', 'LaTeX', 'FontSize', 15)

subplot(212), hold off
plot(t,u(1,:),'o-', 'LineWidth', 3, 'MarkerSize', 10), hold on
axis tight, grid on
title('Control input $\dot Q_c(t)$', 'Interpreter', 'LaTeX', 'FontSize', 20)

return

%% Cikkbe

labels = {
    '0'
    % '$\frac{\pi}{4}$'
    '$\frac{\pi}{2}$'
    % '$\frac{3\pi}{4}$'
    '$\pi$'
    % '$\frac{5\pi}{4}$'
    '$\frac{3\pi}{2}$'
    % '$\frac{7\pi}{4}$'
    '$2\pi$'
    % '$\frac{9\pi}{4}$'
    '$\frac{5\pi}{2}$'
    % '$\frac{11\pi}{4}$'
    '$3\pi$'
    % '$\frac{13\pi}{4}$'
    '$\frac{7\pi}{2}$'
    % '$\frac{7\pi}{4}$'
    '$~~~~4\pi \cdot \frac{P}{2 \pi}$'
    };

fig = figure(3);
ax1 = subplot(211); hold off
plot(2*pi*t/P, x(:,end),'.:', 'LineWidth', 1.5, 'MarkerSize', 16),
axis([0 2*pi*T/P 275 330]), grid on, hold on
shade(2*pi*ts/P, Tt_Min + 0*ts, 2*pi*ts/P, Tt_Max + 0*ts, 'FillType', [1 2;2 1]);
plot([1 1]*2*pi*t(p1)/P, [Tt_Min Tt_Max], 'r', 'LineWidth',3);
title(sprintf('$T_{\\mathrm{T}} \\in [%d,%d]\\, \\mathrm{K}$, $\\lambda = %g$ ($\\lambda^* = %g$).', ...
    [Tt_Min Tt_Max],round(lambda,3), lambdaStar), 'Interpreter', 'LaTeX', 'FontSize', 15)
% title(sprintf('$T_{\\mathrm{T}} \\in [%d,%d]\\, \\mathrm{K}$, $\\dot Q_{\\mathrm{c}} \\in [%g,%g]$, $\\lambda = %g$ ($\\lambda^* = %g$).', ...
%     [Tt_Min Tt_Max],minu, maxu, round(lambda,3), lambdaStar), 'Interpreter', 'LaTeX', 'FontSize', 15)

ylabel('Tank temp. [K]','FontSize',15,'Interpreter','latex')

text(pi/4,280,'$P_1$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(pi,280,'$P_2$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(7*pi/4,280,'$P_3$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(9*pi/4,280,'$P_1$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(3*pi,280,'$P_2$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(15*pi/4,280,'$P_3$','FontSize',15,'Interpreter','latex','horizontalalignment','center')

plot([0 0 1 1 3 3 4 4 5 5 7 7 8 8 9 9]*pi/2,repmat([-2 2 2 -2],[1 4])*500,'--','Color',pcz_get_plot_colors([],2),'LineWidth',2)
plot([0 0 4 4 8 8]*pi/2,[2 -2 -2 2 2 -2]*500,'-','Color',pcz_get_plot_colors([],2),'LineWidth',2)

xticks((0:0.25:T/P)*2*pi);
xticklabels(labels)

PersistStandalone.latexify_axis(15)

ax2 = subplot(212); hold off
plot(2*pi*t/P,u(1,:),'.:', 'LineWidth', 1.5, 'MarkerSize', 16), hold on
axis tight, grid on

ylabel('Control input','FontSize',15,'Interpreter','latex')
xlabel('Time $t$ [sec]','FontSize',15,'Interpreter','latex')

title(sprintf('Heat flux $\\dot Q_{\\mathrm{c}} \\in [%g,%g]$.', ...
    minu, maxu), 'Interpreter', 'LaTeX', 'FontSize', 15)

text(pi/4,280,'$P_1$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(pi,280,'$P_2$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(7*pi/4,280,'$P_3$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(9*pi/4,280,'$P_1$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(3*pi,280,'$P_2$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(15*pi/4,280,'$P_3$','FontSize',15,'Interpreter','latex','horizontalalignment','center')

ax2.YLim = [min(u(1,:)) max(u(1,:))];
ax2.XLim = [0 2*pi*T/P];

plot([0 0 1 1 3 3 4 4 5 5 7 7 8 8 9 9]*pi/2,repmat([-2 2 2 -2],[1 4])*500,'--','Color',pcz_get_plot_colors([],2),'LineWidth',2)
plot([0 0 4 4 8 8]*pi/2,[2 -2 -2 2 2 -2]*500,'-','Color',pcz_get_plot_colors([],2),'LineWidth',2)

xticks((0:0.25:T/P)*2*pi);
xticklabels(labels)

PersistStandalone.latexify_axis(15)


pdfname = persist.file_simple('fig',sprintf('MPC_res%d_per%d_Tt%d_%d_dQc%g_lambda%g.pdf',...
    resolution,round(T/P),[Tt_Min Tt_Max],maxu,round(lambda,3)));

matname = persist.file_simple('mat',sprintf('MPC_res%d_per%d_Tt%d_%d_dQc%g_lambda%g.mat',...
    resolution,round(T/P),[Tt_Min Tt_Max],maxu,round(lambda,3)));


%{

print(pdfname,'-dpdf')

save(matname)

% print(pngname,'-dpng','-r500')

%}

%% Cikkbe

labels = {
    '0'
    % '$\frac{\pi}{4}$'
    '$\frac{\pi}{2}$'
    % '$\frac{3\pi}{4}$'
    '$\pi$'
    % '$\frac{5\pi}{4}$'
    '$\frac{3\pi}{2}$'
    % '$\frac{7\pi}{4}$'
    '$2\pi$'
    % '$\frac{9\pi}{4}$'
    '$\frac{5\pi}{2}$'
    % '$\frac{11\pi}{4}$'
    '$3\pi$'
    % '$\frac{13\pi}{4}$'
    '$\frac{7\pi}{2}$'
    % '$\frac{7\pi}{4}$'
    '$~~~~4\pi \cdot \frac{P}{2 \pi}$'
    };

fig = figure(3);
ax1 = subplot(311); hold off
plot(2*pi*t/P, x(:,end),'.:', 'LineWidth', 1.5, 'MarkerSize', 16),
axis([0 2*pi*T/P 270 330]), grid on, hold on, yticks(270:20:330)
shade(2*pi*ts/P, Tt_Min + 0*ts, 2*pi*ts/P, Tt_Max + 0*ts, 'FillType', [1 2;2 1]);
plot([1 1]*2*pi*t(p1)/P, [Tt_Min Tt_Max], 'r', 'LineWidth',3);
title(sprintf('$T_{\\mathrm{T}} \\in [%d,%d]\\, \\mathrm{K}$, $\\lambda = %g$ ($\\lambda^* = %g$).', ...
    [Tt_Min Tt_Max],round(lambda,3), lambdaStar), 'Interpreter', 'LaTeX', 'FontSize', 15)
% title(sprintf('$T_{\\mathrm{T}} \\in [%d,%d]\\, \\mathrm{K}$, $\\dot Q_{\\mathrm{c}} \\in [%g,%g]$, $\\lambda = %g$ ($\\lambda^* = %g$).', ...
%     [Tt_Min Tt_Max],minu, maxu, round(lambda,3), lambdaStar), 'Interpreter', 'LaTeX', 'FontSize', 15)

ylabel('Tank temp. [K]','FontSize',13,'Interpreter','latex')

text(pi/4,280,'$P_1$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(pi,280,'$P_2$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(7*pi/4,280,'$P_3$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(9*pi/4,280,'$P_1$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(3*pi,280,'$P_2$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(15*pi/4,280,'$P_3$','FontSize',15,'Interpreter','latex','horizontalalignment','center')

plot([0 0 1 1 3 3 4 4 5 5 7 7 8 8 9 9]*pi/2,repmat([-2 2 2 -2],[1 4])*500,'--','Color',pcz_get_plot_colors([],2),'LineWidth',2)
plot([0 0 4 4 8 8]*pi/2,[2 -2 -2 2 2 -2]*500,'-','Color',pcz_get_plot_colors([],2),'LineWidth',2)

xticks((0:0.25:T/P)*2*pi);
xticklabels(labels)

PersistStandalone.latexify_axis(15)

ax2 = subplot(312); hold off
plot(2*pi*t/P, x(:,1:6),'.-')

axis([0 2*pi*T/P 250 400]), grid on, hold on
title(sprintf('Surface temperature $T_i \\in [%d,%d]\\, \\mathrm{K}$, $i = 1 \\dots 6$.', ...
    floor(min(min(x(:,1:6)))), ceil(max(max(x(:,1:6))))), 'Interpreter', 'LaTeX', 'FontSize', 15)
% title(sprintf('$T_{\\mathrm{T}} \\in [%d,%d]\\, \\mathrm{K}$, $\\dot Q_{\\mathrm{c}} \\in [%g,%g]$, $\\lambda = %g$ ($\\lambda^* = %g$).', ...
%     [Tt_Min Tt_Max],minu, maxu, round(lambda,3), lambdaStar), 'Interpreter', 'LaTeX', 'FontSize', 15)

ylabel('Faces temp. [K]','FontSize',13,'Interpreter','latex')

plot([0 0 1 1 3 3 4 4 5 5 7 7 8 8 9 9]*pi/2,repmat([-2 2 2 -2],[1 4])*500,'--','Color',pcz_get_plot_colors([],2),'LineWidth',2)
plot([0 0 4 4 8 8]*pi/2,[2 -2 -2 2 2 -2]*500,'-','Color',pcz_get_plot_colors([],2),'LineWidth',2)

xticks((0:0.25:T/P)*2*pi);
xticklabels(labels)

PersistStandalone.latexify_axis(15)

ax3 = subplot(313); hold off
plot(2*pi*t/P,u(1,:),'.:', 'LineWidth', 1.5, 'MarkerSize', 16), hold on
axis tight, grid on

ylabel('Control input [W]','FontSize',13,'Interpreter','latex')
xlabel('Time $t$ [sec]','FontSize',13,'Interpreter','latex')

title(sprintf('Heat flux $\\dot Q_{\\mathrm{c}} \\in [%g,%g]\\, \\mathrm{W}$.', ...
    minu, maxu), 'Interpreter', 'LaTeX', 'FontSize', 15)

text(pi/4,280,'$P_1$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(pi,280,'$P_2$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(7*pi/4,280,'$P_3$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(9*pi/4,280,'$P_1$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(3*pi,280,'$P_2$','FontSize',15,'Interpreter','latex','horizontalalignment','center')
text(15*pi/4,280,'$P_3$','FontSize',15,'Interpreter','latex','horizontalalignment','center')

ax3.YLim = [min([ u(1,:) 0]) max(u(1,:))];
ax3.XLim = [0 2*pi*T/P];

plot([0 0 1 1 3 3 4 4 5 5 7 7 8 8 9 9]*pi/2,repmat([-2 2 2 -2],[1 4])*500,'--','Color',pcz_get_plot_colors([],2),'LineWidth',2)
plot([0 0 4 4 8 8]*pi/2,[2 -2 -2 2 2 -2]*500,'-','Color',pcz_get_plot_colors([],2),'LineWidth',2)

xticks((0:0.25:T/P)*2*pi);
xticklabels(labels)

PersistStandalone.latexify_axis(15)


pdfname = persist.file_simple('fig',sprintf('MPC_res%d_per%d_Tt%d_%d_dQc%g_lambda%g-new.pdf',...
    resolution,round(T/P),[Tt_Min Tt_Max],maxu,round(lambda,3)));

matname = persist.file_simple('mat',sprintf('MPC_res%d_per%d_Tt%d_%d_dQc%g_lambda%g.mat',...
    resolution,round(T/P),[Tt_Min Tt_Max],maxu,round(lambda,3)));


%{

% Position: [1 1 694 581]
    
print(pdfname,'-dpdf')

save(matname)

% print(pngname,'-dpng','-r500')

%}