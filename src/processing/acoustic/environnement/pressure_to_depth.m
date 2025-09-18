function d =  pressure_to_depth(p,lat)

c1 = +9.72659;
c2 = -2.2512E-5;
c3 = +2.279E-10;
c4 = -1.82E-15;
gam = 2.184e-6;

X   = sind(abs(lat)); 
X   = X.*X;
denum = 9.780318*(1.0+(5.2788E-3+2.36e-5*X).*X) + gam*0.5*p;
num = (((c4*p+c3).*p+c2).*p+c1).*p;
d   = num./denum;