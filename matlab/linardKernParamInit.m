function kern = linardKernParamInit(kern)

% LINARDKERNPARAMINIT linear ARD kernel parameter initialisation.

% KERN

% This parameters is restricted positive.
kern.variance = 1;
% These parameters are restricted to lie between 0 and 1.
kern.inputScales = 0.999*ones(1, kern.inputDimension);
kern.nParams = 1 + kern.inputDimension;

kern.transforms(1).index = 1;
kern.transforms(1).type = 'negLogLogit';
kern.transforms(2).index = [2:kern.nParams];
kern.transforms(2).type = 'sigmoid';
