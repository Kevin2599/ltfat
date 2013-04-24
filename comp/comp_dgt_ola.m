function coef=comp_dgt_ola(f,g,a,M,Lb)
%
%  This function implements periodic convolution using overlap-add. The
%  window g is supposed to be extended by fir2iir.
  
[L W]=size(f);
gl=length(g);
  
N=L/a;

% Length of extended block and padded g
Lext=Lb+gl;

% Number of blocks
Nb=L/Lb;

% Number of time positions per block
Nblock   = Lb/a;
Next = Lext/a;

if rem(Nblock,1)~=0
  error('The length of the time shift must devide the block length.');
end;

% Number of time positions in half extension
b2 = gl/2/a;

if rem(b2,1)~=0
  error(['The length of the time shift must devide the window length by ' ...
         'an even number.'])
end;

% Extend window to length of extended block.
gpad=fir2long(g,Lext);

coef=zeros(M,N,W,assert_classname(f,g));

for ii=0:Nb-1
  
  block=comp_dgt_long(postpad(f(ii*Lb+1:(ii+1)*Lb,:),Lext),gpad,a,M);
  block=reshape(block,M,Next,W);

  % Large block
  coef(:,ii*Nblock+1:(ii+1)*Nblock,:) = coef(:,ii*Nblock+1:(ii+1)*Nblock,:)+block(:,1:Nblock,:);  
  
  % Small block +
  s_ii=mod(ii+1,Nb);
  coef(:,s_ii*Nblock+1   :s_ii*Nblock+b2,:) = coef(:,s_ii*Nblock+1 ...
                                                   :s_ii*Nblock+b2,:)+ block(:,Nblock+1:Nblock+b2,:); 

  % Small block -
  s_ii=mod(ii-1,Nb)+1;
  coef(:,s_ii*Nblock-b2+1:s_ii*Nblock,:) =coef(:,s_ii*Nblock-b2+1:s_ii*Nblock,:)+ block(:,Nblock+b2+1:Nblock+2*b2,:);

end;

