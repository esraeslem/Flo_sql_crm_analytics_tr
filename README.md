# FLO CRM Analitiği — SQL Alıştırmaları

FLO'nun OmniChannel (hem online hem offline alışveriş yapan) müşteri veri
seti (2020–2021) üzerine hazırlanmış 16 soruluk CRM analiz vaka çalışmasının
SQL çözümleri. Bu proje Miuul Data Scientist bootcamp'i kapsamında
hazırlanmıştır. Tüm sorgular gerçek veri seti (19.945 satır) üzerinde
doğrulanmıştır.

## İş problemi

FLO, hem online hem de fiziksel mağazalardan alışveriş yapan OmniChannel
müşterilerini; müşteri sayısı, ciro, kanal ve mağaza tipi kırılımları,
kategori ilgisi ve en değerli müşterilerin alışveriş sıklığı gibi 16
analitik soru üzerinden anlamak istiyor.

## Veri seti

`data/flo_data_20K.csv` — 19.945 müşteri, 13 değişken.

| Değişken | Açıklama |
|---|---|
| `master_id` | Eşsiz müşteri numarası |
| `order_channel` | Alışveriş yapılan platform (Android App, iOS App, Desktop, Mobile) |
| `last_order_channel` | En son alışverişin yapıldığı kanal |
| `first_order_date` | Müşterinin ilk alışveriş tarihi |
| `last_order_date` | Müşterinin son alışveriş tarihi |
| `last_order_date_online` / `_offline` | Online / offline platformda yapılan son alışveriş tarihi |
| `order_num_total_ever_online` / `_offline` | Online / offline'da yapılan toplam alışveriş sayısı |
| `customer_value_total_ever_offline` / `_online` | Offline / online alışverişlerde ödenen toplam ücret |
| `interested_in_categories_12` | Son 12 ayda alışveriş yapılan kategoriler |
| `store_type` | Müşterinin alışveriş yaptığı company'ler (A, B, C — örn. `A`, `A,B`, `A,B,C`) |

## Repo yapısı

```
├── data/
│   └── flo_data_20K.csv          # kaynak veri seti
├── docs/
│   └── flo_sql_case_study.pdf    # orijinal ödev metni
├── sql/
│   ├── 01_schema.sql             # Soru 1 — CREATE DATABASE / CREATE TABLE (MySQL)
│   └── 02_solutions.sql          # Soru 2–16 — tüm çözümler (MySQL)
├── scripts/
│   ├── build_database.py         # CSV'yi yerel bir SQLite veritabanına yükler
│   └── run_solutions.py          # 16 sorguyu çalıştırıp sonuçları basar (SQLite)
├── requirements.txt
└── LICENSE
```

## Nasıl çalıştırılır

**Seçenek A — MySQL (asıl çözüm anahtarı)**
`sql/01_schema.sql` dosyasını çalıştırın, `data/flo_data_20K.csv`'yi `FLO`
tablosuna yükleyin (dosyanın sonundaki `LOAD DATA INFILE` örneğine bakın ya
da herhangi bir istemcinin CSV içe aktarma özelliğini kullanın), ardından
`sql/02_solutions.sql`'i çalıştırın.

**Seçenek B — SQLite, kurulum gerektirmez (aşağıdaki sonuçları tekrar üretin)**
```bash
pip install -r requirements.txt
python scripts/build_database.py   # flo_data_20K.csv -> flo_customers.db
python scripts/run_solutions.py    # 16 sorunun cevabını basar
```
`sql/02_solutions.sql` asıl MySQL sürümüdür; `run_solutions.py` aynı
mantığı SQLite söz dizimiyle (`DATEDIFF()` yerine `julianday()`, `YEAR()`
yerine `strftime()`) yeniden uygular — tek amacı, sadece Python kurulu bir
makinede bile sonuçların doğrulanabilmesini sağlamaktır.

## Sorular ve sonuçlar

| # | Soru | Sonuç |
|---|---|---|
| 2 | Farklı müşteri sayısı | **19.945** |
| 3 | Toplam alışveriş sayısı / toplam ciro | **100.219 alışveriş** / **14.983.567,31 ₺** |
| 4 | Alışveriş başına ortalama ciro | **149,51 ₺** |
| 5 | Ciroya göre en iyi kanal (`last_order_channel`) | **Android App** — 5,62M ₺ / 37.320 alışveriş |
| 6 | Ciroya göre en iyi store_type | **A** — 10,84M ₺ |
| 7 | En yoğun yıl (ilk alışveriş tarihine göre) | **2019** — 47.827 alışveriş |
| 8 | Kanal bazında en yüksek ortalama alışveriş cirosu | **iOS App** — 164,64 ₺ |
| 9 | Son 12 ayda en çok ilgi gören kategori | **AKTIFSPOR** — 9.204 müşteri |
| 10 | En çok tercih edilen store_type | **A** — 15.453 müşteri |
| 11 | Kanal bazında en popüler kategori | Offline hariç tüm kanallarda **AKTIFSPOR**; Offline'da **KADIN** |
| 12 | En çok alışveriş yapan müşteri | `5d1c466a-9cfd-11e9-9897-000d3a38a36f` — 202 alışveriş |
| 13 | Bu müşterinin alışveriş başına ort. cirosu & sıklığı | 227,25 ₺/alışveriş, ortalama **13,7 günde bir** alışveriş |
| 14 | Ciroya göre ilk 100 müşterinin ort. alışveriş sıklığı | ortalama **42,2 günde bir** |
| 15 | Kanal bazında en çok alışveriş yapan müşteri | 5 müşteri — bkz. `run_solutions.py` çıktısı |
| 16 | En son alışveriş yapan müşteri(ler) | 2021-05-30 tarihinde **80 müşteri** eşit |

Gruplanmış sorguların tüm satırları dahil tam sonuç kümeleri
`scripts/run_solutions.py` tarafından yazdırılır.

## Yorumlama notları

- `interested_in_categories_12` her müşteri için köşeli parantez içinde bir
  liste tutar (örn. `[ERKEK, COCUK, KADIN, AKTIFSPOR]`). Kategori sayımları
  (Soru 9, 11) bu listeyi virgülle sarılmış token'lara normalize eder; böylece
  `LIKE '%,COCUK,%'` sorgusu, `AKTIFCOCUK` içinde geçen "COCUK" alt dizesiyle
  yanlışlıkla eşleşmez.
- Veri setinde kategori bazlı ciro alanı yok — her müşterinin tek bir toplam
  cirosu var — bu nedenle Soru 11'de "ne kadarlık alışveriş yapıldığı",
  ciro değil, o kategoriyle ilgilenen müşteri sayısı olarak hesaplanmıştır.
- "Alışveriş sıklığı" (Soru 13, 14),
  `(son_alisveris_tarihi − ilk_alisveris_tarihi) / toplam_alisveris_sayisi`
  formülüyle hesaplanmıştır: müşterinin yaşam süresi boyunca alışverişlerin
  eşit aralıklarla dağıldığı varsayımıyla, iki alışveriş arasındaki
  ortalama gün sayısı.

## Teknoloji

SQL (MySQL 8.0+ — CTE'ler, pencere fonksiyonları) · Python (pandas,
sqlite3) yerel doğrulama için.

## Kaynak

Vaka çalışması ve veri seti [Miuul](https://miuul.com) Data Scientist
bootcamp'inden alınmıştır (FLO SQL Alıştırmaları). Orijinal ödev PDF'i
referans amacıyla `docs/` klasöründe bulunmaktadır.

## Lisans

MIT — bkz. [LICENSE](LICENSE).
