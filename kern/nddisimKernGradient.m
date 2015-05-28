function g = nddisimKernGradient(kern, t1, varargin)

% NDDISIMKERNGRADIENT Gradient of NDDISIM kernel's parameters.
% FORMAT
% DESC computes the gradient of functions with respect to the
% single input motif
% kernel's parameters. As well as the kernel structure and the
% input positions, the user provides a matrix PARTIAL which gives
% the partial derivatives of the function with respect to the
% relevant elements of the kernel matrix. 
% ARG kern : the kernel structure for which the gradients are being
% computed.
% ARG t : the input locations for which the gradients are being
% computed. 
% ARG partial : matrix of partial derivatives of the function of
% interest with respect to the kernel matrix. The argument takes
% the form of a square matrix of dimension  numData, where numData is
% the number of rows in X.
% RETURN g : gradients of the function of interest with respect to
% the kernel parameters. The ordering of the vector should match
% that provided by the function kernExtractParam.
%
% FORMAT
% DESC computes the derivatives as above, but input locations are
% now provided in two matrices associated with rows and columns of
% the kernel matrix. 
% ARG kern : the kernel structure for which the gradients are being
% computed.
% ARG t1 : the input locations associated with the rows of the
% kernel matrix.
% ARG t2 : the input locations associated with the columns of the
% kernel matrix.
% ARG partial : matrix of partial derivatives of the function of
% interest with respect to the kernel matrix. The matrix should
% have the same number of rows as X1 and the same number of columns
% as X2 has rows.
% RETURN g : gradients of the function of interest with respect to
% the kernel parameters.
%
% SEEALSO disimKernParamInit, kernGradient, disimKernDiagGradient, kernGradX
%
% COPYRIGHT : Neil D. Lawrence, 2006
%
% COPYRIGHT : Antti Honkela, 2007

% KERN

if length(varargin)<2
  t2 = t1;
else
  t2 = varargin{1};
end
covGrad=varargin{end};

if isfield(kern,'delay'),
  origt1=t1;
  t1=t1-kern.delay;
  
  % crude way to handle times below zero, just truncate to zero
  % since the kernel value at t=0 is zero, which is the same as
  % kernel values for negative t.
  I=find(t1<0);
  t1(I)=0;
end;

if isfield(kern,'delay'),
  origt2=t2;
  t2=t2-kern.delay;
  
  % crude way to handle times below zero, just truncate to zero
  % since the kernel value at t=0 is zero, which is the same as
  % kernel values for negative t.
  I=find(t2<0);
  t2(I)=0;
end;



% Order or parameters in gradient (same as in nddisimKernExtractParam):
% kern.inverseWidth, kern.di_variance, kern.decay, kern.variance, kern.delay




dim1 = size(t1, 1);
dim2 = size(t2, 1);
t1 = t1;
t2 = t2;
t1Mat = t1(:, ones(1, dim2));
t2Mat = t2(:, ones(1, dim1))';
diffT = (t1Mat - t2Mat);

delay=kern.delay;
D = kern.decay;
l = sqrt(2/kern.inverseWidth);
varfactor=kern.di_variance*kern.variance;

origt1PosFlag=origt1>delay;origt1PosFlag=origt1PosFlag(:, ones(1, dim2));
origt2PosFlag=origt2>delay;origt2PosFlag=origt2PosFlag(:, ones(1, dim1))';


h1a=0.5*sqrt(pi)*l/(D^2) * ...
    (  (t1Mat - 1/D + exp(-D*t2Mat)/D).*erf(t1Mat/l) ...
       +(t2Mat - 1/D + exp(-D*t1Mat)/D).*erf(t2Mat/l) ...
       -(diffT).*erf(diffT/l) );
h1b=0.5*(l^2)/(D^2) * ...
    ( exp(-(t1Mat/l).^2) + exp(-(t2Mat/l).^2) - exp(-(diffT/l).^2) - 1 );

