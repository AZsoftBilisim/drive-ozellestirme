

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.Ref.IsEmpty() Then
		
		MakeCopyValues(Parameters.CopyingValue); 
		OnCreatReadAtServer();
		
	EndIf;
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	// End StandardSubsystems.Core

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	GlossaryDescriptions.Clear();
	
	For Each CurRow In CurrentObject.GlossaryDetails Do
		NewRow = GlossaryDescriptions.Add();
		NewRow.LongDesc = CurRow.LongDesc.Get();
		NewRow.LanguageCode = CurRow.LanguageCode;
	EndDo;
	
	OnCreatReadAtServer();
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	TransferEditingResultToDescriptionTable(ThisObject);
	
	CurrentObject.GlossaryDetails.Clear();
	For Each CurRow In GlossaryDescriptions Do
		NewRow = CurrentObject.GlossaryDetails.Add();
		NewRow.LongDesc = New ValueStorage(CurRow.LongDesc);
		NewRow.LanguageCode = CurRow.LanguageCode;
	EndDo; 
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	// End StandardSubsystems.Core
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not ValueIsFilled(FormDisplayOption) Then
		
		SwitchDisplayOption( "View");
		ConfigureDisplayOfInformationViewingMode();
		
		VisibilityManagement(ThisObject);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure TranslateFromViewingLanguage(Command) 
	
	ClearMessages();
	
	HTMLDataEditing = DemoScenariosClientServer.HTMLTextFromFormattedDocument(DescriptionTextEditing);
	HTMLDataReading = DemoScenariosClientServer.HTMLTextFromFormattedDocument(DescriptionTextReading);
	
	DemoScenariosClient.TranslateFromViewingLanguage(
		ThisObject, HTMLDataReading.HTML, HTMLDataEditing.HTML, GlossaryLanguageReading, GlossaryLanguage, "ScenarioText", HTMLDataReading.Attachments);

EndProcedure

#Region ChangingTheDisplayMode

&AtClient
Procedure SetViewOption(Command)
	
	SwitchDisplayOption( "View");
	ConfigureDisplayOfInformationViewingMode();
	
EndProcedure

&AtClient
Procedure SetEditOption(Command)
	
	SwitchDisplayOption( "Edit");
	
EndProcedure 

&AtClient
Procedure SetTranslationOption(Command)
	
	SwitchDisplayOption( "Translation");
	ConfigureDisplayOfInformationViewingMode();
	
EndProcedure 

#EndRegion

#Region ChangeLanguage

&AtClient
Procedure Attachable_ChangeEditingLanguage(Command)

	CommandName = Command.Name;
	
	LanguageCode = DemoScenariosClientServer.LanguageCodeFromCommandName(CommandName, "SwitchToEditingLanguage_");
	
	WhenChangingGlossaryLanguage(LanguageCode);
	
EndProcedure

&AtClient
Procedure Attachable_ChangeViewingLanguage(Command)

	CommandName = Command.Name;
	
	LanguageCode = DemoScenariosClientServer.LanguageCodeFromCommandName(CommandName, "SwitchToViewingLanguage_");
	
	WhenChangingGlossaryLanguageRead(LanguageCode);
	
EndProcedure

#EndRegion

#EndRegion 

#Region Private

&AtServer
Function GetDescriptionInLanguage(LanguageCode)
	
	TheStructureOfTheSearch = New Structure("LanguageCode", LanguageCode);
	
	FoundRows = GlossaryDescriptions.FindRows(TheStructureOfTheSearch);
	If FoundRows.Count() > 0 Then
		StorageData = FoundRows[0].LongDesc;
	EndIf;
	
	If TypeOf(StorageData) = Type("FormattedDocument") Then
		TextReceived = StorageData;
	Else
		TextReceived = New FormattedDocument;
	EndIf;
	
	Return TextReceived;
	
EndFunction

&AtServer
Procedure OnCreatReadAtServer() 
	
	DemoScenarios.CreateFormElementsConfigurationLanguages(ThisObject);
	DemoScenarios.SetConfigurationLanguagesInForm(ThisObject);
	
	DemoScenarios.SetLanguageSettingInForm(ThisObject, "GlossaryLanguageReading", "GlossaryLanguage");
	
	DemoScenariosClientServer.ReflectCurLanguagesOnForm(ThisObject, "GlossaryLanguageReading", "GlossaryLanguage");
	DemoScenariosClientServer.GenerateTitleOfTranslationCommands(GlossaryLanguageReading, GlossaryLanguage, Items.Translate);
	
	DemoScenarios.LoadSettingForFormDisplayOption(
		ThisObject,
		DemoScenarios.AvailableDisplayOptions(True),
		Metadata.Catalogs.Glossary);
	
	VisibilityManagement(ThisObject);
	DescriptionTextEditing = GetDescriptionInLanguage(GlossaryLanguage);
	DescriptionTextReading         = GetDescriptionInLanguage(GlossaryLanguageReading);
	ConfigureDisplayOfInformationViewingMode();

