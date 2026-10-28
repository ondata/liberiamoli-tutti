-- sbarcati 2025 (report del 31/12/2025) per milione di abitanti; popolazione Banca Mondiale via opensdmx (codici ISO a 3 lettere)
create table iso as select * from (values ('BD','BGD'),('EG','EGY'),('ML','MLI'),('ER','ERI'),('DZ','DZA'),('SD','SDN'),('TN','TUN'),('GN','GIN'),('PK','PAK'),('SY','SYR'),('MA','MAR'),('NG','NGA'),('SO','SOM'),('IR','IRN'),('ET','ETH')) t(iso2, iso3);
copy (select iso2 iso, OBS_VALUE::bigint pop from read_csv('pop_opensdmx.csv') join iso on REF_AREA = iso3 order by iso) to 'popolazione_2025.csv';
copy (
  select n."ISO_3166-1" iso, n.Nazione nazione, n.Valore sbarcati, p.pop popolazione, round(1e6 * n.Valore / p.pop, 1) per_milione
  from read_csv('../../dati/nazionalita.csv') n join read_csv('popolazione_2025.csv') p on p.iso = n."ISO_3166-1"
  where n.Data_Report = '2025-12-31' order by per_milione desc
) to 'tasso_2025.csv';
