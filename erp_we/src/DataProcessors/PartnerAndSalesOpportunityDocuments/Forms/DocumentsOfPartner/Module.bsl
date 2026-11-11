
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	DataProcessorObject = FormAttributeToValue("Object");

	FormNameDocumentKindsContentSetting = DataProcessorObject.Metadata().FullName()
			+ ".Form.SettingOfDocumentKindsList";

	SetSettingsKey();

	FillInQueryTable(DataProcessorObject);

	UpdateListOfDocumentTypes();

	RestoreSettings();

	UpdateRequestText();

	SetDefaultValues();

	ApplyCommandParameters();

EndProcedure

&AtClient
Procedure OnClose(Exit)

	If Not Exit Then
		ShouldSaveSettings();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDocumentsTable

&AtClient
Procedure DocumentsTableSelection(Item, RowSelected, Field, StandardProcessing)

	ShowValue(Undefined, Item.CurrentData.Document);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetContentOfDocuments(Command)

	EditDocumentComposition();

EndProcedure

&AtClient
Procedure Generate(Command)
	
	ClearMessages();

	UpdateDocumentTableOnServer();

EndProcedure

&AtClient
Procedure SelectPeriod(Command)

	TMCommonUseClient.EditPeriod(DocumentsSelectionPeriod);

EndProcedure

&AtClient
Procedure Edit(Command)

	CurrentData = Items.DocumentsTable.CurrentData;
	If CurrentData <> Undefined Then

		ShowValue(Undefined, CurrentData.Document);

	EndIf;

EndProcedure

#EndRegion

#Region Private

#Region Settings

&AtServer
Procedure RestoreSettings()

	SettingsValue = Common.CommonSettingsStorageLoad("DataProcessor.DocumentsOfPartner", SettingsKey);
	If TypeOf(SettingsValue) = Type("Map") Then

		ValueFromSettings = SettingsValue.Get("DocumentKindList");
		If TypeOf(ValueFromSettings) = Type("ValueList") Then
			ApplySettingsToListOfDocumentTypes(ValueFromSettings);
		EndIf;

		DocumentsSelectionPeriod.StartDate    = SettingsValue.Get("StartDate");
		DocumentsSelectionPeriod.EndDate = SettingsValue.Get("EndDate");

		Partner = SettingsValue.Get("Parameter");

	EndIf;

EndProcedure

&AtServer
Procedure ShouldSaveSettings()

	Settings = New Map;
	Settings.Insert("Partner",               Parameter);
	Settings.Insert("DocumentKindList", DocumentKindList);
	Settings.Insert("StartDate",            DocumentsSelectionPeriod.StartDate);
	Settings.Insert("EndDate",         DocumentsSelectionPeriod.EndDate);

	Common.CommonSettingsStorageSave("DataProcessor.DocumentsOfPartner", SettingsKey, Settings);

EndProcedure

