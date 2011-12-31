var cos=Math.cos, sin=Math.sin;
vec3={
	create:function(a){var b=new Array(3);a?(b[0]=a[0],b[1]=a[1],b[2]=a[2]):b[0]=b[1]=b[2]=0;return b},
	set:function(a,b){b[0]=a[0];b[1]=a[1];b[2]=a[2];return b},
	add:function(a,b,c){if(!c||a===c)return a[0]+=b[0],a[1]+=b[1],a[2]+=b[2],a;c[0]=a[0]+b[0];c[1]=a[1]+b[1];c[2]=a[2]+b[2];return c},
	mul:function(a,b,c){if(!c||a===c)return a[0]*=b[0],a[1]*=b[1],a[2]*=b[2],a;c[0]=a[0]*b[0];c[1]=a[1]*b[1];c[2]=a[2]*b[2];return c},
	sub:function(a,b,c){if(!c||a===c)return a[0]-=b[0],a[1]-=b[1],a[2]-=b[2],a;c[0]=a[0]-b[0];c[1]=a[1]-b[1];c[2]=a[2]-b[2];return c},
	negate:function(a,b){b||(b=a);b[0]=-a[0];b[1]=-a[1];b[2]=-a[2];return b},
	scale:function(a,b,c){if(!c||a===c)return a[0]*=b,a[1]*=b,a[2]*=b,a;c[0]=a[0]*b;c[1]=a[1]*b;c[2]=a[2]*b;return c},
	plus:function(a,b,c){if(!c||a===c)return a[0]+=b,a[1]+=b,a[2]+=b,a;c[0]=a[0]+b;c[1]=a[1]+b;c[2]=a[2]+b;return c},
	normalize:function(a,b){b||(b=a);var c=a[0],e=a[1],f=a[2],d=Math.sqrt(c*c+e*e+f*f);if(d){if(1===d)return b[0]=c,b[1]=e,b[2]=f,b}else return b[0]=0,b[1]=0,b[2]=0,b;d=1/d;b[0]=c*d;b[1]=e*d;b[2]=f*d;return b},
	cross:function(a,b,c){c||(c=a);var e=a[0],f=a[1],a=a[2],d=b[0],g=b[1],b=b[2];c[0]=f*b-a*g;c[1]=a*d-e*b;c[2]=e*g-f*d;return c},
	dot:function(a,b){return a[0]*b[0]+a[1]*b[1]+a[2]*b[2]},
	str:function (a) {return '['+a[0]+', '+a[1]+', '+a[2]+']'},
	length:function (vec) { var x = vec[0], y = vec[1], z = vec[2]; return Math.sqrt(x * x + y * y + z * z);},
	reflect:function(i,n,r){return vec3.sub(i,vec3.scale(n,2*vec3.dot(n,i),r),r)},
	rotateXYZ:function(v,x,y,z){
		var m=mat4.create(mat4.identity());
		mat4.rotateX(m,x);
		mat4.rotateY(m,y);
		mat4.rotateZ(m,z);
		return mat4.multiplyVec3(m,v);
	},
	mix:function(x,y,a){
		return vec3.add(
			vec3.scale(x,1-a,vec3.create()),
			vec3.scale(y,a,vec3.create()),
			vec3.create());
	}
}
mat4={
	create:function(a){var b=new Array(16);a&&(b[0]=a[0],b[1]=a[1],b[2]=a[2],b[3]=a[3],b[4]=a[4],b[5]=a[5],b[6]=a[6],b[7]=a[7],b[8]=a[8],b[9]=a[9],b[10]=a[10],b[11]=a[11],b[12]=a[12],b[13]=a[13],b[14]=a[14],b[15]=a[15]);return b},
	identity:function(a){a||(a=mat4.create());a[0]=1;a[1]=0;a[2]=0;a[3]=0;a[4]=0;a[5]=1;a[6]=0;a[7]=0;a[8]=0;a[9]=0;a[10]=1;a[11]=0;a[12]=0;a[13]=0;a[14]=0;a[15]=1;return a},
	multiplyVec3:function(a,b,c){c||(c=b);var d=b[0],e=b[1],b=b[2];c[0]=a[0]*d+a[4]*e+a[8]*b+a[12];c[1]=a[1]*d+a[5]*e+a[9]*b+a[13];c[2]=a[2]*d+a[6]*e+a[10]*b+a[14];return c},
	multiplyDelta3: function(mat, vec) {
		var a_ = mat4.multiplyVec3(mat, [0, 0, 0]);
		var b_ = mat4.multiplyVec3(mat, vec3.create(vec));
		return vec3.sub(b_, a_);
	},
	rotateX:function(b,c,a){var d=Math.sin(c),c=Math.cos(c),e=b[4],f=b[5],g=b[6],h=b[7],i=b[8],j=b[9],k=b[10],l=b[11];a?b!==a&&(a[0]=b[0],a[1]=b[1],a[2]=b[2],a[3]=b[3],a[12]=b[12],a[13]=b[13],a[14]=b[14],a[15]=b[15]):a=b;a[4]=e*c+i*d;a[5]=f*c+j*d;a[6]=g*c+k*d;a[7]=h*c+l*d;a[8]=e*-d+i*c;a[9]=f*-d+j*c;a[10]=g*-d+k*c;a[11]=h*-d+l*c;return a},
	rotateY:function(b,c,a){var d=Math.sin(c),c=Math.cos(c),e=b[0],f=b[1],g=b[2],h=b[3],i=b[8],j=b[9],k=b[10],l=b[11];a?b!==a&&(a[4]=b[4],a[5]=b[5],a[6]=b[6],a[7]=b[7],a[12]=b[12],a[13]=b[13],a[14]=b[14],a[15]=b[15]):a=b;a[0]=e*c+i*-d;a[1]=f*c+j*-d;a[2]=g*c+k*-d;a[3]=h*c+l*-d;a[8]=e*d+i*c;a[9]=f*d+j*c;a[10]=g*d+k*c;a[11]=h*d+l*c;return a},
	rotateZ:function(b,c,a){var d=Math.sin(c),c=Math.cos(c),e=b[0],f=b[1],g=b[2],h=b[3],i=b[4],j=b[5],k=b[6],l=b[7];a?b!==a&&(a[8]=b[8],a[9]=b[9],a[10]=b[10],a[11]=b[11],a[12]=b[12],a[13]=b[13],a[14]=b[14],a[15]=b[15]):a=b;a[0]=e*c+i*d;a[1]=f*c+j*d;a[2]=g*c+k*d;a[3]=h*c+l*d;a[4]=e*-d+i*c;a[5]=f*-d+j*c;a[6]=g*-d+k*c;a[7]=h*-d+l*c;return a},
	translate:function(a,c,b){var d=c[0],e=c[1],c=c[2],f,g,h,i,j,k,l,m,n,o,p,q;if(!b||a===b)return a[12]=a[0]*d+a[4]*e+a[8]*c+a[12],a[13]=a[1]*d+a[5]*e+a[9]*c+a[13],a[14]=a[2]*d+a[6]*e+a[10]*c+a[14],a[15]=a[3]*d+a[7]*e+a[11]*c+a[15],a;f=a[0];g=a[1];h=a[2];i=a[3];j=a[4];k=a[5];l=a[6];m=a[7];n=a[8];o=a[9];p=a[10];q=a[11];b[0]=f;b[1]=g;b[2]=h;b[3]=i;b[4]=j;b[5]=k;b[6]=l;b[7]=m;b[8]=n;b[9]=o;b[10]=p;b[11]=q;b[12]=f*d+j*e+n*c+a[12];b[13]=g*d+k*e+o*c+a[13];b[14]=h*d+l*e+p*c+a[14];b[15]=i*d+m*e+q*c+a[15];return b},
	scale:function(a,c,b){var d=c[0],e=c[1],c=c[2];if(!b||a===b)return a[0]*=d,a[1]*=d,a[2]*=d,a[3]*=d,a[4]*=e,a[5]*=e,a[6]*=e,a[7]*=e,a[8]*=c,a[9]*=c,a[10]*=c,a[11]*=c,a;b[0]=a[0]*d;b[1]=a[1]*d;b[2]=a[2]*d;b[3]=a[3]*d;b[4]=a[4]*e;b[5]=a[5]*e;b[6]=a[6]*e;b[7]=a[7]*e;b[8]=a[8]*c;b[9]=a[9]*c;b[10]=a[10]*c;b[11]=a[11]*c;b[12]=a[12];b[13]=a[13];b[14]=a[14];b[15]=a[15];return b},
	inverse:function(c,a){a||(a=c);var d=c[0],e=c[1],f=c[2],g=c[3],h=c[4],i=c[5],j=c[6],k=c[7],l=c[8],m=c[9],n=c[10],o=c[11],p=c[12],q=c[13],r=c[14],s=c[15],t=d*i-e*h,u=d*j-f*h,v=d*k-g*h,w=e*j-f*i,x=e*k-g*i,y=f*k-g*j,z=l*q-m*p,A=l*r-n*p,B=l*s-o*p,C=m*r-n*q,D=m*s-o*q,E=n*s-o*r,b=t*E-u*D+v*C+w*B-x*A+y*z;if(!b)return null;b=1/b;a[0]=(i*E-j*D+k*C)*b;a[1]=(-e*E+f*D-g*C)*b;a[2]=(q*y-r*x+s*w)*b;a[3]=(-m*y+n*x-o*w)*b;a[4]=(-h*E+j*B-k*A)*b;a[5]=(d*E-f*B+g*A)*b;a[6]=(-p*y+r*v-s*u)*b;a[7]=(l*y-n*v+o*u)*b;a[8]=(h*D-i*B+k*z)*b;a[9]=(-d*D+e*B-g*z)*b;a[10]=(p*x-q*v+s*t)*b;a[11]=(-l*x+m*v-o*t)*b;a[12]=(-h*C+i*A-j*z)*b;a[13]=(d*C-e*A+f*z)*b;a[14]=(-p*w+q*u-r*t)*b;a[15]=(l*w-m*u+n*t)*b;return a},
	multiply:function(a,b,c){c||(c=a);var d=a[0],e=a[1],f=a[2],g=a[3],h=a[4],i=a[5],j=a[6],k=a[7],l=a[8],m=a[9],n=a[10],o=a[11],p=a[12],q=a[13],r=a[14],a=a[15],s=b[0],t=b[1],u=b[2],v=b[3],w=b[4],x=b[5],y=b[6],z=b[7],A=b[8],B=b[9],C=b[10],D=b[11],E=b[12],F=b[13],G=b[14],b=b[15];c[0]=s*d+t*h+u*l+v*p;c[1]=s*e+t*i+u*m+v*q;c[2]=s*f+t*j+u*n+v*r;c[3]=s*g+t*k+u*o+v*a;c[4]=w*d+x*h+y*l+z*p;c[5]=w*e+x*i+y*m+z*q;c[6]=w*f+x*j+y*n+z*r;c[7]=w*g+x*k+y*o+z*a;c[8]=A*d+B*h+C*l+D*p;c[9]=A*e+B*i+C*m+D*q;c[10]=A*f+B*j+C*n+D*r;c[11]=A*g+B*k+C*o+D*a;c[12]=E*d+F*h+G*l+b*p;c[13]=E*e+F*i+G*m+b*q;c[14]=E*f+F*j+G*n+b*r;c[15]=E*g+F*k+G*o+b*a;return c}
}
