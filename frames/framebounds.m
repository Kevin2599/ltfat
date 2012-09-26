function [AF,BF]=framebounds(F,varargin);
%FRAMEBOUNDS  Frame bounds
%   Usage: fcond=framebounds(F);
%          [A,B]=framebounds(F);
%
%   `framebounds(F)` calculates the ratio $B/A$ of the frame bounds
%   of the frame given by *F*.
%
%   `framebounds(F,Ls)` additionally specifies a signal length for which
%   the frame should work.
%
%   `[A,B]=framebounds(F)` returns the frame bounds *A* and *B* instead of
%   just their ratio.
%
%   `framebounds(F,'s')` returns the framebounds of the synthesis frame
%   instead of those of the analysis frame.
%
%   'framebounds` accepts the following optional parameters:
%
%     'a'          Use the analysis frame. This is the default.
%  
%     's'          Use the synthesis.
%
%     'fac'        Use a factorization algorithm. The function will throw
%                  an error if no algorithm is available.
%
%     'iter'       Call `eigs` to use an iterative algorithm.
%
%     'full'       Call `eig` to solve the full problem.
%
%     'auto'       Choose the `fac` method if possible, otherwise
%                  use the `full` method for small problems and the
%                  `iter` method for larger problems. This is the
%                  default. 
%
%     'crossover',c
%                  Set the problem size for which the 'auto' method
%                  switches between `full` and `iter`. Default is 200.
%
%   The following parameters specifically related to the `iter` method: 
%
%     'tol',t      Stop if relative residual error is less than the
%                  specified tolerance. Default is 1e-9 
%
%     'maxit',n    Do at most n iterations.
%
%     'p',p        The number of Lanzcos basis vectors to use.  More vectors
%                  will result in faster convergence, but a larger amount of
%                  memory.  The optimal value of `p` is problem dependent and
%                  should be less than *L*.  The default value is 2.
% 
%     'print'      Display the progress.
%
%     'quiet'      Don't print anything, this is the default.

%
%   See also: newframe, framered

% We handle fusion frames first
  if strcmp(F.type,'fusion')
      AF=0;
      BF=0;
      for ii=1:F.Nframes
          [A,B]=framebounds(F.frames{ii},varargin{:});
          AF=AF+(A*F.w(ii)).^2;
          BF=BF+(B*F.w(ii)).^2;
      end;
      AF=sqrt(AF);
      BF=sqrt(BF);
        
      return;
  end;    
    
  definput.keyvals.Ls=1;
  definput.flags.system={'a','s'};
  definput.keyvals.maxit=100;
  definput.keyvals.tol=1e-9;
  definput.keyvals.crossover=200;
  definput.keyvals.p=4;
  definput.flags.print={'quiet','print'};
  definput.flags.method={'auto','fac','iter','full'};
  
  [flags,kv]=ltfatarghelper({'Ls'},definput,varargin);
  
  F=frameaccel(F,kv.Ls);
  L=F.L;
  
  % Default values, works for the pure frequency transforms.
  AF=1;
  BF=1;
  
  % Simple heuristic: If F.ga is defined, the frame uses windows.
  if isfield(F,'ga')
    if flags.do_a
      if isempty(F.ga)
        error('%s: No analysis frame is defined.', upper(mfilename));
      end;
      g=F.ga;
      isfac=F.isfacana;
      op    = @frana;
      opadj = @franaadj;
    else
      if isempty(F.gs)
        error('%s: No synthesis frame is defined.', upper(mfilename));
      end;
      g=F.gs;
      isfac=F.isfacsyn;
      op    = @frsyn;
      opadj = @frsynadj;
    end;
  else
      % If F.ga is not defined, the tranform always has a fast way of
      % calculating the frame bounds.
      isfac=1;
  end;
  
  if flags.do_fac && ~isfac
    error('%s: The type of frame has no factorization algorithm.',upper(mfilename));
  end;
  
  if (flags.do_auto && isfac) || flags.do_fac
    switch(F.type)
     case 'gen'
      V=svd(g);
      AF=min(V)^2;
      BF=max(V)^2;
     case {'dgt','dgtreal'}
      [AF,BF]=gabframebounds(g,F.a,F.M,L); 
     case {'dwilt','wmdct'}
      [AF,BF]=wilbounds(g,F.M,L); 
     case {'filterbank','ufilterbank'}
      [AF,BF]=filterbankbounds(g,F.a,L);
     case {'filterbankreal','ufilterbankreal'}
      [AF,BF]=filterbankrealbounds(g,F.a,L); 
     case 'fft'
      AF=L;
      BF=L;
     case 'fftreal'
      AF=F.L;
      BF=F.L; 
    end;  
  end;
  
  if (flags.do_auto && ~isfac && F.L>kv.crossover) || flags.do_iter
    
    if flags.do_print
      opts.disp=1;
    else
      opts.disp=0;
    end;
    opts.isreal = false;
    opts.maxit  = kv.maxit;
    opts.tol    = kv.tol;
    %opts.issym  = 1;
    opts.p      = kv.p;
    
    afun(1,F,op,opadj); 
    % The inverse method does not work.
    %AF = real(eigs(@afun,L,1,'SM',opts));
    BF = real(eigs(@afun,L,1,'LM',opts));
    
  end;
  
  if (flags.do_auto && ~isfac && F.L<=kv.crossover) || flags.do_full
    % Compute thee transform matrix.
    bigM=opadj(F,op(F,eye(L)));
    
    D=eig(bigM);
    
    % Clean the eigenvalues, we know they are real
    D=real(D);
    AF=min(D);
    BF=max(D);
  end;

  if nargout<2
    % Avoid the potential warning about division by zero.
    if AF==0
      AF=Inf;
    else
      AF=BF/AF;
    end;
  end;
  
end

% The function has been written in this way, because Octave (at the time
% of writing) does not accept additional parameters at the end of the
% line of input arguments for eigs
function y=afun(x,F_in,op_in,opadj_in)
  persistent F;
  persistent op;
  persistent opadj;
  
  if nargin>1
    F     = F_in; 
    op    = op_in;
    opadj = opadj_in;
  else
    y=opadj(F,op(F,x));
  end;

end
