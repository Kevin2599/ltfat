function [c,Ls]=dwilt2(f,g1,p3,p4,p5)
%DWILT2  2D Discrete Wilson transform
%   Usage: c=dwilt2(f,g,M); 
%          c=dwilt2(f,g1,g2,[M1,M2]);
%          c=dwilt2(f,g1,g2,[M1,M2],[L1,L2]);
%          [c,Ls]=dwilt2(f,g1,g2,[M1,M2],[L1,L2]);
%
%   Input parameters:
%         f        : Input data, matrix.
%         g,g1,g2  : Window functions.
%         M,M1,M2  : Number of bands.
%         L1,L2    : Length of transform to do.
%   Output parameters:
%         c        : array of coefficients.
%         Ls       : Original size of input matrix.
%
%   `dwilt2(f,g,M)` calculates a two dimensional discrete Wilson transform
%   of the input signal *f* using the window *g* and parameter *M* along each
%   dimension.
%
%   For each dimension, the length of the transform will be the smallest
%   possible that is larger than the length of the signal along that dimension.
%   f will be appropriately zero-extended.
%
%   All windows must be whole-point even.
% 
%   `dwilt2(f,g,M,L)` computes a Wilson transform as above, but does
%   a transform of length *L* along each dimension. *f* will be cut or
%   zero-extended to length *L* before the transform is done.
%
%   `[c,Ls]=dwilt(f,g,M)` or `[c,Ls]=dwilt(f,g,M,L)` additionally returns the
%   length of the input signal *f*. This is handy for reconstruction.
%
%   `c=dwilt2(f,g1,g2,M)` makes it possible to use a different window along the
%   two dimensions. 
%
%   The parameters *L*, *M* and *Ls* can also be vectors of length 2. In
%   this case the first element will be used for the first dimension and the
%   second element will be used for the second dimension.
%
%   The output *c* has 4 or 5 dimensions. The dimensions index the
%   following properties:
%
%     1. Number of translations along 1st dimension of input.
%
%     2. Number of channels along 1st dimension  of input
%
%     3. Number of translations along 2nd dimension of input.
%
%     4. Number of channels along 2nd dimension  of input
%
%     5. Plane number, corresponds to 3rd dimension of input. 
%
%   Examples:
%   ---------
%
%   The following example visualize the `dwilt2` coefficients of a test
%   image. For clarity, only the 50 dB largest coefficients are show::::
%
%     c=dwilt2(cameraman,'itersine',16);
%     c=reshape(c,256,256);
%     
%     figure(1);
%     imagesc(cameraman), colormap(gray), axis('image');
%
%     figure(2);
%     cc=dynlimit(20*log10(abs(c)),50);
%     imagesc(cc), colormap(flipud(bone)), axis('image'), colorbar;
%
%   See also:  dwilt, idwilt2, dgt2, wildual

%   AUTHOR : Peter L. Søndergaard.

complainif_argnonotinrange(nargin,3,5,mfilename);

L=[];

if prod(size(p3))>2
  % Two windows was specified.
  g2=p3;
  M=p4;
  if nargin==5
    L=p5;
  end;
else
  g2=g1;
  M=p3;
  if nargin==4
    L=p4;
  end;
end;
  
if isempty(L)
  L1=[];
  L2=[];
else
  L1=L(1);
  L2=L(2);
end;

% Expand M if necessary to two elements
M=bsxfun(@times,M,[1 1]);

Ls=size(f);
Ls=Ls(1:2);

c=dwilt(f,g1,M(1),L1);
c=dwilt(c,g2,M(2),L2,'dim',3);
