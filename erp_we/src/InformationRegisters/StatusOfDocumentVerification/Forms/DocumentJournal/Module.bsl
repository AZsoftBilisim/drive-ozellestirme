#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	URL = "e1cib/app/" + ThisObject.FormName;
	
	Items.TeamGroupDocumentVerification.Visible = AccessRight("Edit", Metadata.InformationRegisters.StatusOfDocumentVerification);
	
	UpdateSelectionByDocumentType();
	
	AllowModificationOfAuditedFinancialDocuments = GetFunctionalOption("AllowModificationOfAuditedFinancialDocuments");
	
	If Parameters.Property("EndingDateOfPeriod") And Not Parameters.EndingDateOfPeriod = '39991231' Then
		Period.EndDate = Parameters.EndingDateOfPeriod;
		SetSelectionByPeriod(List, Period);
	EndIf;
	
	Parameters.Filter.Property("Organization", Organization);
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Organization", 
		Organization, 
		,
		,
		ValueIsFilled(Organization));
	
	Parameters.Filter.Property("CheckStatus", CheckStatus);
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"CheckStatus",
		CheckStatus,
		,
		, 
		ValueIsFilled(CheckStatus));
	
	Items.Organization.Visible = GetFunctionalOption("UseMultipleCompanies");
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If StrFind(EventName, "Record_") > 0 Then
		Items.List.Refresh();
	EndIf;
		
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Not Exit Then
		Notify("DocumentListFormIsClosed");
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompanyFilterOnChange(Item)
	CommonClientServer.SetDynamicListFilterItem(List, "Organization", Organization, , , ValueIsFilled(Organization));
	AttachIdleHandler("ConfigureAccessibilityOfListButtons", 0.2, True);
EndProcedure

