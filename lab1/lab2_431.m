clear; clc;

%================ PARAMETRY NOMINALNE ====================
TzewN = -20;        %oC
TwewN = 20;         %oC
TpN = 15;           %oC
Vw = 100 * 2.5;     %m3     objętość pokoju
Vp = 0.25 * Vw;     %m3     objętość poddasza
PgN = 10000;        %W      zapotrzebowanie budynku na ciepło
cpp = 1000;         %J/(kgK) powietrze - ciepło właściwe
rop = 1.2;          %kg/m3  powietrze - gęstość

%================ IDENTYFIKACJA PARAMETRÓW ====================
heatLossFactor = 3; % Wsp. strat ciepła przez ściany względem sufitu
Kp = PgN / (TwewN * (heatLossFactor + 1) - heatLossFactor * TzewN - TpN);
Kd = Kp * (TwewN - TpN) / (TpN - TzewN);
K1 = heatLossFactor * Kp;

Cvw = cpp * rop * Vw; % J/K - pojemność cieplna parteru
Cvp = cpp * rop * Vp; % J/K - pojemność cieplna poddasza

fprintf('Parametry statyczne:\nKp = %.2f, Kd = %.2f, K1 = %.2f\n', Kp, Kd, K1);

%================ DEFINICJA FUNKCJI ====================
function [Tp_eq, Twew_eq] = computeEquilibrium(Tzew, Pg, Kp, K1, Kd)
    Tp_eq = Pg * (Kp / (K1 * Kp + K1 * Kd + Kp * Kd)) + Tzew;
    Twew_eq = Tp_eq + (Kd / Kp) * (Tp_eq - Tzew);
end

%================ PUNKT PRACY ====================
Tzew0 = TzewN;
Pg0 = PgN*0.7;

[Tp0, Twew0] = computeEquilibrium(Tzew0, Pg0, Kp, K1, Kd);
fprintf('Punkt pracy:\nTwew0 = %.2f, Tp0 = %.2f\n', Twew0, Tp0);

%================ SYMULACJA ====================
simulationTime = 12000; % czas symulacji [s]
stepTime = 500;
dTzew = 0;    % zmiana temperatury zewnętrznej
dPg = PgN*0.1;   % zmiana mocy grzejnika
num = [K_];
den = [T_ 1];

workPoints = [TzewN, TzewN + 10, TzewN; ...
              PgN, PgN, PgN * 0.7];
colors = {'r', 'g', 'b'};
lineStyles = {'-', '--', ':'};

out = sim('simulink_431.slx', simulationTime);

fig = figure; hold on; grid on; grid minor;
xlabel('Czas [s]'); ylabel('Temperatura [C]');
title(sprintf('%s dla skoku dTzew = %d, dPg = %d', ...
    dTzew, dPg), ...
    'FontName', 'Times New Roman CE');

% Wykresy
figure(fig);
plot(out.tout, out.oTp, 'Color', 'r', 'LineStyle', '-', ...
    'LineWidth', 1.5, 'DisplayName', sprintf('Tzew0 = %d, Pg0 = %d', Tzew0, Pg0));
legend;

% %================ WYKRESY ====================
% figureNames = {'Temperatura wnętrza', 'Temperatura poddasza', ...
%                'Zmiana temperatury wnętrza', 'Zmiana temperatury poddasza'};
% figureHandles = cell(1, 4);
% 
% for i = 1:4
%     figureHandles{i} = figure; hold on; grid on;
%     xlabel('Czas [s]'); ylabel('Temperatura [C]');
%     title(sprintf('%s dla skoku dTzew = %d, dPg = %d', ...
%           figureNames{i}, dTzew, dPg), ...
%           'FontName', 'Times New Roman CE');
% end
% 
% for i = 1:size(workPoints, 2)
%     Tzew0 = workPoints(1, i);
%     Pg0 = workPoints(2, i);
%     [Tp0, Twew0] = computeEquilibrium(Tzew0, Pg0, Kp, K1, Kd);
% 
%     fprintf('\nPunkt pracy %d:\nTzew0 = %.2f, Pg0 = %.2f\n', i, Tzew0, Pg0);
%     fprintf('Twew0 = %.2f, Tp0 = %.2f\n', Twew0, Tp0);
% 
%     % Symulacja w Simulink
%     out = sim('simulink_431.slx', simulationTime);
% 
%     % Wybór koloru i stylu linii
%     color = colors{i};
%     style = lineStyles{i};
% 
%     % Wykresy
%     figure(figureHandles{1}); % Temperatura wnętrza
%     plot(out.tout, out.oTwew, 'Color', color, 'LineStyle', style, ...
%         'LineWidth', 1.5, 'DisplayName', sprintf('Tzew0 = %d, Pg0 = %d', Tzew0, Pg0));
%     legend;
% 
%     figure(figureHandles{2}); % Temperatura poddasza
%     plot(out.tout, out.oTp, 'Color', color, 'LineStyle', style, ...
%         'LineWidth', 1.5, 'DisplayName', sprintf('Tzew0 = %d, Pg0 = %d', Tzew0, Pg0));
%     legend;
% 
%     figure(figureHandles{3}); % Zmiana temperatury wnętrza
%     deltaTwew = out.oTwew - Twew0;
%     plot(out.tout, deltaTwew, 'Color', color, 'LineStyle', style, ...
%         'LineWidth', 1.5, 'DisplayName', sprintf('Tzew0 = %d, Pg0 = %d', Tzew0, Pg0));
%     legend('Location', 'southeast');
% 
%     figure(figureHandles{4}); % Zmiana temperatury poddasza
%     deltaTp = out.oTp - Tp0;
%     plot(out.tout, deltaTp, 'Color', color, 'LineStyle', style, ...
%         'LineWidth', 1.5, 'DisplayName', sprintf('Tzew0 = %d, Pg0 = %d', Tzew0, Pg0));
%     legend('Location', 'southeast');
% end
% 
% % Zapis wykresów
% for i = 1:4
%     set(figureHandles{i}, 'PaperPositionMode', 'auto', 'PaperSize', [8, 6]);
%     print(figureHandles{i}, sprintf('wykres_%s.png', figureNames{i}), '-dpng', '-r300');
% end
