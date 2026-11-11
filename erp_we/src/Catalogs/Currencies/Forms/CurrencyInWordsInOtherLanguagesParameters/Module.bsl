///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	LanguagesSet = New ValueTable;
	LanguagesSet.Columns.Add("LanguageCode", Common.StringTypeDetails(10));
	LanguagesSet.Columns.Add("Presentation", Common.StringTypeDetails(150));

	AvailableLanguages = New Array;
	For Each Language In Metadata.Languages Do
		AvailableLanguages.Add(Language.LanguageCode);
	EndDo;

	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport.Print") Then
		PrintManagementModuleNationalLanguageSupport = Common.CommonModule("PrintManagementNationalLanguageSupport");
		AvailableLanguages = PrintManagementModuleNationalLanguageSupport.AvailableLanguages();
	EndIf;

	For Each LanguageCode In AvailableLanguages Do
		NewLanguage = LanguagesSet.Add();
		NewLanguage.LanguageCode = LanguageCode;
		NewLanguage.Presentation = CurrencyRateOperationsInternal.LanguagePresentation(LanguageCode);
	EndDo;

	AvailableScriptInputLanguages = AvailableScriptInputLanguages();

	For Each ConfigurationLanguage In LanguagesSet Do
		If AvailableScriptInputLanguages.Find(ConfigurationLanguage.LanguageCode) <> Undefined Then
			Continue;
		EndIf;
		NewRow = Languages.Add();
		FillPropertyValues(NewRow, ConfigurationLanguage);
		NewRow.Name = "Language_" + ConfigurationLanguage.LanguageCode;
	EndDo;

	GenerateInputFieldsInDifferentLanguages(False, Parameters.ReadOnly);

	DefaultLanguage = Common.DefaultLanguageCode();
	LanguageDetails = LanguageDetails(DefaultLanguage);
	
	If LanguageDetails <> Undefined Then
		ThisObject[LanguageDetails.Name] = Parameters.CurrentValue;
	EndIf;

	For Each Presentation In Parameters.Presentations Do

		LanguageDetails = LanguageDetails(Presentation.LanguageCode);
		If LanguageDetails <> Undefined Then
			If StrCompare(LanguageDetails.LanguageCode, DefaultLanguage) = 0 Then
				ThisObject[LanguageDetails.Name] = ?(ValueIsFilled(Parameters.CurrentValue),
					Parameters.CurrentValue, Presentation[Parameters.AttributeName]);
			Else
				ThisObject[LanguageDetails.Name] = Presentation[Parameters.AttributeName];
			EndIf;
		EndIf;

	EndDo;

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	AmountInDigits = 123.45;
	SetAmountInWords();

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)

	SetAmountInWords();

EndProcedure

&AtClient
Procedure AmountInDigitsOnChange(Item)

	SetAmountInWords();

EndProcedure

&AtClient
Procedure Attachable_InputFieldOnChange(Item)

	Modified = True;
	SetAmountInWords();
	NotifyOwner();

EndProcedure

&AtClient
Procedure Attachable_InputFieldEditTextChange(Item, Text, StandardProcessing)

	Modified = True;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)

	NotifyOwner(True, True);

EndProcedure