EndProcedure

&AtClientAtServerNoContext
Procedure VisibilityManagement(Form)
	
	Items = Form.Items;
	
	ThisIsEditingMode = (Form.FormDisplayOption = "Edit");
	ThisIsTranslationMode        = (Form.FormDisplayOption = "Translation");
	ThisIsViewMode       = (Form.FormDisplayOption = "View");
	
	Items.AdvancedGroup.Visible       = ThisIsEditingMode Or ThisIsTranslationMode; 
	Items.EditGroup.Visible      = ThisIsEditingMode Or ThisIsTranslationMode;
	
	Items.Translate.Visible = ThisIsTranslationMode; 
	
	Items.SubmenuViewingLanguage.Visible = ThisIsViewMode Or ThisIsTranslationMode;
	Items.ReadingGroup.Visible         = ThisIsViewMode Or ThisIsTranslationMode;
	
	DemoScenariosClientServer.MarkCommandsForSwitchingFormDisplayOption(Form);
	
EndProcedure

&AtClient
Procedure SwitchDisplayOption( NewOption)
	
	SwitchingParameters = DemoScenariosClientServer.NewDisplayOptionSwitchingOptions();
	SwitchingParameters.Form                          = ThisObject;
	SwitchingParameters.NewOption                   = NewOption;
	SwitchingParameters.AttributeNameLanguageReading         = "GlossaryLanguageReading";
	SwitchingParameters.AttributeNameLanguageEditing = "GlossaryLanguage";
	SwitchingParameters.ConfigurationLanguages              = ConfigurationLanguages;
	
	DemoScenariosClientServer.SwitchDisplayOption(SwitchingParameters);
	
	If SwitchingParameters.LanguageSwitchingCompleted Then
		
		If SwitchingParameters.AttributeNameLanguageSwitched = "GlossaryLanguageReading" Then
			WhenChangingGlossaryLanguageRead( SwitchingParameters.SwitchedToLanguage);
		ElsIf SwitchingParameters.AttributeNameLanguageSwitched = "ScriptLanguage" Then
			WhenChangingGlossaryLanguage(SwitchingParameters.SwitchedToLanguage);
		EndIf;
		
	EndIf;
	
	VisibilityManagement(ThisObject);
	
EndProcedure

