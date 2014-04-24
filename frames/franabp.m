function [c,relres,iter,frec,cd] = franabp(F,f,varargin)
%FRANABP Frame Analysis Basis Pursuit
%   Usage: c = franabp(F,f)
%          c = franabp(F,f,lambda)
%          c = franabp(F,f,lambda,C)
%          c = franabp(F,f,lambda,C,tol)
%          c = franabp(F,f,lambda,C,tol,maxit)
%
%   Input parameters:
%       F        : Frame definition
%       f        : Input signal
%       lambda   : Regularization parameter.
%       C        : Step size of the algorithm.
%       tol      : Reative error tolerance.
%       maxit    : Maximum number of iterations.
%   Output parameters:
%       c        : Sparse coefficients.
%       relres   : Last relative error.
%       iter     : Number of iterations done.
%       frec     : Reconstructed signal such that frec = frsyn(F,c)
%       cd       : The min ||c||_2 solution using the canonical dual frame.
%
%   `c = franabp(F,f,lambda)` solves the Basis Pursuit problem
%
%   .. min lambda*||c||_1 subject to Fc = f
%
%   .. math:: \lambda||c||_1 \\ \text{subject to } Fc = f
%
%   for a general frame *F* using SALSA (Split Augmented Lagrangian
%   Srinkage algorithm) which is an appication of ADMM (Alternating
%   Direction Method of Multipliers) to the basis pursuit problem.
%
%   The algorithm acts as follows:
%
%   Initialize d,C>0
%   repeat
%      v <- soft(c+d,lambda/C) - d
%      d <- F*(FF*)^(-1)(f - Fv)
%      c <- d + v
%   end
%
%   For a quick execution, the function requires analysis operator of the
%   canonical dual frame F*(FF*)^(-1). By default, the function attempts
%   to call |framedual| to create the canonical dual frame explicitly.
%   If it is not available, the conjugate cradient algorithm is
%   used for inverting the frame operator in each iteration of the
%   algorithm.
%   Optionally, the canonical dual frame object or an anonymous function 
%   acting as the analysis operator of the canonical dual frame can be 
%   passed as a key-value pair `'Fd',Fd`.   
%
%   REMARK: `tol` defines tolerance of `relres` which is norm or a relative
%   difference of coefficients obtained in two consecutive iterations of the
%   algorithm.
%
%   **Note**: If you do not specify *C*, it will be obtained as the upper
%   framebound. Depending on the structure of the frame, this can be an
%   expensive operation.
%
%   Optional parameters:
%   --------------------
%
%   Key-value pairs:
%
%     `'Fd',Fd`
%             A canonical dual frame object or an anonymous function 
%             acting as the analysis operator of the canonical dual frame.
%
%     `'printstep',printstep`
%             Print current status every `printstep` iteration.
%
%   Flag groups (first one listed is the default):
%
%     `'print','quiet'`
%             Enables/disables printing of notifications.
%
%     `'zeros','frana'`
%             Starting point of the algorithm. With `'zeros'` enabled, the
%             algorithm starts from coefficients set to zero, with `'frana'`
%             the algorithm starts from `c=frana(F,f)`.             
%
%   Returned arguments:
%   -------------------
%
%   `[c,relres,iter] = franabp(...)` return thes residuals *relres* in a
%   vector and the number of iteration steps done *iter*.
%
%   `[tc,relres,iter,frec,cd] = franabp(...)` returns the reconstructed
%   signal from the coefficients, *frec* (this requires additional
%   computations) and a coefficients *cd* minimizing the ||c||_2 norm
%   (this is a byproduct of the algorithm).
%
%   The relationship between the output coefficients *frec* and *c* is
%   given by ::
%
%     frec = frsyn(F,c);
%
%   And *cd* and f by ::
%
%     cd = frana(framedual(F),f);
%
%   Examples:
%   ---------
%
%   The following example shows how franabp produces a sparse
%   representation of a test signal *greasy* still maintaining a perfect
%   reconstruction:::
%
%      f = greasy;
%      % Gabor frame with redundancy 8
%      F = frame('dgtreal','gauss',64,512);
%      % Solve the basis pursuit problem
%      [c,~,~,frec,cd] = franabp(F,f);
%      % Plot sparse coefficients
%      figure(1);
%      plotframe(F,c,'dynrange',50);
%
%      % Plot coefficients obtained by applying an analysis operator of a
%      % dual Gabor system to *f*
%      figure(2);
%      plotframe(F,cd,'dynrange',50);
%
%      % Check the reconstruction error (should be close do zero).
%      % frec is obtained by applying the synthesis operator of frame *F*
%      % to sparse coefficients *c*.
%      norm(f-frec)
%
%      % Compare decay of coefficients sorted by absolute values
%      % (compressibility of coefficients)
%      figure(3);
%      semilogx([sort(abs(c),'descend')/max(abs(c)),...
%      sort(abs(cd),'descend')/max(abs(cd))]);
%      legend({'sparsified coefficients','dual system coefficients'});
%
%   See also: frame, frana, frsyn, framebounds, franalasso
%
%   References: se14 bopachupeec11

%   AUTHOR: Zdenek Prusa


complainif_notenoughargs(nargin,2,'FRANABP');

% Define initial value for flags and key/value pairs.
definput.keyvals.C=[];
definput.keyvals.lambda=[];
definput.keyvals.tol=1e-2;
definput.keyvals.maxit=100;
definput.keyvals.printstep=10;
definput.keyvals.Fd=[];
definput.flags.print={'print','quiet'};
definput.flags.startpoint={'zeros','frana'};
[flags,kv,lambda,C]=ltfatarghelper({'lambda','C','tol','maxit'},definput,varargin);

if isempty(lambda)
    lambda = 1;
end

if ~isnumeric(lambda) || lambda<0
    error('%s: ''lambda'' parameter must be a positive scalar.',...
          upper(mfilename));
end

%% ----- step 1 : Verify f and determine its length -------
% Change f to correct shape.
[f,~,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(f,[],[],upper(mfilename));

if W>1
    error('%s: Input signal can be single channel only.',upper(mfilename));
end

% Do a correct postpad so that we can call F.frana and F.frsyn
% directly.
L = framelength(F,Ls);
f = postpad(f,L);


if isempty(C)
    % Use the upper framebound as C
   [~,C] = framebounds(F,L);
else
   if ~isnumeric(C) || C<0
       error('%s: ''C'' parameter must be a positive scalar.',...
           upper(mfilename));
   end
end;


if isempty(kv.Fd)
    % If the dual frame was not explicitly passed try creating it
    try
       % Try to create and accelerate the dual frame
       Fd = frameaccel(framedual(F),L);
       Fdfrana = @(insig) Fd.frana(insig);
    catch
       warning(sprintf(['The canonical dual system is not available for a given ',...
           'frame.\n Using franaiter.'],upper(mfilename)));
        % err = lasterror.message;
        % The dual system cannot be created.
        % We will use franaiter instead
       Fdfrana = @(insig) franaiter(F,insig,'tol',1e-14);
    end
else
   if isstruct(kv.Fd) && isfield(kv.Fd,'type') 
      % The canonical dual frame was passed explicitly as a frame object
      Fd = frameaccel(kv.Fd,L);
      Fdfrana = @(insig) Fd.frana(insig);
   elseif isa(kv.Fd,'function_handle')
      % The anonymous function is expected to do F*(FF*)^(-1)
      Fdfrana = kv.Fd;
   else
       error('%s: Invalid format of Fd.',upper(mfielname));
   end
end

% Accelerate the frame
F = frameaccel(F,L);

% Cache the constant part
cd = Fdfrana(f);

% Intermediate results
d = zeros(size(cd));
% Initial point
if flags.do_frana
   tc0 = F.frana(f);
elseif flags.do_zeros
   tc0 = zeros(size(cd));
end
c = tc0;

% 1/C is the lower frame bound of the dual frame.
threshold = lambda/C;
relres = 1e16;
iter = 0;

% The main algorithm
while ((iter < kv.maxit)&&(relres >= kv.tol))
   v = thresh(c + d,threshold,'soft') - d;
   d = cd - Fdfrana(F.frsyn(v));
   c = d + v;
   relres = norm(c(:)-tc0(:))/norm(tc0(:));
   tc0 = c;
   iter = iter + 1;
   if flags.do_print
     if mod(iter,kv.printstep)==0
       fprintf('Iteration %d: relative error = %f\n',iter,relres);
     end;
   end;
end


if nargout>3
    % Do a reconstruction with the original frame
    frec = postpad(F.frsyn(c),Ls);
    % Reformat to the original shape
    frec = assert_sigreshape_post(frec,dim,permutedsize,order);
end