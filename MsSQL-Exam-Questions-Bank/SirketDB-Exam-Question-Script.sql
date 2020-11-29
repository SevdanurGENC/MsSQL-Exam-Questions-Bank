-- 1 - personel tablosunda ad ve soyad alanlarini fonksiyon kullanarak birlestirin ve tek bir sutunda yazdirin ayni zaman da yeni sutunun adi Personel Ad Soyad olarak belirleyin
select  CONCAT(ad, ' ', soyad) as 'Personel Adi ve Soyadi' 
from personel

-- 2 - proje tablosunda bulunan proje isimlerini kucuk harfle yazdiriniz
select lower(proje_ad) 
from proje

-- 3 - personel tablosunda bulunan benzersiz maas'lari isim ve soy isimleriyle birlikte listeleyiniz
select distinct maas from personel

-- 4 - Tum tablolarini birbirine baglayan full Join sorgusunu tasarlayiniz.

select p.ad, p.soyad,  p.dogum_tarihi, p.dogum_yeri,
	u.unvan_ad, b.birim_ad, pr.proje_ad, 
	c.ad, c.soyad, c.dogum_tarihi, c.dogu_yeri
from personel p
full join cocuk c
on p.personel_no = c.personel_no
full join ilce ic
on ic.ilce_no = c.dogu_yeri
full join il i
on i.il_no = p.dogum_yeri
full join unvan u
on u.unvan_no = p.unvan_no
full join gorevlendirme g
on g.personel_no = p.personel_no
full join birim b
on b.birim_no = p.birim_no
full join proje pr
on pr.proje_no = g.proje_no


-- 5 - sirkette 2002 yilininin mayis ayinda calismaya baslayanlari listelettiriniz.
Select * from personel where year(baslama_tarihi) = 2002 and month(baslama_tarihi) = 5;

-- 6 - personel tablosunda bulunan kisilerin 2000 ve 3000 arasindaki maaslari sorgulayan bir ic sorgudan gelen sonuclara gore kisilerin birlestirilmis isim ve soyisimlerini maaslariyla birlikte gosteriniz.
SELECT CONCAT(ad, ' ', soyad) as 'Personel Adi ve Soyadi', maas
FROM personel 
WHERE personel_no IN 
(SELECT personel_no FROM personel 
WHERE maas BETWEEN 2000 AND 3000);


-- 7 - personellerin hangi birimlerde toplam kacar kisinin calistigini gosteren sql cumlesini yaziniz.
SELECT birim_no, count(personel_no) KacKisiCalisiyor 
FROM personel 
GROUP BY birim_no 
ORDER BY KacKisiCalisiyor DESC;


-- 8 - idari birimde calisan personellerin isim ve soyisimlerini yapmis olduklari projeleri ile birlikte join kullanarak listelettiriniz.

SELECT W.ad, W.soyad, T.birim_ad, p.proje_ad
FROM personel W
INNER JOIN birim T ON W.birim_no = T.birim_no
inner join gorevlendirme g on w.personel_no = g.personel_no
inner join proje p on g.proje_no = p.proje_no
AND T.birim_ad = 'idari';

-- 9 - 1'den fazla cocugu olan kisilerin isimleriyle birlikte cocuk sayilarini listelettiriniz

SELECT p.ad, p.soyad, count(*) As KacCocuguVar 
FROM personel p
INNER JOIN cocuk c ON c.personel_no = p.personel_no  
GROUP BY p.ad, p.soyad
HAVING COUNT(*) > 1;

-- 10 - personel tablosundaki en yuksek maasa sahip olmayan kisilerden en yuksek maasa sahip olanlari listeleyiniz.

Select max(maas) from personel 
where maas not in (Select max(maas) from personel);

-- 11 - var olan personel numarasi siralamasinda yaridan asagisini (1'den n'3 kadar) listeleyiniz.

SELECT *
FROM personel
WHERE personel_no <= (SELECT count(personel_no)/2 from personel);

-- 12 : 5 calisanindan az olan birimin ismini ve calisan sayisini yazdiriniz
 