&AtClient
Procedure WhenChangingGlossaryLanguage(LanguageCode)

	If Modified Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("LanguageCode", LanguageCode);
		CallbackDescription = New CallbackDescription("LanguageOfGlossaryWhenChangingEnd", ThisObject, AdditionalParameters);
		ShowQueryBox(CallbackDescription, NStr("vi = 'Chưa lưu nội dung bảng thuật ngữ. Ghi lại?';
												|ru = 'Текст глоссария не сохранен. Записать?';
												|en = 'The glossary text is not saved. Do you want to save it?'; fa = 'The glossary text is not saved. Do you want to save it?';
												|it = 'Текст глоссария не сохранен. Записать?';
												|pl = 'The glossary text is not saved. Do you want to save it?';
												|tr = 'Terim sözlüğü metni kaydedilmedi. Yazılsın mı?'"), QuestionDialogMode.OKCancel);
	Else
		ChangeGlossaryLanguage(LanguageCode);
	EndIf;
	
EndProcedure 

&AtClient
Procedure WhenChangingGlossaryLanguageRead(LanguageCode)

	GlossaryLanguageReading = LanguageCode;
	DescriptionTextReading = GetDescriptionInLanguage(GlossaryLanguageReading);
	DemoScenariosClientServer.ReflectCurLanguagesOnForm(ThisObject , "GlossaryLanguageReading", "GlossaryLanguage");
	DemoScenariosClientServer.GenerateTitleOfTranslationCommands(GlossaryLanguageReading, GlossaryLanguage, Items.Translate);
	
EndProcedure

&AtServer
Procedure ConfigureDisplayOfInformationViewingMode()

	PresentationOfMetadataObject = PresentationOfMetadataObject();
	
	NameConfigurationObjects = PresentationOfMetadataObject.MetadataViews;
	Items.GroupPresentationConfigurationObjects.Title = PresentationOfMetadataObject.Presentation;
	
	TransferEditingResultToDescriptionTable(ThisObject);
	DescriptionTextReading = GetDescriptionInLanguage(GlossaryLanguageReading);
	
EndProcedure

&AtServer
Function PresentationOfMetadataObject()
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("Presentation",            "");
	ReturnStructure.Insert("Count",               0);
	ReturnStructure.Insert("MetadataViews", New ValueList);

	SetPrivilegedMode(True);
	
	If Object.ConfigurationObjects.Count() = 0 Then
		ReturnStructure.Presentation = NStr("vi = 'Chưa chỉ ra việc sử dụng trong các đối tượng cấu hình';
											|ru = 'Использование в объектах конфигурации не указано';
											|en = 'Usage in configuration objects is not specified'; fa = 'Usage in configuration objects is not specified';
											|it = 'Использование в объектах конфигурации не указано';
											|pl = 'Usage in configuration objects is not specified';
											|tr = 'Konfigürasyon nesnelerinde kullanım belirtilmedi'");
		Return ReturnStructure;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	MetadataObjectIDs.Ref       AS Ref,
	|	MetadataObjectIDs.Description AS Description
	|FROM
	|	Catalog.MetadataObjectIDs AS MetadataObjectIDs
	|WHERE
	|	MetadataObjectIDs.Ref IN(&MetadataObjects)";
	
	Query.SetParameter("MetadataObjects", Object.ConfigurationObjects.Unload().UnloadColumn("ConfigurationObject"));
	
	Selection = Query.Execute().Select(); 
	While Selection.Next() Do
		 ReturnStructure.MetadataViews.Add(Selection.Ref, Selection.Description);
	EndDo;
	
	ReturnStructure.Count = ReturnStructure.MetadataViews.Count();
	ReturnStructure.Presentation = DemoScenarios.LinePresentationWithMore(NStr("vi = 'Đối tượng cấu hình:';
																				|ru = 'Объекты конфигурации:';
																				|en = 'Configuration objects:'; fa = 'Configuration objects:';
																				|it = 'Объекты конфигурации:';
																				|pl = 'Configuration objects:';
																				|tr = 'Konfigürasyon nesneleri:'"),
	                                                                                   ReturnStructure.MetadataViews, 80);
	
	Return ReturnStructure;
	
EndFunction

&AtClient
Procedure LanguageOfGlossaryWhenChangingEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.OK Then
		
		Success = Write();
		
		If Success Then
			
			ChangeGlossaryLanguage(AdditionalParameters.LanguageCode);
			
		EndIf;
		
	EndIf;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure TransferEditingResultToDescriptionTable(Form)
	
	TheStructureOfTheSearch = New Structure("LanguageCode", Form.GlossaryLanguage); 
	
	FoundRows = Form.GlossaryDescriptions.FindRows(TheStructureOfTheSearch);
	If FoundRows.Count() > 0 Then
		GlossaryLine = FoundRows[0];
	Else
		GlossaryLine = Form.GlossaryDescriptions.Add();
		GlossaryLine.LanguageCode = Form.GlossaryLanguage;
	EndIf;
	
	GlossaryLine.LongDesc = Form.DescriptionTextEditing;
	
EndProcedure

&AtClient
Procedure ChangeGlossaryLanguage(LanguageCode)

	GlossaryLanguage  = LanguageCode;
	DescriptionTextEditing = GetDescriptionInLanguage(GlossaryLanguage);
	DemoScenariosClientServer.ReflectCurLanguagesOnForm(ThisObject, "GlossaryLanguageReading", "GlossaryLanguage");
	DemoScenariosClientServer.GenerateTitleOfTranslationCommands(GlossaryLanguageReading, GlossaryLanguage, Items.Translate);

EndProcedure

&AtClient
Procedure AfterAnsweringQuestionAfterTranslation(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	DescriptionTextEditing = DemoScenariosClientServer.FormattedDocumentFromHTMLData(
		AdditionalParameters.TextIsTranslated, AdditionalParameters.Attachments);
	Modified = True;
	
EndProcedure

&AtServer
Procedure MakeCopyValues(CopyingValue)
	
	If ValueIsFilled(CopyingValue) And ValueIsFilled(CopyingValue.GlossaryDetails) Then
		Object.GlossaryDetails.Clear();
		GlossaryDescriptions.Clear();
		For Each GlossaryLine In CopyingValue.GlossaryDetails Do
			NewRow = GlossaryDescriptions.Add();
			GlossaryText = GlossaryLine.LongDesc.Get();
			
			NewRow.LongDesc = GlossaryText;
			NewRow.LanguageCode = GlossaryLine.LanguageCode;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion