#!/bin/bash

set -x
set -e
set -u
set -o pipefail

### requisiti ###
# pdftk https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/
# tabula-java https://github.com/tabulapdf/tabula-java
# Miller versione 6, che nello script è rinominato mlrgo https://github.com/johnkerl/miller
### requisiti ###

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# extract the total pages of a pdf file

pagine=$(pdftk "$folder"/../rawdata/"Registro Pubblico LR17-2003_dal 2012 al 2022.pdf" dump_data | grep NumberOfPages | awk '{print $2}')

# if "$folder"/tmp.csv exists, delete it
if [ -f "$folder"/tmp.csv ]; then
  rm "$folder"/tmp.csv
fi

# estrai prima pagina
java -jar ~/bin/tabula-java.jar -l -a 98.962,97.474,789.464,1101.975 -p 1 "$folder"/../rawdata/"Registro Pubblico LR17-2003_dal 2012 al 2022.pdf" | mlrgo --csv -N skip-trivial-records then clean-whitespace | mlrgo --csv put '$pagina=1' >>"$folder"/tmp.csv

# estrai le altre pagine
for (( i=2; i<=pagine; i++ )); do
  java -jar ~/bin/tabula-java.jar  -l -a 39.436,73.663,796.904,1109.416 -p "$i" "$folder"/../rawdata/"Registro Pubblico LR17-2003_dal 2012 al 2022.pdf" | mlrgo --csv -N clean-whitespace then put '$pagina='"$i"'' >>"$folder"/tmp.csv
done