&AtServer
Procedure SetDefaultValues()
	
	If Not ValueIsFilled(DocumentsSelectionPeriod.StartDate)
		Or Not ValueIsFilled(DocumentsSelectionPeriod.EndDate) Then
		
		DocumentsSelectionPeriod.StartDate    = AddMonth(CurrentSessionDate(), - 12);
		DocumentsSelectionPeriod.EndDate = CurrentSessionDate();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ApplyCommandParameters()

	If Parameters.Property("Filter") Then

		Parameters.Filter.Property("Partner", Parameter);
	
	EndIf;

	If Parameters.Property("GenerateOnOpen") And Parameters.GenerateOnOpen Then

		UpdateDocumentTableOnServer();

	EndIf;
	
	If Not ValueIsFilled(Parameter) Then
		Items.Parameter.Visible = True;
		If GetFunctionalOption("UsePartnersAsCounterparties") Then
			Items.Parameter.Title = NStr("vi = 'Đối tác';
										|ru = 'Контрагент';
										|en = 'Counterparty'; fa = 'طرف حساب';
										|it = 'Controparte';
										|pl = 'Counterparty';
										|tr = 'Cari hesap'");
		EndIf;
	EndIf;

EndProcedure

&AtServer
Procedure SetSettingsKey()

	If Parameters.Property("SettingsKey") And Not IsBlankString(Parameters.SettingsKey) Then

		SettingsKey = Parameters.SettingsKey;

	Else

		SettingsKey = "WithoutAPartner";

	EndIf;

	SettingsKey = SettingsKey + "_" + Users.CurrentUser().UUID();

	If Parameters.Property("Filter") And Parameters.Filter.Property("Partner") Then

		SettingsKey = SettingsKey + "_" + Parameters.Filter.Partner.UUID();

	EndIf;

EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure FillInQueryTable(DataProcessorObject)

	AdditionalDocuments_ = New Array;
	AdditionalDocuments_.Add(Metadata.Documents.GoodsIssueNote);
	AdditionalDocuments_.Add(Metadata.Documents.GoodsReceiptNote);

	HeaderFields = New Array;
	HeaderFields.Add("DocumentAmount");
	HeaderFields.Add("Currency");
	HeaderFields.Add("Warehouse");
	HeaderFields.Add("Organization");

	DataProcessorObject.FillInQueryTable(TableOfRequests, "DocumentsOfPartner",
			AdditionalDocuments_,
			HeaderFields);

EndProcedure

&AtServer
Procedure UpdateRequestText()

	TimeRequestTextTT     = "";
	TimeRequestTextData = "";
	For Each TabRow In TableOfRequests.FindRows(New Structure("Use", True)) Do
		
		RequestEmpty = IsBlankString(TimeRequestTextTT);
		If Not RequestEmpty Then
			QueryTextByLine = StrReplace(TabRow.QueryText, "INTO TTSelectionTable", "");
		Else 
			QueryTextByLine = TabRow.QueryText;
		EndIf;

		TimeRequestTextTT = TimeRequestTextTT + ?(RequestEmpty, "", " UNION ALL " + Chars.LF)
				+ QueryTextByLine;
				
		RequestDataEmpty = IsBlankString(TimeRequestTextData);
		TimeRequestTextData = TimeRequestTextData + ?(RequestDataEmpty, "", " UNION ALL " + Chars.LF)
				+ TabRow.QueryTextSelection;
				
		TimeRequestTextData = StrReplace(TimeRequestTextData, "&PostfixToChoose,", ?(RequestDataEmpty," ALLOWED ", ""));

	EndDo;
	
	If Not IsBlankString(TimeRequestTextData) Then

		TimeRequestTextData = TimeRequestTextData + 
		"ORDER BY
		|	DATE,
		|	Document
		|";

	EndIf;

	QueryTextFilter       = TimeRequestTextTT;
	QueryTextByDocuments = TimeRequestTextData;

EndProcedure

&AtServer
Procedure SetWhetherToUseDocumentType()

	For Each TabRow In TableOfRequests Do

		ListItem = DocumentKindList.FindByValue(TabRow.DocumentName);
		If ListItem <> Undefined Then
			TabRow.Use = ListItem.Check;
		EndIf;

	EndDo;

EndProcedure

&AtServer
Procedure UpdateListOfDocumentTypes()

	DocumentKindList.Clear();
	For Each String In TableOfRequests Do
		DocumentKindList.Add(String.DocumentName, String.DocumentSynonym, String.Use);
	EndDo;

	DocumentKindList.SortByValue(SortDirection.Asc);

EndProcedure

&AtServer
Procedure ApplySettingsToListOfDocumentTypes(SettingValue)

	ReformatRequest = False;
	For Each Item In SettingValue Do

		ListItem = DocumentKindList.FindByValue(Item.Value);
		If ListItem <> Undefined And ListItem.Check <> Item.Check Then

			ListItem.Check = Item.Check;
			ReformatRequest = True;

		EndIf;

	EndDo;

	If ReformatRequest Then

		SetWhetherToUseDocumentType();

		UpdateRequestText();

		ShouldSaveSettings();

	EndIf;

EndProcedure

&AtClient
Procedure EditDocumentComposition()

	Result = Undefined;


	OpenForm(FormNameDocumentKindsContentSetting,
			New Structure("DocumentKindList", DocumentKindList),,,,, New CallbackDescription("EditDocumentCompositionCompletion", ThisObject), FormWindowOpeningMode.LockWholeInterface);

EndProcedure

&AtClient
Procedure EditDocumentCompositionCompletion(Result, AdditionalParameters) Export
    
    If TypeOf(Result) = Type("ValueList") Then
        
        ApplySettingsToListOfDocumentTypes(Result);
        
    EndIf;

EndProcedure

&AtServer
Procedure UpdateDocumentTableOnServer()

	If IsBlankString(QueryTextByDocuments) Then

		CommonClientServer.MessageToUser(NStr("vi = 'Cần tùy chỉnh thành phần chứng từ';
												|ru = 'Необходимо настроить состав документов';
												|en = 'It is necessary to set content of documents'; fa = 'It is necessary to set content of documents';
												|it = 'È necessario impostare la composizione dei documenti';
												|pl = 'Należy dostosować skład dokumentów';
												|tr = 'Belgelerin içeriğini ayarlamak gerekir'"),,"ThisForm");
		Return;

	EndIf;

	Query = New Query(QueryTextFilter);
	Query.SetParameter("Parameter",         Parameter);
	Query.SetParameter("BeginOfPeriod",    DocumentsSelectionPeriod.StartDate);
	Query.SetParameter("PeriodEnding", DocumentsSelectionPeriod.EndDate);
	Query.TempTablesManager  = New TempTablesManager;

	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);

	Query.Text = QueryTextByDocuments;

	ValueToFormAttribute(Query.Execute().Unload(), "DocumentsTable");

EndProcedure

#EndRegion

#EndRegion
