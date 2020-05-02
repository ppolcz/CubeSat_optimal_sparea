%%
%  File: CubeSat_plot_v3.m
%  Directory: workspace
%  Author: Peter Polcz (ppolcz@gmail.com) 
% 
%  Created on 2020. May 01. (2019b)
% 

fig = figure(3);
ts = t(p1:end);

Title_fontSize = 13.5;

%% First subplot
ax1 = subplot(311); hold off

% Predicted tank temperature (discrete-time)
plot(2*pi*t/P, x(:,end),'.-', 'LineWidth', 1.5, 'MarkerSize', 16), hold on

% Red shaded region (allowed region)
shade(2*pi*ts/P, Tt_Min + 0*ts, 2*pi*ts/P, Tt_Max + 0*ts, 'FillType', [1 2;2 1]);

% Red vertical line at start time
plot([1 1]*2*pi*t(p1)/P, [Tt_Min Tt_Max], 'r', 'LineWidth',3);

% Plot decorations
axis([0 2*pi*Prediction_Time/P Tt_lim]), grid on
title(sprintf('Predicted $T_{\\mathrm{T}}(t_i) \\in [%d,%d],\\, i = 1,\\dots,N,\\, \\mathrm{K}$, $\\lambda = %g$ ($\\lambda^* = %g$).', ...
    [Tt_Min Tt_Max],round(lambda,3), round(lambdaStar,3)), 'Interpreter', 'LaTeX', 'FontSize', Title_fontSize)
ylabel('Tank temp. [K]','FontSize',13,'Interpreter','latex')
CubeSat_plot_v3_helper_P2(280);
Logger.latexify_axis(15)


%% Second subplot
ax2 = subplot(312); hold off

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
ax3 = subplot(313); hold off

% Computed staircase input function
plot(2*pi*t/P,u(:,1),'.-', 'MarkerSize', 16); hold on

% Plot decorations
axis tight, grid on
ax3.YLim = dQc_lim;
ax3.XLim = [0 2*pi*Prediction_Time/P];
xlabel('Time $t$ [sec]','FontSize',13,'Interpreter','latex')
ylabel('Control input [W]','FontSize',13,'Interpreter','latex')
title(sprintf('Conputed discrete-time input heat flux $\\dot Q_{\\mathrm{c}}(t_i) \\in [%g,%g]\\, \\mathrm{W}$.', ...
    minu, maxu), 'Interpreter', 'LaTeX', 'FontSize', Title_fontSize)
CubeSat_plot_v3_helper_P2(Inf);
Logger.latexify_axis(15)

%% Export figure

% %{

% Position: [1 1 694 581]
    
pdfname = logger.fig_fname('-v3.pdf', modelname);
print(pdfname,'-dpdf')

% print(pngname,'-dpng','-r500')

%}
