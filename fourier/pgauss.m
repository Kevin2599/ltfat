function [g,tfr]=pgauss(L,varargin)
%PGAUSS  Sampled, periodized Gaussian.
%   Usage: g=pgauss(L);
%          g=pgauss(L,tfr);
%          g=pgauss(L,...);
%          [g,tfr]=pgauss( ... );
% 
%   Input parameters:
%         L    : Length of vector.
%         tfr  : ratio between time and frequency support.
%   Output parameters:
%         g    : The periodized Gaussian.
%
%   PGAUSS(L,tfr) computes samples of a periodized Gaussian. The function
%   returns a regular sampling of the periodization of the function
%   exp(-pi*(x.^2/tfr)).
%
%   The returned function has norm == 1.
%
%   The parameter tfr determines the ratio between the effective
%   support of g and the effective support of the DFT of g. If tfr>1 then
%   g has a wider support than the DFT of g.
%
%   PGAUSS(L) does the same setting tfr=1.
%
%   Additional properties of the Gaussian can be specified as flags at
%   the end of the line of input arguments.
%
%   [g,tfr] = PGAUSS( ... ) will additionally return the time-to-frequency
%   support ratio. This is useful if you did not specify it (i.e. used
%   the 'width' or bandwidth flag).
%
%   The function is whole-point even. This implies that FFT(PGAUSS(L,tfr))
%   is real for any L and tfr. The DFT of g is equal to PGAUSS(L,1/tfr).
%
%   In addition to the 'width' flag, PGAUSS understands the following
%   flags at the end of the list of input parameters:
%
%      'fs',fs    - Use a sampling rate of fs Hz as unit for specifying the
%                   width, bandwidth, center frequency and delay of the
%                   Gaussian. Default is fs=[] which indicates to measure
%                   everything in samples.
%
%      'width',s  - Set the width of the Gaussian such that it has an
%                   effective support of s samples. This means that
%                   approx. 96% of the energy or 79% of the area
%                   under the graph is contained within s samples. This 
%                   corresponds to a -6 db cutoff. This is equivalent to
%                   calling PGAUSS(L,s^2/L);
%
%      'bw',bw    - As for the 'width' argument, but specifies the width
%                   in the frequency domain. The bandwidth is measured in 
%                   normalized frequency, unless the 'fs' value is given.
%
%      'cf',cf    - Set the center frequency of the Gaussian to fc.  
%
%-     'wp'       - Output is whole point even. This is the default.
%
%-     'hp'       - Output is half point even, as most Matlab filter
%                  routines.
%
%-     'delay',d  - Delay the output by d. Default is zero delay.
%
%   If this function is used to generate a window for a Gabor frame, then
%   the window giving the smallest frame bound ratio is generated by
%   PGAUSS(L,a*M/L);
%
%   See also:  longpar, psech, firwin, pbspline
%
%   Demos:  demo_pgauss
%
%R  mazh93

% AUTHOR : Peter Soendergaard.

%   First reference on this found in mazh93 eq. 63

if nargin<1
  error('Too few input parameters.');
end;

if (prod(size(L,1))~=1 || ~isnumeric(L))
  error('L must be a scalar');
end;

if rem(L,1)~=0
  error('L must be an integer.')
end;

% Define initial value for flags and key/value pairs.
definput.flags.centering={'wp','hp'};
definput.flags.delay={'nodelay','delay'};
definput.flags.width={'tfr','width','bw'};

definput.keyvals.tfr=1;
definput.keyvals.delay=0;
definput.keyvals.width=0;
definput.keyvals.fs=[];
definput.keyvals.cf=0;
definput.keyvals.bw=0;

[flags,keyvals,tfr]=ltfatarghelper({'tfr'},definput,varargin);

if (prod(size(tfr,1))~=1 || ~isnumeric(tfr))
  error('tfr must be a scalar.');
end;

fs=keyvals.fs;

if flags.do_wp
  cent=0;
else
  cent=0.5;
end;

if isempty(fs)
  
  if flags.do_width
    tfr=keyvals.width^2/L;
  end;
  
  if flags.do_bw
  tfr=L/(keyvals.bw*L/2)^2;
  end;
  
  delay_s=keyvals.delay;
  cf_s   =keyvals.cf;
else
  
  if flags.do_width
    tfr=(keyvals.width*fs)^2/L;
  end;

  if flags.do_bw
    tfr=L/(keyvals.bw/fs*L)^2;
  end;
  
  delay_s=keyvals.delay*fs;
  cf_s   =keyvals.cf/fs*L;
end;

g=comp_pgauss(L,tfr,cent-delay_s,cf_s);

