// sh_ShamsiSync - Add-ShamsiAttributes.ps1 tarafından üretildi.
// Tarih alanlarının yanındaki "sh_<Ad>" String(10) alanlarını Şemsi tarihle doldurur.

#Region Subscriptions

Procedure DocumentBeforeWrite(Source, Cancel, WriteMode, PostingMode) Export
	FillShamsiAttributes(Source);
EndProcedure

Procedure ObjectBeforeWrite(Source, Cancel) Export
	FillShamsiAttributes(Source);
EndProcedure

#EndRegion

#Region Public

// Nesnedeki tüm sh_ alanlarını ilgili tarih alanından hesaplar (başlık + tablo bölümleri)
Procedure FillShamsiAttributes(Source) Export

	MD = Source.Metadata();

	For Each Attr In MD.Attributes Do
		If Not StrStartsWith(Attr.Name, "sh_") Then
			Continue;
		EndIf;
		Try
			Source[Attr.Name] = ToShamsi(Source[Mid(Attr.Name, 4)]);
		Except
			// ör. katalog grubunda kullanılmayan alan
		EndTry;
	EndDo;

	For Each TS In MD.TabularSections Do
		Names = New Array;
		For Each Attr In TS.Attributes Do
			If StrStartsWith(Attr.Name, "sh_") Then
				Names.Add(Attr.Name);
			EndIf;
		EndDo;
		If Names.Count() = 0 Then
			Continue;
		EndIf;
		Try
			Rows = Source[TS.Name];
		Except
			Continue;
		EndTry;
		For Each Row In Rows Do
			For Each Name In Names Do
				Try
					Row[Name] = ToShamsi(Row[Mid(Name, 4)]);
				Except
				EndTry;
			EndDo;
		EndDo;
	EndDo;

EndProcedure

// Mevcut kayıtları bir kez doldurur (zamanlanmış görev "sh_ShamsiFillExisting" ile elle çalıştırılır)
Procedure FillAllExisting() Export

	Groups = New Array;
	Groups.Add(Metadata.Documents);
	Groups.Add(Metadata.Catalogs);
	Groups.Add(Metadata.BusinessProcesses);
	Groups.Add(Metadata.Tasks);
	Groups.Add(Metadata.ChartsOfCharacteristicTypes);
	Groups.Add(Metadata.ChartsOfAccounts);
	Groups.Add(Metadata.ExchangePlans);

	Total = 0;
	Errors = 0;
	For Each Group In Groups Do
		For Each MD In Group Do
			If Not HasShamsiAttributes(MD) Then
				Continue;
			EndIf;
			Query = New Query("SELECT T.Ref AS Ref FROM " + MD.FullName() + " AS T");
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				Try
					Obj = Selection.Ref.GetObject();
					If Obj = Undefined Then
						Continue;
					EndIf;
					Obj.DataExchange.Load = True;
					FillShamsiAttributes(Obj);
					Obj.Write();
					Total = Total + 1;
				Except
					Errors = Errors + 1;
					WriteLogEvent("ShamsiDate.Fill", EventLogLevel.Warning, MD, Selection.Ref,
						DetailErrorDescription(ErrorInfo()));
				EndTry;
			EndDo;
		EndDo;
	EndDo;

	WriteLogEvent("ShamsiDate.Fill", EventLogLevel.Information, , ,
		StrTemplate("Şemsi alanları dolduruldu: %1 kayıt, %2 hata", Total, Errors));

EndProcedure

Function HasShamsiAttributes(MD) Export
	For Each Attr In MD.Attributes Do
		If StrStartsWith(Attr.Name, "sh_") Then
			Return True;
		EndIf;
	EndDo;
	For Each TS In MD.TabularSections Do
		For Each Attr In TS.Attributes Do
			If StrStartsWith(Attr.Name, "sh_") Then
				Return True;
			EndIf;
		EndDo;
	EndDo;
	Return False;
EndFunction

// Miladi tarih -> "1405/08/18"
Function ToShamsi(GDate) Export

	If TypeOf(GDate) <> Type("Date") Or Not ValueIsFilled(GDate) Or Year(GDate) < 1000 Then
		Return "";
	EndIf;

	gy = Year(GDate); gm = Month(GDate); gd = Day(GDate);
	DaysBeforeMonth = StrSplit("0,31,59,90,120,151,181,212,243,273,304,334", ",");

	gy2  = ?(gm > 2, gy + 1, gy);
	Days = 355666 + 365 * gy + Int((gy2 + 3) / 4) - Int((gy2 + 99) / 100)
	     + Int((gy2 + 399) / 400) + gd + Number(DaysBeforeMonth[gm - 1]);

	jy   = -1595 + 33 * Int(Days / 12053);
	Days = Days % 12053;
	jy   = jy + 4 * Int(Days / 1461);
	Days = Days % 1461;
	If Days > 365 Then
		jy   = jy + Int((Days - 1) / 365);
		Days = (Days - 1) % 365;
	EndIf;
	If Days < 186 Then
		jm = 1 + Int(Days / 31);
		jd = 1 + Days % 31;
	Else
		jm = 7 + Int((Days - 186) / 30);
		jd = 1 + (Days - 186) % 30;
	EndIf;

	Return Format(jy, "NG=") + "/" + Format(jm, "ND=2; NLZ=") + "/" + Format(jd, "ND=2; NLZ=");

EndFunction

#EndRegion