h2a=sqrt(pi)*l * ...
    ( 0.25*exp(-3*log(D) + (D*l/2)^2 + D*(diffT) + lnDiffErfs(D*l/2+t1Mat/l,D*l/2+diffT/l)) ...
     +0.25*exp(-3*log(D) + (D*l/2)^2 - D*t2Mat - D*t1Mat + lnDiffErfs(D*l/2,D*l/2-t2Mat/l)) ...
     -0.5*exp(-3*log(D) + (D*l/2)^2 - D*t2Mat + lnDiffErfs(D*l/2,D*l/2-t2Mat/l)) );
h2b=sqrt(pi)*l * ...
    ( 0.25*exp(-3*log(D) + (D*l/2)^2 - D*(diffT) + lnDiffErfs(D*l/2+t2Mat/l,D*l/2-diffT/l)) ...
     +0.25*exp(-3*log(D) + (D*l/2)^2 - D*t1Mat - D*t2Mat + lnDiffErfs(D*l/2,D*l/2-t1Mat/l)) ...
     -0.5*exp(-3*log(D) + (D*l/2)^2 - D*t1Mat + lnDiffErfs(D*l/2,D*l/2-t1Mat/l)) );

K=varfactor*(h1a + h1b - h2a - h2b);


%----------------------------------------
% Gradient with respect to SIM-level effect variance factor
%----------------------------------------
dK_ddi_variance = kern.variance*(h1a + h1b - h2a - h2b);
dk_ddi_variance = sum(sum(dK_ddi_variance.*covGrad));


%----------------------------------------
% Gradient with respect to DISIM-level effect variance factor
%----------------------------------------
dK_dvariance = kern.di_variance*(h1a + h1b - h2a - h2b);
dk_dvariance = sum(sum(dK_dvariance.*covGrad));


%----------------------------------------
% Gradient with respect to delay
%----------------------------------------

dK_ddelay_part1a = ...
    1/(D^2) * ...
    (  0.5*sqrt(pi)*l*(-origt1PosFlag + origt2PosFlag.*exp(-D*t2Mat)).*erf(t1Mat/l) ...
       -origt1PosFlag.*(t1Mat - 1/D + exp(-D*t2Mat)/D).*exp(-(t1Mat/l).^2) ) ...
    + 1/(D^2) * ...
    (  0.5*sqrt(pi)*l*(-origt2PosFlag + origt1PosFlag.*exp(-D*t1Mat)).*erf(t2Mat/l) ...
       -origt2PosFlag.*(t2Mat - 1/D + exp(-D*t1Mat)/D).*exp(-(t2Mat/l).^2) ) ...
    - 1/(D^2) * ...
    (  0.5*sqrt(pi)*l*(-origt1PosFlag+origt2PosFlag).*erf(diffT/l) ...
       +(diffT).*exp(-(diffT/l).^2).*(-origt1PosFlag+origt2PosFlag) ) ;

dK_ddelay_part1b = ...
   1/(D^2) * ...
    ( origt1PosFlag.*exp(-(t1Mat/l).^2).*t1Mat ...
      + origt2PosFlag.*exp(-(t2Mat/l).^2).*t2Mat ...
      + exp(-(diffT/l).^2).*diffT.*(-origt1PosFlag+origt2PosFlag)    );