SELECT t.birim_ad, COUNT(w.personel_no) as 'Toplam Calısan Sayısı' 
FROM personel W
INNER JOIN birim T ON W.birim_no = T.birim_no
GROUP BY t.birim_ad 
HAVING COUNT(w.personel_no) < 5;

-- 13 : hangi il ve ilcelerde dogan calisanlarin toplam sayilari 3'den buyuk olacak kisileri listeleyiniz.

SELECT i.ilce_ad, i1.il_ad, COUNT(p.personel_no) as 'Toplam Calısan Sayısı' 
FROM personel p 
inner join ilce i on p.dogum_yeri = i.ilce_no 
INNER JOIN il i1 ON i.il_no = i1.il_no
GROUP BY i.ilce_ad, i1.il_ad
HAVING COUNT(p.personel_no) > 3

-- 14 : baslangic tarihininden su anki tarihe kadar toplam calistigi sene 20 yilin altindaysa deneyimsiz, uzerindeyse deneyimli 
-- olacak sekilde ekrana cikti gonderen bir fonksiyon yaziniz.

create FUNCTION SenelikMaasHesaplama(@personel_no int)
RETURNS varchar(max)
AS 
    BEGIN
        Declare @kacYil int       
		declare @mesajVar varchar(max) 
		Set @kacYil = (select convert(int,(SELECT (YEAR(CURRENT_TIMESTAMP)-YEAR(baslama_tarihi)) 
											FROM personel 
											where personel_no = @personel_no)))
  		if (@kacYil < 20)
			set @mesajVar = 'Deneyimsiz'
		if (@kacYil >= 20)
			set @mesajVar = 'Deneyimli'   

		return @mesajVar
    END
	 
select dbo.SenelikMaasHesaplama(20)
 
-- 15 : calisma saati 35 in altinda olan kisilerin maaslarina primleri normal bir sekilde eklenirken, 
-- 35'in uzerinde calisma saati olan kisilerin maaslarine primlerine yuzde 50 daha ek prim verilmektedir.  (function kullanin)
 
alter FUNCTION AylikPrimHesaplama(@personel_no int)
RETURNS varchar(30)
AS 
    BEGIN
        Declare @calismaSaati int
		declare @maas int
		declare @prim int
		declare @ekprim int       
		declare @toplamAylikAlacagi int 
		declare @mesajVer varchar(15)
		Set @calismaSaati = (select convert(int,(SELECT calisma_saati from personel where personel_no = @personel_no)))
		set @maas = (select convert(int,(SELECT maas from personel where personel_no = @personel_no)))
		set @prim = (select convert(int,(SELECT prim from personel where personel_no = @personel_no)))
		set @ekprim = @prim*0.50
  		
		if (@calismaSaati < 35)
		begin
			set @toplamAylikAlacagi = @maas + @prim
			set @mesajVer = 'zamsiz maas : '
		end
		if (@calismaSaati >= 35)
		begin
			set @toplamAylikAlacagi =  @maas + @prim + @ekprim
			set @mesajVer = 'zamli maas : '
		end

		return @mesajVer + (select convert(varchar,@toplamAylikAlacagi))
    END 
 
select dbo.AylikPrimHesaplama(15)


-- 16 : 2'den az cocuga sahip, cocuklarindan en buyugu 5 yasindan kucuk olan ve calisma saati 35 in altinda olan kisilerin 
-- maaslarina primleri normal bir sekilde eklenirken, 
-- 2'den cok cocuga sahip, cocuklarindan en buyugu 5 yasindan buyuk olan ve 35'in uzerinde calisma saati olan 
-- kisilerin maaslarine primlerine yuzde 50 daha ek prim verilmektedir.  (function kullanin)
--   6-2\17-3\19=1
 use sirketDB
