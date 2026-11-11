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
	
	MetadataObject = NationalLanguageSupportServer.MetadataObject(Parameters.Object);
	If MetadataObject = Undefined Then
		MetadataObject = NationalLanguageSupportServer.MetadataObject(Parameters.Ref);
	EndIf;
	
	ReadOnly = Not AccessRight("Update", MetadataObject);
	
	MultilanguageStringsInAttributes = NationalLanguageSupportServer.MultilanguageStringsInAttributes(MetadataObject);
	StorageInTabularSection = NationalLanguageSupportServer.ObjectContainsPMRepresentations(MetadataObject.FullName(), Parameters.AttributeName);
	Attribute = MetadataObject.Attributes.Find(Parameters.AttributeName);
	If Attribute = Undefined Then
		For Each StandardAttribute In MetadataObject.StandardAttributes Do
			If StrCompare(StandardAttribute.Name, Parameters.AttributeName) = 0 Then
				Attribute = StandardAttribute;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	MainLanguageSuffix         = "";
	If Not Common.IsMainLanguage() Then
		MainLanguageSuffix = NationalLanguageSupportServer.CurrentLanguageSuffix();
	EndIf;
	
	LanguagesInformationRecords = NationalLanguageSupportServer.LanguagesInfo();
	
	LanguagesSet = New ValueTable;
	LanguagesSet.Columns.Add("LanguageCode",      Common.StringTypeDetails(10));
	LanguagesSet.Columns.Add("Presentation", Common.StringTypeDetails(150));
	LanguagesSet.Columns.Add("Suffix",       Common.StringTypeDetails(50));
	
	If StorageInTabularSection And Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport.Print") Then
		PrintManagementModuleNationalLanguageSupport = Common.CommonModule("PrintManagementNationalLanguageSupport");
		PrintManagementModuleNationalLanguageSupport.WhenFillingInASetOfLanguages(LanguagesSet);
	EndIf;
	
	LanguagesUsed = New Map;
	LanguagesUsed.Insert(NationalLanguageSupportServer.DefaultLanguageCode(), True);
	
	IsAdditionalLangUsed = False;
	
	For Each LangData In LanguagesInformationRecords.Used Do
		If LangData.Value Then
			LanguagesUsed.Insert(LanguagesInformationRecords[LangData.Key], True);
			IsAdditionalLangUsed = True;
		EndIf;
	EndDo;
	
	For Each ConfigurationLanguage In Metadata.Languages Do
		If LanguagesUsed[ConfigurationLanguage.LanguageCode] <> True Then
			Continue;
		EndIf;
		
		LanguageString = LanguagesSet.FindRows(New Structure("LanguageCode", ConfigurationLanguage.LanguageCode));
		
		If LanguageString.Count() = 0 Then
			LanguageData = LanguagesSet.Add();
			LanguageData.LanguageCode = ConfigurationLanguage.LanguageCode;
			LanguageData.Presentation = ConfigurationLanguage.Presentation();
		Else
			LanguageData = LanguageString[0];
		EndIf;
		
		If ConfigurationLanguage.LanguageCode =  NationalLanguageSupportServer.DefaultLanguageCode() Then
			LanguageData.Suffix = MainLanguageSuffix;
		Else
			For LanguageSeqNumber = 1 To NationalLanguageSupportCached.AdditionalLanguagesCount() Do
				If StrCompare(ConfigurationLanguage.LanguageCode, CurrentLanguage().LanguageCode) = 0 Then
					LanguageData.Suffix = "";
					Continue;
				EndIf;

				
				LanguageSuffix = NationalLanguageSupportClientServer.LanguageSuffix(LanguageSeqNumber);
				
				If StrCompare(ConfigurationLanguage.LanguageCode, LanguagesInformationRecords[LanguageSuffix]) = 0 Then
					LanguageData.Suffix = LanguageSuffix;
					Break;
				EndIf;
				
			EndDo;
		EndIf;
		
	EndDo;
	
	If Attribute = Undefined Then
		ErrorTemplate = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khi bạn mở biểu mẫu %1 trong tham số %2 đã chỉ ra mục tin không tồn tại %1';
				|ru = 'При открытии формы %1 в параметре %2 указан не существующий реквизит %1';
				|en = 'When opening form %1, parameter %2 contains attribute %1 that does not exist'; fa = 'When opening form %1, parameter %2 contains attribute %1 that does not exist';
				|it = 'Durante l''apertura del modulo %1nel parametro %2è indicato un requisito inesistente %1';
				|pl = 'Podczas otwarcia formularza %1 w parametrze %2 określany jest nieistniejący atrybut %1';
				|tr = '%2parametresinde %1formu aşılırken mevcut olmayan %1 öznitelik belirtilmiştir '"), "InputInMultipleLanguages", "AttributeName");
		Raise StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, Parameters.AttributeName);
	EndIf;
	
	If Attribute.MultiLine Then
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "MultiLine");
	EndIf;
	
	For Each ConfigurationLanguage In LanguagesSet Do
		NewRow = Languages.Add();
		FillPropertyValues(NewRow, ConfigurationLanguage);
		NewRow.Name = "_" + StrReplace(New UUID, "-", "");
	EndDo;
	
	GenerateInputFieldsInDifferentLanguages(Attribute.MultiLine, Parameters.ReadOnly Or ReadOnly);
	
	If Not IsBlankString(Parameters.Title) Then
		Title = Parameters.Title;
	Else
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 trong các ngôn ngữ khác nhau';
				|ru = '%1 на разных языках';
				|en = '%1 in different languages'; fa = '%1 in different languages';
				|it = '%1 in diverse lingue';
				|pl = '%1 w różnych językach';
				|tr = 'Farklı dillerde %1'"), Attribute.Presentation());
		If IsBlankString(Title) Then
			Title = Attribute.Presentation();
		EndIf;
	EndIf;
	
	LanguageDetails = LanguageDetails(CurrentLanguage().LanguageCode);
	If LanguageDetails <> Undefined Then
		ThisObject[LanguageDetails.Name] = Parameters.ValueCurrent;
	EndIf;
	
	DefaultLanguage = Common.DefaultLanguageCode();
	LocalizableHeaderAttributes = NationalLanguageSupportServer.TheNamesOfTheLocalizedDetailsOfTheObjectInTheHeader(MetadataObject);

	If StorageInTabularSection Then
		
		For Each Presentation In Parameters.Presentations Do
			
			LanguageDetails = LanguageDetails(Presentation.LanguageCode);
			If LanguageDetails <> Undefined Then
				If StrCompare(LanguageDetails.LanguageCode, CurrentLanguage().LanguageCode) = 0 Then
					ThisObject[LanguageDetails.Name] = ?(ValueIsFilled(Parameters.ValueCurrent), Parameters.ValueCurrent, Presentation[Parameters.AttributeName]);
				Else
					ThisObject[LanguageDetails.Name] = Presentation[Parameters.AttributeName];
				EndIf;
			EndIf;
			
		EndDo;
		
		If LocalizableHeaderAttributes[Parameters.AttributeName] <> Undefined Then
			LanguageDetails = LanguageDetails(DefaultLanguage);
			If ValueIsFilled(MainLanguageSuffix) And Parameters.Object <> Undefined Then
				ThisObject[LanguageDetails.Name] = Parameters.Object[Parameters.AttributeName + MainLanguageSuffix];
			EndIf;
		EndIf;
		
	EndIf;
	
	If MultilanguageStringsInAttributes
		And LocalizableHeaderAttributes[Parameters.AttributeName] <> Undefined
		And IsAdditionalLangUsed Then
		
		LanguageDetails = LanguageDetails(DefaultLanguage);
		If IsBlankString(MainLanguageSuffix) Then
			ThisObject[LanguageDetails.Name] = Parameters.ValueCurrent;
		ElsIf Parameters.AttributesValues <> Undefined Then
			ThisObject[LanguageDetails.Name] = Parameters.AttributesValues[Parameters.AttributeName + MainLanguageSuffix];
		ElsIf Parameters.Object <> Undefined Then
			ThisObject[LanguageDetails.Name] = Parameters.Object[Parameters.AttributeName + MainLanguageSuffix];
		EndIf;
		
		For Each AdditionalLanguage In LanguagesInformationRecords.Used Do
			If AdditionalLanguage.Value  Then
				LanguageCode = LanguagesInformationRecords[AdditionalLanguage.Key];
				If IsBlankString(LanguageCode) Or StrCompare(CurrentLanguage().LanguageCode, LanguageCode) = 0 Then
					Continue;
				EndIf;
				LanguageDetails = LanguageDetails(LanguageCode);
				
				If StrCompare(LanguageDetails.LanguageCode, CurrentLanguage().LanguageCode) = 0 Then
					ThisObject[LanguageDetails.Name] = Parameters.Object[Parameters.AttributeName];
				ElsIf Parameters.AttributesValues <> Undefined Then
					ThisObject[LanguageDetails.Name] = Parameters.AttributesValues[Parameters.AttributeName + AdditionalLanguage.Key]
				ElsIf Parameters.Object <> Undefined Then
					ThisObject[LanguageDetails.Name] = Parameters.Object[Parameters.AttributeName +  AdditionalLanguage.Key];
				ElsIf IsBlankString(ThisObject[LanguageDetails.Name]) Then
					ThisObject[LanguageDetails.Name] = Parameters.ValueCurrent;
				EndIf;
				
			EndIf;
		EndDo;
		
	EndIf;
	
	Items.Translate.Visible = False;
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport.TextTranslation") Then
		ModuleTranslationOfTextIntoOtherLanguages = Common.CommonModule("TextTranslationTool");
		Items.Translate.Visible = ModuleTranslationOfTextIntoOtherLanguages.TextTranslationAvailable()
			And Not Parameters.ReadOnly And Not ReadOnly;
		RepresentationInTheSourceLanguage = RepresentationInTheSourceLanguage();
	EndIf;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
		Items.Move(Items.Translate, Items.FormCommandBar);
		Items.OK.Representation = ButtonRepresentation.Picture;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If Not Modified Then
		Close();
		Return;
	EndIf;
	
	Result = New Structure;
	
	Result.Insert("DefaultLanguage",            DefaultLanguage);
	Result.Insert("StorageInTabularSection", StorageInTabularSection);
	Result.Insert("Modified",      Modified);
	Result.Insert("ValuesInDifferentLanguages",  New Array);
	
	CurrentCodeLanguage = ?(TypeOf(CurrentLanguage()) = Type("String"), CurrentLanguage(), CurrentLanguage().LanguageCode); 
	
	For Each Language In Languages Do
		
		If StrCompare(Language.LanguageCode, CurrentCodeLanguage) = 0 
		   Or (StrCompare(Language.LanguageCode, DefaultLanguage) = 0 
		   And Not Result.Property("StringInCurrentLanguage")) Then
			Result.Insert("StringInCurrentLanguage", ThisObject[Language.Name]);
		EndIf;
		
		If CurrentCodeLanguage = DefaultLanguage And Language.LanguageCode = DefaultLanguage Then
			Continue;
		EndIf;
		
		Values = New Structure;
		Values.Insert("LanguageCode",          Language.LanguageCode);
		Values.Insert("AttributeValue", ThisObject[Language.Name]);
		Values.Insert("Suffix",           Language.Suffix);
		
		Result.ValuesInDifferentLanguages.Add(Values);
	EndDo;
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure Translate(Command)
	
	TranslateOnTheServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateInputFieldsInDifferentLanguages(MultiLine, Var_ReadOnly)
	
	Add = New Array;
	StringType = New TypeDescription("String");
	For Each ConfigurationLanguage In Languages Do
		NewAttribute = New FormAttribute(ConfigurationLanguage.Name, StringType,, ConfigurationLanguage.Presentation);
		NewAttribute.StoredData = True;
		Add.Add(NewAttribute);
	EndDo;
	
	ChangeAttributes(Add);
	ItemsParent = Items.LanguagesGroup;
	
	For Each ConfigurationLanguage In Languages Do
		
		If StrCompare(ConfigurationLanguage.LanguageCode, CurrentLanguage().LanguageCode) = 0 And ItemsParent.ChildItems.Count() > 0 Then
			Item = Items.Insert(ConfigurationLanguage.Name, Type("FormField"), ItemsParent, ItemsParent.ChildItems.Get(0));
			CurrentItem = Item;
		Else
			Item = Items.Add(ConfigurationLanguage.Name, Type("FormField"), ItemsParent);
		EndIf;
		
		Item.DataPath        = ConfigurationLanguage.Name;
		
		If ValueIsFilled(ConfigurationLanguage.EditForm) Then
			Item.Type = FormFieldType.LabelField;
			Item.Hyperlink = True;
			Item.SetAction("Click", "Attachable_Click");
		Else
			Item.Type                = FormFieldType.InputField;
			Item.Width             = 40;
			Item.MultiLine = MultiLine;
			Item.TitleLocation = FormItemTitleLocation.Top;
			Item.ReadOnly     = Var_ReadOnly;
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