&AtClient
Procedure Write(Command)

	NotifyOwner(True);
	Modified = FormOwner.Modified;

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateInputFieldsInDifferentLanguages(MultiLine, Var_ReadOnly)

	Add = New Array;
	StringType = New TypeDescription("String");
	For Each ConfigurationLanguage In Languages Do
		Add.Add(New FormAttribute(ConfigurationLanguage.Name, StringType, ,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tham số chữ ký đối với ngôn ngữ %1';
																			|ru = 'Параметры прописи для языка %1';
																			|en = 'Parameters for spelling out numbers in %1'; fa = 'Parameters for spelling out numbers in %1';
																			|it = 'Параметры прописи для языка %1';
																			|pl = 'Parameters for spelling out numbers in %1';
																			|tr = '%1 dili için yazılış parametreleri'"),
			ConfigurationLanguage.Presentation)));
		Add.Add(New FormAttribute("InputHint" + ConfigurationLanguage.Name, StringType, ,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Chỉ dẫn nhập đối với ngôn ngữ %1';
																			|ru = 'Подсказка ввода для языка %1';
																			|en = 'Input tooltip for the %1 language'; fa = 'Input tooltip for the %1 language';
																			|it = 'Suggerimento dli inserimento per la lingua %1';
																			|pl = 'Podpowiedź wprowadzenia dla języka %1';
																			|tr = 'Dil girişi ipucu %1'"),
			ConfigurationLanguage.Presentation)));
	EndDo;

	ChangeAttributes(Add);
	ItemsParent = Items.Pages;

	For Each ConfigurationLanguage In Languages Do

		If StrCompare(ConfigurationLanguage.LanguageCode, CurrentLanguage().LanguageCode) = 0
			And ItemsParent.ChildItems.Count() > 0 Then
			Page = Items.Insert("Page" + ConfigurationLanguage.Name, Type("FormGroup"), ItemsParent,
				ItemsParent.ChildItems.Get(0));
		Else
			Page = Items.Add("Page" + ConfigurationLanguage.Name, Type("FormGroup"), ItemsParent);
		EndIf;

		ConfigurationLanguage.Page = Page.Name;

		Page.Type = FormGroupType.Page;
		Page.Title = ConfigurationLanguage.Presentation;

		InputField = Items.Add(ConfigurationLanguage.Name, Type("FormField"), Page);
		InputField.DataPath = ConfigurationLanguage.Name;

		If ValueIsFilled(ConfigurationLanguage.EditForm) Then
			InputField.Type = FormFieldType.LabelField;
			InputField.Hyperlink = True;
			InputField.SetAction("Click", "Attachable_Click");
		Else
			InputField.Type                = FormFieldType.InputField;
			InputField.Width             = 40;
			InputField.MultiLine = MultiLine;
			InputField.ReadOnly     = Var_ReadOnly;
			InputField.TitleLocation = FormItemTitleLocation.None;
			InputField.SetAction("OnChange", "Attachable_InputFieldOnChange");
			InputField.SetAction("EditTextChange",
				"Attachable_InputFieldEditTextChange");

			ToolTip = HintForFillingInTheRegistrationParameters(ConfigurationLanguage.LanguageCode);
			InputField.InputHint = ToolTip.InputHint;

			InputHint = Items.Add("InputHint" + ConfigurationLanguage.Name, Type("FormField"), Page);
			InputHint.DataPath = "InputHint" + ConfigurationLanguage.Name;
			InputHint.Type = FormFieldType.InputField;
			InputHint.ReadOnly = True;
			InputHint.TextColor = StyleColors.NoteText;
			InputHint.VerticalStretch = True;
			InputHint.AutoMaxHeight = False;
			InputHint.MultiLine = True;
			InputHint.TitleLocation = FormItemTitleLocation.None;
			InputHint.BorderColor = StyleColors.FormBackColor;

			If Not ValueIsFilled(ToolTip.Instruction) Then
				ToolTip.Instruction = NStr("vi = 'Đối với ngôn ngữ này, không cho phép tùy chỉnh viết bằng chữ.';
											|ru = 'Для данного языка настройка прописи не предусмотрена.';
											|en = 'Cannot set up writing amounts in words for this language.'; fa = 'Cannot set up writing amounts in words for this language.';
											|it = 'Non sono previste impostazioni di trascrizione per questa lingua.';
											|pl = 'Dla tego języka ustawienie napisania słownie nie jest przewidziane.';
											|tr = 'Bu dil için yazım ayarı yok.'");
			EndIf;
			
			ThisObject["InputHint" + ConfigurationLanguage.Name] = ToolTip.Instruction;
		EndIf;

	EndDo;

EndProcedure

&AtServer
Function LanguageDetails(LanguageCode)

	Filter = New Structure("LanguageCode", LanguageCode);
	FoundItems1 = Languages.FindRows(Filter);
	If FoundItems1.Count() > 0 Then
		Return FoundItems1[0];
	EndIf;

	Return Undefined;

EndFunction

&AtClient
Procedure SetAmountInWords()

	CurrentLanguage = DescriptionOfTheCurrentLanguage();
	If CurrentLanguage = Undefined Then
		Return;
	EndIf;

	AmountInWordsParameters = ThisObject[CurrentLanguage.Name];
	AmountInWords = NumberInWords(AmountInDigits, "L=" + CurrentLanguage.LanguageCode + ";DP=False", AmountInWordsParameters); // ACC:1357

EndProcedure

&AtClient
Function DescriptionOfTheCurrentLanguage()

	CurrentPage = Items.Pages.CurrentPage;
	If CurrentPage = Undefined Then
		Return Undefined;
	EndIf;

	Return Languages.FindRows(New Structure("Page", CurrentPage.Name))[0];

EndFunction

&AtClient
Procedure NotifyOwner(Write = False, Close = False)

	CurrentLanguage = DescriptionOfTheCurrentLanguage();

	AmountInWordsParameters = New Structure;
	AmountInWordsParameters.Insert("LanguageCode", CurrentLanguage.LanguageCode);
	AmountInWordsParameters.Insert("AmountInWordsParameters", ThisObject[CurrentLanguage.Name]);
	AmountInWordsParameters.Insert("Write", Write);
	AmountInWordsParameters.Insert("Close", Close);

	Notify("CurrencyInWordsParameters", AmountInWordsParameters, FormOwner);

EndProcedure

&AtServer
Function AvailableScriptInputLanguages()

	Return CurrencyRateOperationsInternal.WritingInWordsInputForms().UnloadValues();

EndFunction

&AtServer
Function HintForFillingInTheRegistrationParameters(Val LanguageCode)

	Result = New Structure;
	Result.Insert("Instruction", "");
	Result.Insert("InputHint", "");

	If Not ValueIsFilled(LanguageCode) Then
		Return Result;
	EndIf;

	LanguageCode = StrSplit(LanguageCode, "_", True)[0];

	If LanguageCode = "ru" Or LanguageCode = "be" Then

		//@skip-check module-nstr-camelcase
		Result.Instruction = StringFunctions.FormattedString(NStr(
		"vi = 'Cần liệt kê các tham số viết bằng chữ sau dấu phẩy.
		|
		|
		|
		|
		|
		|
		|
		|
		|
		|
		|';
		|ru = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для русского и белорусского языков (ru_RU, be_BY):
		|
		|рубль, рубля, рублей, м, копейка, копейки, копеек, ж, 2
		|
		|""рубль, рубля, рублей, м"" – предмет исчисления:
		|рубль – единственное число именительный падеж;
		|рубля – единственное число родительный падеж;
		|рублей – множественное число родительный падеж;
		|м – мужской род (ж – женский род, с - средний род);
		|""копейка, копейки, копеек, ж"" – дробная часть, аналогично предмету исчисления (может отсутствовать);
		|""2"" – количество разрядов дробной части (может отсутствовать, по умолчанию равно 2).';
		|en = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Russian and Belarusian (ru_RU, be_BY):
		|
		|рубль, рубля, рублей, м, копейка, копейки, копеек, ж, 2
		|
		|""рубль, рубля, рублей, м"" – the calculation object:
		|рубль – nominative singular
		|рубля – genitive singular
		|рублей – genitive plural
		|м – masculine (ж – feminine, с – neuter)
		|""копейка, копейки, копеек, ж"" – the fractional part similar to the calculation object (may be missing)
		|""2"" – the number of decimal places (may be missing; the default value is 2).'; fa = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Russian and Belarusian (ru_RU, be_BY):
		|
		|рубль, рубля, рублей, м, копейка, копейки, копеек, ж, 2
		|
		|""рубль, рубля, рублей, м"" – the calculation object:
		|рубль – nominative singular
		|рубля – genitive singular
		|рублей – genitive plural
		|м – masculine (ж – feminine, с – neuter)
		|""копейка, копейки, копеек, ж"" – the fractional part similar to the calculation object (may be missing)
		|""2"" – the number of decimal places (may be missing; the default value is 2).';
		|it = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для русского и белорусского языков (ru_RU, be_BY):
		|
		|рубль, рубля, рублей, м, копейка, копейки, копеек, ж, 2
		|
		|""рубль, рубля, рублей, м"" – предмет исчисления:
		|рубль – единственное число именительный падеж;
		|рубля – единственное число родительный падеж;
		|рублей – множественное число родительный падеж;
		|м – мужской род (ж – женский род, с - средний род);
		|""копейка, копейки, копеек, ж"" – дробная часть, аналогично предмету исчисления (может отсутствовать);
		|""2"" – количество разрядов дробной части (может отсутствовать, по умолчанию равно 2).';
		|pl = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Russian and Belarusian (ru_RU, be_BY):
		|
		|рубль, рубля, рублей, м, копейка, копейки, копеек, ж, 2
		|
		|""рубль, рубля, рублей, м"" – the calculation object:
		|рубль – nominative singular
		|рубля – genitive singular
		|рублей – genitive plural
		|м – masculine (ж – feminine, с – neuter)
		|""копейка, копейки, копеек, ж"" – the fractional part similar to the calculation object (may be missing)
		|""2"" – the number of decimal places (may be missing; the default value is 2).';
		|tr = 'Yazım parametrelerini virgülle ayırarak listeleyin.
		|Rusça ve Belarusça dilleri için doldurma örneği (ru_RU, be_BY):
		|
		|рубль, рубля, рублей, м, копейка, копейки, копеек, ж, 2
		|
		|""рубль, рубля, рублей, м"": hesaplama konusu;
		|рубль: tekil yalın hâl;
		|рубля: tekil ismin –in hâli;
		|рублей: çoğul ismin –in hâli;
		|м: eril cins (ж: dişil cins, с: nötr cins);
		|""копейка, копейки, копеек, ж"": hesaplama konusuna benzer kesirli kısım (eksik olabilir);
		|""2"": kesirli kısmın basamak sayısı (eksik olabilir, varsayılan olarak 2''dir).'"));

		Result.InputHint = NStr("vi = 'rúp, rúp, rúp, m, kopeck, kopeck, kopecks, w, 2';
								|ru = 'рубль, рубля, рублей, м, копейка, копейки, копеек, ж, 2';
								|en = 'рубль, рубля, рублей, м, копейка, копейки, копеек, ж, 2'; fa = 'рубль, рубля, рублей, м, копейка, копейки, копеек, ж, 2';
								|it = 'рубль, рубля, рублей, m, копейка, копейки, копеек, f, 2';
								|pl = 'rubel, rubla, rubli, m, kopiejka, kopiejki, kopiejek, ż, 2';
								|tr = 'ruble, ruble, ruble, m, kuruş, kuruş, kuruş, f, 2'");

	ElsIf LanguageCode = "uk" Then

		//@skip-check module-nstr-camelcase
		Result.Instruction = StringFunctions.FormattedString(NStr(
		"vi = 'Cần liệt kê các tham số viết bằng chữ sau dấu phẩy.
		|
		|
		|
		|
		|
		|
		|
		|
		|
		|
		|';
		|ru = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для украинского языка (uk_UA):
		|
		|гривна, гривны, гривен, м, копейка, копейки, копеек, ж, 2
		|
		|""гривна, гривны, гривен, м"" – предмет исчисления:
		|""гривна – единственное число именительный падеж;
		|гривны – единственное число родительный падеж;
		|гривен – множественное число родительный падеж;
		|м – мужской род (ж – женский род, с - средний род);
		|""копейка, копейки, копеек, ж"" – дробная часть, аналогично предмету исчисления (может отсутствовать);
		|""2"" – количество разрядов дробной части (может отсутствовать, по умолчанию равно 2).';
		|en = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Ukrainian (uk_UA):
		|
		|гривна, гривны, гривен, м, копейка, копейки, копеек, ж, 2
		|
		|""гривна, гривны, гривен, м"" – the calculation object:
		|""гривна – nominative singular
		|гривны – genitive singular
		|гривен – genitive plural
		|м – masculine (ж – feminine, с – neuter)
		|""копейка, копейки, копеек, ж"" – the fractional part similar to the calculation object (may be missing)
		|""2"" – the number of decimal places (may be missing; the default value is 2).'; fa = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Ukrainian (uk_UA):
		|
		|гривна, гривны, гривен, м, копейка, копейки, копеек, ж, 2
		|
		|""гривна, гривны, гривен, м"" – the calculation object:
		|""гривна – nominative singular
		|гривны – genitive singular
		|гривен – genitive plural
		|м – masculine (ж – feminine, с – neuter)
		|""копейка, копейки, копеек, ж"" – the fractional part similar to the calculation object (may be missing)
		|""2"" – the number of decimal places (may be missing; the default value is 2).';
		|it = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для украинского языка (uk_UA):
		|
		|гривна, гривны, гривен, м, копейка, копейки, копеек, ж, 2
		|
		|""гривна, гривны, гривен, м"" – предмет исчисления:
		|""гривна – единственное число именительный падеж;
		|гривны – единственное число родительный падеж;
		|гривен – множественное число родительный падеж;
		|м – мужской род (ж – женский род, с - средний род);
		|""копейка, копейки, копеек, ж"" – дробная часть, аналогично предмету исчисления (может отсутствовать);
		|""2"" – количество разрядов дробной части (может отсутствовать, по умолчанию равно 2).';
		|pl = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Ukrainian (uk_UA):
		|
		|гривна, гривны, гривен, м, копейка, копейки, копеек, ж, 2
		|
		|""гривна, гривны, гривен, м"" – the calculation object:
		|""гривна – nominative singular
		|гривны – genitive singular
		|гривен – genitive plural
		|м – masculine (ж – feminine, с – neuter)
		|""копейка, копейки, копеек, ж"" – the fractional part similar to the calculation object (may be missing)
		|""2"" – the number of decimal places (may be missing; the default value is 2).';
		|tr = 'Yazım parametrelerini virgülle ayırarak listeleyin.
		|Ukraynaca için doldurma örneği (uk_UA):
		|
		|гривна, гривны, гривен, м, копейка, копейки, копеек, ж, 2
		|
		|""гривна, гривны, гривен, м"": hesaplama konusu;
		|гривна: tekil yalın hâl
		|гривны: tekil ismin –in hâli;
		|гривен: çoğul ismin –in hâli;
		|м: eril cins (ж: dişil cins, с: nötr cins);
		|""копейка, копейки, копеек, ж"": hesaplama konusuna benzer kesirli kısım (eksik olabilir);
		|""2"": kesirli kısmın basamak sayısı (eksik olabilir, varsayılan olarak 2''dir).'"));

		Result.InputHint = NStr("vi = 'hryvnia, hryvnia, hryvnia, kopeck, kopeck, kopecks, 2';
								|ru = 'гривна, гривны, гривен, м, копейка, копейки, копеек, ж, 2';
								|en = 'гривна, гривны, гривен, м, копейка, копейки, копеек, ж, 2'; fa = 'гривна, гривны, гривен, м, копейка, копейки, копеек, ж, 2';
								|it = 'гривна, гривны, гривен, m, копейка, копейки, копеек, f, 2';
								|pl = 'hrywna, hrywny, hrywien, m, kopiejka, kopiejki, kopiejek, ż, 2';
								|tr = 'grivnası, grivnası, grivnası, m, kopek, kopek, kopek, f, 2'");

	ElsIf LanguageCode = "pl" Then

		//@skip-check module-nstr-camelcase
		Result.Instruction = StringFunctions.FormattedString(NStr(
		"vi = 'Cần liệt kê các tham số viết bằng chữ sau dấu phẩy.
		|
		|
		|
		|
		|
		|
		|
		|
		|
		|
		|';
		|ru = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для польского языка (pl_PL):
		|
		|złoty, złote, złotych, m, grosz, grosze, groszy, m, 2
		|
		|""złoty, złote, złotych, m "" - предмет исчисления (m - мужской род, ż - женский род, ń - средний род, mo – личностный мужской род).
		|złoty - единственное число именительный падеж;
		|złote - единственное число винительный падеж;
		|złotych - множественное число винительный падеж;
		|m - мужской род (ż - женский род, ń - средний род, mo – личностный мужской род);
		|""grosz, grosze, groszy, m "" - дробная часть (может отсутствовать) (аналогично целой части);
		|2 - количество разрядов дробной части (может отсутствовать, по умолчанию равно 2).';
		|en = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Polish (pl_PL):
		|
		|złoty, złote, złotych, m, grosz, grosze, groszy, m, 2
		|
		|""złoty, złote, złotych, m "" - the calculation subject (m - masculine, ż - feminine, ń - neuter, mo – masculine personal).
		|złoty - nominative singular
		|złote - accusative singular
		|złotych - accusative plural
		|m - masculine (ż - feminine, ń - neuter, mo – masculine personal)
		|""grosz, grosze, groszy, m "" - the fractional part (may be missing) (similar to the integral part)
		|2 - the number of decimal places (may be missing; the default value is 2).'; fa = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Polish (pl_PL):
		|
		|złoty, złote, złotych, m, grosz, grosze, groszy, m, 2
		|
		|""złoty, złote, złotych, m "" - the calculation subject (m - masculine, ż - feminine, ń - neuter, mo – masculine personal).
		|złoty - nominative singular
		|złote - accusative singular
		|złotych - accusative plural
		|m - masculine (ż - feminine, ń - neuter, mo – masculine personal)
		|""grosz, grosze, groszy, m "" - the fractional part (may be missing) (similar to the integral part)
		|2 - the number of decimal places (may be missing; the default value is 2).';
		|it = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для польского языка (pl_PL):
		|
		|złoty, złote, złotych, m, grosz, grosze, groszy, m, 2
		|
		|""złoty, złote, złotych, m "" - предмет исчисления (m - мужской род, ż - женский род, ń - средний род, mo – личностный мужской род).
		|złoty - единственное число именительный падеж;
		|złote - единственное число винительный падеж;
		|złotych - множественное число винительный падеж;
		|m - мужской род (ż - женский род, ń - средний род, mo – личностный мужской род);
		|""grosz, grosze, groszy, m "" - дробная часть (может отсутствовать) (аналогично целой части);
		|2 - количество разрядов дробной части (может отсутствовать, по умолчанию равно 2).';
		|pl = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Polish (pl_PL):
		|
		|złoty, złote, złotych, m, grosz, grosze, groszy, m, 2
		|
		|""złoty, złote, złotych, m "" - the calculation subject (m - masculine, ż - feminine, ń - neuter, mo – masculine personal).
		|złoty - nominative singular
		|złote - accusative singular
		|złotych - accusative plural
		|m - masculine (ż - feminine, ń - neuter, mo – masculine personal)
		|""grosz, grosze, groszy, m "" - the fractional part (may be missing) (similar to the integral part)
		|2 - the number of decimal places (may be missing; the default value is 2).';
		|tr = 'Yazım parametrelerini virgülle ayırarak listeleyin.
		|Lehçe için doldurma örneği (pl_PL):
		|
		|złoty, złote, złotych, m, grosz, grosze, groszy, m, 2
		|
		|""złoty, złote, złotych, m"": hesaplama konusu (m: eril cins, ż: dişil cins, ń: nötr cins, mo: kişisel eril cins).
		|złoty: tekil yalın hâl;
		|złote: tekil ismin –in hâli;
		|złotych: çoğul ismin –in hâli;
		|m: eril cins (ż: dişil cins, ń: nötr cins, mo: kişisel eril cins);
		|""grosz, grosze, groszy, m"": kesirli kısım (eksik olabilir) (tam sayı kısmına benzer);
		|2: kesirli kısmın basamak sayısı (eksik olabilir, varsayılan olarak 2''dir).'"));

		Result.InputHint = NStr("vi = 'złoty, złote, złotych, m, grosz, grosze, groszy, m, 2';
								|ru = 'złoty, złote, złotych, m, grosz, grosze, groszy, m, 2';
								|en = 'złoty, złote, złotych, m, grosz, grosze, groszy, m, 2'; fa = 'złoty, złote, złotych, m, grosz, grosze, groszy, m, 2';
								|it = 'złoty, złote, złotych, m, grosz, grosze, groszy, m, 2';
								|pl = 'złoty, złote, złotych, m, grosz, grosze, groszy, m, 2';
								|tr = 'złoty, złote, złotych, m, grosz, grosze, groszy, m, 2'");

	ElsIf LanguageCode = "en" Or LanguageCode = "fr" Or LanguageCode = "fi" Or LanguageCode = "kk" Then

		//@skip-check module-nstr-camelcase
		Result.Instruction = StringFunctions.FormattedString(NStr(
		"vi = 'Cần liệt kê các tham số viết bằng chữ sau dấu phẩy.
		|
		|
		|
		|
		|
		|
		|';
		|ru = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для английского, французского, финского и казахского языков (en_US, fr_CA,fi_FI, kk_KZ):
		|
		|dollar, dollars, cent, cents, 2
		|
		|""dollar, dollars"" – предмет исчисления в единственном и множественном числе;
		|""cent, cents"" – дробная часть в единственном и множественном числе (может отсутствовать);
		|""2"" – количество разрядов дробной части (может отсутствовать, по умолчанию равно 2).';
		|en = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for English, French, Finnish and Kazakh (en_US, fr_CA,fi_FI, kk_KZ):
		|
		|dollar, dollars, cent, cents, 2
		|
		|""dollar, dollars"" – calculation object singular and plural
		|""cent, cents"" - fractional part singular and plural (may be missing)
		|""2"" - the number of decimal places (may be missing; the default value is 2).'; fa = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for English, French, Finnish and Kazakh (en_US, fr_CA,fi_FI, kk_KZ):
		|
		|dollar, dollars, cent, cents, 2
		|
		|""dollar, dollars"" – calculation object singular and plural
		|""cent, cents"" - fractional part singular and plural (may be missing)
		|""2"" - the number of decimal places (may be missing; the default value is 2).';
		|it = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для английского, французского, финского и казахского языков (en_US, fr_CA,fi_FI, kk_KZ):
		|
		|dollar, dollars, cent, cents, 2
		|
		|""dollar, dollars"" – предмет исчисления в единственном и множественном числе;
		|""cent, cents"" – дробная часть в единственном и множественном числе (может отсутствовать);
		|""2"" – количество разрядов дробной части (может отсутствовать, по умолчанию равно 2).';
		|pl = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for English, French, Finnish and Kazakh (en_US, fr_CA,fi_FI, kk_KZ):
		|
		|dollar, dollars, cent, cents, 2
		|
		|""dollar, dollars"" – calculation object singular and plural
		|""cent, cents"" - fractional part singular and plural (may be missing)
		|""2"" - the number of decimal places (may be missing; the default value is 2).';
		|tr = 'Yazım parametrelerini virgülle ayırarak listeleyin.
		|İngilizce, Fransızca, Fince ve Kazakça dilleri için doldurma örneği (en_US, fr_CA,fi_FI, kk_KZ):
		|
		|dollar, dollars, cent, cents, 2
		|
		|""dollar, dollars"": tekil ve çoğul formlarda hesaplama konusu;
		|""cent, cents"": tekil ve çoğulda kesirli kısım (eksik olabilir);
		|""2"": kesirli kısmın basamak sayısı (eksik olabilir, varsayılan olarak 2''dir).'"));

		Result.InputHint = NStr("vi = 'dollar, dollars, cent, cents, 2';
								|ru = 'dollar, dollars, cent, cents, 2';
								|en = 'dollar, dollars, cent, cents, 2'; fa = 'دلار, دلار, سنت, سنت, 2';
								|it = 'dollar, dollars, cent, cents, 2';
								|pl = 'dollar, dollars, cent, cents, 2';
								|tr = 'dollar, dollars, cent, cents, 2'");

	ElsIf LanguageCode = "de" Then

		//@skip-check module-nstr-camelcase
		Result.Instruction = StringFunctions.FormattedString(NStr(
		"vi = 'Cần liệt kê các tham số viết bằng chữ sau dấu phẩy.
		|
		|
		|
		|
		|
		|
		|
		|
		|';
		|ru = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для немецкого языка (de_DE):
		|
		|EURO, EURO, М, Cent, Cent, M, 2
		|
		|""EURO, EURO, М"" – предмет исчисления:
		|EURO, EURO – предмет исчисления в единственном и множественном числе;
		|М – мужской род (F – женский род, N - средний род);
		|""Cent, Cent, M"" – дробная часть, аналогично предмету исчисления (может отсутствовать);
		|""2"" – количество разрядов дробной части (может отсутствовать, по умолчанию равно 2).';
		|en = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for German (de_DE):
		|
		|EURO, EURO, M, Cent, Cent, M, 2
		|
		|""EURO, EURO, M"" – the calculation object:
		|EURO, EURO - calculation object singular and plural
		|M – masculine (F – feminine, N - neuter)
		|""Cent, Cent, M"" – the fractional part similar to the calculation object (may be missing)
		|""2"" – the number of decimal places (may be missing; the default value is 2).'; fa = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for German (de_DE):
		|
		|EURO, EURO, M, Cent, Cent, M, 2
		|
		|""EURO, EURO, M"" – the calculation object:
		|EURO, EURO - calculation object singular and plural
		|M – masculine (F – feminine, N - neuter)
		|""Cent, Cent, M"" – the fractional part similar to the calculation object (may be missing)
		|""2"" – the number of decimal places (may be missing; the default value is 2).';
		|it = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для немецкого языка (de_DE):
		|
		|EURO, EURO, М, Cent, Cent, M, 2
		|
		|""EURO, EURO, М"" – предмет исчисления:
		|EURO, EURO – предмет исчисления в единственном и множественном числе;
		|М – мужской род (F – женский род, N - средний род);
		|""Cent, Cent, M"" – дробная часть, аналогично предмету исчисления (может отсутствовать);
		|""2"" – количество разрядов дробной части (может отсутствовать, по умолчанию равно 2).';
		|pl = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for German (de_DE):
		|
		|EURO, EURO, M, Cent, Cent, M, 2
		|
		|""EURO, EURO, M"" – the calculation object:
		|EURO, EURO - calculation object singular and plural
		|M – masculine (F – feminine, N - neuter)
		|""Cent, Cent, M"" – the fractional part similar to the calculation object (may be missing)
		|""2"" – the number of decimal places (may be missing; the default value is 2).';
		|tr = 'Yazım parametrelerini virgülle ayırarak listeleyin.
		|Almanca için doldurma örneği (de_DE):
		|
		|EURO, EURO, М, Cent, Cent, M, 2
		|
		|""EURO, EURO, М"": hesaplama konusu;
		|EURO, EURO: tekil ve çoğul formlarda hesaplama konusu;
		|М: eril (F – dişil, N - nötr);
		|""Cent, Cent, M"": kesirli kısım, hesaplama konusuna benzer (eksik olabilir);
		|""2"": kesirli kısmın basamak sayısı (eksik olabilir, varsayılan olarak 2''dir).'"));

		Result.InputHint = NStr("vi = 'EURO, EURO, М, Cent, Cent, M, 2';
								|ru = 'EURO, EURO, М, Cent, Cent, M, 2';
								|en = 'EURO, EURO, M, Cent, Cent, M, 2'; fa = 'EURO, EURO, M, Cent, Cent, M, 2';
								|it = 'EURO, EURO, М, Cent, Cent, M, 2';
								|pl = 'EURO, EURO, М, Cent, Cent, M, 2';
								|tr = 'EURO, EURO, М, Cent, Cent, M, 2'");

	ElsIf LanguageCode = "lv" Then

		//@skip-check module-nstr-camelcase
		Result.Instruction = StringFunctions.FormattedString(NStr(
		"vi = 'Cần liệt kê các tham số viết bằng chữ sau dấu phẩy.
		|
		|
		|
		|
		|
		|
		|
		|
		|
		|
		|
		|
		|
		|
		|';
		|ru = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для латышского языка (lv_LV):
		|
		|lats, lati, latu, V, santīms, santīmi, santīmu, V, 2, J, J
		|
		|""lats, lati, latu, v"" – предмет исчисления:
		|lats – для чисел заканчивающихся на 1, кроме 11;
		|lati – для чисел заканчивающихся на 2-9 и 11;
		|latu – множественное число (родительный падеж) используется после числительных 0, 10, 20,..., 90, 100, 200, ..., 1000, ..., 100000;
		|v – мужской род (s – женский род);
		|""santīms, santīmi, santīmu, V"" – дробная часть, аналогично предмету исчисления (может отсутствовать);
		|""2"" – количество разрядов дробной части (может отсутствовать, по умолчанию равно 2);
		|""J"" - число 100 выводится как ""Одна сотня"" для предмета исчисления (N - как ""Сто"");
		|может отсутствовать, по умолчанию равно ""J"";
		|""J"" - число 100 выводится как ""Одна сотня"" для дробной части (N - как ""Сто"");
		|может отсутствовать, по умолчанию равно ""J"".';
		|en = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Latvian (lv_LV):
		|
		|lats, lati, latu, V, santīms, santīmi, santīmu, V, 2, J, J
		|
		|""lats, lati, latu, v"" – the calculation object:
		|lats – for numbers ending with 1, except for 11
		|lati – for numbers ending with 2-9 and 11
		|latu – plural (genitive) used for numerals 0, 10, 20,…, 90, 100, 200, …, 1000, …, 100000
		|v – masculine (s – feminine)
		|""santīms, santīmi, santīmu, V"" – the fractional part similar to the calculation object (may be missing)
		|""2"" – the number of decimal places (may be missing; the default value is 2)
		|""J"" - the number 100 is displayed as ""One hundred"" for the calculation object (N - the number 100 is displayed as ""Hundred"");
		|may be missing; the default value is ""J""
		|""J"" - the number 100 is displayed as ""One hundred"" for the fractional part (N - the number 100 is displayed as ""Hundred"")
		|may be missing; the default value is ""J"".'; fa = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Latvian (lv_LV):
		|
		|lats, lati, latu, V, santīms, santīmi, santīmu, V, 2, J, J
		|
		|""lats, lati, latu, v"" – the calculation object:
		|lats – for numbers ending with 1, except for 11
		|lati – for numbers ending with 2-9 and 11
		|latu – plural (genitive) used for numerals 0, 10, 20,…, 90, 100, 200, …, 1000, …, 100000
		|v – masculine (s – feminine)
		|""santīms, santīmi, santīmu, V"" – the fractional part similar to the calculation object (may be missing)
		|""2"" – the number of decimal places (may be missing; the default value is 2)
		|""J"" - the number 100 is displayed as ""One hundred"" for the calculation object (N - the number 100 is displayed as ""Hundred"");
		|may be missing; the default value is ""J""
		|""J"" - the number 100 is displayed as ""One hundred"" for the fractional part (N - the number 100 is displayed as ""Hundred"")
		|may be missing; the default value is ""J"".';
		|it = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для латышского языка (lv_LV):
		|
		|lats, lati, latu, V, santīms, santīmi, santīmu, V, 2, J, J
		|
		|""lats, lati, latu, v"" – предмет исчисления:
		|lats – для чисел заканчивающихся на 1, кроме 11;
		|lati – для чисел заканчивающихся на 2-9 и 11;
		|latu – множественное число (родительный падеж) используется после числительных 0, 10, 20,..., 90, 100, 200, ..., 1000, ..., 100000;
		|v – мужской род (s – женский род);
		|""santīms, santīmi, santīmu, V"" – дробная часть, аналогично предмету исчисления (может отсутствовать);
		|""2"" – количество разрядов дробной части (может отсутствовать, по умолчанию равно 2);
		|""J"" - число 100 выводится как ""Одна сотня"" для предмета исчисления (N - как ""Сто"");
		|может отсутствовать, по умолчанию равно ""J"";
		|""J"" - число 100 выводится как ""Одна сотня"" для дробной части (N - как ""Сто"");
		|может отсутствовать, по умолчанию равно ""J"".';
		|pl = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Latvian (lv_LV):
		|
		|lats, lati, latu, V, santīms, santīmi, santīmu, V, 2, J, J
		|
		|""lats, lati, latu, v"" – the calculation object:
		|lats – for numbers ending with 1, except for 11
		|lati – for numbers ending with 2-9 and 11
		|latu – plural (genitive) used for numerals 0, 10, 20,…, 90, 100, 200, …, 1000, …, 100000
		|v – masculine (s – feminine)
		|""santīms, santīmi, santīmu, V"" – the fractional part similar to the calculation object (may be missing)
		|""2"" – the number of decimal places (may be missing; the default value is 2)
		|""J"" - the number 100 is displayed as ""One hundred"" for the calculation object (N - the number 100 is displayed as ""Hundred"");
		|may be missing; the default value is ""J""
		|""J"" - the number 100 is displayed as ""One hundred"" for the fractional part (N - the number 100 is displayed as ""Hundred"")
		|may be missing; the default value is ""J"".';
		|tr = 'Yazım parametrelerini virgülle ayırarak listeleyin.
		|Letonca için doldurma örneği (lv_LV):
		|
		|lats, lati, latu, V, santīms, santīmi, santīmu, V, 2, J, J
		|
		|""lats, lati, latu, v"": hesaplama nesnesi;
		|lats: sonu 1 ile biten sayılar için, 11 hariç;
		|lati: 2-9 ve 11 ile biten sayılar için;
		|latu: Çoğul (ismin ismin –in hâli) 0, 10, 20,..., 90, 100, 200, ..., 1000, ..., 100000 rakamlarından sonra kullanılır;
		|v: eril (s dişildir);
		|""santīms, santīmi, santīmu, V"": kesirli kısım, hesaplama konusuna benzer (eksik olabilir);
		|""2"": kesirli kısmın basamak sayısı (eksik olabilir, varsayılan olarak 2''dir);
		|""J"": 100 sayısı, hesaplama konusu için ""Bir yüz"" olarak türetilir (N: ""Yüz"" olarak);
		|eksik olabilir, varsayılan olarak ""J""dir;
		|""J"": 100 sayısı kesirli kısım için ""Bir yüz"" olarak türetilir (N: ""Yüz"" olarak);
		|eksik olabilir, varsayılan olarak ""J""dir.'"));

		Result.InputHint = NStr("vi = 'lats, lati, latu, V, santīms, santīmi, santīmu, V, 2, J, J';
								|ru = 'lats, lati, latu, V, santīms, santīmi, santīmu, V, 2, J, J';
								|en = 'lats, lati, latu, V, santīms, santīmi, santīmu, V, 2, J, J'; fa = 'lats, lati, latu, V, santīms, santīmi, santīmu, V, 2, J, J';
								|it = 'lats, lati, latu, V, santīms, santīmi, santīmu, V, 2, J, J';
								|pl = 'lats, lati, latu, V, santīms, santīmi, santīmu, V, 2, J, J';
								|tr = 'lats, lati, latu, V, santīms, santīmi, santīmu, V, 2, J, J'");

	ElsIf LanguageCode = "lt" Then

		//@skip-check module-nstr-camelcase
		Result.Instruction = StringFunctions.FormattedString(NStr(
		"vi = 'Cần liệt kê các tham số viết bằng chữ sau dấu phẩy.
		|
		|
		|
		|
		|
		|
		|
		|
		|
		|
		|';
		|ru = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для литовского языка (lt_LT):
		|
		|litas, litai, litų, М, centas, centai, centų, М, 2
		|
		|""litas, litai, litų, М"" – предмет исчисления:
		|litas - единственное число целой части;
		|litai - множественное число целой части от 2 до 9;
		|litų - множественное число целой части прочие;
		|m - род целой части (f - женский род),
		|""centas, centai, centų, М"" – дробная часть, аналогично предмету исчисления (может отсутствовать);
		|""2"" - количество разрядов дробной части (может отсутствовать, по умолчанию равно 2).';
		|en = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Lithuanian (lt_LT):
		|
		|litas, litai, litų, M, centas, centai, centų, M, 2
		|
		|""litas, litai, litų, M"" – the calculation object:
		|litas - integral part singular
		|litai - integral part plural (from 2 to 9)
		|litų - integral part plural (other)
		|m - the integral part gender (f - feminine),
		|""centas, centai, centų, M"" – the fractional part similar to the calculation object (may be missing)
		|""2"" - the number of decimal places (may be missing; the default value is 2).'; fa = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Lithuanian (lt_LT):
		|
		|litas, litai, litų, M, centas, centai, centų, M, 2
		|
		|""litas, litai, litų, M"" – the calculation object:
		|litas - integral part singular
		|litai - integral part plural (from 2 to 9)
		|litų - integral part plural (other)
		|m - the integral part gender (f - feminine),
		|""centas, centai, centų, M"" – the fractional part similar to the calculation object (may be missing)
		|""2"" - the number of decimal places (may be missing; the default value is 2).';
		|it = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для литовского языка (lt_LT):
		|
		|litas, litai, litų, М, centas, centai, centų, М, 2
		|
		|""litas, litai, litų, М"" – предмет исчисления:
		|litas - единственное число целой части;
		|litai - множественное число целой части от 2 до 9;
		|litų - множественное число целой части прочие;
		|m - род целой части (f - женский род),
		|""centas, centai, centų, М"" – дробная часть, аналогично предмету исчисления (может отсутствовать);
		|""2"" - количество разрядов дробной части (может отсутствовать, по умолчанию равно 2).';
		|pl = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Lithuanian (lt_LT):
		|
		|litas, litai, litų, M, centas, centai, centų, M, 2
		|
		|""litas, litai, litų, M"" – the calculation object:
		|litas - integral part singular
		|litai - integral part plural (from 2 to 9)
		|litų - integral part plural (other)
		|m - the integral part gender (f - feminine),
		|""centas, centai, centų, M"" – the fractional part similar to the calculation object (may be missing)
		|""2"" - the number of decimal places (may be missing; the default value is 2).';
		|tr = 'Yazım parametrelerini virgülle ayırarak listeleyin.
		|Litvanca için doldurma örneği (lt_LT):
		|
		|litas, litai, litų, М, centas, centai, centų, М, 2
		|
		|""litas, litai, litų, М"": hesaplama konusu;
		|litas: tekil tam sayı;
		|litai: 2''den 9''a kadar tam sayı kısmının çoğul formu;
		|litų: Diğerinin tam sayı kısmının çoğul formu;
		|m: tüm parçanın cinsi (f dişildir),
		|""centas, centai, centų, М"": kesirli kısım, hesaplama konusuna benzer (eksik olabilir);
		|""2"": kesirli kısmın basamak sayısı (eksik olabilir, varsayılan olarak 2''dir).'"));

		Result.InputHint = NStr("vi = 'litas, litai, litų, М, centas, centai, centų, М, 2';
								|ru = 'litas, litai, litų, М, centas, centai, centų, М, 2';
								|en = 'litas, litai, litų, M, centas, centai, centų, M, 2'; fa = 'litas, litai, litų, M, centas, centai, centų, M, 2';
								|it = 'litas, litai, litų, М, centas, centai, centų, М, 2';
								|pl = 'litas, litai, litų, М, centas, centai, centų, М, 2';
								|tr = 'litas, litai, litų, M, centas, centai, centų, M, 2'");

	ElsIf LanguageCode = "et" Then

		//@skip-check module-nstr-camelcase
		Result.Instruction = StringFunctions.FormattedString(NStr(
		"vi = 'Cần liệt kê các tham số viết bằng chữ sau dấu phẩy.
		|
		|
		|
		|
		|
		|
		|';
		|ru = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для эстонского языка (et_EE):
		|
		|kroon, krooni, sent, senti, 2
		|
		|""kroon, krooni"" – – предмет исчисления в единственном и множественном числе;
		|""sent, senti"" – дробная часть в единственном и множественном числе (может отсутствовать);
		|2 – количество разрядов дробной части (может отсутствовать, по умолчанию равно 2).';
		|en = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Estonian (et_EE):
		|
		|kroon, krooni, sent, senti, 2
		|
		|""kroon, krooni"" – calculation object singular and plural
		|""sent, senti"" - fractional part singular and plural (may be missing)
		|2 - the number of decimal places (may be missing; the default value is 2).'; fa = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Estonian (et_EE):
		|
		|kroon, krooni, sent, senti, 2
		|
		|""kroon, krooni"" – calculation object singular and plural
		|""sent, senti"" - fractional part singular and plural (may be missing)
		|2 - the number of decimal places (may be missing; the default value is 2).';
		|it = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для эстонского языка (et_EE):
		|
		|kroon, krooni, sent, senti, 2
		|
		|""kroon, krooni"" – – предмет исчисления в единственном и множественном числе;
		|""sent, senti"" – дробная часть в единственном и множественном числе (может отсутствовать);
		|2 – количество разрядов дробной части (может отсутствовать, по умолчанию равно 2).';
		|pl = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Estonian (et_EE):
		|
		|kroon, krooni, sent, senti, 2
		|
		|""kroon, krooni"" – calculation object singular and plural
		|""sent, senti"" - fractional part singular and plural (may be missing)
		|2 - the number of decimal places (may be missing; the default value is 2).';
		|tr = 'Yazım parametrelerini virgülle ayırarak listeleyin.
		|Estonca için doldurma örneği (et_EE):
		|
		|kroon, krooni, sent, senti, 2
		|
		|""kroon, krooni"": tekil ve çoğul formlarda hesaplama konusu;
		|""sent, senti"": tekil ve çoğul formlarda kesirli kısım (eksik olabilir);
		|2: kesirli kısmın basamak sayısı (eksik olabilir, varsayılan olarak 2''dir).'"));

		Result.InputHint = NStr("vi = 'kroon, krooni, sent, senti, 2';
								|ru = 'kroon, krooni, sent, senti, 2';
								|en = 'kroon, krooni, sent, senti, 2'; fa = 'kroon, krooni, sent, senti, 2';
								|it = 'kroon, krooni, sent, senti, 2';
								|pl = 'kroon, krooni, sent, senti, 2';
								|tr = 'kroon, krooni, sent, senti, 2'");

	ElsIf LanguageCode = "bg" Then

		//@skip-check module-nstr-camelcase
		Result.Instruction = StringFunctions.FormattedString(NStr(
		"vi = 'Cần liệt kê các tham số viết bằng chữ sau dấu phẩy.
		|
		|
		|
		|
		|
		|
		|
		|
		|
		|
		|
		|
		|';
		|ru = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для болгарского языка (bg_BG):
		|
		|лев, лева, м, стотинка, стотинки, ж, 2
		|
		|""лев, лева, м"" – предмет исчисления:
		|лев - единственное число целой части;
		|лева - множественное число целой части;
		|м - род целой части,
		|""стотинка, стотинки, ж"" - дробная часть:
		|стотинка - единственное число дробной части;
		|стотинки - множественное число дробной части;
		|ж - род дробной части,
		|""2"" - количество разрядов дробной части.';
		|en = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Bulgarian (bg_BG):
		|
		|лев, лева, м, стотинка, стотинки, ж, 2
		|
		|""лев, лева, м"" – the calculation object:
		|лев - integral part singular
		|лева - integral part plural
		|м - the integral part gender
		|""стотинка, стотинки, ж"" - the fractional part:
		|стотинка - fractional part singular
		|стотинки - fractional part plural
		|ж - the fractional part gender
		|""2"" - the number of decimal places.'; fa = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Bulgarian (bg_BG):
		|
		|лев, лева, м, стотинка, стотинки, ж, 2
		|
		|""лев, лева, м"" – the calculation object:
		|лев - integral part singular
		|лева - integral part plural
		|м - the integral part gender
		|""стотинка, стотинки, ж"" - the fractional part:
		|стотинка - fractional part singular
		|стотинки - fractional part plural
		|ж - the fractional part gender
		|""2"" - the number of decimal places.';
		|it = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для болгарского языка (bg_BG):
		|
		|лев, лева, м, стотинка, стотинки, ж, 2
		|
		|""лев, лева, м"" – предмет исчисления:
		|лев - единственное число целой части;
		|лева - множественное число целой части;
		|м - род целой части,
		|""стотинка, стотинки, ж"" - дробная часть:
		|стотинка - единственное число дробной части;
		|стотинки - множественное число дробной части;
		|ж - род дробной части,
		|""2"" - количество разрядов дробной части.';
		|pl = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Bulgarian (bg_BG):
		|
		|лев, лева, м, стотинка, стотинки, ж, 2
		|
		|""лев, лева, м"" – the calculation object:
		|лев - integral part singular
		|лева - integral part plural
		|м - the integral part gender
		|""стотинка, стотинки, ж"" - the fractional part:
		|стотинка - fractional part singular
		|стотинки - fractional part plural
		|ж - the fractional part gender
		|""2"" - the number of decimal places.';
		|tr = 'Yazım parametrelerini virgülle ayırarak listeleyin.
		|Bulgarca için doldurma örneği (bg_BG):
		|
		|лев, лева, м, стотинка, стотинки, ж, 2
		|
		|""лев, лева, м"": hesaplama konusu:
		|лев: tekil tam sayı;
		|лева: tam sayı kısmının çoğul formu;
		|м: tam sayı cinsi;
		|""стотинка, стотинки, ж"": kesirli kısım;
		|стотинка: kesirli kısmın tekil formu;
		|стотинки: kesirli kısmın çoğul formu;
		|ж: kesirli kısım cinsi;
		|""2"": kesirli kısmın basamak sayısı.'"));

		Result.InputHint = NStr("vi = 'lev, leva, m, xu, xu, 2';
								|ru = 'лев, лева, м, стотинка, стотинки, ж, 2';
								|en = 'лев, лева, м, стотинка, стотинки, ж, 2'; fa = 'лев, лева, м, стотинка, стотинки, ж, 2';
								|it = 'lev, leva, m, stotinka, stotinki, f, 2';
								|pl = 'лев, лева, м, стотинка, стотинки, ж, 2';
								|tr = 'aslan, lev, m, stotinka, stotinki, f, 2'");

	ElsIf LanguageCode = "ro" Then

		//@skip-check module-nstr-camelcase
		Result.Instruction = StringFunctions.FormattedString(NStr(
		"vi = 'Cần liệt kê các tham số viết bằng chữ sau dấu phẩy.
		|
		|
		|
		|
		|
		|
		|
		|
		|
		|
		|
		|
		|';
		|ru = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для румынского языка (ro_RO):
		|
		|leu, lei, M, ban, bani, W, 2
		|
		|""leu, lei, M"" – предмет исчисления:
		|leu - единственное число целой части;
		|lei - множественное число целой части;
		|M - род целой части;
		|""ban, bani, W"" - дробная часть:
		|ban - единственное число дробной части;
		|bani - множественное число дробной части;
		|W - род дробной части;
		|""2"" - количество разрядов дробной части.';
		|en = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Romanian (ro_RO):
		|
		|leu, lei, M, ban, bani, W, 2
		|
		|""leu, lei, M"" – the calculation object:
		|leu - integral part singular
		|lei - integral part plural
		|M - the integral part gender
		|""ban, bani, W"" - the fractional part:
		|ban - fractional part singular
		|bani - fractional part plural
		|W - the fractional part gender
		|""2"" - the number of decimal places.'; fa = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Romanian (ro_RO):
		|
		|leu, lei, M, ban, bani, W, 2
		|
		|""leu, lei, M"" – the calculation object:
		|leu - integral part singular
		|lei - integral part plural
		|M - the integral part gender
		|""ban, bani, W"" - the fractional part:
		|ban - fractional part singular
		|bani - fractional part plural
		|W - the fractional part gender
		|""2"" - the number of decimal places.';
		|it = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для румынского языка (ro_RO):
		|
		|leu, lei, M, ban, bani, W, 2
		|
		|""leu, lei, M"" – предмет исчисления:
		|leu - единственное число целой части;
		|lei - множественное число целой части;
		|M - род целой части;
		|""ban, bani, W"" - дробная часть:
		|ban - единственное число дробной части;
		|bani - множественное число дробной части;
		|W - род дробной части;
		|""2"" - количество разрядов дробной части.';
		|pl = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Romanian (ro_RO):
		|
		|leu, lei, M, ban, bani, W, 2
		|
		|""leu, lei, M"" – the calculation object:
		|leu - integral part singular
		|lei - integral part plural
		|M - the integral part gender
		|""ban, bani, W"" - the fractional part:
		|ban - fractional part singular
		|bani - fractional part plural
		|W - the fractional part gender
		|""2"" - the number of decimal places.';
		|tr = 'Yazım parametrelerini virgülle ayırarak listeleyin.
		|Rumence için doldurma örneği (ro_RO):
		|
		|leu, lei, M, ban, bani, W, 2
		|
		|""leu, lei, M"": hesaplama konusu;
		|leu: tekil tam sayı;
		|lei: tam sayı kısmının çoğul formu;
		|M: tam sayı cinsi;
		|""ban, bani, W"": kesirli kısım;
		|ban: kesirli kısmın tekil formu;
		|bani: kesirli kısmın çoğul formu;
		|W: kesirli cins;
		|""2"": kesirli kısmın basamak sayısı.'"));

		Result.InputHint = NStr("vi = 'leu, lei, M, ban, bani, W, 2';
								|ru = 'leu, lei, M, ban, bani, W, 2';
								|en = 'leu, lei, M, ban, bani, W, 2'; fa = 'leu, lei, M, ban, bani, W, 2';
								|it = 'leu, lei, M, ban, bani, W, 2';
								|pl = 'leu, lei, M, ban, bani, W, 2';
								|tr = 'leu, lei, M, ban, bani, W, 2'");

	ElsIf LanguageCode = "ka" Then

		//@skip-check module-nstr-camelcase
		Result.Instruction = StringFunctions.FormattedString(NStr(
		"vi = 'Cần liệt kê các tham số viết bằng chữ sau dấu phẩy.
		|
		|
		|
		|
		|
		|
		|';
		|ru = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для грузинского языка (ka_GE):
		|
		|ლარი, თეთრი, 2
		|
		|ლარი - целая часть;
		|თეთრი - дробная часть;
		|""2"" - количество разрядов дробной части.';
		|en = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Georgian (ka_GE):
		|
		|ლარი, თეთრი, 2
		|
		|ლარი - the integral part
		|თეთრი - the fractional part
		|2 - the number of decimal places.'; fa = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Georgian (ka_GE):
		|
		|ლარი, თეთრი, 2
		|
		|ლარი - the integral part
		|თეთრი - the fractional part
		|2 - the number of decimal places.';
		|it = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для грузинского языка (ka_GE):
		|
		|ლარი, თეთრი, 2
		|
		|ლარი - целая часть;
		|თეთრი - дробная часть;
		|""2"" - количество разрядов дробной части.';
		|pl = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Georgian (ka_GE):
		|
		|ლარი, თეთრი, 2
		|
		|ლარი - the integral part
		|თეთრი - the fractional part
		|2 - the number of decimal places.';
		|tr = 'Yazım parametrelerini virgülle ayırarak listeleyin.
		|Gürcüce için doldurma örneği (ka_GE):
		|
		|ლარი, თეთრი, 2
		|
		|ლარი: tam sayı;
		|თეთრი: kesirli kısım;
		|""2"": kesirli kısmın basamak sayısı.'"));

		Result.InputHint = NStr("vi = 'ლარი, თეთრი, 2';
								|ru = 'ლარი, თეთრი, 2';
								|en = 'ლარი, თეთრი, 2'; fa = 'ლარი, თეთრი, 2';
								|it = 'ლარი, თეთრი, 2';
								|pl = 'ლარი, თეთრი, 2';
								|tr = 'ლარი, თეთრი, 2'");

	ElsIf LanguageCode = "az" Or LanguageCode = "tk" Then

		Result.Instruction = StringFunctions.FormattedString(NStr(
		"vi = 'Cần liệt kê các tham số viết bằng chữ sau dấu phẩy.
		|
		|
		|
		|
		|
		|
		|';
		|ru = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для азербайджанского(az) и туркменского языков(tk):
		|
		|TL,Kr,2
		|
		|""TL"" - предмет исчисления;
		|""Kr"" - дробная часть (может отсутствовать);
		|2 - количество разрядов дробной части (может отсутствовать, по умолчанию - 2)';
		|en = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Azerbaijani (az) and Turkmen (tk):
		|
		|TL,Kr,2
		|
		|""TL"" - the calculation object
		|""Kr"" - the fractional part (may be missing)
		|2 - the number of decimal places (may be missing; the default value is 2)'; fa = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Azerbaijani (az) and Turkmen (tk):
		|
		|TL,Kr,2
		|
		|""TL"" - the calculation object
		|""Kr"" - the fractional part (may be missing)
		|2 - the number of decimal places (may be missing; the default value is 2)';
		|it = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для азербайджанского(az) и туркменского языков(tk):
		|
		|TL,Kr,2
		|
		|""TL"" - предмет исчисления;
		|""Kr"" - дробная часть (может отсутствовать);
		|2 - количество разрядов дробной части (может отсутствовать, по умолчанию - 2)';
		|pl = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Azerbaijani (az) and Turkmen (tk):
		|
		|TL,Kr,2
		|
		|""TL"" - the calculation object
		|""Kr"" - the fractional part (may be missing)
		|2 - the number of decimal places (may be missing; the default value is 2)';
		|tr = 'Yazım parametrelerini virgülle ayırarak listeleyin.
		|Azerbaycan Türkçesi (az) ve Türkmence (tk) dilleri için doldurma örneği:
		|
		|TL,Kr,2
		|
		|""TL"": hesaplama konusu;
		|""Kr"": kesirli kısım (eksik olabilir);
		|2: kesirli kısmın basamak sayısı (eksik olabilir, varsayılan olarak 2''dir)'"));

		Result.InputHint = NStr("vi = 'TL,Kr,2';
								|ru = 'TL,Kr,2';
								|en = 'TL,Kr,2'; fa = 'TL,Kr,2';
								|it = 'TL,Kr,2';
								|pl = 'TL,Kr,2';
								|tr = 'TL,Kr,2'");

	ElsIf LanguageCode = "vi" Then

		//@skip-check module-nstr-camelcase
		Result.Instruction = StringFunctions.FormattedString(NStr(
		"vi = 'Tham số viết bằng chữ cần liệt kê sau dấu phẩy.
		|Mẫu điền tiếng Việt (vi_VN):
		|
		|đồng, chỉ có phần nguyên.
		|
		|
		|
		|';
		|ru = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для вьетнамского языка (vi_VN):
		|
		|dong, xu, 2
		|
		|dong, - целая часть;
		|xu, - дробная часть;
		|2 - количество разрядов дробной части.';
		|en = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Vietnamese (vi_VN):
		|
		|dong, xu, 2
		|
		|dong, - the integral part
		|xu, - the fractional part
		|2 - the number of decimal places.'; fa = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Vietnamese (vi_VN):
		|
		|dong, xu, 2
		|
		|dong, - the integral part
		|xu, - the fractional part
		|2 - the number of decimal places.';
		|it = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для вьетнамского языка (vi_VN):
		|
		|dong, xu, 2
		|
		|dong, - целая часть;
		|xu, - дробная часть;
		|2 - количество разрядов дробной части.';
		|pl = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Vietnamese (vi_VN):
		|
		|dong, xu, 2
		|
		|dong, - the integral part
		|xu, - the fractional part
		|2 - the number of decimal places.';
		|tr = 'Yazım parametrelerini virgülle ayırarak listeleyin.
		|Vietnamca için doldurma örneği (vi_VN):
		|
		|dong, xu, 2
		|
		|dong: tam sayı;
		|xu: kesirli kısım;
		|2: kesirli kısmın basamak sayısı.'"));

		Result.InputHint = NStr("vi = 'dong, xu, 2';
								|ru = 'dong, xu, 2';
								|en = 'dong, xu, 2'; fa = 'dong, xu, 2';
								|it = 'dong, xu, 2';
								|pl = 'dong, xu, 2';
								|tr = 'dong, xu, 2'");

	ElsIf LanguageCode = "tr" Then

		//@skip-check module-nstr-camelcase
		Result.Instruction = StringFunctions.FormattedString(NStr(
		"vi = 'Cần liệt kê các tham số viết bằng chữ sau dấu phẩy.
		|
		|
		|
		|
		|
		|
		|
		|';
		|ru = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для турецкого языка (tr_TR):
		|
		|TL,Kr,2,Separate
		|
		|TL - целая часть;
		|Kr - дробная часть (может отсутствовать);
		|2 - количество разрядов дробной части (может отсутствовать, значение по умолчанию - 2);
		|""Separate"" - признак написания прописи раздельно, ""Solid"" - слитно (может отсутствовать, по умолчанию слитно).';
		|en = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Turkish (tr_TR):
		|
		|TL,Kr,2,Separate
		|
		|TL - the integral part
		|Kr - the fractional part (may be missing)
		|2 - the number of decimal places (may be missing; the default value is 2)
		|""Separate"" - indicates whether to write words separately, ""Solid"" - indicates whether to write words solid (may be missing; the default value is ""Solid"").'; fa = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Turkish (tr_TR):
		|
		|TL,Kr,2,Separate
		|
		|TL - the integral part
		|Kr - the fractional part (may be missing)
		|2 - the number of decimal places (may be missing; the default value is 2)
		|""Separate"" - indicates whether to write words separately, ""Solid"" - indicates whether to write words solid (may be missing; the default value is ""Solid"").';
		|it = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для турецкого языка (tr_TR):
		|
		|TL,Kr,2,Separate
		|
		|TL - целая часть;
		|Kr - дробная часть (может отсутствовать);
		|2 - количество разрядов дробной части (может отсутствовать, значение по умолчанию - 2);
		|""Separate"" - признак написания прописи раздельно, ""Solid"" - слитно (может отсутствовать, по умолчанию слитно).';
		|pl = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Turkish (tr_TR):
		|
		|TL,Kr,2,Separate
		|
		|TL - the integral part
		|Kr - the fractional part (may be missing)
		|2 - the number of decimal places (may be missing; the default value is 2)
		|""Separate"" - indicates whether to write words separately, ""Solid"" - indicates whether to write words solid (may be missing; the default value is ""Solid"").';
		|tr = 'Yazım parametrelerini virgülle ayırarak listeleyin.
		|Türkçe için doldurma örneği (tr_TR):
		|
		|TL,Kr,2,Separate
		|
		|TL: tam sayı;
		|Kr: kesirli kısım (eksik olabilir);
		|2: kesirli kısmın basamak sayısı (eksik olabilir, varsayılan olarak 2''dir);
		|""Separate"": ayrı oalrak yazım işareti, ""Solid"": bitişik (eksik olabilir, varsayılan olarak bitişiktir).'"));

		Result.InputHint = NStr("vi = 'TL,Kr,2,Separate';
								|ru = 'TL,Kr,2,Separate';
								|en = 'TL,Kr,2,Separate'; fa = 'TL,Kr,2,Separate';
								|it = 'TL,Kr,2,Separate';
								|pl = 'TL,Kr,2,Separate';
								|tr = 'TL,Kr,2,Separate'");

	ElsIf LanguageCode = "hu" Then

		Result.Instruction = StringFunctions.FormattedString(NStr(
		"vi = 'Cần liệt kê các tham số viết bằng chữ sau dấu phẩy.
		|
		|
		|
		|
		|
		|
		|';
		|ru = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для венгерского языка (hu):
		|
		|Forint, fillér, 2
		|
		|Forint - целая часть;
		|fillér - дробная часть;
		|""2"" - количество разрядов дробной части.';
		|en = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Hungarian (hu):
		|
		|Forint, fillér, 2
		|
		|Forint - the integral part
		|fillér - the fractional part
		|""2"" - the number of decimal places.'; fa = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Hungarian (hu):
		|
		|Forint, fillér, 2
		|
		|Forint - the integral part
		|fillér - the fractional part
		|""2"" - the number of decimal places.';
		|it = 'Перечислите параметры прописи через запятую.
		|Образец заполнения для венгерского языка (hu):
		|
		|Forint, fillér, 2
		|
		|Forint - целая часть;
		|fillér - дробная часть;
		|""2"" - количество разрядов дробной части.';
		|pl = 'List comma-separated parameters for writing amounts in words.
		|Example of filling for Hungarian (hu):
		|
		|Forint, fillér, 2
		|
		|Forint - the integral part
		|fillér - the fractional part
		|""2"" - the number of decimal places.';
		|tr = 'Yazım parametrelerini virgülle ayırarak listeleyin.
		|Macarca için doldurma örneği (hu):
		|
		|Forint, fillér, 2
		|
		|Forint: tam sayı;
		|fillér: kesirli kısım;
		|""2"": kesirli kısmın basamak sayısı.'"));

		Result.InputHint = NStr("vi = 'Forint, fillér, 2';
								|ru = 'Forint, fillér, 2';
								|en = 'Forint, fillér, 2'; fa = 'Forint, fillér, 2';
								|it = 'Forint, fillér, 2';
								|pl = 'Forint, fillér, 2';
								|tr = 'Forint, fillér, 2'");

	EndIf;

	Return Result;

EndFunction

#EndRegion