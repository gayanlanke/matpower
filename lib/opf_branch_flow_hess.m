function d2H = opf_branch_flow_hess(x, lambda, mpc, Yf, Yt, il, mpopt)
%OPF_BRANCH_FLOW_HESS  Evaluates Hessian of branch flow constraints.
%   D2H = OPF_BRANCH_FLOW_HESS(X, LAMBDA, OM, YF, YT, IL, MPOPT)
%
%   Hessian evaluation function for AC branch flow constraints.
%
%   Inputs:
%     X : optimization vector
%     LAMBDA : column vector of Kuhn-Tucker multipliers on constrained
%              branch flows
%     MPC : MATPOWER case struct
%     YF : admittance matrix for "from" end of constrained branches
%     YT : admittance matrix for "to" end of constrained branches
%     IL : vector of branch indices corresponding to branches with
%          flow limits (all others are assumed to be unconstrained).
%          YF and YT contain only the rows corresponding to IL.
%     MPOPT : MATPOWER options struct
%
%   Outputs:
%     D2H : Hessian of AC branch flow constraints.
%
%   Example:
%       d2H = opf_branch_flow_hess(x, lambda, mpc, Yf, Yt, il, mpopt);
%
%   See also OPF_BRANCH_FLOW_FCN.

%   MATPOWER
%   Copyright (c) 1996-2017, Power Systems Engineering Research Center (PSERC)
%   by Ray Zimmerman, PSERC Cornell
%   and Carlos E. Murillo-Sanchez, PSERC Cornell & Universidad Nacional de Colombia
%
%   This file is part of MATPOWER.
%   Covered by the 3-clause BSD License (see LICENSE file for details).
%   See http://www.pserc.cornell.edu/matpower/ for more info.

%%----- initialize -----
%% define named indices into data matrices
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
    TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;

%% unpack data
lim_type = upper(mpopt.opf.flow_lim(1));
if mpopt.opf.v_cartesian
    [Vr, Vi] = deal(x{:});
    V = Vr + 1j * Vi;           %% reconstruct V
else
    [Va, Vm] = deal(x{:});
    V = Vm .* exp(1j * Va);     %% reconstruct V
end

%% problem dimensions
nb = length(V);         %% number of buses
nl2 = length(il);       %% number of constrained lines

%%----- evaluate Hessian of flow constraints -----
%% keep dimensions of empty matrices/vectors compatible
%% (required to avoid problems when using Knitro
%%  on cases with all lines unconstrained)
nmu = length(lambda) / 2;
if nmu
    muF = lambda(1:nmu);
    muT = lambda((1:nmu)+nmu);
else    %% keep dimensions of empty matrices/vectors compatible
    muF = zeros(0,1);   %% (required to avoid problems when using Knitro
    muT = zeros(0,1);   %%  on cases with all lines unconstrained)
end
if lim_type == 'I'          %% square of current
    if mpopt.opf.v_cartesian
        warning('Current magnitude limit |I| is not calculated in Cartesian coordinates')
    else
        [dIf_dVa, dIf_dVm, dIt_dVa, dIt_dVm, If, It] = dIbr_dV(mpc.branch(il,:), Yf, Yt, V);
        [Hfaa, Hfav, Hfva, Hfvv] = d2AIbr_dV2(dIf_dVa, dIf_dVm, If, Yf, V, muF);
        [Htaa, Htav, Htva, Htvv] = d2AIbr_dV2(dIt_dVa, dIt_dVm, It, Yt, V, muT);
    end
else
    f = mpc.branch(il, F_BUS);    %% list of "from" buses
    t = mpc.branch(il, T_BUS);    %% list of "to" buses
    Cf = sparse(1:nl2, f, ones(nl2, 1), nl2, nb);   %% connection matrix for line & from buses
    Ct = sparse(1:nl2, t, ones(nl2, 1), nl2, nb);   %% connection matrix for line & to buses
    [dSf_dV1, dSf_dV2, dSt_dV1, dSt_dV2, Sf, St] = dSbr_dV(mpc.branch(il,:), Yf, Yt, V, mpopt.opf.v_cartesian);
    if lim_type == '2'        %% square of real power
        if mpopt.opf.v_cartesian
            warning('Square of real power is not calculated in Cartesian coordinates')
        else
            [Hfaa, Hfav, Hfva, Hfvv] = d2ASbr_dV2_P(real(dSf_dV1), real(dSf_dV2), real(Sf), Cf, Yf, V, muF);
            [Htaa, Htav, Htva, Htvv] = d2ASbr_dV2_P(real(dSt_dV1), real(dSt_dV2), real(St), Ct, Yt, V, muT);
        end
    elseif lim_type == 'P'    %% real power
        if mpopt.opf.v_cartesian
            warning('Real power is not calculated in Cartesian coordinates')
        else
            [Hfaa, Hfav, Hfva, Hfvv] = d2Sbr_dV2(Cf, Yf, V, muF, 0);
            [Htaa, Htav, Htva, Htvv] = d2Sbr_dV2(Ct, Yt, V, muT, 0);
            [Hfaa, Hfav, Hfva, Hfvv] = deal(real(Hfaa), real(Hfav), real(Hfva), real(Hfvv));
            [Htaa, Htav, Htva, Htvv] = deal(real(Htaa), real(Htav), real(Htva), real(Htvv));
        end
    else                      %% square of apparent power
        if mpopt.opf.v_cartesian
            [Hfrr, Hfri, Hfir, Hfii] = d2ASbr_dV2_C(dSf_dV1, dSf_dV2, Sf, Cf, Yf, V, muF);
            [Htrr, Htri, Htir, Htii] = d2ASbr_dV2_C(dSt_dV1, dSt_dV2, St, Ct, Yt, V, muT);
        else
            [Hfaa, Hfav, Hfva, Hfvv] = d2ASbr_dV2_P(dSf_dV1, dSf_dV2, Sf, Cf, Yf, V, muF);
            [Htaa, Htav, Htva, Htvv] = d2ASbr_dV2_P(dSt_dV1, dSt_dV2, St, Ct, Yt, V, muT);
        end
    end
end
if mpopt.opf.v_cartesian
    d2H = [Hfrr Hfri; Hfir Hfii] + [Htrr Htri; Htir Htii];
else
    d2H = [Hfaa Hfav; Hfva Hfvv] + [Htaa Htav; Htva Htvv];
end