&AtServer
Procedure TranslateOnTheServer()
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport.TextTranslation") Then
		ModuleTranslationOfTextIntoOtherLanguages = Common.CommonModule("TextTranslationTool");
	Else
		Return;
	EndIf;
	
	SourceLanguage = StrSplit(Common.DefaultLanguageCode(), "_", False)[0];
	If RepresentationInTheSourceLanguage <> RepresentationInTheSourceLanguage() Then
		RepresentationInTheSourceLanguage = RepresentationInTheSourceLanguage();
		IsSourceLangPresentationChanged = True;
	EndIf;
	
	AvailableLanguages = ModuleTranslationOfTextIntoOtherLanguages.AvailableLanguages();
	If AvailableLanguages.FindByValue(SourceLanguage) = Undefined Then
		Return;
	EndIf;
	
	For IndexOf = 0 To Languages.Count() - 1 Do
		TableRow = Languages[IndexOf];
		TranslationLanguage = StrSplit(TableRow.LanguageCode, "_", False)[0];
		If SourceLanguage = TranslationLanguage Then
			Continue;
		EndIf;
		If AvailableLanguages.FindByValue(TranslationLanguage) = Undefined Then
			Continue;
		EndIf;
		If Not IsSourceLangPresentationChanged And ValueIsFilled(ThisObject[TableRow.Name]) Then
			Items[TableRow.Name].BackColor = New Color;
		Else
			ThisObject[TableRow.Name] = TranslateTextOnTheServer(RepresentationInTheSourceLanguage, TranslationLanguage, SourceLanguage);
			Items[TableRow.Name].BackColor = StyleColors.ChangedFieldColor;
			Modified = True;
		EndIf;
	EndDo;
	
	IsSourceLangPresentationChanged = False;
	
EndProcedure

&AtServerNoContext
Function TranslateTextOnTheServer(SourceText, TranslationLanguage, SourceLanguage)
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport.TextTranslation") Then
		ModuleTranslationOfTextIntoOtherLanguages = Common.CommonModule("TextTranslationTool");
		Return ModuleTranslationOfTextIntoOtherLanguages.TranslateText(SourceText, TranslationLanguage, SourceLanguage);
	EndIf;
	
EndFunction

&AtServer
Function RepresentationInTheSourceLanguage()
	
	FoundRows = Languages.FindRows(New Structure("LanguageCode", Common.DefaultLanguageCode()));
	For Each LanguageDetails In FoundRows Do
		Return ThisObject[LanguageDetails.Name];
	EndDo;
	
	Return "";
	
EndFunction

#EndRegion