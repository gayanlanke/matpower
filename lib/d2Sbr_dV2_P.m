function [Haa, Hav, Hva, Hvv] = d2Sbr_dV2_P(Cbr, Ybr, V, mu)
%d2Sbr_dV2_P   Computes 2nd derivatives of complex power flow w.r.t. voltage.
%   [HAA, HAV, HVA, HVV] = d2Sbr_dV2_P(CBR, YBR, V, MU) returns 4 matrices
%   containing the partial derivatives w.r.t. voltage angle and magnitude
%   of the product of a vector MU with the 1st partial derivatives of the
%   complex branch power flows. Takes sparse connection matrix CBR, sparse
%   branch admittance matrix YBR, voltage vector V and nl x 1 vector of
%   multipliers MU. Output matrices are sparse.
%
%   Example:
%       f = branch(:, F_BUS);
%       Cf =  sparse(1:nl, f, ones(nl, 1), nl, nb);
%       [Ybus, Yf, Yt] = makeYbus(baseMVA, bus, branch);
%       Cbr = Cf;
%       Ybr = Yf;
%       [Haa, Hav, Hva, Hvv] = d2Sbr_dV2_P(Cbr, Ybr, V, mu);
%
%   Here the output matrices correspond to:
%       Haa = (d/dVa (dSbr_dVa.')) * mu
%       Hav = (d/dVm (dSbr_dVa.')) * mu
%       Hva = (d/dVa (dSbr_dVm.')) * mu
%       Hvv = (d/dVm (dSbr_dVm.')) * mu
%
%   For more details on the derivations behind the derivative code used
%   in MATPOWER information, see:
%
%   [TN2]  R. D. Zimmerman, "AC Power Flows, Generalized OPF Costs and
%          their Derivatives using Complex Matrix Notation", MATPOWER
%          Technical Note 2, February 2010.
%             http://www.pserc.cornell.edu/matpower/TN2-OPF-Derivatives.pdf

%   MATPOWER
%   Copyright (c) 2008-2016, Power Systems Engineering Research Center (PSERC)
%   by Ray Zimmerman, PSERC Cornell
%
%   This file is part of MATPOWER.
%   Covered by the 3-clause BSD License (see LICENSE file for details).
%   See http://www.pserc.cornell.edu/matpower/ for more info.

%% define
nl = length(mu);
nb = length(V);

diagmu = sparse(1:nl, 1:nl, mu, nl, nl);
diagV  = sparse(1:nb, 1:nb, V, nb, nb);

A = Ybr' * diagmu * Cbr;
B = conj(diagV) * A * diagV;
D = sparse(1:nb, 1:nb, (A*V) .* conj(V), nb, nb);
E = sparse(1:nb, 1:nb, (A.'*conj(V)) .* V, nb, nb);
F = B + B.';
G = sparse(1:nb, 1:nb, ones(nb, 1)./abs(V), nb, nb);

Haa = F - D - E;
Hva = 1j * G * (B - B.' - D + E);
Hav = Hva.';
Hvv = G * F * G;
