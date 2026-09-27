# zivefarmy.cz

**Živé farmy** — mapa bio a regenerativních farem v Česku. 89 farem s tím,
co prodávají, kde a jak se u nich dá nakoupit.

Celá stránka je jeden statický soubor `index.html` bez build kroku a bez
závislostí. Otevře se i z disku.

## Nasazení

GitHub Pages, větev `main`, složka root. `CNAME` drží doménu `zivefarmy.cz`.

## Data

Farmy jsou v polích `FARMS` a `MORE_FARMS` uvnitř `index.html`. U každé farmy
se uvádí jen to, co jde ověřit na jejím vlastním webu — chybějící údaj se
nedoplňuje odhadem.

`cert:"bio"` označuje farmu s doloženou ekologickou certifikací. Farma bez
tohoto pole certifikaci doloženou nemá; víc to neznamená.
