%%
%  File: CubeSat_plot_v2.m
%  Directory: workspace
%  Author: Peter Polcz (ppolcz@gmail.com) 
% 
%  Created on 2020. May 01. (2019b)
% 
%%

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
axis([0 2*pi*T/P 275 310]), grid on, hold on
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

Logger.latexify_axis(15)

ax2 = subplot(212); hold off
pcz_stairs(2*pi*t/P,u(1,:), 'MarkerSize', 16), hold on
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

Logger.latexify_axis(15)


pdfname = logger.fig_fname('-v2.pdf',modelname);

save(logger.mat_fname);


%{

print(pdfname,'-dpdf')

print(pngname,'-dpng','-r500')

%}
