// sh_ShamsiServer (sadece Server)
// Bu modülün TÜM içeriğini bu dosyayla değiştirin. (v7)
//
// İki giriş noktası:
//   AddShamsiLabels(Form)          - Şemsi kodu eklenmiş form modüllerinden (sh_ShamsiInit) çağrılır.
//                                    Bu formlarda sh_ShamsiOnChange prosedürü vardır -> kutu DÜZENLENEBİLİR.
//   AddShamsiLabelsFromHook(Form)  - AttachableCommands hook'undan çağrılır.
//                                    Formda sh_ShamsiOnChange olup olmadığı bilinmez -> kutu SALT OKUNUR.
// Aynı formda ikisi de çalışırsa (önce hook, sonra sh_ShamsiInit) kutular düzenlenebilir hale getirilir.
// Böylece ayrı bir "düzenlenebilir formlar" listesine gerek kalmaz.

Procedure AddShamsiLabels(Form) Export
	BuildShamsiFields(Form, True);
EndProcedure

Procedure AddShamsiLabelsFromHook(Form) Export
	BuildShamsiFields(Form, False);
EndProcedure

Procedure BuildShamsiFields(Form, Editable)

	TopAttrs = New Map;
	For Each Attr In Form.GetAttributes() Do
		If Attr.Name = "sh_ShamsiFields" Then
			// Kutular zaten eklenmiş: gerekiyorsa düzenlenebilir yap, değerleri yenile
			If Editable Then
				MakeShamsiFieldsEditable(Form);
			EndIf;
			sh_ShamsiCalendar.RefreshShamsiLabels(Form);
			Return;
		ElsIf StrFind(Upper(Attr.Name), "SHAMSI") > 0 Then
			Return; // elle Şemsi alanı eklenmiş form
		EndIf;
		TopAttrs.Insert(Attr.Name, True);
	EndDo;

	// Tarih alanlarını bul: Object.<Ad> ve form attribute'u <Ad>
	Fields = New Array;
	Keys = New Map;
	For Each Item In Form.Items Do
		If TypeOf(Item) <> Type("FormField") Then
			Continue;
		EndIf;
		If Item.Type <> FormFieldType.InputField And Item.Type <> FormFieldType.LabelField Then
			Continue;
		EndIf;
		Path = Item.DataPath;
		If Not ValueIsFilled(Path) Then
			Continue;
		EndIf;
		Parts = StrSplit(Path, ".");

		If Parts.Count() = 2 And Parts[0] = "Object" And TopAttrs["Object"] <> Undefined Then
			FieldKey = Parts[1];
			If StrStartsWith(FieldKey, "sh_") Then
				Continue;
			EndIf;
			Values = New Structure(FieldKey);
			FillPropertyValues(Values, Form.Object);
			Value = Values[FieldKey];
		ElsIf Parts.Count() = 1 And TopAttrs[Path] <> Undefined Then
			FieldKey = "F_" + Path;
			Value = Form[Path];
		Else
			Continue;
		EndIf;

		If TypeOf(Value) <> Type("Date") Then
			Continue;
		EndIf;
		If Keys[FieldKey] <> Undefined Then
			Continue;
		EndIf;
		Keys.Insert(FieldKey, Path);
		Fields.Add(New Structure("Item, FieldKey", Item, FieldKey));
	EndDo;

	If Fields.Count() = 0 Then
		Return;
	EndIf;

	// Form attribute'ları (veritabanına yazılmaz)
	NewAttrs = New Array;
	NewAttrs.Add(New FormAttribute("sh_ShamsiFields", New TypeDescription("String")));
	Pairs = New Array;
	For Each KV In Keys Do
		NewAttrs.Add(New FormAttribute("sh_Shamsi_" + KV.Key,
			New TypeDescription("String", , New StringQualifiers(10)), , "Şemsi"));
		Pairs.Add(KV.Key + "=" + KV.Value);
	EndDo;
	Form.ChangeAttributes(NewAttrs);
	Form["sh_ShamsiFields"] = StrConcat(Pairs, ",");

	// Her tarih alanının hemen arkasına Şemsi kutusu
	For Each F In Fields Do
		Field = F.Item;
		NewName = "sh_ShamsiInput_" + F.FieldKey;
		If Form.Items.Find(NewName) <> Undefined Then
			Continue;
		EndIf;

		Parent = Field.Parent;
		NextItem = Undefined;
		Found = False;
		For Each Child In Parent.ChildItems Do
			If Found Then
				NextItem = Child;
				Break;
			EndIf;
			If Child = Field Then
				Found = True;
			EndIf;
		EndDo;

		If NextItem = Undefined Then
			NewItem = Form.Items.Add(NewName, Type("FormField"), Parent);
		Else
			NewItem = Form.Items.Insert(NewName, Type("FormField"), Parent, NextItem);
		EndIf;
		NewItem.Type              = FormFieldType.InputField;
		NewItem.DataPath          = "sh_Shamsi_" + F.FieldKey;
		NewItem.Title             = NStr("en = 'Shamsi'; tr = 'Şemsi'; fa = 'شمسی'; ru = 'Шамси'");
		NewItem.Visible           = Field.Visible;
		NewItem.Width             = 10;
		NewItem.HorizontalStretch = False;
		NewItem.InputHint         = "1405/08/18";
		NewItem.ReadOnly          = True;
	EndDo;

	If Editable Then
		MakeShamsiFieldsEditable(Form);
	EndIf;

	sh_ShamsiCalendar.RefreshShamsiLabels(Form);

EndProcedure

// Şemsi kutularını düzenlenebilir yapar (orijinal tarih alanı salt okunur değilse)
Procedure MakeShamsiFieldsEditable(Form)

	FieldMap = sh_ShamsiCalendar.ShamsiFieldMap(Form);
	For Each KV In FieldMap Do
		ShItem = Form.Items.Find("sh_ShamsiInput_" + KV.Key);
		If ShItem = Undefined Then
			Continue;
		EndIf;

		// Orijinal tarih alanını bul
		SourceReadOnly = False;
		For Each Item In Form.Items Do
			If TypeOf(Item) = Type("FormField") And Item.DataPath = KV.Value Then
				SourceReadOnly = Item.ReadOnly Or Item.Type = FormFieldType.LabelField;
				Break;
			EndIf;
		EndDo;

		If Not SourceReadOnly And ShItem.ReadOnly Then
			ShItem.ReadOnly = False;
			ShItem.SetAction("OnChange", "sh_ShamsiOnChange");
			// Alanın içinde takvim butonu: form modülündeki sh_ShamsiStartChoice takvimi açar,
			// seçilen değer alana yazılır ve OnChange (sh_ShamsiOnChange) çalışır.
			ShItem.ChoiceButton = True;
			ShItem.SetAction("StartChoice", "sh_ShamsiStartChoice");
			Try
				ShItem.ChoiceButtonPicture = PictureLib.Calendar;
			Except
			EndTry;
		EndIf;
	EndDo;

EndProcedure