&AtClient
Procedure VerificationStatusSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"CheckStatus",
		CheckStatus,
		,
		, 
		ValueIsFilled(CheckStatus));
	
	AttachIdleHandler("ConfigureAccessibilityOfListButtons", 0.2, True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	ListLine = Items.List.CurrentData;
	ShowValue(Undefined, ListLine.Document);
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	AttachIdleHandler("ConfigureAccessibilityOfListButtons", 0.2, True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CancelVerification(Command)
	
	DocumentsArray = New Array;
	For Each ListLine In Items.List.SelectedRows Do
		Data = Items.List.RowData(ListLine);
		DocumentsArray.Add(Data.Document);
	EndDo;
	
	MessageAboutErrors = SetCheckStatusOnServerAndReturnErrors(DocumentsArray, False);
	
	If DocumentsArray.Count() > 0 Then
		Notify("Record_DocumentVerificationStatus", DocumentsArray, ThisObject);
	EndIf;
	
	If ValueIsFilled(MessageAboutErrors) Then
		CommonClient.MessageToUser(MessageAboutErrors);
	EndIf;
	ConfigureAccessibilityOfListButtons();
EndProcedure

&AtClient
Procedure Validate(Command)
	
	DocumentsArray = New Array;
	For Each ListLine In Items.List.SelectedRows Do
		Data = Items.List.RowData(ListLine);
		DocumentsArray.Add(Data.Document);
	EndDo;
	
	MessageAboutErrors = SetCheckStatusOnServerAndReturnErrors(DocumentsArray, True);
	
	If DocumentsArray.Count() > 0 Then
		Notify("Record_DocumentVerificationStatus", DocumentsArray, ThisObject);
	EndIf;
	
	If ValueIsFilled(MessageAboutErrors) Then
		CommonClient.MessageToUser(MessageAboutErrors);
	EndIf;
	ConfigureAccessibilityOfListButtons();
	
EndProcedure

&AtClient
Procedure FinancialAccountingPostings(Command)
	CurrentRow = Items.List.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	Document = CurrentRow.Document;
	
	Filter = New Structure("Recorder", Document);
	FormParameters = New Structure("Filter", Filter);
	OpenForm("DataProcessor.DocumentPostingInFinancialAccounting.Form.FinancialAccountingPostings",
		FormParameters,
		Command,
		Document);
	Return;
	
EndProcedure

&AtClient
Procedure PostingsOfReglAccounting(Command)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(Period, , Notification);
	
EndProcedure

&AtClient
Procedure SetDateIntervalCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	Period = ValueSelected;
	SetSelectionByPeriod(List, Period);
	AttachIdleHandler("ConfigureAccessibilityOfListButtons", 0.2, True);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();

	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CheckStatus.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.CheckStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không kiểm tra>';
													|ru = '<не проверяется>';
													|en = '<not under check>'; fa = '<not under check>';
													|it = '<non verificato>';
													|pl = '<nie jest sprawdzany>';
													|tr = '<denetlenmiyor>'"));
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Number.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Number");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có>';
													|ru = '<отсутствует>';
													|en = '<missing>'; fa = '<missing>';
													|it = '<assente>';
													|pl = '<missing>';
													|tr = '<eksik>'"));
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByPeriod(List, Period)
	
	CommonClientServer.SetDynamicListParameter(
		List, "BeginOfPeriod", Period.StartDate, ValueIsFilled(Period.StartDate)); 
	
	CommonClientServer.SetDynamicListParameter(
		List, "EndOfPeriod", Period.EndDate, ValueIsFilled(Period.EndDate)); 
		
EndProcedure

&AtServerNoContext
Function SetCheckStatusOnServerAndReturnErrors(DocumentsArray, CheckStatus)
	
	ErrorsString = "";
	ErrorsData = New Map;
	
	InformationRegisters.StatusOfDocumentVerification.SetStatusOfDocumentVerification(DocumentsArray, ErrorsData, CheckStatus);
	
	If ErrorsData.Count() Then
		
		For Each Error In ErrorsData Do
			ErrorsString = ErrorsString + Error.Value + ";" + Chars.LF;
			IndexOfErroneousDocumentInArray = DocumentsArray.Find(Error.Key);
			If Not IndexOfErroneousDocumentInArray = Undefined Then
				DocumentsArray.Delete(IndexOfErroneousDocumentInArray);
			EndIf;
		EndDo;
		
	EndIf;
	
	Return ErrorsString;
	
EndFunction

&AtClient
Procedure HelpTextFilterURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "UpdateSelection_" Then
		
		UpdateSelectionByDocumentType();
		
	ElsIf FormattedStringURL = "ConfigureFilter" Then
		
		FormParameters = New Structure();
		FormParameters.Insert("AvailableBusinessTransactionsAndDocuments", PlaceBusinessTransactionsAndDocumentsInTemporaryStorage());
		FormParameters.Insert("SettingsKey", PurposeUseKey);
		FormParameters.Insert("OnlyByDocumentTypes", True);
		FormParameters.Insert("FormKey", DefaultFormAssignmentKey());
		
		OpenForm("Catalog.BusinessTransactionsSettings.Form.FormOfFilterSetting",
			FormParameters,,,,,
			New CallbackDescription("EstablishSelectionsForBusinessTransactionsAndDocuments", 
			ThisObject));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure EstablishSelectionsForBusinessTransactionsAndDocuments(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(ValueSelected) = Type("String") Then
		
		AddressOfAvailableBusinessTransactionsAndDocuments = ValueSelected;
		
		SelectionOperationTypeSelectionProcessingServer(AddressOfAvailableBusinessTransactionsAndDocuments);
		ConnectHyperlinkWaitingHandlerToLayout();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ConnectHyperlinkWaitingHandlerToLayout()
	
	If ValueIsFilled(JobID) Then
		AttachIdleHandler("Attachable_CheckTaskCompletion", 1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureAccessibilityOfListButtons()
	
	CheckAvailability = False;
	CancelAvailabilityCheck = False;
	
	If Items.List.SelectedRows.Count() > 0 Then
		
		For Each ListLine In Items.List.SelectedRows Do
			RowData = Items.List.RowData(ListLine);
			If RowData = Undefined Then
				Continue;
			EndIf;
			
			VerificationStatusInLine = RowData.CheckStatus;
			If Not CheckAvailability Then
				CheckAvailability = 
					Not VerificationStatusInLine = PredefinedValue("Enum.StatusOfFinancialDocumentVerification.Verified")
					And Not VerificationStatusInLine = PredefinedValue("Enum.StatusOfFinancialDocumentVerification.EmptyRef");
			EndIf;
			If Not CancelAvailabilityCheck Then
				CancelAvailabilityCheck = 
					Not VerificationStatusInLine = PredefinedValue("Enum.StatusOfFinancialDocumentVerification.ToReCheck")
					And Not VerificationStatusInLine = PredefinedValue("Enum.StatusOfFinancialDocumentVerification.NotVerified")
					And Not VerificationStatusInLine = PredefinedValue("Enum.StatusOfFinancialDocumentVerification.EmptyRef");
			EndIf;
			
			If CheckAvailability
				And CancelAvailabilityCheck Then
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Items.ListValidate.Enabled = CheckAvailability;
	Items.ListCancelVerification.Enabled = CancelAvailabilityCheck;
	
EndProcedure
&AtServer
Procedure SelectionOperationTypeSelectionProcessingServer(AddressOfBusinessTransactionsAndDocuments)
	
	VTBusinessTransactionsAndDocumentTypes = GetFromTempStorage(AddressOfBusinessTransactionsAndDocuments);
	BusinessTransactionsAndDocuments.Load(VTBusinessTransactionsAndDocumentTypes);
	
	TKTypesOfDocuments = VTBusinessTransactionsAndDocumentTypes.Copy(New Structure("Filter", True), "DocumentType");
	TKTypesOfDocuments.GroupBy("DocumentType");
	
	FilterDocumentTypes.LoadValues(TKTypesOfDocuments.UnloadColumn("DocumentType"));
	
	ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes);
	
EndProcedure

&AtServer
Procedure ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes)
	
	WorkplaceData = TMCommonUse.WorkplaceData(VTBusinessTransactionsAndDocumentTypes,
		DefaultFormAssignmentKey(), NStr("vi = 'Nhật ký chứng từ được kiểm tra';
										|ru = 'Журнал проверяемых документов';
										|en = 'Journal of documents to check'; fa = 'دفتر اسناد برای بررسی';
										|it = 'Registro dei documenti verificati';
										|pl = 'Dziennik sprawdzanych dokumentów';
										|tr = 'Kontrol edilen belgelerin günlüğü'"));
	
	Title   = WorkplaceData.WorkplaceTitle;
	CurrentKey = WorkplaceData.PurposeUseKey;
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"DocumentType",
		FilterDocumentTypes,
		DataCompositionComparisonType.InList,
		,
		True);
	
	HelpTextFilter = "";
	
	If VTBusinessTransactionsAndDocumentTypes.Count() = 0 Then
		
		HelpTextFilter = StringFunctions.FormattedString(
											NStr("vi = 'Không có chứng từ để hiển thị trong nhật ký <a href=""%1"">Cập nhật</a>';
												|ru = 'Нет документов для отображения в журнале <a href=""%1"">Обновить</a>';
												|en = 'No documents to record in journal <a href=""%1"">Update</a>'; fa = 'No documents to record in journal <a href=""%1"">Update</a>';
												|it = 'Нет документов для отображения в журнале <a href=""%1"">Обновить</a>';
												|pl = 'No documents to record in journal <a href=""%1"">Update</a>';
												|tr = '<a href=""%1"">Yenile</a> günlüğünde görüntülenecek belge yok'"),
											"UpdateSelection_");
	Else
		
		ThereAreSelections = BusinessTransactionsAndDocuments.FindRows(New Structure("Filter",False)).Count() > 0;
		If ThereAreSelections Then
			
			NumberOfDocumentTypes = StringFunctionsClientServer.StringWithNumberForAnyLanguage(NStr("vi = ';%1 chứng từ;;%1 chứng từ;%1 chứng từ;%1 chứng từ';
																									|ru = ';%1 документ;;%1 документа;%1 документов;%1 документа';
																									|en = ';%1 document;;%1 document;%1 documents;%1 document'; fa = ';%1 document;;%1 document;%1 documents;%1 document';
																									|it = ';%1 documento;;%1 documenti;%1 documenti;%1 documento';
																									|pl = ';%1 dokument;;%1 dokumenty;%1 dokumentów;%1 dokumenty';
																									|tr = ';%1 belge;;%1 belgenin;%1 belgelerin;%1 belgenin'"), FilterDocumentTypes.Count());
			
			HelpTextFilter = StringFunctions.FormattedString(
												NStr("vi = 'Hiển thị %1 <a href=""%2"">Tùy chỉnh</a>';
													|ru = 'Показаны %1 <a href=""%2"">Настроить</a>';
													|en = 'Shown %1 <a href=""%2"">Set up</a>'; fa = 'Shown %1 <a href=""%2"">Set up</a>';
													|it = 'Показаны %1 <a href=""%2"">Настроить</a>';
													|pl = 'Shown %1 <a href=""%2"">Set up</a>';
													|tr = '%1 <a href=""%2"">Ayarla</a> gösterildi'"),
												NumberOfDocumentTypes, "ConfigureFilter");
			
		Else
			
			HelpTextFilter = StringFunctions.FormattedString(
											NStr("vi = 'Hiển thị tất cả chứng từ trong nhật ký <a href=""%1"">Tùy chỉnh</a>';
												|ru = 'Показаны все документы журнала <a href=""%1"">Настроить</a>';
												|en = 'All journal documents are shown <a href=""%1"">Set up</a>'; fa = 'All journal documents are shown <a href=""%1"">Set up</a>';
												|it = 'Показаны все документы журнала <a href=""%1"">Настроить</a>';
												|pl = 'All journal documents are shown <a href=""%1"">Set up</a>';
												|tr = 'Tüm defter belgeleri gösterildi <a href=""%1"">Ayarla</a>'"),
											"ConfigureFilter");
			
		EndIf;
	
	EndIf;
	
	Items.HelpTextFilter.Title = HelpTextFilter;
	
EndProcedure

&AtServer
Function PlaceBusinessTransactionsAndDocumentsInTemporaryStorage()
	Return PutToTempStorage(BusinessTransactionsAndDocuments.Unload(), UUID);
EndFunction

&AtClientAtServerNoContext
Function DefaultFormAssignmentKey()
	
	Return "LogOfDocumentsBeingChecked";
	
EndFunction

&AtServer
Procedure UpdateSelectionByDocumentType()
	
	FilterDocumentTypes.Clear();
	ArrayOfDocumentNames = New Array;
	For Each DocumentType In Metadata.InformationRegisters.StatusOfDocumentVerification.Dimensions.Document.Type.Types() Do
		MetadataObject = Metadata.FindByType(DocumentType);
		If Not Common.MetadataObjectAvailableByFunctionalOptions(MetadataObject) Then
			Continue;
		EndIf;
		NewRow = BusinessTransactionsAndDocuments.Add();
		NewRow.FullDocumentName = MetadataObject.FullName();
		NewRow.Filter = True;
		NewRow.DocumentType = Type("DocumentRef." + MetadataObject.Name);
		NewRow.DocumentPresentation = MetadataObject.Synonym;
		
		FilterDocumentTypes.Add(NewRow.DocumentType);
		ArrayOfDocumentNames.Add(NewRow.FullDocumentName);
	EndDo;
	
	MetadataObjectIDs = Common.MetadataObjectIDs(ArrayOfDocumentNames);
	For Each TableRow In BusinessTransactionsAndDocuments Do
		TableRow.MetadataObjectID = MetadataObjectIDs[TableRow.FullDocumentName];
	EndDo;
	
	ConfigureFormForSelectedOperationsAndDocuments(BusinessTransactionsAndDocuments.Unload());
	
EndProcedure

#EndRegion