create FUNCTION CocukluAylikPrimHesaplama(@personel_no int)
RETURNS varchar(30)
AS 
    BEGIN
        Declare @calismaSaati int
		declare @maas int
		declare @prim int
		declare @ekprim int       
		declare @toplamAylikAlacagi int 
		declare @mesajVer varchar(15)
		declare @cocuksayisi int
		declare @cocukYasi int

		Set @calismaSaati = (select convert(int,(SELECT calisma_saati from personel where personel_no = @personel_no)))
		set @maas = (select convert(int,(SELECT maas from personel where personel_no = @personel_no)))
		set @prim = (select convert(int,(SELECT prim from personel where personel_no = @personel_no)))
		set @cocukSayisi = (select count(*) from personel, cocuk where personel.personel_no = cocuk.personel_no
							and personel.personel_no = @personel_no)
		set @cocukYasi = (select Max(YEAR(CURRENT_TIMESTAMP)-YEAR(cocuk.dogum_tarihi)) as yas from personel, cocuk 
							where personel.personel_no = cocuk.personel_no
							and personel.personel_no = @personel_no)
		set @ekprim = @prim*0.50
  		
		if ((@calismaSaati < 35) and (@cocukYasi<5) and (@cocuksayisi <2 )
)		begin
			set @toplamAylikAlacagi = @maas + @prim
			set @mesajVer = 'zamsiz maas : '
		end
		if ((@calismaSaati >= 35) and (@cocukYasi >=5) and (@cocuksayisi >=2))
		begin
			set @toplamAylikAlacagi =  @maas + @prim + @ekprim
			set @mesajVer = 'zamli maas : '
		end

		return @mesajVer + (select convert(varchar,@toplamAylikAlacagi))
    END 
 
select dbo.CocukluAylikPrimHesaplama(19)

-- 17 - istenen personele ait proje hakkinda bilgileri gosterebilecek (Table cagiran function sorusudur.)
 
create FUNCTION PersonelHangiProjelerdeBulunuyor(@personel_no int)
RETURNS TABLE
AS  
return
		 select p.ad, p.soyad, u.unvan_ad, pr.proje_ad, pr.baslama_tarihi,
			 pr.planlanan_bitis_tarihi, b.birim_ad
		 from personel p, proje pr, gorevlendirme g, birim b, unvan u
		 where p.unvan_no = u.unvan_no 
			 and p.personel_no = g.personel_no
			 and p.birim_no = b.birim_no
			 and pr.proje_no = g.proje_no
			 and p.personel_no = @personel_no
 
select * from PersonelHangiProjelerdeBulunuyor(10)

 -- 18 - gunumuzde halen devam etmekte olan proje var midir varsa proje nosuyla birlikte kac yildir devam ettigiyle ilgili bilgileri listeleyiniz ?

create FUNCTION GunumuzdeDevamEdenProjeler()
RETURNS table
AS 
return   
	SELECT proje_no as 'Devam Eden Projeler',planlanan_bitis_tarihi, 
		(YEAR(CURRENT_TIMESTAMP)-YEAR(baslama_tarihi)) as KacYildirSuruyor
	from proje
	where YEAR(planlanan_bitis_tarihi ) >= 2020

select * from GunumuzdeDevamEdenProjeler()

	
-- 19 - 2000 yili ve sonrasinda hangi projelerin bitecegine ait
-- tum bilgileri getiren ic ice select sorgusu 
 
select personel.personel_no, personel.ad, personel.soyad, unvan.unvan_ad
from personel, unvan
where personel.unvan_no = unvan.unvan_no
and personel.personel_no in (select distinct personel.personel_no
								from personel, gorevlendirme
								where gorevlendirme.proje_no in (SELECT proje_no 
													from proje
													where YEAR(planlanan_bitis_tarihi) >= 2020)
								and gorevlendirme.personel_no = personel.personel_no)


-- 20 - INSERT INTO ILE YENI BIR TABLO OLUSTURUNUz

select p.ad, p.soyad, u.unvan_ad, pr.proje_ad, pr.baslama_tarihi,
			 pr.planlanan_bitis_tarihi, b.birim_ad
INTO personelProjeListesi
from personel p, proje pr, gorevlendirme g, birim b, unvan u
where p.unvan_no = u.unvan_no 
and p.personel_no = g.personel_no
and p.birim_no = b.birim_no
and pr.proje_no = g.proje_no

select * from personelProjeListesi