dK_ddelay_part2a = ...
    sqrt(pi)*l * ...
     0.25*exp(-2*log(D) + (D*l/2)^2 + D*(diffT) + lnDiffErfs(D*l/2+t1Mat/l,D*l/2+diffT/l)).*(-origt1PosFlag+origt2PosFlag) ...
  + 0.5*( exp(-3*log(D) + (D*l/2)^2 + D*(diffT) -(D*l/2+t1Mat/l).^2).*(-origt1PosFlag) ...
	-exp(-3*log(D) + (D*l/2)^2 + D*(diffT) -(D*l/2+diffT/l).^2).*(-origt1PosFlag+origt2PosFlag) ) ...
    + sqrt(pi)*l * ...
     0.25*exp(-2*log(D) + (D*l/2)^2 - D*(t2Mat+t1Mat) + lnDiffErfs(D*l/2,D*l/2-t2Mat/l)).*(origt1PosFlag+origt2PosFlag) ...
  + 0.5*(  -exp(-3*log(D) + (D*l/2)^2 - D*(t2Mat+t1Mat) -(D*l/2-t2Mat/l).^2).*(origt2PosFlag) ) ...
    - sqrt(pi)*l * ...
     0.5*exp(-2*log(D) + (D*l/2)^2 - D*t2Mat + lnDiffErfs(D*l/2,D*l/2-t2Mat/l)).*(origt2PosFlag) ...
  - 1*(  -exp(-3*log(D) + (D*l/2)^2 - D*(t2Mat) -(D*l/2-t2Mat/l).^2).*(origt2PosFlag) ) ;

dK_ddelay_part2b = ...
    sqrt(pi)*l * ...
     0.25*exp(-2*log(D) + (D*l/2)^2 - D*(diffT) + lnDiffErfs(D*l/2+t2Mat/l,D*l/2-diffT/l)).*(-origt2PosFlag+origt1PosFlag) ...
  + 0.5*( exp(-3*log(D) + (D*l/2)^2 - D*(diffT) -(D*l/2+t2Mat/l).^2).*(-origt2PosFlag) ...
	-exp(-3*log(D) + (D*l/2)^2 - D*(diffT) -(D*l/2-diffT/l).^2).*(-origt2PosFlag+origt1PosFlag) ) ...
    + sqrt(pi)*l * ...
     0.25*exp(-2*log(D) + (D*l/2)^2 - D*(t1Mat+t2Mat) + lnDiffErfs(D*l/2,D*l/2-t1Mat/l)).*(origt2PosFlag+origt1PosFlag) ...
  + 0.5*(  -exp(-3*log(D) + (D*l/2)^2 - D*(t1Mat+t2Mat) -(D*l/2-t1Mat/l).^2).*(origt1PosFlag) ) ...
    - sqrt(pi)*l * ...
     0.5*exp(-2*log(D) + (D*l/2)^2 - D*t1Mat + lnDiffErfs(D*l/2,D*l/2-t1Mat/l)).*(origt1PosFlag) ...
  - 1*(  -exp(-3*log(D) + (D*l/2)^2 - D*(t1Mat) -(D*l/2-t1Mat/l).^2).*(origt1PosFlag) ) ;

% dK_ddelay_part1a
% dK_ddelay_part1b
% dK_ddelay_part2a
% dK_ddelay_part2b
% pause

dK_ddelay = varfactor*(dK_ddelay_part1a + dK_ddelay_part1b - dK_ddelay_part2a - dK_ddelay_part2b);
dk_ddelay = sum(sum(dK_ddelay.*covGrad));



%----------------------------------------
% Gradient with respect to inverse width
%----------------------------------------
dK_dl_part1a = ...
    0.5*sqrt(pi)*varfactor/(D^2) * ...
    (   (t1Mat - 1/D + exp(-D*t2Mat)/D).*erf(t1Mat/l) ...
       +(t2Mat - 1/D + exp(-D*t1Mat)/D).*erf(t2Mat/l) ...
       -(diffT).*erf(diffT/l) ) ...
    + 0.5*sqrt(pi)*varfactor/(D^2)/l * ...
    ( - (t1Mat - 1/D + exp(-D*t2Mat)/D) .* (2/sqrt(pi)*exp(-(t1Mat/l).^2)).*t1Mat ...
      - (t2Mat - 1/D + exp(-D*t1Mat)/D) .* (2/sqrt(pi)*exp(-(t2Mat/l).^2)).*t2Mat ...
      + (diffT).* (2/sqrt(pi)*exp(-(diffT/l).^2)).*diffT );

