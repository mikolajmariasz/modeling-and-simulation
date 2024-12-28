% zad 4.3.1

clear all; 
close all;


% ================ I część (Definicja) ====================
% wartości nominalne
TzewN = -20;        %oC
TwewN = 20;         %oC
TpN = 15;           %oC
Vw = 100 .* 2.5;    %m3         objętość pokoju
Vp = 0.25 .* Vw;    %m3         objętość poddasza
PgN = 10000;        %W          zapotrzebowanie budynku na ciepło
cpp = 1000;         %J/(kgK)    powietrze - ciepło właściwe
rop = 1.2;          %kg/m3      powietrze - gęstość

% identyfikacja parametrów statycznych
a = 3;      % Wspołczynnik strat ciepła przez ściany względem przez sufit
Kp = PgN / (TwewN*(a+1)-a*TzewN-TpN);     %W/K      wsp. strat przez sufit
Kd = Kp * ((TwewN-TpN)/(TpN-TzewN));      %W/K      wsp. strat przez dach
K1 = 3*Kp;                                %W/K      wsp. strat przez ściany

% parametry "dynamiczne"
Cvw = cpp*rop*Vw;       %J/K        pojemność cieplna parteru
Cvp = cpp*rop*Vp;       %J/K        pojemność cieplna poddasza

%================ II część (Punkt pracy) ====================
% warunki początkowe
Tzew0 = TzewN;          %oC
Pg0 = PgN * 1.0;        %W

%stan równowagi - metoda algebraiczna
function [ Tp_0, Twew_0 ] = policzPunktPracy ( Tzew0, Pg0, Kp, K1, Kd )
    Tp_0 = Pg0 * (Kp/(K1*Kp+K1*Kd+Kp*Kd)) +Tzew0; 
    Twew_0 = Tp_0 + (Kd/Kp)*(Tp_0-Tzew0);
end

[ Tp0, Twew0 ] = policzPunktPracy (Tzew0, Pg0, Kp, K1, Kd);

disp('************************************************')

%================ III część (Symulacja) ====================
czas = 12000;        % czas symulacji (s)
czas_skok = 500;     % czas wystąpienia skoku (s)

dTzew = 0;           % skok - Stała dodawana do Temperatury zewnętrznej
dPg = PgN*0.1;         % skok - stała (Mnożnik) dodawana do Mocy grzejnika

%================= IV część (Identyfikacja obiektu) ======================
kolory = [ 'b', 'r' ];

% Wykres temperatury poddasz
fig_p = figure; hold on; grid on;
grid minor; % Dodaje linie mniejszej siatki
set(gca, 'XTick', 0:1000:czas); % Przykład: krok siatki co 1000 s
xlabel('Czas [s]'); ylabel('Temperatura [C]');
title(sprintf(['Wykres temperatury poddasza dla skoku ' ...
    '\ndTzew = %d, dPg = %d'], dTzew, dPg));

% Punkty pracy
Tzew0 = TzewN + 0;      %oC
Pg0 = PgN * 0.7;        %W

% Policzenie warunków początkowych dla punktów pracy z funkcji
[ Tp0, Twew0 ] = policzPunktPracy (Tzew0, Pg0, Kp, K1, Kd);

 % Symulacja
[out] = sim('simulink_431.slx', czas);     

% Wykres Tp
figure(fig_p)                                   
plot(out.tout, out.oTp,  kolory(1), ...
    'DisplayName', sprintf('Tzew0 = %d, Pg0 = %d', Tzew0, Pg0));
legend;


% ===================== Metoda dwupunktowa =====================
% Punkt 1: 28.3% wartości końcowej
value_28_3 = 0.283 * (max(out.oTp) - min(out.oTp)) + min(out.oTp);

% Punkt 2: 63.2% wartości końcowej
value_63_2 = 0.632 * (max(out.oTp) - min(out.oTp)) + min(out.oTp);

% Interpolacja punktów
idx1 = find(out.oTp <= value_28_3, 1, 'last');
idx2 = find(out.oTp >= value_28_3, 1, 'first');
t_28_3 = interp1(out.oTp([idx1, idx2]), out.tout([idx1, idx2]), value_28_3);

idx1 = find(out.oTp <= value_63_2, 1, 'last');
idx2 = find(out.oTp >= value_63_2, 1, 'first');
t_63_2 = interp1(out.oTp([idx1, idx2]), out.tout([idx1, idx2]), value_63_2);

% Obliczanie parametrów modelu (czas charakterystyczny)
T = 1.5 * (t_63_2 - t_28_3); % Stała czasowa
to = t_28_3 - 0.5 * T;       % Opóźnienie czasowe
k = (max(out.oTp) - min(out.oTp)) / dPg; % Wzmocnienie statyczne

% Wyświetlanie wyników
fprintf('Metoda dwupunktowa:\n');
fprintf('t_28_3 = %.2f s, t_63_2 = %.2f s\n', t_28_3, t_63_2);
fprintf('T = %.2f s, to = %.2f s, k = %.2f\n', T, to, k);

% Dodanie punktów na wykresie
scatter(t_28_3, value_28_3, 'r', 'DisplayName', 'Punkt 28.3%');
scatter(t_63_2, value_63_2, 'r', 'DisplayName', 'Punkt 63.2%');

% Prosta przchodząca przez oba punkty
m = (value_63_2 - value_28_3) / (t_63_2 - t_28_3); 
b = value_28_3 - m * t_28_3;                      

x_line = linspace(min(out.tout), max(out.tout), 1000);
y_line = m * x_line + b;

x_limits = [min(out.tout), max(out.tout)];
y_limits = [min(out.oTp), max(out.oTp)];

figure(fig_p)
hold on;
plot(x_line, y_line, 'k--', ...
    'LineWidth', 0.5, 'DisplayName', 'Prosta przecinająca punkty x1 i x2');
legend;

xlim(x_limits);
ylim(y_limits);

hold off;

%================= IV część (Weryfikacja modelu) ======================
kolory = [ 'b', 'r' ];

% Obiekt: Wykres temperatury poddasz
fig_wykres = figure; hold on; grid on;
grid minor; % Dodaje linie mniejszej siatki
xlabel('Czas [s]'); ylabel('Temperatura [C]');
title(sprintf(['Weryfikacja modelu: Wykres temperatury poddasza dla skoku ' ...
    'dTzew = %d, dPg = %d'], dTzew, dPg));

 % Symulacja
[out] = sim('schemat_4_3_1_identyfikacja.slx', czas);     

% Wykres Tp
figure(fig_wykres)                                   
plot(out.tout, out.oTp,  kolory(1), ...
    'DisplayName', sprintf('Obiekt'));
plot(out.tout, out.oTp_model,  kolory(2), ...
    'DisplayName', sprintf('Model'));
legend;
