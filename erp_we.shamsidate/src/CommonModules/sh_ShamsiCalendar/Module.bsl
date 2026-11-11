// sh_ShamsiCalendar (Client (managed application) + Server)
// Bu modülün TÜM içeriğini bu dosyayla değiştirin. (v6)

Function GregorianToShamsi(GDate) Export

	If TypeOf(GDate) <> Type("Date") Or Not ValueIsFilled(GDate) Or Year(GDate) < 1000 Then
		Return "";
	EndIf;

	gy = Year(GDate); gm = Month(GDate); gd = Day(GDate);

	DaysBeforeMonth = New Array;
	For Each D In StrSplit("0,31,59,90,120,151,181,212,243,273,304,334", ",") Do
		DaysBeforeMonth.Add(Number(D));
	EndDo;

	gy2  = ?(gm > 2, gy + 1, gy);
	Days = 355666 + 365 * gy + Int((gy2 + 3) / 4) - Int((gy2 + 99) / 100)
	     + Int((gy2 + 399) / 400) + gd + DaysBeforeMonth[gm - 1];

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

// Returns Date (start of day) or Undefined if the input is invalid
Function ShamsiToGregorian(ShamsiString) Export

	Str   = StrReplace(StrReplace(TrimAll(ShamsiString), ".", "/"), "-", "/");
	Parts = StrSplit(Str, "/", False);
	If Parts.Count() <> 3 Then
		Return Undefined;
	EndIf;

	Try
		jy = Number(Parts[0]); jm = Number(Parts[1]); jd = Number(Parts[2]);
	Except
		Return Undefined;
	EndTry;

	If jy < 1 Or jm < 1 Or jm > 12 Or jd < 1 Or jd > ?(jm <= 6, 31, 30) Then
		Return Undefined;
	EndIf;

	jy   = jy + 1595;
	Days = -355668 + 365 * jy + Int(jy / 33) * 8 + Int((jy % 33 + 3) / 4) + jd
	     + ?(jm < 7, (jm - 1) * 31, (jm - 7) * 30 + 186);

	gy   = 400 * Int(Days / 146097);
	Days = Days % 146097;
	If Days > 36524 Then
		Days = Days - 1;
		gy   = gy + 100 * Int(Days / 36524);
		Days = Days % 36524;
		If Days >= 365 Then
			Days = Days + 1;
		EndIf;
	EndIf;

	gy   = gy + 4 * Int(Days / 1461);
	Days = Days % 1461;
	If Days > 365 Then
		gy   = gy + Int((Days - 1) / 365);
		Days = (Days - 1) % 365;
	EndIf;

	Result = Date(gy, 1, 1) + Days * 86400;

	// Round-trip check (catches e.g. Esfand 30 in non-leap years)
	Normalized = Format(jy - 1595, "NG=") + "/" + Format(jm, "ND=2; NLZ=") + "/" + Format(jd, "ND=2; NLZ=");
	If GregorianToShamsi(Result) <> Normalized Then
		Return Undefined;
	EndIf;

	Return Result;

EndFunction

// sh_ShamsiFields: "Anahtar=Yol,Anahtar=Yol"  ör. "Date=Object.Date,F_Date=Date"
// Eski biçim ("Date,PeriodEnding") de desteklenir.
Function ShamsiFieldMap(Form) Export
	Result = New Map;
	Try
		Text = Form["sh_ShamsiFields"];
	Except
		Return Result;
	EndTry;
	If Not ValueIsFilled(Text) Then
		Return Result;
	EndIf;
	For Each Pair In StrSplit(Text, ",", False) Do
		Parts = StrSplit(Pair, "=");
		If Parts.Count() = 2 Then
			Result.Insert(Parts[0], Parts[1]);
		Else
			Result.Insert(Pair, "Object." + Pair);
		EndIf;
	EndDo;
	Return Result;
EndFunction

Function GetDateByPath(Form, Path) Export
	If StrStartsWith(Path, "Object.") Then
		Name = Mid(Path, 8);
		Values = New Structure(Name);
		FillPropertyValues(Values, Form.Object);
		Return Values[Name];
	EndIf;
	Return Form[Path];
EndFunction

Procedure SetDateByPath(Form, Path, Value) Export
	If StrStartsWith(Path, "Object.") Then
		Name = Mid(Path, 8);
		Values = New Structure(Name, Value);
		FillPropertyValues(Form.Object, Values);
	Else
		Form[Path] = Value;
	EndIf;
EndProcedure

// Formdaki tüm Şemsi kutularını miladi tarihlerden yeniden hesaplar
Procedure RefreshShamsiLabels(Form) Export
	For Each KV In ShamsiFieldMap(Form) Do
		Try
			CurrentValue = GetDateByPath(Form, KV.Value);
			Form["sh_Shamsi_" + KV.Key] = GregorianToShamsi(CurrentValue);
			// Takvim penceresi mevcut tarihin ayıyla açılsın
			ShItem = Form.Items.Find("sh_ShamsiInput_" + KV.Key);
			If ShItem <> Undefined And TypeOf(CurrentValue) = Type("Date") Then
				ChoiceParams = New Array;
				ChoiceParams.Add(New ChoiceParameter("Date", CurrentValue));
				ShItem.ChoiceParameters = New FixedArray(ChoiceParams);
			EndIf;
		Except
		EndTry;
	EndDo;
EndProcedure

// Kullanıcı Şemsi kutuya yazınca miladi tarihi günceller. Tarih değiştiyse True.
Function ShamsiFieldOnChange(Form, Item) Export
	FieldKey = Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1);
	Path = ShamsiFieldMap(Form).Get(FieldKey);
	If Path = Undefined Then
		Return False;
	EndIf;

	Text = TrimAll(Form["sh_Shamsi_" + FieldKey]);
	OldDate = GetDateByPath(Form, Path);

	If Text = "" Then
		RefreshShamsiLabels(Form);
		Return False;
	EndIf;

	NewDate = ShamsiToGregorian(Text);
	If NewDate = Undefined Then
		Message("Geçersiz Şemsi tarih: " + Text + "  (örnek: 1405/08/18)");
		RefreshShamsiLabels(Form);
		Return False;
	EndIf;

	// Saat kısmını koru
	If TypeOf(OldDate) = Type("Date") And ValueIsFilled(OldDate) Then
		NewDate = NewDate + (OldDate - BegOfDay(OldDate));
	EndIf;

	SetDateByPath(Form, Path, NewDate);
	Form.Modified = True;
	RefreshShamsiLabels(Form);
	Return True;
EndFunction
