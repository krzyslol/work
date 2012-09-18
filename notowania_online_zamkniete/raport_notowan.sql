SELECT   *
    FROM (SELECT nr_kl, nr_cz, wlasciciel,
                 DECODE (status,
                         0, 'zamkniety',
                         'otwarty'
                        ) "status rachunku",nvl(saldo,0) saldo, opis notowania,
                 to_char(ostatnie_naliczenie,'DD-MM-YYYY') "ostatnie naliczenie oplaty",
                 NVL (TO_CHAR (ostatnie_zlecenie),
                      'brak'
                     ) "data ostatniego zlecenia",
                 to_char(data_otwarcia,'DD-MM-YYYY') "data otwarcia rachunku",
                 DECODE (status,
                         0, TO_CHAR (data_zamkniecia,'DD-MM-YYYY'),
                         'brak'
                        ) "data zamkniecia rachunku"
            FROM (SELECT u.nr_kl nr_kl, r.nr_cz nr_cz,
                         r.imie || ' ' || r.nazwisko wlasciciel,
                         NVL (r.status, 0) status,
                         (SELECT SUM (wartosc)
                            FROM main99.kf kf
                           WHERE kf.nr_kl = r.nr_kl) saldo,
                         (SELECT opis
                            FROM w_uslugi_typy ut
                           WHERE ut.ID = u.id_uslugi) opis,
                         (SELECT MAX (data_oper)
                            FROM w_dof dof
                           WHERE dof.nr_kl = r.nr_kl
                             AND kod_op = '127') ostatnie_naliczenie,
                         data_pocz, data_konc,
                         (SELECT MAX (data_wyst)
                            FROM w_zl zl
                           WHERE zl.nr_kl = r.nr_kl) ostatnie_zlecenie,
                         TRUNC (NVL ((SELECT MIN (data_zm)
                                        FROM dziennik_zmian dz
                                       WHERE tabela = 'RK'
                                         AND pole = 'STATUS'
                                         AND na > 0
                                         AND klucz = r.nr_kl),
                                     (r.DATA)
                                    )
                               ) data_otwarcia,
                         (SELECT MAX (data_zm)
                            FROM dziennik_zmian dz
                           WHERE tabela = 'RK'
                             AND pole = 'STATUS'
                             AND na = 0
                             AND klucz = r.nr_kl) data_zamkniecia
                    FROM w_uslugi_umowy u, w_rk r
                   WHERE (   u.data_konc >= SYSDATE
                          OR u.data_konc = TO_DATE (1, 'J')
                         )
                     AND u.oplata = 'T'
                     AND r.nr_kl(+) = u.nr_kl)
           WHERE nr_kl IS NOT NULL)
ORDER BY DECODE ("status rachunku", 'zamkniety', 0, 1)
