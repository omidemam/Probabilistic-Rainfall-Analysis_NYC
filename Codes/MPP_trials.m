clc;clear;close all
Data = readtable('NYC_Central_Park_weather_1912_onwards.csv');
u = Data.PRCP';
tu = (0:length(u)-1);

K = length(u);
n = zeros(1, K);

pt = find(u > 0);
n(pt) = 1;
r = u;

M = 5e4;
ve = zeros(1, M);   % process noise variance
r0 = zeros(1, M);
r1 = zeros(1, M);   % linear model coefficients (continuous variable)
vr = zeros(1, M);   % observation noise variance (continuous variable)

x_pred = zeros(1, K);
v_pred = zeros(1, K);

x_updt = zeros(1, K);
v_updt = zeros(1, K);

x_smth = zeros(1, K);
v_smth = zeros(1, K);

p_updt = zeros(1, K);

tol = 1e-8; % convergence criteria


A = zeros(1, K);
W = zeros(1, K);
CW = zeros(1, K);
C = zeros(1, K);

base_prob = mean(u);

ve(1) = 0.5;
x_smth(1) = 0;
r0(1) = 0.03;

vr(1) = 0.2;
b0 = log(base_prob / (1 - base_prob));

for m = 1:M

    for k = 1:K

        if (k == 1)
            x_pred(k) = x_smth(1);
            v_pred(k) = ve(m) + ve(m);
        else
            x_pred(k) = x_updt(k - 1);
            v_pred(k) = v_updt(k - 1) + ve(m);
        end
        x_updt(k) = get_posterior_mode(x_pred(k), v_pred(k), r(k), r0(m), r1(m), vr(m), b0, n(k));
        p_updt(k) = 1 / (1 + exp((-1) * (b0 + x_updt(k))));

        if (n(k) == 0)
            v_updt(k) = 1 / ((1 / v_pred(k)) + p_updt(k) * (1 - p_updt(k)));
        elseif (n(k) == 1)
            v_updt(k) = 1 / ((1 / v_pred(k)) + ((r1(m) ^ 2) / vr(m)) + p_updt(k) * (1 - p_updt(k)));
        end
    end

    x_smth(K) = x_updt(K);
    v_smth(K) = v_updt(K);
    W(K) = v_smth(K) + (x_smth(K) ^ 2);

    A(1:(end - 1)) = v_updt(1:(end - 1)) ./ v_pred(2:end);

    for k = (K - 1):(-1):1
        x_smth(k) = x_updt(k) + A(k) * (x_smth(k + 1) - x_pred(k + 1));
        v_smth(k) = v_updt(k) + (A(k) ^ 2) * (v_smth(k + 1) - v_pred(k + 1));

        CW(k) = A(k) * v_smth(k + 1) + x_smth(k) * x_smth(k + 1);
        W(k) = v_smth(k) + (x_smth(k) ^ 2);
    end

    if (m < M)

        R = get_linear_parameters(x_smth, W, r, pt);

        if R(2, 1) > 0
            r0(m + 1) = R(1, 1);
            r1(m + 1) = R(2, 1);
            vr(m + 1) = get_maximum_variance(r, r0(m + 1), r1(m + 1), W, x_smth, pt);
        else
            fprintf('m = %d\nx0 = %.18f\n\nr0 = %.18f\nr1 = %.18f\nvr = %.18f\nve = %.18f\n\n', m, x_smth(1), r0(m), r1(m), vr(m), ve(m));
            fprintf('Converged at m = %d\n\n', m);
            break;
        end

        ve(m + 1) = (sum(W(2:end)) + sum(W(1:(end - 1))) - 2 * sum(CW)) / K;

        mean_dev = mean(abs([ve(m + 1) r0(m + 1) r1(m + 1) vr(m + 1)] - [ve(m) r0(m) r1(m) vr(m)]));

        if mean_dev < tol
            fprintf('m = %d\nx0 = %.18f\n\nr0 = %.18f\nr1 = %.18f\nvr = %.18f\nve = %.18f\n\n', m, x_smth(1), r0(m), r1(m), vr(m), ve(m));
            fprintf('Converged at m = %d\n\n', m);

            break;
        else
            fprintf('m = %d\nx0 = %.18f\n\nr0 = %.18f\nr1 = %.18f\nvr = %.18f\nve = %.18f\n\n', m, x_smth(1), r0(m + 1), r1(m + 1), vr(m + 1), ve(m + 1));

            x_pred = zeros(1, K);
            v_pred = zeros(1, K);

            x_updt = zeros(1, K);
            v_updt = zeros(1, K);

            x_smth(2:end) = zeros(1, K - 1);    % x_smth(1) needed for next iteration
            v_smth = zeros(1, K);

            p_updt = zeros(1, K);

            A = zeros(1, K);
            W = zeros(1, K);
            CW = zeros(1, K);
            C = zeros(1, K);
        end
    end
end

p_smth = 1 ./ (1 + exp((-1) * (b0 + x_smth)));
r_smth = r0(m) + r1(m) * x_smth;

