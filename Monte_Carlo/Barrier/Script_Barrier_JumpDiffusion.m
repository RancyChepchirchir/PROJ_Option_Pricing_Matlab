%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% MONTE CARLO BARRIER OPTION PRICER for Diffusions AND Jump Diffusions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Descritpion: Script to Price Barrier options in Diffusion and Jump Diffusion Models
%              using the Monte Carlo Simulation
% Author:      Justin Kirkby
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[folder, name, ext] = fileparts(which( mfilename('fullpath')));
cd(folder);

addpath('../')

% ---------------------
%  Contract/Market Params
% ---------------------
call   = 1;    % For call use 1 (else, its a put)
down   = 1;    % down = 1 for down and out, else up and out
S_0    = 100;  % Initial price
H      = 0.85 * S_0;   % Barrier 
M      = 252;  % number of monitoring points, e.g. 252 for "daily" monitoring
r      = 0.05;  % Interest rate
q      = 0.00;  % dividend yield
T      = 1;    % Time (in years)
rebate = 0;  % rebate which is paid upon barrier breach
Kvec   = S_0*[.85 .90 .95 1 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.5 1.6];   % strikes to price


% ---------------------
% Model Params
% ---------------------
sigma = 0.2;  % diffusion parameter
jumpModel = 0;  % determines jump model, select params below (set to 0 for no jumps)

% ---------------------
% Sim Params
% ---------------------
N_sim = 2*10^5;  % number of simulated paths
mult = 2; % multiplier for simulation (see below) to reduce bias
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

jumpParams = {};

if jumpModel == 1 %Normal Jumps, e.g. Merton
    lambda = 1;  muJ = -.10;  sigJ = 0.3;
    
    jumpParams.kappa = exp(muJ + .5*sigJ^2)-1;  jumpParams.lambda = lambda; jumpParams.muJ = muJ; jumpParams.sigJ = sigJ;

elseif jumpModel == 2 %Double Exponenial Jumps     
    lambda = 1;
    p_up   = 0.5; % up jump probability    
    eta1   = 25;
    eta2   = 30;
    
    kappa  = p_up*eta1/(eta1-1)+(1-p_up)*eta2/(eta2+1)-1;
    jumpParams.lambda = lambda; jumpParams.kappa = kappa; jumpParams.eta1 = eta1; jumpParams.eta2 = eta2; jumpParams.p_up = p_up;    

elseif jumpModel == 3 %Mixed normal Jumps
    lambda = 1; 
    a1 = -0.05; 
    b1 = 0.07;    
    a2 = 0.02; 
    b2 = 0.03;
    p_up = 0.6;

    kappa = p_up*exp(a1 + .5*b1^2)+ (1-p_up)*exp(a2 + .5*b2^2)  -1;
    jumpParams.lambda = lambda; jumpParams.kappa = kappa; jumpParams.a1 = a1; jumpParams.b1 = b1; jumpParams.a2 = a2; jumpParams.b2 = b2; jumpParams.p_up = p_up;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

M_mult = M*mult;  %time partitioning to reduce bias
Spath = Simulate_Jump_Diffusion_func( N_sim, M_mult + 1, T, S_0, r, q, sigma, jumpModel, jumpParams);

[prices, stdErrs] = Price_MC_Barrier_Strikes_func(Spath, call, down, H, Kvec, M, mult, rebate, r, T)

% Plot
plot(Kvec, prices)
ylabel('price')
xlabel('strike')
grid on;
