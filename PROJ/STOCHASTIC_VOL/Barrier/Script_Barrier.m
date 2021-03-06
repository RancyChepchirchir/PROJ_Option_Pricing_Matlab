%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Barrier Option Pricier
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Descritpion: Script to Price Barrier Options in Stochastic volatility models (with jumps)
%              using the PROJ method
% Author:      Justin Kirkby
% References:  (1) A unified approach to Bermudan and Barrier options under stochastic
%               volatility models with jumps. J. Economic Dynamics and Control, 2017
%              (2) Robust barrier option pricing by Frame Projection under
%               exponential Levy Dynamics. Applied Mathematical Finance, 2018.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[folder, name, ext] = fileparts(which( mfilename('fullpath')));
cd(folder);
addpath('../Helper_Functions')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
S_0  = 55;
W    = 55;  %strike
r    = 0.05; 
T    = .25;
M    = 80;

call = 1;
down = 1;
H    = 50;

%%%----------------------------
N    = 2^10;    %number of points in density expansion... Value grid size is K:=N/2
alph = 6;  %density projection grid on [-alpha,alpha]
%%%----------------------------
m_0           = 30;  % number of CTMC grid points
gamma         = 3.3;  % CTMC grid width param
gridMethod    = 4;
gridMultParam = 0.2;

%%%========================
%%%% Select Stochastic Volatility Model
%%%========================
model = 1;    % 1 = Heston (output compares with analytical)
              % 2 = Stein-Stein
              % 3 = 3/2 Model
              % 4 = 4/2 Model
              % 5 = Hull White (output compares with analytical)
              % 6 = Scott
              % 7 = Alpha-Hypergeometric

%%%========================
%%%% Select Jump Model
%%%========================
jumpModel = 0;    % 0 = No Jumps 
                  % 1 = Normal Jumps
                  % 2 = Double Exponential Jumps

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Jump Model Parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
jumpParams = {};

if jumpModel == 0    %%%%% NO Jumps
    jumpParams.Nothing = 0;
    psi_J = @(u)0*[u>0];
    
    c2Jump = 0;
    c4Jump = 0;
    
elseif jumpModel == 1  %%%% Normal Jumps
    lambda = 1;  muJ = -.12;  sigJ = 0.15;
    
    jumpParams.kappa = exp(muJ + .5*sigJ^2)-1;
    jumpParams.lambda = lambda; jumpParams.muJ = muJ; jumpParams.sigJ = sigJ;
    psi_J = @(u) lambda*(exp(1i*u*muJ - .5*sigJ^2*u.^2)-1);    
    
    c2Jump = lambda*(muJ^2 +sigJ^2); %2nd cumulant of jump component
    c4Jump = lambda*(muJ^4 + 6*sigJ^2*muJ^2+3*sigJ^4*lambda);    
    
elseif jumpModel == 2 %%%% DE Jumps
    lambda = 1;
    p_up   = 0.5; % up jump probability    
    eta1   = 25;
    eta2   = 30;
    
    kappa  = p_up*eta1/(eta1-1)+(1-p_up)*eta2/(eta2+1)-1;
    jumpParams.lambda = lambda; jumpParams.kappa = kappa; jumpParams.eta1 = eta1; jumpParams.eta2 = eta2; jumpParams.p_up = p_up;     
    psi_J = @(u) lambda*(p_up*eta1./(eta1-1i*u) + (1-p_up)*eta2./(eta2+1i*u) -1) ;
    
    c2Jump = 2*lambda*p_up/eta1^2 + 2*lambda*(1-p_up)/eta2^2; %2nd cumulant of jump component
    c4Jump = 24*lambda*(p_up/eta1^4 + (1-p_up)/eta2^4);
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    Set the Stochastic Volatility Model Component
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if model == 1
    %%%==============================
    %%% HESTON MODEL  Parameters
    %%%==============================
    modparam.eta    = 4;
    modparam.theta  = 0.035; 
    modparam.rho    = -0.75;
    modparam.Sigmav = 0.15;
    modparam.v0     = 0.04; 
    
elseif model == 2
    %%%=============================================================
    %%% STEIN-STEIN MODEL  Parameters
    %%%=============================================================
    modparam.eta    = 2; 
    modparam.theta  = 0.18; 
    modparam.Sigmav = 0.18; 
    modparam.v0     = 0.22; 
    modparam.rho    = -0.5; 
    
elseif model == 3
    %%%=============================================================
    %%% 3/2 MODEL  Parameters
    %%%=============================================================
    modparam.Sigmav = 0.10; 
    modparam.eta    = 3; 
    modparam.rho    = -0.7; 
    modparam.theta  = 0.04; 
    modparam.v0     = 0.04 ;
    
elseif model == 4
    %%%=============================================================
    %%% 4/2 MODEL  Parameters
    %%%=============================================================
    modparam.eta    = 3;
    modparam.theta  = 0.04; 
    modparam.rho    = -0.7; 
    modparam.Sigmav = 0.25; 
    modparam.v0     = 0.04; 
    modparam.aa     = 0.5; 
    modparam.bb     = 0.5*modparam.v0; 
    
elseif model == 5
    %%%=============================================================
    %%% HULL-WHITE MODEL  Parameters
    %%%=============================================================
    modparam.av     = 0.05; 
    modparam.rho    = -0.6;
    modparam.Sigmav = 0.6;
    modparam.v0     = 0.03; 
    
elseif model == 6
    %%%=============================================================
    %%% SCOTT MODEL  Parameters
    %%%============================================================= 
    modparam.eta    = 2; 
    modparam.theta  = log(0.16); 
    modparam.Sigmav = 0.20; 
    modparam.v0     = log(0.18);
    modparam.rho    = -0.9;

elseif model == 7
    %%%=============================================================
    %%% ALPHA-HYPERGEOMETRIC MODEL  Parameters
    %%%=============================================================
    modparam.rho    = -.9;
    modparam.Sigmav = .20; 
    modparam.v0     = log(0.17); 
    modparam.eta    = .05; 
    modparam.theta  = .2; 
    modparam.av     = 0.03;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PRICE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
price = Barrier_StochasticVol_func(N,alph,call,down,S_0,W,H,M,r,T,m_0,psi_J,model, modparam, gridMethod, gamma, gridMultParam);
toc
fprintf('%.8f \n', price)