dK_dl_part1b =  ...
    l*varfactor/(D^2) * ...
      ( exp(-(t1Mat/l).^2) + exp(-(t2Mat/l).^2) - exp(-(diffT/l).^2) - 1 ) ...
    + varfactor/(D^2)/l * ...
    ( exp(-(t1Mat/l).^2).*(t1Mat.^2) + exp(-(t2Mat/l).^2).*(t2Mat.^2) - exp(-(diffT/l).^2).*(diffT.^2) );

dK_dl_part2a = ...
    sqrt(pi)*varfactor*(0.25 + 0.125*(D^2)*(l^2))* ...
      exp(-3*log(D) + (D*l/2)^2 + D*(diffT) + lnDiffErfs(D*l/2+t1Mat/l,D*l/2+diffT/l)) ...
    + 0.5*varfactor * exp(-3*log(D) + (D*l/2)^2 + D*(diffT) -(D*l/2+t1Mat/l).^2).*(D*l/2-t1Mat/l) ...
    - 0.5*varfactor * exp(-3*log(D) + (D*l/2)^2 + D*(diffT) -(D*l/2+diffT/l).^2).*(D*l/2-diffT/l) ...
  + sqrt(pi)*varfactor*(0.25 + 0.125*(D^2)*(l^2))* ...
      exp(-3*log(D) + (D*l/2)^2 - D*t2Mat - D*t1Mat + lnDiffErfs(D*l/2,D*l/2-t2Mat/l)) ...
    + 0.5*varfactor * exp(-3*log(D) + (D*l/2)^2 - D*t2Mat - D*t1Mat -(D*l/2).^2).*(D*l/2) ...
    - 0.5*varfactor * exp(-3*log(D) + (D*l/2)^2 - D*t2Mat - D*t1Mat -(D*l/2-t2Mat/l).^2).*(D*l/2+t2Mat/l) ...
  + sqrt(pi)*varfactor*(-0.5 - 0.25*(D^2)*(l^2))* ...
      exp(-3*log(D) + (D*l/2)^2 - D*t2Mat + lnDiffErfs(D*l/2,D*l/2-t2Mat/l)) ...
    - varfactor * exp(-3*log(D) + (D*l/2)^2 - D*t2Mat -(D*l/2).^2).*(D*l/2) ...
    + varfactor * exp(-3*log(D) + (D*l/2)^2 - D*t2Mat -(D*l/2-t2Mat/l).^2).*(D*l/2+t2Mat/l); 
    
dK_dl_part2b = ...
    sqrt(pi)*varfactor*(0.25 + 0.125*(D^2)*(l^2))* ...
      exp(-3*log(D) + (D*l/2)^2 - D*(diffT) + lnDiffErfs(D*l/2+t2Mat/l,D*l/2-diffT/l)) ...
    + 0.5*varfactor * exp(-3*log(D) + (D*l/2)^2 - D*(diffT) -(D*l/2+t2Mat/l).^2).*(D*l/2-t2Mat/l) ...
    - 0.5*varfactor * exp(-3*log(D) + (D*l/2)^2 - D*(diffT) -(D*l/2-diffT/l).^2).*(D*l/2+diffT/l) ...
  + sqrt(pi)*varfactor*(0.25 + 0.125*(D^2)*(l^2))* ...
      exp(-3*log(D) + (D*l/2)^2 - D*t1Mat - D*t2Mat + lnDiffErfs(D*l/2,D*l/2-t1Mat/l)) ...
    + 0.5*varfactor * exp(-3*log(D) + (D*l/2)^2 - D*t1Mat - D*t2Mat -(D*l/2).^2).*(D*l/2) ...
    - 0.5*varfactor * exp(-3*log(D) + (D*l/2)^2 - D*t1Mat - D*t2Mat -(D*l/2-t1Mat/l).^2).*(D*l/2+t1Mat/l) ...
+ sqrt(pi)*varfactor*(-0.5 - 0.25*(D^2)*(l^2))* ...
      exp(-3*log(D) + (D*l/2)^2 - D*t1Mat + lnDiffErfs(D*l/2,D*l/2-t1Mat/l)) ...
    - varfactor * exp(-3*log(D) + (D*l/2)^2 - D*t1Mat -(D*l/2).^2).*(D*l/2) ...
    + varfactor * exp(-3*log(D) + (D*l/2)^2 - D*t1Mat -(D*l/2-t1Mat/l).^2).*(D*l/2+t1Mat/l); 

dK_dl = dK_dl_part1a + dK_dl_part1b - dK_dl_part2a - dK_dl_part2b;
dk_dInverseWidth = sum(sum(dK_dl.*covGrad))*(-kern.inverseWidth^(-1.5)/sqrt(2));



%----------------------------------------
% Gradient with respect to decay
%----------------------------------------
dK_dD_part1a = ...
  sqrt(pi)*l*varfactor/(D^3) * ...
      (  ( 1.5/D*(1 - exp(-D*t2Mat)) -0.5*t2Mat.*exp(-D*t2Mat)).*erf(t1Mat/l) ...
	 +( 1.5/D*(1 - exp(-D*t1Mat)) -0.5*t1Mat.*exp(-D*t1Mat)).*erf(t2Mat/l) ...
	 -t1Mat.*exp(lnDiffErfs(t1Mat/l,diffT/l))-t2Mat.*exp(lnDiffErfs(t2Mat/l,-diffT/l)) );    

dK_dD_part1b = ...
  -(l^2)*varfactor/(D^3) * ...
      ( exp(-(t1Mat/l).^2) + exp(-(t2Mat/l).^2) - exp(-(diffT/l).^2) - 1 );

dK_dD_part2a = ...
  0.25*sqrt(pi)*l*varfactor * ...
    ( -3*exp(-4*log(D) + (D*l/2)^2 + D*(diffT) + lnDiffErfs(D*l/2+t1Mat/l,D*l/2+diffT/l)) ...
      + 0.5*(l^2)*exp(-2*log(D) + (D*l/2)^2 + D*(diffT) + lnDiffErfs(D*l/2+t1Mat/l,D*l/2+diffT/l)) ...
      + diffT.*exp(-3*log(D) + (D*l/2)^2 + D*(diffT) + lnDiffErfs(D*l/2+t1Mat/l,D*l/2+diffT/l)) ...
      + exp(-3*log(D) + (D*l/2)^2 + D*(diffT) -(D*l/2+t1Mat/l).^2)*(l/sqrt(pi)) ...
      - exp(-3*log(D) + (D*l/2)^2 + D*(diffT) -(D*l/2+diffT/l).^2)*(l/sqrt(pi)) ...
      ...
      -3*exp(-4*log(D) + (D*l/2)^2 - D*t2Mat - D*t1Mat + lnDiffErfs(D*l/2,D*l/2-t2Mat/l)) ...
      +0.5*(l^2)*exp(-2*log(D) + (D*l/2)^2 - D*t2Mat - D*t1Mat + lnDiffErfs(D*l/2,D*l/2-t2Mat/l)) ...
      -(t2Mat+t1Mat).*exp(-3*log(D) + (D*l/2)^2 - D*t2Mat - D*t1Mat + lnDiffErfs(D*l/2,D*l/2-t2Mat/l)) ...
      +exp(-3*log(D) + (D*l/2)^2 - D*t2Mat - D*t1Mat -(D*l/2)^2)*(l/sqrt(pi)) ...
      -exp(-3*log(D) + (D*l/2)^2 - D*t2Mat - D*t1Mat -(D*l/2-t2Mat/l).^2)*(l/sqrt(pi)) ...
      ...      
      +6*exp(-4*log(D) + (D*l/2)^2 - D*t2Mat + lnDiffErfs(D*l/2,D*l/2-t2Mat/l)) ...           
      -(l^2)*exp(-2*log(D) + (D*l/2)^2 - D*t2Mat + lnDiffErfs(D*l/2,D*l/2-t2Mat/l)) ...
      +2*t2Mat.*exp(-3*log(D) + (D*l/2)^2 - D*t2Mat + lnDiffErfs(D*l/2,D*l/2-t2Mat/l)) ...
      -2*exp(-3*log(D) + (D*l/2)^2 - D*t2Mat - (D*l/2)^2)*(l/sqrt(pi)) ...
      +2*exp(-3*log(D) + (D*l/2)^2 - D*t2Mat - (D*l/2-t2Mat/l).^2)*(l/sqrt(pi)) );

dK_dD_part2b = ...
  0.25*sqrt(pi)*l*varfactor * ...
    ( -3*exp(-4*log(D) + (D*l/2)^2 - D*(diffT) + lnDiffErfs(D*l/2+t2Mat/l,D*l/2-diffT/l)) ...
      + 0.5*(l^2)*exp(-2*log(D) + (D*l/2)^2 - D*(diffT) + lnDiffErfs(D*l/2+t2Mat/l,D*l/2-diffT/l)) ...
      - diffT.*exp(-3*log(D) + (D*l/2)^2 - D*(diffT) + lnDiffErfs(D*l/2+t2Mat/l,D*l/2-diffT/l)) ...
      + exp(-3*log(D) + (D*l/2)^2 - D*(diffT) -(D*l/2+t2Mat/l).^2)*(l/sqrt(pi)) ...
      - exp(-3*log(D) + (D*l/2)^2 - D*(diffT) -(D*l/2-diffT/l).^2)*(l/sqrt(pi)) ...
      ...
      -3*exp(-4*log(D) + (D*l/2)^2 - D*t1Mat - D*t2Mat + lnDiffErfs(D*l/2,D*l/2-t1Mat/l)) ...
      +0.5*(l^2)*exp(-2*log(D) + (D*l/2)^2 - D*t1Mat - D*t2Mat + lnDiffErfs(D*l/2,D*l/2-t1Mat/l)) ...
      -(t1Mat+t2Mat).*exp(-3*log(D) + (D*l/2)^2 - D*t1Mat - D*t2Mat + lnDiffErfs(D*l/2,D*l/2-t1Mat/l)) ...
      +exp(-3*log(D) + (D*l/2)^2 - D*t1Mat - D*t2Mat -(D*l/2)^2)*(l/sqrt(pi)) ...
      -exp(-3*log(D) + (D*l/2)^2 - D*t1Mat - D*t2Mat -(D*l/2-t1Mat/l).^2)*(l/sqrt(pi)) ...
      ...      
      +6*exp(-4*log(D) + (D*l/2)^2 - D*t1Mat + lnDiffErfs(D*l/2,D*l/2-t1Mat/l)) ...           
      -(l^2)*exp(-2*log(D) + (D*l/2)^2 - D*t1Mat + lnDiffErfs(D*l/2,D*l/2-t1Mat/l)) ...
      +2*t1Mat.*exp(-3*log(D) + (D*l/2)^2 - D*t1Mat + lnDiffErfs(D*l/2,D*l/2-t1Mat/l)) ...
      -2*exp(-3*log(D) + (D*l/2)^2 - D*t1Mat - (D*l/2)^2)*(l/sqrt(pi)) ...
      +2*exp(-3*log(D) + (D*l/2)^2 - D*t1Mat - (D*l/2-t1Mat/l).^2)*(l/sqrt(pi)) );

dK_dD = dK_dD_part1a + dK_dD_part1b - dK_dD_part2a - dK_dD_part2b;
dk_dD = sum(sum(dK_dD.*covGrad));



%----------------------------------------
% Complete gradient
%----------------------------------------

g=[dk_dInverseWidth dk_ddi_variance dk_dD dk_dvariance dk_ddelay];
