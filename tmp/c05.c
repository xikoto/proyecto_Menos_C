// Calcula el factorial de un m�mero > 0 y < 13
{ int n; int fac; int i;

  fac = 1; read(n);
  if ((n > 0) && (n < 13)) {
    for (i = 2; i <= n; i++) fac = fac * i;
    print(fac);
  }
  else {}
}
