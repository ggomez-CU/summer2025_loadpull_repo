clear all
close all
clc

% Parameters
chi = .5; % Radius
center = 0; % Center (x0 + i*y0)
zf = 45;
z0 = 50;

% Create circle points
theta = linspace(0, 2*pi, 100);
gamma = center + chi * exp(1i*theta);

z = (1 + gamma) ./ (1 - gamma) * zf;
gamma_z0 = (z - z0)./ (z + z0);
polar(angle(gamma_z0),abs(gamma_z0))