certainty = 1 - normcdf(prctile(x_smth, 50) * ones(1, length(x_smth)), x_smth, sqrt(v_smth));

u_plot = NaN * ones(1, K);
u_plot(pt) = r(pt);

% calling timing data





figure('position', [0 0 515 660]);
subplot(311);
stem(tu, u_plot, 'fill', 'k', 'markersize', 5);hold on
%             plot(tu, r_smth, 'b', 'linewidth', 1.5);
ylabel('(a) Amplitude'); grid;
xlim([0 365*2]);
yl = ylim;
set(gca,'xticklabel', []);
title(['The Precipitation Measurement and Recovered Hidden State',' '])



subplot(312);
hold on;
plot(tu, x_smth, 'b', 'linewidth', 1.5);

ylabel('(b) State (x_{j})');
set(gca,'xticklabel', []);
xlim([0 365*2]);
grid; yl = ylim;





subplot(313);
hold on;
v1 = [0 0.9; tu(end) 0.9; tu(end) 1; 0 1];
c1 = [1 (220 / 255) (220 / 255); 1 (220 / 255) (220 / 255); 1 0 0; 1 0 0];
faces1 = [1 2 3 4];

patch('Faces', faces1, 'Vertices', v1, 'FaceVertexCData', c1, 'FaceColor', 'interp', ...
    'EdgeColor', 'none', 'FaceAlpha', 0.7);

v2 = [0 0; tu(end) 0; tu(end) 0.1; 0 0.1];
c2 = [0 0.8 0; 0 0.8 0; (204 / 255) 1 (204 / 255); (204 / 255) 1 (204 / 255)];
faces2 = [1 2 3 4];

patch('Faces', faces2, 'Vertices', v2, 'FaceVertexCData', c2, 'FaceColor', 'interp', ...
    'EdgeColor', 'none', 'FaceAlpha', 0.7);

plot(tu, certainty, 'color', [(138 / 255) (43 / 255) (226 / 255)], 'linewidth', 1.5); grid;
ylabel('(C) Normalized State'); xlabel('time');
xlim([0 365*2]);


[xtick_labels,xtick_positions] = myticks (Data);
xticks(xtick_positions);
xticklabels(xtick_labels);
xtickangle(45);
my_position = [0 2.5 10.5 6.5]; % left bottom width height]
set(gcf, 'units', 'inches', 'position', my_position);set(findall(gcf, '-property', 'FontSize'), 'FontSize', 12.5);
exportgraphics(gcf,"MPP"+".pdf")


MPP_result.number_of_iter = m;

MPP_result.r0 = r0(m);
MPP_result.r1 = r1(m);

MPP_result.ve = ve(m);
MPP_result.vr = vr(m);

MPP_result.x_smth = x_smth;
MPP_result.x_updt = x_updt;

MPP_result.r_smth = r_smth;

MPP_result.v_smth = v_smth;
MPP_result.v_updt = v_updt;

MPP_result.base_prob = base_prob;

MPP_result.p_smth = p_smth;





function [y] = get_posterior_mode(x_pred, v_pred, z, r0, r1, vr, b0, n)

M = 100;    % maximum iterations
y = NaN;

it = zeros(1, M);
f = zeros(1, M);
df = zeros(1, M);

it(1) = x_pred;

for i = 1:(M - 1)
    if (n == 0)
        C = v_pred;
        f(i) = it(i) - x_pred - C * (n - exp(b0 + it(i)) / (1 + exp(b0 + it(i))));
        df(i) = 1 + C * exp(b0 + it(i)) / (1 + exp(b0 + it(i))) ^ 2;
    elseif (n == 1)
        C = v_pred / ((r1 ^ 2) * v_pred + vr);
        f(i) = it(i) - x_pred - C * (r1 * (z - r0 - r1 * x_pred) + vr * (n - (1 / (1 + exp((-1) * (b0 + it(i)))))));
        df(i) = 1 + C * vr * exp(b0 + it(i)) / ((1 + exp(b0 + it(i))) ^ 2);
    end

    it(i + 1)  = it(i) - f(i) / df(i);

    if abs(it(i + 1) - it(i)) < 1e-14
        y = it(i + 1);
        return
    end
end

error('Newton-Raphson failed to converge.');

end

function y = get_maximum_variance(z, r0, r1, W, x_smth, pt)

x_smth = x_smth(pt);
W = W(pt);
z = z(pt);
K = length(pt);

y = (z * z' + K * (r0 ^ 2) + (r1 ^ 2) * sum(W) ...
    - 2 * r0 * sum(z) - 2 * r1 * dot(x_smth, z) + 2 * r0 * r1 * sum(x_smth)) / K;
end

function y = get_linear_parameters(x_smth, W, z, pt)

x_smth = x_smth(pt);
W = W(pt);
z = z(pt);
K = length(pt);

y = [K sum(x_smth); sum(x_smth) sum(W)] \ [sum(z); sum(z .* x_smth)];

end