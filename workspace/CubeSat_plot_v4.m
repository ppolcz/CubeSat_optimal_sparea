%%
%  File: CubeSat_plot_v4.m
%  Directory: workspace
%  Author: Peter Polcz (ppolcz@gmail.com) 
% 
%  Created on 2020. May 01. (2019b)
% 

fig = figure(4);
ts = (p1-1)*Ts:Ts:10*Prediction_Time;

Title_fontSize = 13.5;

%% First subplot
ax1 = subplot(611); hold off

% Predicted tank temperature (discrete-time)
plot(2*pi*t/P, x(:,end),'.-', 'LineWidth', 1.5, 'MarkerSize', 10), hold on

% Red shaded region (allowed region)
shade(2*pi*ts/P, Tt_Min + 0*ts, 2*pi*ts/P, Tt_Max + 0*ts, 'FillType', [1 2;2 1]);

% Red vertical line at start time
plot([1 1]*2*pi*t(p1)/P, [Tt_Min Tt_Max], 'r', 'LineWidth',3);

% Plot decorations
axis([0 2*pi*Prediction_Time/P Tt_lim]), grid on
title(sprintf('Predicted $T_{\\mathrm{T}}(t_i) \\in [%d,%d]\\, \\mathrm{K},\\, i = %d,\\dots,N=%d,\\, \\lambda = %g$ ($\\lambda^*_{(%d)} = %g$).', ...
    [Tt_Min Tt_Max],p1-1,N,round(lambda,3), NrIt, round(lambdaStar,3)), 'Interpreter', 'LaTeX', 'FontSize', Title_fontSize)
ylabel('Tank temp. [K]','FontSize',13,'Interpreter','latex')
CubeSat_plot_v3_helper_P2(280);
Logger.latexify_axis(15)


%% Second subplot
ax2 = subplot(612); hold off

% Predicted faces temperature
plot(2*pi*t/P, x(:,1:6),'.-'), hold on

% Plot decorations
axis([0 2*pi*Prediction_Time/P Ts_lim]), grid on
title(sprintf('Predicted surface temperature $T_j(t_i) \\in [%d,%d]\\, \\mathrm{K}$, $j = 1, \\dots, 6$.', ...
    floor(min(min(x(:,1:6)))), ceil(max(max(x(:,1:6))))), 'Interpreter', 'LaTeX', 'FontSize', Title_fontSize)
ylabel('Faces temp. [K]','FontSize',13,'Interpreter','latex')
CubeSat_plot_v3_helper_P2(Inf);
Logger.latexify_axis(15)


%% Third subplot
ax3 = subplot(613); hold off

% Computed staircase input function
if u_MPC
    plot(2*pi*t/P,u(:,1),'.-', 'MarkerSize', 10, 'LineWidth', 1); hold on
else
    pcz_stairs(2*pi*t/P,u(:,1), 'MarkerSize', 7, 'HLineWidth', 1); hold on
end

% Plot decorations
axis tight, grid on
ax3.YLim = dQc_lim;
ax3.XLim = [0 2*pi*Prediction_Time/P];
ylabel('Control input [W]','FontSize',13,'Interpreter','latex')
title(sprintf('Conputed discrete-time input heat flux $\\dot Q_{\\mathrm{c}}(t_i) \\in [%g,%g]\\, \\mathrm{W}$.', ...
    minu, maxu), 'Interpreter', 'LaTeX', 'FontSize', Title_fontSize)
CubeSat_plot_v3_helper_P2(Inf);
Logger.latexify_axis(15)


%% Fourth subplot
ax4 = subplot(614); hold off

% Simulated tank temperature (continuous-time)
Pl_sim = plot(2*pi*tt/P, xx(:,end),'-', 'LineWidth', 1.5, 'MarkerSize', 10); hold on

% Red shaded region (allowed region)
shade(2*pi*ts/P, Tt_Min + 0*ts, 2*pi*ts/P, Tt_Max + 0*ts, 'FillType', [1 2;2 1]);

% Red vertical line at start time
plot([1 1]*2*pi*t(p1)/P, [Tt_Min Tt_Max], 'r', 'LineWidth',3);

% Predicted tank temperature (discrete-time)
Pl_pred = plot(2*pi*t/P, x(:,end),'.-', 'LineWidth', 1, 'MarkerSize', 10, 'Color', [1,1,1]/2);

% Plot decorations
axis([0 2*pi*Simulation_Time/P Tt_lim]), grid on
title(sprintf('Simulated $T_{\\mathrm{T}}(t) \\in [%d,%d]\\, \\mathrm{K}$, $\\lambda = %g$.', ...
    floor(min(xx(tt > Time_for_convergence,end))), ceil(max(xx(tt > Time_for_convergence,end))),...
    round(lambda,3)), 'Interpreter', 'LaTeX', 'FontSize', Title_fontSize)
ylabel('Tank temp. [K]','FontSize',13,'Interpreter','latex')
CubeSat_plot_v3_helper_P4(280);
Logger.latexify_axis(15)
T1 = text(Time_for_convergence/P*2*pi,Tt_lim(1)+(Tt_lim(2)-Tt_lim(1))/10,...
    sprintf('(MSE: %s [K], abs err: %s [K])', num2str(MSE), num2str(AbsEr)), ...
    'interpreter', 'latex','FontSize',10,'VerticalAlignment','bottom',...
    'BackgroundColor','white');

Leg = legend([Pl_pred Pl_sim], {'Predicted' 'Simulated'});
Leg.Interpreter = 'latex';
Leg.FontSize = 11;
Leg.Location = 'southeast';

%% Fifth subplot
ax4 = subplot(615); hold off

% Simulated faces temperature
plot(2*pi*tt/P, xx(:,1:6),'-'), hold on

% Plot decorations
axis([0 2*pi*Simulation_Time/P Ts_lim]), grid on
title(sprintf('Simulated surface temperature $T_j(t) \\in [%d,%d]\\, \\mathrm{K}$, $j = 1, \\dots, 6$.', ...
    floor(min(min(xx(:,1:6)))), ceil(max(max(xx(:,1:6))))), 'Interpreter', 'LaTeX', 'FontSize', Title_fontSize)
ylabel('Faces temp. [K]','FontSize',13,'Interpreter','latex')
CubeSat_plot_v3_helper_P4(Inf);
Logger.latexify_axis(15)


%% Sixth subplot
ax6 = subplot(616); hold off

CubeSat_plot_v3_helper_P4(Inf), hold on;

% Computed staircase input function
if u_SIM
    plot(2*pi*tt/P,u_fh(tt), 'MarkerSize', 0.1, 'Color', pcz_get_plot_colors([],1));
else
    pcz_stairs(2*pi*tt/P,u_fh(tt), 'MarkerSize', 0.1, 'Color', pcz_get_plot_colors([],1));
end

% Plot decorations
axis tight, grid on
ax6.YLim = dQc_lim;
ax6.XLim = [0 2*pi*Simulation_Time/P];
xlabel('Time $t$ [sec]','FontSize',13,'Interpreter','latex')
ylabel('Control input [W]','FontSize',13,'Interpreter','latex')
title(sprintf('Continuous-time input heat flux $\\dot Q_{\\mathrm{c}}(t) \\in [%g,%g]\\, \\mathrm{W}$.', ...
    minu, maxu), 'Interpreter', 'LaTeX', 'FontSize', Title_fontSize)
Logger.latexify_axis(15)

%% Export figure

% %{

% Position: [2291 23 708 1335]

pdfname = logger.fig_fname('-v4.pdf', modelname);
print(pdfname,'-dpdf')

% print(pngname,'-dpng','-r500')

%}
