///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

// A form for customizing the registration of object changes on the given node.
// Form parameters:
// 
// ExchangeNode - ExchangePlanRef - Reference to the exchange node.
// SelectExchangeNodeProhibited - Boolean - Flag indicating whether the user is not allowed to edit the node.
//                                                  Requires the "ExchangeNode" parameter.
// NamesOfMetadataToHide - ValueList - Names of metadata objects to hide from the registration tree.
//                                                  The subsystem "AdditionalReportsAndDataProcessors" supports additional parameters:
//
// AdditionalDataProcessorRef - Arbitrary - Reference to a catalog item that is calling the form.
//
// Requires the "RelatedObjects" parameter.
//                                                RelatedObjects - Array - Objects to be processed. The first array element will be used to
//                                                open the form for registering the object on the nodes.
// Requires the "CommandID" parameter.
//                                                
//                                                
//

#Region Variables

&AtClient
Var MetadataCurrentRow;

#EndRegion

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AdditionalReportsAndDataProcessors

// APK:78-off additional processing

// Command export handler for the additional reports and data processors subsystem.
//
// Parameters:
//     CommandID - String - command ID to execute.
//     RelatedObjects    - Array of AnyRef - references to process. This parameter is not used in the current procedure,
//                            expected that a similar parameter is passed and processed during the from creation.
//     CreatedObjects     - Array of AnyRef - a return value, an array of references to created objects. 
//                            This parameter is not used in the current data processor.
//
&AtClient
Procedure ExecuteCommand(CommandID, RelatedObjects, CreatedObjects) Export
	
	If CommandID = "OpenRegistrationEditingForm" Then
		
		If RegistrationObjectParameter <> Undefined Then
			// Using parameters that are set in the OnCreateAtServer procedure.
			
			RegistrationFormParameters = New Structure;
			RegistrationFormParameters.Insert("RegistrationObject",  RegistrationObjectParameter);
			RegistrationFormParameters.Insert("RegistrationTable", RegistrationTableParameter);

			OpenForm(ThisFormName + "Form.ObjectRegistrationNodes", RegistrationFormParameters);
		EndIf;
		
	EndIf;
	
EndProcedure
// ACC:78-on

// End StandardSubsystems.AdditionalReportsAndDataProcessors

#EndRegion

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	CheckPlatformVersionAndCompatibilityMode();
	
	RegistrationTableParameter = Undefined;
	RegistrationObjectParameter  = Undefined;
	
	OpenWithNodeParameter = False;
	CurrentObject = ThisObject();
	ThisFormName = GetFormName();
	// Analyze form parameters and setting options.
	If Parameters.AdditionalDataProcessorRef = Undefined Then
		// Starting the data processor in standalone mode, with the ExchangeNodeRef parameter specified.
		ExchangeNodeReference = Parameters.ExchangeNode;
		Parameters.Property("SelectExchangeNodeProhibited", SelectExchangeNodeProhibited);
		OpenWithNodeParameter = True;
		
	Else
		// This data processor is called from the additional reports and data processors subsystem.
		If TypeOf(Parameters.RelatedObjects) = Type("Array") And Parameters.RelatedObjects.Count() > 0 Then
			
			// The form is opened with the specified object.
			RelatedObject = Parameters.RelatedObjects[0];
			Type = TypeOf(RelatedObject);
			
			If ExchangePlans.AllRefsType().ContainsType(Type) Then
				ExchangeNodeReference = RelatedObject;
				OpenWithNodeParameter = True;
			Else
				// Filling internal attributes.
				LongDesc = CurrentObject.MetadataCharacteristics(RelatedObject.Metadata());
				If LongDesc.IsReference Then
					RegistrationObjectParameter = RelatedObject;
					
				ElsIf LongDesc.IsRecordsSet Then
					// Structure and table name
					RegistrationTableParameter = LongDesc.TableName;
					RegistrationObjectParameter  = New Structure;
					For Each Dimension In CurrentObject.RecordSetDimensions(RegistrationTableParameter) Do
						CurName = Dimension.Name;
						RegistrationObjectParameter.Insert(CurName, RelatedObject.Filter[CurName].Value);
					EndDo;
					
				EndIf;
			EndIf;
			
		Else
			Raise StrReplace(
				NStr("vi = 'Sai tham số đối tượng chỉ định mở lệnh ""%1""';
					|ru = 'Некорректные параметры объектов назначения открытия команды ""%1""';
					|en = 'Invalid destination object parameters for the ""%1"" command'; fa = 'Invalid destination object parameters for the ""%1"" command';
					|it = 'Parametri errati degli oggetti di assegnazione dell''apertura comando ""%1""';
					|pl = 'Nieprawidłowe ustawienia obiektów przeznaczenia otwarcia polecenia ""%1""';
					|tr = '""%1"" komutu için geçersiz hedef nesne parametreleri'"),
				"%1", Parameters.CommandID);
		EndIf;
		
	EndIf;
	
	// Initializing object settings.
	CurrentObject.ReadSettings();
	CurrentObject.ReadSSLSupportFlags();
	CurrentObject.ReadSignsOfBSDSupport();
	ThisObject(CurrentObject);
	
	// Initializing other parameters only if this form will be opened
	If RegistrationObjectParameter <> Undefined Then
		Return;
	EndIf;
	Items.GroupPages.CurrentPage = Items.Main;
	// Filling the list of prohibited metadata objects based on form parameters.
	Parameters.Property("NamesOfMetadataToHide", Object.NamesOfMetadataToHide);
	AddNameOfMetadataToHide();
	
	Items.ObjectsListOptions.CurrentPage = Items.BlankPage;
	Parameters.Property("SelectExchangeNodeProhibited", SelectExchangeNodeProhibited);
	
	ExchangePlanNodeDescription = String(ExchangeNodeReference);
	
	FillAdditionalInformation();
	
	If Not ControlSettings() And OpenWithNodeParameter Then
		
		MessageText = StrReplace(
			NStr("vi = 'Đối với ""%1"" không cho phép chỉnh sửa ghi nhận đối tượng.';
				|ru = 'Для ""%1"" редактирование регистрации объектов недоступно.';
				|en = 'Cannot change item registration state for node ""%1"".'; fa = 'Cannot change item registration state for node ""%1"".';
				|it = 'Per ""%1"" la modifica della registrazione oggetti non è disponibile.';
				|pl = 'Dla ""%1"" edytowanie rejestracji obiektów jest niedostępne.';
				|tr = '""%1"" ünitesi için öğe hazırlama durumu değiştirilemiyor.'"),
			"%1", ExchangePlanNodeDescription);
		
		Raise MessageText;
		
	EndIf;
		
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	If ForceCloseForm Then
		Return;
	EndIf;
	
	If TimeConsumingOperationStarted Then
		Cancel = True;
		Notification = New CallbackDescription("ConfirmFormClosingCompletion", ThisObject);
		ShowQueryBox(Notification, NStr("vi = 'Ngắt thực hiện ghi nhận dữ liệu?';
										|ru = 'Прервать выполнение регистрации данных?';
										|en = 'Abort registration?'; fa = 'Abort registration?';
										|it = 'Interrompere l''esecuzione della registrazione dei dati?';
										|pl = 'Przerwać rejestrowanie danych?';
										|tr = 'Verilerin kaydı iptal edilsin mi?'"), QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	If TimeConsumingOperationStarted Then
		EndExecutingTimeConsumingOperation(IDBackgroundJob);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If Not (TypeOf(ChoiceSource) = Type("ClientApplicationForm")
			And ChoiceSource.UniqueKey = QueryResultChoiceFormUniqueKey) Then
		Return;
	EndIf;
	
	// Analyzing selected value, it must be a structure.
	If TypeOf(ValueSelected) <> Type("Structure") 
		Or (Not ValueSelected.Property("ChoiceAction"))
		Or (Not ValueSelected.Property("ChoiceData"))
		Or TypeOf(ValueSelected.ChoiceAction) <> Type("Boolean")
		Or TypeOf(ValueSelected.ChoiceData) <> Type("String") Then
		Error = NStr("vi = 'Kết quả lựa chọn không mong muốn từ Bảng điều khiển truy vấn';
					|ru = 'Неожиданный результат выбора из консоли запросов';
					|en = 'Unexpected query result'; fa = 'Unexpected query result';
					|it = 'Risultato imprevisto della selezione dalla console di richieste';
					|pl = 'Nieoczekiwany wynik wyboru z konsoli zapytań';
					|tr = 'Beklenmeyen sorgu sonucu'");
	Else
		Error = RefControlForQuerySelection(ValueSelected.ChoiceData);
	EndIf;
	
	If Error <> "" Then 
		ShowMessageBox(,Error);
		Return;
	EndIf;
		
	If ValueSelected.ChoiceAction Then
		Text = NStr("vi = 'Ghi nhận kết quả truy vấn
		                 |tại nút ""%1""?';
		                 |ru = 'Зарегистрировать результат запроса
		                 |на узле ""%1""?';
		                 |en = 'Do you want to register the query result
		                 |at node ""%1""?'; fa = 'Do you want to register the query result
		                 |at node ""%1""?';
		                 |it = 'Registrare il risultato della richiesta
		                 |al nodo ""%1""?';
		                 |pl = 'Zarejestrować wynik zapytania 
		                 |na węźle ""%1""?';
		                 |tr = '""%1"" ünitesinde
		                 |sorgu sonucu hazırlansın mı?'"); 
	Else
		Text = NStr("vi = 'Hủy ghi nhận kết quả truy vấn
		                 |tại nút ""%1""?';
		                 |ru = 'Отменить регистрацию результата запроса
		                 |на узле ""%1""?';
		                 |en = 'Do you want to unregister the query result
		                 |at node ""%1""?'; fa = 'Do you want to unregister the query result
		                 |at node ""%1""?';
		                 |it = 'Annullare la registrazione del risultato della richiesta
		                 |al nodo ""%1""?';
		                 |pl = 'Anulować rejestrację wyniku zapytania
		                 |na węźle ""%1""?';
		                 |tr = '""%1"" ünitesinde
		                 |sorgu sonucu kaldırılsın mı?'");
	EndIf;
	Text = StrReplace(Text, "%1", String(ExchangeNodeReference));
					 
	QuestionTitle = NStr("vi = 'Xác nhận';
						|ru = 'Подтверждение';
						|en = 'Confirm operation'; fa = 'Confirm operation';
						|it = 'Conferma';
						|pl = 'Potwierdzenie';
						|tr = 'Parolayı doğrula'");
	
	Notification = New CallbackDescription("ChoiceProcessingCompletion", ThisObject, New Structure);
	Notification.AdditionalParameters.Insert("ValueSelected", ValueSelected);
	ShowQueryBox(Notification, Text, QuestionDialogMode.YesNo, , , QuestionTitle);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ObjectDataExchangeRegistrationEdit" Then
		FillRegistrationCountInTreeRows();
		UpdatePageContent();

	ElsIf EventName = "ExchangeNodeDataEdit" And ExchangeNodeReference = Parameter Then
		SetMessageNumberTitle();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	// Automatic settings.
	CurrentObject = ThisObject();
	CurrentObject.ShouldSaveSettings();
	ThisObject(CurrentObject);
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If RegistrationObjectParameter <> Undefined Then
		// Another form will be used.
		Return;
	EndIf;
	
	If ValueIsFilled(Parameters.ExchangeNode) Then
		ExchangeNodeReference = Parameters.ExchangeNode;
	Else
		ExchangeNodeReference = Settings["ExchangeNodeReference"];
		DataVersion = Common.ObjectAttributeValue(ExchangeNodeReference, "DataVersion");
		// If restored exchange node is deleted, clearing the ExchangeNodeRef value.
		If ExchangeNodeReference <> Undefined 
		    And ExchangePlans.AllRefsType().ContainsType(TypeOf(ExchangeNodeReference))
		    And IsBlankString(DataVersion) Then
			ExchangeNodeReference = Undefined;
		EndIf;
	EndIf;
	
	ControlSettings();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers
//

&AtClient
Procedure ExchangeNodeReferenceStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	CurFormName = ThisFormName + "Form.SelectExchangePlanNode";
	CurParameters = New Structure("MultipleChoice, ChoiceInitialValue", False, ExchangeNodeReference);
	OpenForm(CurFormName, CurParameters, Item);
EndProcedure

&AtClient
Procedure ExchangeNodeReferenceChoiceProcessing(Item, ValueSelected, StandardProcessing)
	If ExchangeNodeReference <> ValueSelected Then
		ExchangeNodeReference = ValueSelected;
		AttachIdleHandler("ExchangeNodeChoiceProcessing", 0.1, True);
	EndIf;
EndProcedure

&AtClient
Procedure ExchangeNodeReferenceOnChange(Item)
	ExchangeNodeChoiceProcessingServer();
	ExpandMetadataTree();
	UpdatePageContent();
EndProcedure

&AtClient
Procedure ExchangeNodeReferenceClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure FilterByMessageNumberOptionOnChange(Item)
	SetFiltersInDynamicLists();
	UpdatePageContent();
EndProcedure

&AtClient
Procedure ObjectsListOptionsOnCurrentPageChange(Item, CurrentPage)
	UpdatePageContent(CurrentPage);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMetadataTree
//

&AtClient
Procedure MetadataTreeCheckOnChange(Item)
	ChangeMark(Items.MetadataTree.CurrentRow);
EndProcedure

&AtClient
Procedure MetadataTreeOnActivateRow(Item)
	If Items.MetadataTree.CurrentRow <> MetadataCurrentRow Then
		MetadataCurrentRow  = Items.MetadataTree.CurrentRow;
		AttachIdleHandler("SetUpChangeEditing", 0.1, True);
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersConstantsList

&AtClient
Procedure ConstantsListOnActivateRow(Item)
	
	CommandAvailability = Items.ConstantsList.SelectedRows.Count() > 0;
	Items.ShowExportResult.Enabled = CommandAvailability;
	
EndProcedure

&AtClient
Procedure ConstantsListChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	Result = AddRegistrationAtServer(True, ValueSelected);
	Items.ConstantsList.Refresh();
	FillRegistrationCountInTreeRows();
	ReportRegistrationResults(Result);
	
	If TypeOf(ValueSelected) = Type("Array") And ValueSelected.Count() > 0 Then
		Item.CurrentRow = ValueSelected[0];
	Else
		Item.CurrentRow = ValueSelected;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReferenceList

&AtClient
Procedure ReferenceListOnActivateRow(Item)
	
	CommandAvailability = Items.ReferenceList.SelectedRows.Count() > 0;
	Items.ShowExportResult.Enabled = CommandAvailability;
	
EndProcedure

&AtClient
Procedure ReferenceListSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	CurrentRef = CurrentRefsListData().Ref;
	If Not ValueIsFilled(CurrentRef)
		Or Not ValueIsFilled(ReferencesListTableName) Then
		Return;
	EndIf;
	ParametersStructure = New Structure("Key, ReadOnly", CurrentRef, True);
	If IsFolder(CurrentRef) Then
		OpenForm(ReferencesListTableName + ".FolderForm", ParametersStructure, ThisObject);	
	Else
		OpenForm(ReferencesListTableName + ".ObjectForm", ParametersStructure, ThisObject);
	EndIf;

EndProcedure

&AtServer
Function IsFolder(Ref)
	
	MetadataObject = Ref.GetObject().Metadata();
	
	If (Metadata.Catalogs.Contains(MetadataObject) Or Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject))
		And MetadataObject.Hierarchical 
		And MetadataObject.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems Then
		
		If Metadata.Catalogs.Contains(MetadataObject) Then
			TableName = "Catalog." + MetadataObject.Name;
		Else
			TableName = "ChartOfCharacteristicTypes." + MetadataObject.Name;
		EndIf;
		
	Else
		
		Return False;
		
	EndIf;
	
	QueryText = 
		"SELECT
		|	Table.Ref AS Ref
		|FROM
		|	#Table AS Table
		|WHERE
		|	Table.IsFolder
		|	AND Table.Ref = &Ref";
					
	QueryText1 = StrReplace(QueryText, "#Table", TableName);

	Query = New Query(QueryText1);
	Query.SetParameter("Ref", Ref);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

&AtClient
Procedure ReferenceListChoiceProcessing(Item, ValueSelected, StandardProcessing)
	DataChoiceProcessing(Item, ValueSelected);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRecordSetsList

&AtClient
Procedure RecordSetsListOnActivateRow(Item)
	
	CommandAvailability = Items.RecordSetsList.SelectedRows.Count() > 0;
	Items.ShowExportResult.Enabled = CommandAvailability;
	
EndProcedure

&AtClient
Procedure RecordSetsListSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	
	WriteParameters = RecordSetKeyStructure(Item.CurrentData);
	If WriteParameters <> Undefined Then
		OpenForm(WriteParameters.FormName, New Structure(WriteParameters.Parameter, WriteParameters.Value));
	EndIf;
	
EndProcedure

&AtClient
Procedure RecordSetsListChoiceProcessing(Item, ValueSelected, StandardProcessing)
	DataChoiceProcessing(Item, ValueSelected);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers
//

&AtClient
Procedure AddRegistrationForSingleObject(Command)
	
	If Not ValueIsFilled(ExchangeNodeReference) Then
		Return;
	EndIf;
	
	CurrRow = Items.ObjectsListOptions.CurrentPage;
	If CurrRow = Items.ConstantsPage Then
		AddConstantRegistrationInList();
		
	ElsIf CurrRow = Items.ReferencesListPage Then
		AddRegistrationInReferenceList();
		
	ElsIf CurrRow = Items.RecordSetPage Then
		AddRegistrationToRecordSetFilter();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteRegistrationForSingleObject(Command)
	
	If Not ValueIsFilled(ExchangeNodeReference) Then
		Return;
	EndIf;
	
	CurrRow = Items.ObjectsListOptions.CurrentPage;
	If CurrRow = Items.ConstantsPage Then
		DeleteConstantRegistrationInList();
		
	ElsIf CurrRow = Items.ReferencesListPage Then
		DeleteRegistrationFromReferenceList();
		
	ElsIf CurrRow = Items.RecordSetPage Then
		DeleteRegistrationInRecordSet();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddRegistrationFilter(Command)
	
	If Not ValueIsFilled(ExchangeNodeReference) Then
		Return;
	EndIf;
	
	CurrRow = Items.ObjectsListOptions.CurrentPage;
	If CurrRow = Items.ReferencesListPage Then
		AddRegistrationInListFilter();
		
	ElsIf CurrRow = Items.RecordSetPage Then
		AddRegistrationToRecordSetFilter();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteRegistrationFilter(Command)
	
	If Not ValueIsFilled(ExchangeNodeReference) Then
		Return;
	EndIf;
	
	CurrRow = Items.ObjectsListOptions.CurrentPage;
	If CurrRow = Items.ReferencesListPage Then
		DeleteRegistrationInListFilter();
		
	ElsIf CurrRow = Items.RecordSetPage Then
		DeleteRegistrationInRecordSetFilter();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenNodeRegistrationForm(Command)
	
	If SelectExchangeNodeProhibited Then
		Return;
	EndIf;
		
	Data = GetCurrentObjectToEdit();
	If Data <> Undefined Then
		RegistrationTable = ?(TypeOf(Data) = Type("Structure"), RecordSetsListTableName, "");
		OpenForm(ThisFormName + "Form.ObjectRegistrationNodes",
			New Structure("RegistrationObject, RegistrationTable, NotifyAboutChanges", 
				Data, RegistrationTable, True), ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowExportResult(Command)
	
	CurrentPage = Items.ObjectsListOptions.CurrentPage;
	Result = New Array;
	
	If CurrentPage = Items.ConstantsPage Then 
		FormItem = Items.ConstantsList;
		For Each String In FormItem.SelectedRows Do
			curData = FormItem.RowData(String);
			Result.Add(New Structure("TypeFlag, Data", 1, curData.MetaFullName));
		EndDo;
		
	ElsIf CurrentPage = Items.RecordSetPage Then
		MeasurementList = RecordSetKeyNameArray(RecordSetsListTableName);
		FormItem = Items.RecordSetsList;
		Prefix = "RecordSetsList";
		For Each Item In FormItem.SelectedRows Do
			curData = New Structure();
			Data = FormItem.RowData(Item);
			For Each Name In MeasurementList Do
				If Data.Property(Prefix + Name) Then 
					curData.Insert(Name, Data[Prefix + Name]);
				EndIf;
			EndDo;
			Result.Add(New Structure("TypeFlag, Data", 2, curData));
		EndDo;
		
	ElsIf CurrentPage = Items.ReferencesListPage Then
		FormItem = Items.ReferenceList;
		For Each Item In FormItem.SelectedRows Do
			curData = FormItem.RowData(Item); // See CurrentRefsListData
			Result.Add(New Structure("TypeFlag, Data", 3, curData.Ref));
		EndDo;
		
	Else
		Return;
		
	EndIf;
	
	If Result.Count() > 0 Then
		Text = SerializationText(Result);
		TextTitle = NStr("vi = 'Kết quả kết xuất chuẩn (CSTTPT)';
						|ru = 'Результат стандартной выгрузки (РИБ)';
						|en = 'Export result (DIB)'; fa = 'نتیجه خروج اطلاعات (DIB)';
						|it = 'Risultato di upload standard (Database distribuito)';
						|pl = 'Rezultat przesyłania standardowego (RBI)';
						|tr = 'Dışa aktarım sonucu (DIB)'");
		Text.Show(TextTitle);
	EndIf;
	
EndProcedure

&AtClient
Procedure EditMessagesNumbers(Command)
	
	If ValueIsFilled(ExchangeNodeReference) Then
		CurFormName = ThisFormName + "Form.ExchangePlanNodeMessageNumbers";
		CurParameters = New Structure("ExchangeNodeReference", ExchangeNodeReference);
		OpenForm(CurFormName, CurParameters, ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure AddConstantRegistration(Command)
	If ValueIsFilled(ExchangeNodeReference) Then
		AddConstantRegistrationInList();
	EndIf;
EndProcedure

&AtClient
Procedure DeleteConstantRegistration(Command)
	If ValueIsFilled(ExchangeNodeReference) Then
		DeleteConstantRegistrationInList();
	EndIf;
EndProcedure

&AtClient
Procedure AddRefRegistration(Command)
	If ValueIsFilled(ExchangeNodeReference) Then
		AddRegistrationInReferenceList();
	EndIf;
EndProcedure

&AtClient
Procedure AddObjectDeletionRegistration(Command)
	If ValueIsFilled(ExchangeNodeReference) Then
		AddObjectDeletionRegistrationInReferenceList();
	EndIf;
EndProcedure

&AtClient
Procedure DeleteRefRegistration(Command)
	If ValueIsFilled(ExchangeNodeReference) Then
		DeleteRegistrationFromReferenceList();
	EndIf;
EndProcedure

&AtClient
Procedure AddRefRegistrationPickup(Command)
	If ValueIsFilled(ExchangeNodeReference) Then
		AddRegistrationInReferenceList(True);
	EndIf;
EndProcedure

&AtClient
Procedure AddRefRegistrationFilter(Command)
	If ValueIsFilled(ExchangeNodeReference) Then
		AddRegistrationInListFilter();
	EndIf;
EndProcedure

&AtClient
Procedure DeleteRefRegistrationFilter(Command)
	If ValueIsFilled(ExchangeNodeReference) Then
		DeleteRegistrationInListFilter();
	EndIf;
EndProcedure

&AtClient
Procedure AddRegistrationForAutoObjects(Command)
	If ValueIsFilled(ExchangeNodeReference) Then
		AddSelectedObjectRegistration(False);
	EndIf;
EndProcedure

&AtClient
Procedure DeleteRegistrationForAutoObjects(Command)
	If ValueIsFilled(ExchangeNodeReference) Then
		DeleteSelectedObjectRegistration(False);
	EndIf;
EndProcedure

&AtClient
Procedure AddRegistrationForAllObjects(Command)
	If ValueIsFilled(ExchangeNodeReference) Then
		AddSelectedObjectRegistration();
	EndIf;
EndProcedure

&AtClient
Procedure DeleteRegistrationForAllObjects(Command)
	If ValueIsFilled(ExchangeNodeReference) Then
		DeleteSelectedObjectRegistration();
	EndIf;
EndProcedure

&AtClient
Procedure AddRecordSetRegistrationFilter(Command)
	If ValueIsFilled(ExchangeNodeReference) Then
		AddRegistrationToRecordSetFilter();
	EndIf;
EndProcedure

&AtClient
Procedure DeleteRecordSetRegistration(Command)
	If ValueIsFilled(ExchangeNodeReference) Then
		DeleteRegistrationInRecordSet();
	EndIf;
EndProcedure

&AtClient
Procedure DeleteRecordSetRegistrationFilter(Command)
	If ValueIsFilled(ExchangeNodeReference) Then
		DeleteRegistrationInRecordSetFilter();
	EndIf;
EndProcedure

&AtClient
Procedure UpdateAllData(Command)
	FillRegistrationCountInTreeRows();
	UpdatePageContent();
EndProcedure

&AtClient
Procedure AddQueryResultRegistration(Command)
	If ValueIsFilled(ExchangeNodeReference) Then
		ActionWithQueryResult(True);
	EndIf;
EndProcedure

&AtClient
Procedure DeleteQueryResultRegistration(Command)
	If ValueIsFilled(ExchangeNodeReference) Then
		ActionWithQueryResult(False);
	EndIf;
EndProcedure

&AtClient
Procedure OpenSettingsForm(Command)
	OpenDataProcessorSettingsForm();
EndProcedure

&AtClient
Procedure EditObjectMessageNumber(Command)
	
	If Items.ObjectsListOptions.CurrentPage = Items.ConstantsPage Then
		EditConstantMessageNo();
		
	ElsIf Items.ObjectsListOptions.CurrentPage = Items.ReferencesListPage Then
		EditRefMessageNo();
		
	ElsIf Items.ObjectsListOptions.CurrentPage = Items.RecordSetPage Then
		EditMessageNoSetList()
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RegisterMOIDAndPredefinedItems(Command)
	
	QuestionTitle = NStr("vi = 'Xác nhận';
						|ru = 'Подтверждение';
						|en = 'Confirm operation'; fa = 'Confirm operation';
						|it = 'Conferma';
						|pl = 'Potwierdzenie';
						|tr = 'Parolayı doğrula'");
	QueryText     = StrReplace( 
		NStr("vi = 'Ghi nhận dữ liệu để phục hồi nút CSTTPT trực thuộc
		     |tại nút ""%1""?';
		     |ru = 'Зарегистрировать данные для восстановления подчиненного узла РИБ
		     |на узле ""%1""?';
		     |en = 'Do you want to register items to recover the DIB subnode
		     |at node ""%1""?'; fa = 'Do you want to register items to recover the DIB subnode
		     |at node ""%1""?';
		     |it = 'Registrare i dati per ripristinare il nodo subordinato del database informatico distribuito
		     |sul nodo ""%1""?';
		     |pl = 'Zarejestrować dane dla przywrócenia podwładnego węzła RBI
		     |na węźle ""%1""?';
		     |tr = '""%1"" ünitesinde
		     |DIB alt ünitesini kurtarmak için öğeler hazırlansın mı?'"),
		"%1", ExchangeNodeReference);
	
	Notification = New CallbackDescription("RegisterMetadataObjectIDCompletion", ThisObject);
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo, , , QuestionTitle);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ConfirmFormClosingCompletion(QuestionResult, AdditionalParameters) Export
	
	If Not QuestionResult = DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ForceCloseForm = True;
	Close();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReferenceListMessageNo.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReferenceList.NotExported");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.LightGray);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Chưa kết xuất';
													|ru = 'Не выгружалось';
													|en = 'Pending export'; fa = 'Pending export';
													|it = 'Non è stato scaricato';
													|pl = 'Nie przesyłano';
													|tr = 'Dışa aktarılmadı'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ConstantsListMessageNo.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ConstantsList.NotExported");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.LightGray);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Chưa kết xuất';
													|ru = 'Не выгружалось';
													|en = 'Pending export'; fa = 'Pending export';
													|it = 'Non è stato scaricato';
													|pl = 'Nie przesyłano';
													|tr = 'Dışa aktarılmadı'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RecordSetsListMessageNo.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RecordSetsList.NotExported");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.LightGray);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Chưa kết xuất';
													|ru = 'Не выгружалось';
													|en = 'Pending export'; fa = 'Pending export';
													|it = 'Non è stato scaricato';
													|pl = 'Nie przesyłano';
													|tr = 'Dışa aktarılmadı'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MetadataTreeChangeCountString.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MetadataTree.ChangeCount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không thay đổi';
													|ru = 'Нет изменений';
													|en = 'Unchanged'; fa = 'بدون تغییر';
													|it = 'Nessuna modifica';
													|pl = 'Bez zmian';
													|tr = 'Değişiklik yok'"));
	
EndProcedure
//

// Dialog continuation notification handler.
&AtClient 
Procedure RegisterMetadataObjectIDCompletion(Val QuestionResult, Val AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ReportRegistrationResults(RegisterMOIDAndPredefinedItemsAtServer() );
		
	FillRegistrationCountInTreeRows();
	UpdatePageContent();
EndProcedure

// Dialog continuation notification handler.
&AtClient 
Procedure ChoiceProcessingCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return
	EndIf;
	ValueSelected = AdditionalParameters.ValueSelected;
	If Object.AsynchronousRegistrationAvailable Then
		BackgroundJobParameters = PrepareRegistrationChangeParameters(ValueSelected.ChoiceAction, 
		AdditionalParameters.Property("NoAutoRegistration") And AdditionalParameters.NoAutoRegistration,
		Undefined);
		BackgroundJobParameters.Insert("AddressData2", ValueSelected.ChoiceData);
		BackgroundJobStartClient(BackgroundJobParameters);
	Else
		ReportRegistrationResults(ChangeQueryResultRegistrationServer(ValueSelected.ChoiceAction, ValueSelected.ChoiceData));
		
		FillRegistrationCountInTreeRows();
		UpdatePageContent();
	EndIf;
EndProcedure

&AtClient
Procedure EditConstantMessageNo()
	curData = Items.ConstantsList.CurrentData;
	If curData = Undefined Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("EditConstantMessageNoCompletion", ThisObject, New Structure);
	Notification.AdditionalParameters.Insert("MetaFullName", curData.MetaFullName);
	
	MessageNo = curData.MessageNo;
	ToolTip = NStr("vi = 'Số đã gửi';
					|ru = 'Номер отправленного';
					|en = 'Sent message number'; fa = 'شماره پیام ارسال‌شده';
					|it = 'Numero dell''inviato';
					|pl = 'Numer wysłanej';
					|tr = 'Gönderilen mesajın numarası'"); 
	
	ShowInputNumber(Notification, MessageNo, ToolTip);
EndProcedure

// Dialog continuation notification handler.
&AtClient
Procedure EditConstantMessageNoCompletion(Val MessageNo, Val AdditionalParameters) Export
	If MessageNo = Undefined Then
		// Cancel input.
		Return;
	EndIf;
	
	ReportRegistrationResults(EditMessageNumberAtServer(MessageNo, AdditionalParameters.MetaFullName));
		
	Items.ConstantsList.Refresh();
	FillRegistrationCountInTreeRows();
EndProcedure

// Parameters:
//   Ref - ExchangePlanRef
//
// Returns:
//   Structure - Additional parameters.:
//     * Ref - ExchangePlanRef
//
&AtClient
Function AdditionalMessageNumberEditParameters(Ref)
	Return New Structure("Ref", Ref);
EndFunction

&AtClient
Procedure EditRefMessageNo()
	curData = CurrentRefsListData();
	If curData = Undefined Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription(
		"EditRefMessageNoCompletion",
		ThisObject,
		AdditionalMessageNumberEditParameters(curData.Ref));
	
	MessageNo = curData.MessageNo;
	ToolTip = NStr("vi = 'Số đã gửi';
					|ru = 'Номер отправленного';
					|en = 'Sent message number'; fa = 'شماره پیام ارسال‌شده';
					|it = 'Numero dell''inviato';
					|pl = 'Numer wysłanej';
					|tr = 'Gönderilen mesajın numarası'"); 
	
	ShowInputNumber(Notification, MessageNo, ToolTip);
EndProcedure

// Dialog continuation notification handler.
//
// Parameters:
//   MessageNo - Number
//   AdditionalParameters - See AdditionalMessageNumberEditParameters
//
&AtClient
Procedure EditRefMessageNoCompletion(Val MessageNo, Val AdditionalParameters) Export
	If MessageNo = Undefined Then
		// Cancel input.
		Return;
	EndIf;
	
	ReportRegistrationResults(EditMessageNumberAtServer(MessageNo, AdditionalParameters.Ref));
		
	Items.ReferenceList.Refresh();
	FillRegistrationCountInTreeRows();
EndProcedure

&AtClient
Procedure EditMessageNoSetList()
	curData = Items.RecordSetsList.CurrentData;
	If curData = Undefined Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("EditMessageNoSetListCompletion", ThisObject, New Structure);
	
	RowData = New Structure;
	KeysNames = RecordSetKeyNameArray(RecordSetsListTableName);
	For Each Name In KeysNames Do
		If curData.Property("RecordSetsList" + Name) Then
			RowData.Insert(Name, curData["RecordSetsList" + Name]);
		EndIf;
	EndDo;
	
	Notification.AdditionalParameters.Insert("RowData", RowData);
	
	MessageNo = curData.MessageNo;
	ToolTip = NStr("vi = 'Số đã gửi';
					|ru = 'Номер отправленного';
					|en = 'Sent message number'; fa = 'شماره پیام ارسال‌شده';
					|it = 'Numero dell''inviato';
					|pl = 'Numer wysłanej';
					|tr = 'Gönderilen mesajın numarası'"); 
	
	ShowInputNumber(Notification, MessageNo, ToolTip);
EndProcedure

// Dialog continuation notification handler.
&AtClient
Procedure EditMessageNoSetListCompletion(Val MessageNo, Val AdditionalParameters) Export
	If MessageNo = Undefined Then
		// Cancel input.
		Return;
	EndIf;
	
	ReportRegistrationResults(EditMessageNumberAtServer(
		MessageNo, AdditionalParameters.RowData, RecordSetsListTableName));
	
	Items.RecordSetsList.Refresh();
	FillRegistrationCountInTreeRows();
EndProcedure

&AtClient
Procedure SetUpChangeEditing()
	
	SetUpChangeEditingServer(MetadataCurrentRow);
	
	CurrentListPage = Items.ObjectsListOptions.CurrentPage;
	If CurrentListPage <> Items.ConstantsPage
		And CurrentListPage <> Items.ReferencesListPage
		And CurrentListPage <> Items.RecordSetPage Then
		
		Items.ShowExportResult.Enabled = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpandMetadataTree()
	For Each String In MetadataTree.GetItems() Do
		Items.MetadataTree.Expand( String.GetID() );
	EndDo;
EndProcedure

&AtServer
Procedure SetMessageNumberTitle()
	
	Text = NStr("vi = 'Số đã gửi %1, Số đã nhận %2';
				|ru = '№ отправленного %1, № принятого %2';
				|en = 'Sent message #%1. Received message #%2'; fa = 'Sent message #%1. Received message #%2';
				|it = '№ dell''inviato %1, № del ricevuto %2';
				|pl = '№ wysłanego %1, № odebranego %2';
				|tr = 'Gönderilen # %1, № alınan #  %2'");
	
	Data = ReadMessageNumbers();
	Text = StrReplace(Text, "%1", Format(Data.SentNo, "NFD=0; NZ="));
	Text = StrReplace(Text, "%2", Format(Data.ReceivedNo, "NFD=0; NZ="));
	
	Items.FormEditMessagesNumbers.Title = Text;
EndProcedure	

&AtClient
Procedure ExchangeNodeChoiceProcessing()
	ExchangeNodeChoiceProcessingServer();
EndProcedure

&AtServer
Procedure ExchangeNodeChoiceProcessingServer()
	
	// Modifying node numbers in the FormEditMessageNumbers title.
	SetMessageNumberTitle();
	
	// Refresh metadata tree.
	ReadMetadataTree();
	FillRegistrationCountInTreeRows();
	
	// Refresh the active page.
	Items.ObjectsListOptions.CurrentPage = Items.BlankPage;
	
	// Setting visibility for related buttons.
	
	MetaNodeExchangePlan = ExchangeNodeReference.Metadata();
	
	FillAdditionalInformation();
	
	If Object.DIBModeAvailable                             // Current SSL version supports MOID.
		And (ExchangePlans.MasterNode() = Undefined)          // Current infobase is a master node.
		And MetaNodeExchangePlan.DistributedInfoBase Then // Current node is DIB.
		Items.FormRegisterMOIDAndPredefinedItems.Visible = True;
	Else
		Items.FormRegisterMOIDAndPredefinedItems.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ReportRegistrationResults(Results)
	Command = Results.Command;
	If TypeOf(Command) = Type("Boolean") Then
		If Command Then
			WarningTitle = NStr("vi = 'Ghi nhận thay đổi:';
								|ru = 'Регистрация изменений:';
								|en = 'Registered items:'; fa = 'Registered items:';
								|it = 'Registrazione delle modifiche:';
								|pl = 'Rejestracja zmian:';
								|tr = 'Hazırlanan öğeler:'");
			WarningText = NStr("vi = 'Đã ghi nhận %1thay đổi từ %2
			                           |tại nút ""%0""';
			                           |ru = 'Зарегистрировано %1 изменений из %2
			                           |на узле ""%0""';
			                           |en = '%1 out of %2 items are registered.
			                           |Node: %0'; fa = '%1 out of %2 items are registered.
			                           |Node: %0';
			                           |it = 'Registrate %1 modifiche da %2
			                           |sul nodo ""%0""';
			                           |pl = 'Zarejestrowano %1 zmian z %2
			                           | na węźle ""%0""';
			                           |tr = '%1 / %2 öğe hazırlandı.
			                           |Ünite: %0'");
		Else
			WarningTitle = NStr("vi = 'Hủy bỏ ghi nhận:';
								|ru = 'Отмена регистрации:';
								|en = 'Unregistered items:'; fa = 'Unregistered items:';
								|it = 'Annullamento registrazione:';
								|pl = 'Anulowanie rejestracji:';
								|tr = 'Kaldırılan öğeler:'");
			WarningText = NStr("vi = 'Hủy bỏ ghi nhận %1 thay đổi 
			                           |tại nút ""%0"".';
			                           |ru = 'Отменена регистрация %1 изменений 
			                           |на узле ""%0"".';
			                           |en = '%1 items are unregistered.
			                           |Node: %0'; fa = '%1 items are unregistered.
			                           |Node: %0';
			                           |it = 'Annullata registrazione %1 delle modifiche 
			                           |sul nodo ""%0"".';
			                           |pl = 'Anulowano rejestrację %1 zmian 
			                           |na węźle ""%0"".';
			                           |tr = '""%0"" ünitesinde 
			                           | değişikliklerin %1 kaydı iptal edildi.'");
		EndIf;
	Else
		WarningTitle = NStr("vi = 'Thay đổi số thông điệp:';
							|ru = 'Изменение номера сообщения:';
							|en = 'Message number changed:'; fa = 'Message number changed:';
							|it = 'Modifica del numero del messaggio:';
							|pl = 'Zmiana numeru wiadomości:';
							|tr = 'Mesaj numarası değiştirildi:'");
		WarningText = NStr("vi = 'Số thông điệp đã thay đổi thành %3
		                           | %1 đối tượng';
		                           |ru = 'Номер сообщения изменен на %3
		                           |у %1 объекта(ов)';
		                           |en = 'Message number changed to %3
		                           |for %1 item(s).'; fa = 'Message number changed to %3
		                           |for %1 item(s).';
		                           |it = 'Il numero del messaggio è modificato in %3
		                           |per %1 oggetto(i)';
		                           |pl = 'Numer wiadomości został zmieniony na %3
		                           | dla %1 obiektu(ów)';
		                           |tr = '%1 nesnede mesaj numarası %3
		                           | olarak değiştirildi'");
	EndIf;
	
	WarningText = StrReplace(WarningText, "%0", ExchangeNodeReference);
	WarningText = StrReplace(WarningText, "%1", Format(Results.Success, "NZ=0;"));
	WarningText = StrReplace(WarningText, "%2", Format(Results.Total, "NZ=0;"));
	WarningText = StrReplace(WarningText, "%3", Command);
	
	WarningRequired = Results.Total <> Results.Success;
	If WarningRequired Then
		ShowMessageBox(, WarningText, , WarningTitle);
	Else
		ShowUserNotification(WarningTitle,
			GetURL(ExchangeNodeReference),
			WarningText,
			Items.HiddenPictureInformation32.Picture);
	EndIf;
EndProcedure

&AtServer
Function GetQueryResultChoiceForm()
	
	CurrentObject = ThisObject();
	CurrentObject.ReadSettings();
	ThisObject(CurrentObject);
	
	Validation = CurrentObject.CheckSettingsCorrectness();
	ThisObject(CurrentObject);
	
	If Validation.QueryExternalDataProcessorAddressSetting <> Undefined Then
		Return Undefined;
		
	ElsIf IsBlankString(CurrentObject.QueryExternalDataProcessorAddressSetting) Then
		Return Undefined;
		
	ElsIf Lower(Right(TrimAll(CurrentObject.QueryExternalDataProcessorAddressSetting), 4)) = ".epf" Then
		Return Undefined;
		
	Else
		DataProcessor = DataProcessors[CurrentObject.QueryExternalDataProcessorAddressSetting].Create();
		FormIdentifier = ".Form";
		
	EndIf;
	
	Return DataProcessor.Metadata().FullName() + FormIdentifier;
EndFunction

&AtClient
Procedure AddConstantRegistrationInList()
	CurFormName = ThisFormName + "Form.SelectConstant";
	CurParameters = New Structure();
	CurParameters.Insert("ExchangeNode",ExchangeNodeReference);
	CurParameters.Insert("MetadataNamesArray",MetadataNamesStructure.Constants);
	CurParameters.Insert("PresentationsArray",MetadataPresentationsStructure.Constants);
	CurParameters.Insert("AutoRecordsArray",MetadataAutoRecordStructure.Constants);
	OpenForm(CurFormName, CurParameters, Items.ConstantsList);
EndProcedure

&AtClient
Procedure DeleteConstantRegistrationInList()
	
	Item = Items.ConstantsList;
	
	PresentationsList = New Array;
	NamesList          = New Array;
	For Each String In Item.SelectedRows Do
		Data = Item.RowData(String);
		PresentationsList.Add(Data.Description);
		NamesList.Add(Data.MetaFullName);
	EndDo;
	
	Count = NamesList.Count();
	If Count = 0 Then
		Return;
	ElsIf Count = 1 Then
		Text = NStr("vi = 'Hủy ghi nhận ""%2""
		                 |tại nút ""%1""?';
		                 |ru = 'Отменить регистрацию ""%2""
		                 |на узле ""%1""?';
		                 |en = 'Do you want to unregister ""%2""
		                 |at node ""%1""?'; fa = 'Do you want to unregister ""%2""
		                 |at node ""%1""?';
		                 |it = 'Annullare la registrazione ""%2""
		                 |sul nodo ""%1""?';
		                 |pl = 'Anulować rejestrację ""%2""
		                 |na węźle ""%1""?';
		                 |tr = '""%1"" ünitesinde
		                 |""%2"" kaldırılsın mı?'"); 
	Else
		Text = NStr("vi = 'Hủy ghi nhận các hằng đã chọn
		                 |tại nút ""%1""?';
		                 |ru = 'Отменить регистрацию выбранных констант
		                 |на узле ""%1""?';
		                 |en = 'Do you want to unregister the constants
		                 |at node ""%1""?'; fa = 'Do you want to unregister the constants
		                 |at node ""%1""?';
		                 |it = 'Annullare la registrazione delle costanti selezionate
		                 |sul nodo ""%1""?';
		                 |pl = 'Anulować rejestrację wybranych stałych
		                 |na węźle ""%1""?';
		                 |tr = '""%1"" ünitesinde
		                 |sabitler kaldırılsın mı?'"); 
	EndIf;
	Text = StrReplace(Text, "%1", ExchangeNodeReference);
	Text = StrReplace(Text, "%2", PresentationsList[0]);
	
	QuestionTitle = NStr("vi = 'Xác nhận';
						|ru = 'Подтверждение';
						|en = 'Confirm operation'; fa = 'Confirm operation';
						|it = 'Conferma';
						|pl = 'Potwierdzenie';
						|tr = 'Parolayı doğrula'");
	
	Notification = New CallbackDescription("DeleteConstantRegistrationInListCompletion", ThisObject, New Structure);
	Notification.AdditionalParameters.Insert("NamesList", NamesList);
	
	ShowQueryBox(Notification, Text, QuestionDialogMode.YesNo, , ,QuestionTitle);
EndProcedure

// Dialog continuation notification handler.
&AtClient
Procedure DeleteConstantRegistrationInListCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
		
	ReportRegistrationResults(DeleteRegistrationAtServer(True, AdditionalParameters.NamesList));
		
	Items.ConstantsList.Refresh();
	FillRegistrationCountInTreeRows();
EndProcedure

&AtClient
Procedure AddRegistrationInReferenceList(IsPick = False)
	CurFormName = ReferencesListTableName + ".ChoiceForm";
	CurParameters = New Structure();
	CurParameters.Insert("ChoiceMode", True);
	CurParameters.Insert("MultipleChoice", True);
	CurParameters.Insert("CloseOnChoice", IsPick);
	CurParameters.Insert("ChoiceFoldersAndItems", FoldersAndItemsUse.FoldersAndItems);

	OpenForm(CurFormName, CurParameters, Items.ReferenceList);
EndProcedure

&AtClient
Procedure AddObjectDeletionRegistrationInReferenceList()
	Ref = ObjectRefToDelete();
	DataChoiceProcessing(Items.ReferenceList, Ref);
EndProcedure

&AtServer
Function ObjectRefToDelete(Val Var_UUID = Undefined)
	LongDesc = ThisObject().MetadataCharacteristics(ReferencesListTableName);
	If Var_UUID = Undefined Then
		Return LongDesc.Manager.GetRef();
	EndIf;
	Return LongDesc.Manager.GetRef(Var_UUID);
EndFunction

&AtClient 
Procedure AddRegistrationInListFilter()
	CurFormName = ThisFormName + "Form.SelectObjectsUsingFilter";
	CurParameters = New Structure("ChoiceAction, TableName", 
		True,
		ReferencesListTableName);
	OpenForm(CurFormName, CurParameters, Items.ReferenceList);
EndProcedure

&AtClient 
Procedure DeleteRegistrationInListFilter()
	CurFormName = ThisFormName + "Form.SelectObjectsUsingFilter";
	CurParameters = New Structure("ChoiceAction, TableName", 
		False,
		ReferencesListTableName);
	OpenForm(CurFormName, CurParameters, Items.ReferenceList);
EndProcedure

&AtClient
Procedure DeleteRegistrationFromReferenceList()
	
	Item = Items.ReferenceList;
	
	DeletionList = New Array;
	For Each String In Item.SelectedRows Do
		Data = Item.RowData(String); // See CurrentRefsListData
		DeletionList.Add(Data.Ref);
	EndDo;
	
	Count = DeletionList.Count();
	If Count = 0 Then
		Return;
	ElsIf Count = 1 Then
		Text = NStr("vi = 'Hủy ghi nhận ""%2""
		                 |tại nút ""%1""?';
		                 |ru = 'Отменить регистрацию ""%2""
		                 |на узле ""%1""?';
		                 |en = 'Do you want to unregister ""%2""
		                 |at node ""%1""?'; fa = 'Do you want to unregister ""%2""
		                 |at node ""%1""?';
		                 |it = 'Annullare la registrazione ""%2""
		                 |sul nodo ""%1""?';
		                 |pl = 'Anulować rejestrację ""%2""
		                 |na węźle ""%1""?';
		                 |tr = '""%1"" ünitesinde
		                 |""%2"" kaldırılsın mı?'"); 
	Else
		Text = NStr("vi = 'Hủy ghi nhận đối tượng đã chọn
		                 |tại nút ""%1""?';
		                 |ru = 'Отменить регистрацию выбранных объектов
		                 |на узле ""%1""?';
		                 |en = 'Do you want to unregister the selected items
		                 |at node ""%1""?'; fa = 'Do you want to unregister the selected items
		                 |at node ""%1""?';
		                 |it = 'Annullare la registrazione degli oggetti selezionati
		                 |sul nodo ""%1""?';
		                 |pl = 'Anulować rejestrację wybranych obiektów
		                 |na węźle ""%1""?';
		                 |tr = '""%1"" ünitesinde
		                 |seçilen öğeler kaldırılsın mı?'"); 
	EndIf;
	Text = StrReplace(Text, "%1", ExchangeNodeReference);
	Text = StrReplace(Text, "%2", DeletionList[0]);
	
	QuestionTitle = NStr("vi = 'Xác nhận';
						|ru = 'Подтверждение';
						|en = 'Confirm operation'; fa = 'Confirm operation';
						|it = 'Conferma';
						|pl = 'Potwierdzenie';
						|tr = 'Parolayı doğrula'");
	
	Notification = New CallbackDescription("DeleteRegistrationFromReferenceListCompletion", ThisObject, New Structure);
	Notification.AdditionalParameters.Insert("DeletionList", DeletionList);
	
	ShowQueryBox(Notification, Text, QuestionDialogMode.YesNo, , , QuestionTitle);
EndProcedure

// Dialog continuation notification handler.
&AtClient 
Procedure DeleteRegistrationFromReferenceListCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ReportRegistrationResults(DeleteRegistrationAtServer(True, AdditionalParameters.DeletionList));
		
	Items.ReferenceList.Refresh();
	FillRegistrationCountInTreeRows();
EndProcedure

&AtClient
Procedure AddRegistrationToRecordSetFilter()
	CurFormName = ThisFormName + "Form.SelectObjectsUsingFilter";
	CurParameters = New Structure("ChoiceAction, TableName", 
		True,
		RecordSetsListTableName);
	OpenForm(CurFormName, CurParameters, Items.RecordSetsList);
EndProcedure

&AtClient
Procedure DeleteRegistrationInRecordSet()
	
	StructureOfData = "";
	KeysNames = RecordSetKeyNameArray(RecordSetsListTableName);
	For Each Name In KeysNames Do
		StructureOfData = StructureOfData +  "," + Name;
	EndDo;
	StructureOfData = Mid(StructureOfData, 2);
	
	Data = New Array;
	Item = Items.RecordSetsList;
	For Each String In Item.SelectedRows Do
		curData = Item.RowData(String);
		RowData = New Structure;
		For Each Name In KeysNames Do
			ColumnName = "RecordSetsList" + Name;
			If curData.Property(ColumnName) Then 
				RowData.Insert(Name, curData[ColumnName]);
			EndIf;
		EndDo;
		Data.Add(RowData);
	EndDo;
	
	If Data.Count() = 0 Then
		Return;
	EndIf;
	
	Case = New Structure();
	Case.Insert("TableName",RecordSetsListTableName);
	Case.Insert("ChoiceData",Data);
	Case.Insert("ChoiceAction",False);
	Case.Insert("FieldsStructure",StructureOfData);
	DataChoiceProcessing(Items.RecordSetsList, Case);
EndProcedure

&AtClient
Procedure DeleteRegistrationInRecordSetFilter()
	CurFormName = ThisFormName + "Form.SelectObjectsUsingFilter";
	CurParameters = New Structure("ChoiceAction, TableName", 
		False,
		RecordSetsListTableName);
	OpenForm(CurFormName, CurParameters, Items.RecordSetsList);
EndProcedure

&AtClient
Procedure AddSelectedObjectRegistration(NoAutoRegistration = True)
	
	Data = GetSelectedMetadataNames(NoAutoRegistration);
	Count = Data.MetaNames.Count();
	If Count = 0 Then
		// Current row.
		Data = GetCurrentRowMetadataNames(NoAutoRegistration);
	EndIf;
	
	Text = NStr("vi = 'Ghi nhận %1 để kết xuất trong nút ""%2""?
	                 |
	                 |Việc thay đổi ghi nhận số lượng lớn đối tượng có thể mất thêm thời gian.';
	                 |ru = 'Зарегистрировать %1 для выгрузки на узле ""%2""?
	                 |
	                 |Изменение регистрации большого количества объектов может занять продолжительное время.';
	                 |en = 'Do you want to register %1 for export to node ""%2""?
	                 |
	                 |This might take a while.'; fa = 'Do you want to register %1 for export to node ""%2""?
	                 |
	                 |This might take a while.';
	                 |it = 'Registrare %1 da scaricare sul nodo ""%2""?
	                 |
	                 |La modifica della registrazione di un numero elevato di oggetti potrebbe richiedere il tempo prolungato.';
	                 |pl = 'Zarejestrować %1 dla ładowania na węźle ""%2""?
	                 |
	                 |Zmiana rejestracji dużej ilości obiektów może potrwać dłuższy czas.';
	                 |tr = '""%2"" ünitesine aktarılacak %1 öğesi kaydedilsin mi?
	                 |
	                 |Çok sayıda nesnelerin kaydının değiştirilmesi çok uzun sürebilir.'");
					 
	Text = StrReplace(Text, "%1", Data.LongDesc);
	Text = StrReplace(Text, "%2", ExchangeNodeReference);
	
	QuestionTitle = NStr("vi = 'Xác nhận';
						|ru = 'Подтверждение';
						|en = 'Confirm operation'; fa = 'Confirm operation';
						|it = 'Conferma';
						|pl = 'Potwierdzenie';
						|tr = 'Parolayı doğrula'");
	
	Notification = New CallbackDescription("AddSelectedObjectRegistrationCompletion", ThisObject, New Structure);
	Notification.AdditionalParameters.Insert("MetaNames", Data.MetaNames);
	Notification.AdditionalParameters.Insert("NoAutoRegistration", NoAutoRegistration);
	
	ShowQueryBox(Notification, Text, QuestionDialogMode.YesNo, , , QuestionTitle);
EndProcedure

// Dialog continuation notification handler.
&AtClient 
Procedure AddSelectedObjectRegistrationCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	If Object.AsynchronousRegistrationAvailable Then
		BackgroundJobParameters = PrepareRegistrationChangeParameters(True, AdditionalParameters.NoAutoRegistration, 
										AdditionalParameters.MetaNames);
		BackgroundJobStartClient(BackgroundJobParameters);
	Else
		Result = AddRegistrationAtServer(AdditionalParameters.NoAutoRegistration, 
			AdditionalParameters.MetaNames);
		
		FillRegistrationCountInTreeRows();
		UpdatePageContent();
		ReportRegistrationResults(Result);
	EndIf;
EndProcedure

&AtClient
Procedure DeleteSelectedObjectRegistration(NoAutoRegistration = True)
	
	Data = GetSelectedMetadataNames(NoAutoRegistration);
	Count = Data.MetaNames.Count();
	If Count = 0 Then
		Data = GetCurrentRowMetadataNames(NoAutoRegistration);
	EndIf;
	
	Text = NStr("vi = 'Hủy bỏ ghi nhận %1 để kết xuất trong nút ""%2""?
	                 |
	                 |Việc thay đổi ghi nhận số lượng lớn đối tượng có thể mất thêm thời gian.';
	                 |ru = 'Отменить регистрацию %1 для выгрузки на узле ""%2""?
	                 |
	                 |Изменение регистрации большого количества объектов может занять продолжительное время.';
	                 |en = 'Do you want to unregister %1 for export to node ""%2""?
	                 |
	                 |This might take a while.'; fa = 'Do you want to unregister %1 for export to node ""%2""?
	                 |
	                 |This might take a while.';
	                 |it = 'Annullare la registrazione %1 per upload sul nodo ""%2""?
	                 |
	                 |La modifica della registrazione di un numero elevato di oggetti potrebbe richiedere il tempo prolungato.';
	                 |pl = 'Anulować rejestrację %1 dla ładowania na węźle ""%2""?
	                 |
	                 |Zmiana rejestracji dużej ilości obiektów może potrwać dłuższy czas.';
	                 |tr = '""%2"" ünitesine aktarılacak %1 öğesi kaldırılsın mı?
	                 |
	                 |Bu işlem uzun sürebilir.'");
	
	QuestionTitle = NStr("vi = 'Xác nhận';
						|ru = 'Подтверждение';
						|en = 'Confirm operation'; fa = 'Confirm operation';
						|it = 'Conferma';
						|pl = 'Potwierdzenie';
						|tr = 'Parolayı doğrula'");
	
	Text = StrReplace(Text, "%1", Data.LongDesc);
	Text = StrReplace(Text, "%2", ExchangeNodeReference);
	
	Notification = New CallbackDescription("DeleteSelectedObjectRegistrationCompletion", ThisObject, New Structure);
	Notification.AdditionalParameters.Insert("MetaNames", Data.MetaNames);
	Notification.AdditionalParameters.Insert("NoAutoRegistration", NoAutoRegistration);
	
	ShowQueryBox(Notification, Text, QuestionDialogMode.YesNo, , , QuestionTitle);
EndProcedure

// Dialog continuation notification handler.
&AtClient
Procedure DeleteSelectedObjectRegistrationCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Object.AsynchronousRegistrationAvailable Then
		BackgroundJobParameters = PrepareRegistrationChangeParameters(False, AdditionalParameters.NoAutoRegistration, 
										AdditionalParameters.MetaNames);
		BackgroundJobStartClient(BackgroundJobParameters);
	Else
		ReportRegistrationResults(DeleteRegistrationAtServer(AdditionalParameters.NoAutoRegistration, 
				AdditionalParameters.MetaNames));
			
		FillRegistrationCountInTreeRows();
		UpdatePageContent();
	EndIf;
EndProcedure

&AtClient
Procedure BackgroundJobStartClient(BackgroundJobParameters)
	TimeConsumingOperationStarted = True;
	TimeConsumingOperationKind = ?(BackgroundJobParameters.Command, True, False);
	AttachIdleHandler("TimeConsumingOperationPage1", 0.1, True);
	Result = BackgroundJobStartAtServer(BackgroundJobParameters);
	If Result = Undefined Then
		TimeConsumingOperationStarted = False;
		WarningText = NStr("vi = 'Khi khởi động nhiệm vụ nền với mục đích thay đổi ghi nhận, đã xảy ra lỗi.';
							|ru = 'При запуске фонового задания с целью изменения регистрации произошла ошибка.';
							|en = 'Error starting background job.'; fa = 'Error starting background job.';
							|it = 'Si è verificato un errore durante l''avvio del task in background per modificare la registrazione.';
							|pl = 'Podczas uruchomienia zadania w tle w celu zmiany rejestracji wystąpił błąd.';
							|tr = 'Arka plan işi başlatılırken hata oluştu.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	CommonModuleTimeConsumingOperationsClient = CommonModuleTimeConsumingOperationsClient();
	If Result.Status = "Running" Then
		IdleParameters = CommonModuleTimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow  = False;
		IdleParameters.OutputMessages     = True;
		
		CallbackOnCompletion = New CallbackDescription("BackgroundJobCompletion", ThisObject);
		CommonModuleTimeConsumingOperationsClient.WaitCompletion(Result, CallbackOnCompletion, IdleParameters);
	Else
		BackgroundJobCompleteResult = Result;
		AttachIdleHandler("BackgroundJobExecutionResult", 0.1, True);
	EndIf;
EndProcedure

&AtClient
Procedure TimeConsumingOperationPage1()
	If Not TimeConsumingOperationStarted Then
		Return;
	EndIf;
	If TimeConsumingOperationKind Then
		OperationStatus = NStr("vi = 'Đang tiến hành ghi nhận các thay đổi. Xin vui lòng đợi.';
								|ru = 'Выполняется регистрация изменений. Пожалуйста, подождите.';
								|en = 'Registering in progress. Please wait.'; fa = 'Registering in progress. Please wait.';
								|it = 'La registrazione delle modifiche è in corso. Attendere prego.';
								|pl = 'Trwa rejestracja zmian. Proszę czekać.';
								|tr = 'Hazırlama devam ediyor. Lütfen bekleyin.'");
	Else
		OperationStatus = NStr("vi = 'Đang tiến hành hủy bỏ ghi nhận các thay đổi. Xin vui lòng đợi.';
								|ru = 'Выполняется отмена регистрации изменений. Пожалуйста, подождите.';
								|en = 'Unregistering in progress. Please wait.'; fa = 'Unregistering in progress. Please wait.';
								|it = 'L''annullamento della registrazione delle modifiche è in corso. Attendere prego.';
								|pl = 'Trwa anulowanie rejestracji zmian. Proszę czekać.';
								|tr = 'Kaldırma devam ediyor. Lütfen bekleyin.'");
	EndIf;
	Items.TimeConsumingOperationStatus.Title = OperationStatus;
	Items.GroupPages.CurrentPage = Items.Waiting;
EndProcedure

&AtClient
Procedure BackgroundJobCompletion(Result, AdditionalParameters) Export
	
	BackgroundJobCompleteResult = Result;
	BackgroundJobExecutionResult();
	
EndProcedure

&AtClient
Procedure BackgroundJobExecutionResult()
	
	BackgroundJobGetResultAtServer();
	TimeConsumingOperationStarted = False;
	
	Items.GroupPages.CurrentPage = Items.Main;
	CurrentItem = Items.MetadataTree;
	
	If ValueIsFilled(ErrorMessage) Then
		Message = New UserMessage;
		Message.Text = ErrorMessage;
		Message.Message();
	EndIf;
	
	If Not BackgroundJobCompleteResult = Undefined Then
		If BackgroundJobCompleteResult.Property("AdditionalResultData")
			And BackgroundJobCompleteResult.AdditionalResultData.Property("Command") Then
			
			ReportRegistrationResults(BackgroundJobCompleteResult.AdditionalResultData);
			FillRegistrationCountInTreeRows();
			UpdatePageContent();
			
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function BackgroundJobStartAtServer(BackgroundJobParameters)
	
	ModuleTimeConsumingOperations = CommonModuleTimeConsumingOperations();
	ExecutionParameters = ModuleTimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.AdditionalResult = False;
	
	If BackgroundJobParameters.Property("AddressData2") Then
		// Data storage address is passed.
		Result = GetFromTempStorage(BackgroundJobParameters.AddressData2);
		Result= Result[Result.UBound()];
		Data = Result.Unload().UnloadColumn("Ref");
		BackgroundJobParameters.Insert("Data", Data);
	EndIf;
	ProcedureName = FormAttributeToValue("Object").Metadata().FullName() + ".ObjectModule.ChangeRegistration";
	Result = ModuleTimeConsumingOperations.ExecuteInBackground(ProcedureName, BackgroundJobParameters, ExecutionParameters);
	IDBackgroundJob  = Result.JobID;
	BackgroundJobStorageAddress = Result.ResultAddress;
	
	Return Result;
	
EndFunction

&AtServer
Procedure BackgroundJobGetResultAtServer()
	
	If BackgroundJobCompleteResult <> Undefined Then
		BackgroundJobCompleteResult.Insert("AdditionalResultData", New Structure);
		ErrorMessage = "";
		StandardErrorPresentation = NStr("vi = 'Khi thay đổi ghi nhận, đã xảy ra lỗi. Chi tiết xem trong nhật ký sự kiện';
										|ru = 'При изменении регистрации произошла ошибка. Подробности см. в журнале регистрации';
										|en = 'Error changing registration state. See the event log for details.'; fa = 'Error changing registration state. See the event log for details.';
										|it = 'Si è verificato un errore durante la modifica della registrazione. Vedi il registro per i dettagli';
										|pl = 'Podczas zmiany rejestracji wystąpił błąd. Szczegóły można znaleźć w dzienniku rejestracji';
										|tr = 'Kaydın değiştirilmesi sırasında hata oluştu. Detaylar için kayıt defterine bakınız.'");
		
		If BackgroundJobCompleteResult.Status = "Error" Then
			ErrorMessage = BackgroundJobCompleteResult.DetailErrorDescription;
		Else
			BackgroundExecutionResult = GetFromTempStorage(BackgroundJobStorageAddress);
			
			If BackgroundExecutionResult = Undefined Then
				ErrorMessage = StandardErrorPresentation;
			Else
				BackgroundJobCompleteResult.AdditionalResultData = BackgroundExecutionResult;
				DeleteFromTempStorage(BackgroundJobStorageAddress);
			EndIf;
		EndIf;
	EndIf;
	
	BackgroundJobStorageAddress = Undefined;
	IDBackgroundJob  = Undefined;
	
EndProcedure

&AtServerNoContext
Procedure EndExecutingTimeConsumingOperation(JobID)
	ModuleTimeConsumingOperations = CommonModuleTimeConsumingOperations();
	ModuleTimeConsumingOperations.CancelJobExecution(JobID);
EndProcedure

// Returns a reference to the TimeConsumingOperationsClient common module.
//
// Returns:
//  CommonModule - the TimeConsumingOperationsClient common module.
//
&AtClient
Function CommonModuleTimeConsumingOperationsClient()
	
	// Don't call CalculateInSafeMode. Calculation takes a string literal instead.
	Module = Eval("TimeConsumingOperationsClient");
	
	If TypeOf(Module) <> Type("CommonModule") Then
		Raise NStr("vi = 'Không tìm thấy mô-đun chung ""ДлительныеОперацииКлиент"".';
					|ru = 'Общий модуль ""ДлительныеОперацииКлиент"" не найден.';
					|en = 'Common module TimeConsumingOperationsClient is not found.'; fa = 'Common module TimeConsumingOperationsClient is not found.';
					|it = 'Il modulo generale ""OperazioniLungheCliente"" non è stato trovato.';
					|pl = 'Wspólny moduł ""DługieOperacjeKlient"" nie został znaleziony.';
					|tr = '""ДлительныеОперацииКлиент"" genel modülü bulunamadı.'");
	EndIf;
	
	Return Module;
	
EndFunction

// Returns a reference to the TimeConsumingOperations common module.
//
// Returns:
//  CommonModule - the TimeConsumingOperations common module.
//
&AtServerNoContext
Function CommonModuleTimeConsumingOperations()

	If Metadata.CommonModules.Find("TimeConsumingOperations") <> Undefined Then
		// Don't call CalculateInSafeMode. Calculation takes a string literal instead.
		SetSafeMode(True);
		Module = Eval("TimeConsumingOperations");
		SetSafeMode(False);
	Else
		Module = Undefined;
	EndIf;
	
	If TypeOf(Module) <> Type("CommonModule") Then
		Raise NStr("vi = 'Không tìm thấy mô-đun chung ""ДлительныеОперации"".';
					|ru = 'Общий модуль ""ДлительныеОперации"" не найден.';
					|en = 'Common module TimeConsumingOperations is not found.'; fa = 'Common module TimeConsumingOperations is not found.';
					|it = 'Il modulo generale ""OperazioniLunghe"" non è stato trovato.';
					|pl = 'Wspólny moduł ""DługieOperacje"" nie został znaleziony.';
					|tr = '""ДлительныеОперации"" genel modülü bulunamadı.'");
	EndIf;
	
	Return Module;
	
EndFunction

// Returns:
//   Structure - Additional parameters.:
//     * Action - Boolean
//     * FormTable - FormTable
//     * Data - Arbitrary
//     * TableName - String
//     * Ref - AnyRef
//
&AtClient
Function AdditionalDataChoiceProcessingParameters()
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Action");
	AdditionalParameters.Insert("FormTable");
	AdditionalParameters.Insert("Data");
	AdditionalParameters.Insert("TableName");
	AdditionalParameters.Insert("Ref");
	
	Return AdditionalParameters;
	
EndFunction

&AtClient
Procedure DataChoiceProcessing(FormTable, ValueSelected)
	
	Ref = Undefined;
	Type    = TypeOf(ValueSelected);
	
	If Type = Type("Structure") Then
		If Not (ValueSelected.Property("TableName")
			And ValueSelected.Property("ChoiceAction")
			And ValueSelected.Property("ChoiceData")) Then
			// Waiting for the structure in the specified format.
			Return;
		EndIf;
		TableName = ValueSelected.TableName;
		Action   = ValueSelected.ChoiceAction;
		Data     = ValueSelected.ChoiceData;
	Else
		TableName = Undefined;
		Action = True;
		If Type = Type("Array") Then
			Data = ValueSelected;
		Else		
			Data = New Array;
			Data.Add(ValueSelected);
		EndIf;
		
		If Data.Count() = 1 Then
			Ref = Data[0];
		EndIf;
	EndIf;
	
	If Action Then
		Result = AddRegistrationAtServer(True, Data, TableName);
		
		FormTable.Refresh();
		FillRegistrationCountInTreeRows();
		ReportRegistrationResults(Result);
		
		FormTable.CurrentRow = Ref;
		Return;
	EndIf;
	
	If Ref = Undefined Then
		Text = NStr("vi = 'Hủy ghi nhận đối tượng đã chọn
		                 |tại nút ""%1?';
		                 |ru = 'Отменить регистрацию выбранных объектов
		                 |на узле ""%1?';
		                 |en = 'Do you want to unregister the selected items
		                 |at node ""%1""?'; fa = 'Do you want to unregister the selected items
		                 |at node ""%1""?';
		                 |it = 'Annullare la registrazione degli oggetti selezionati
		                 |sul nodo ""%1""?';
		                 |pl = 'Anulować rejestrację wybranych obiektów
		                 |na węźle ""%1""?';
		                 |tr = '""%1"" ünitesinde seçilmiş nesnelerin
		                 | kaydı iptal edilsin mi?'"); 
	Else
		Text = NStr("vi = 'Hủy ghi nhận ""%2""
		                 |tại nút ""%1?';
		                 |ru = 'Отменить регистрацию ""%2""
		                 |на узле ""%1?';
		                 |en = 'Do you want to unregister ""%2""
		                 |at node ""%1""?'; fa = 'Do you want to unregister ""%2""
		                 |at node ""%1""?';
		                 |it = 'Annullare la registrazione ""%2""
		                 |sul nodo ""%1""?';
		                 |pl = 'Anulować rejestrację ""%2""
		                 |na węźle ""%1""?';
		                 |tr = '""%1"" ünitesinde
		                 |""%2"" kaldırılsın mı?'"); 
	EndIf;
		
	Text = StrReplace(Text, "%1", ExchangeNodeReference);
	Text = StrReplace(Text, "%2", Ref);
	
	QuestionTitle = NStr("vi = 'Xác nhận';
						|ru = 'Подтверждение';
						|en = 'Confirm operation'; fa = 'Confirm operation';
						|it = 'Conferma';
						|pl = 'Potwierdzenie';
						|tr = 'Parolayı doğrula'");
		
	AdditionalParameters = AdditionalDataChoiceProcessingParameters();
	AdditionalParameters.Action     = Action;
	AdditionalParameters.FormTable = FormTable;
	AdditionalParameters.Data       = Data;
	AdditionalParameters.TableName   = TableName;
	AdditionalParameters.Ref       = Ref;
	
	Notification = New CallbackDescription("DataChoiceProcessingCompletion", ThisObject, AdditionalParameters);
	
	ShowQueryBox(Notification, Text, QuestionDialogMode.YesNo, , ,QuestionTitle);
EndProcedure

// Dialog continuation notification handler.
//
// Parameters:
//   QuestionResult -DialogReturnCode
//   AdditionalParameters - See AdditionalDataChoiceProcessingParameters
//
&AtClient
Procedure DataChoiceProcessingCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	If Object.AsynchronousRegistrationAvailable Then
		BackgroundJobParameters = PrepareRegistrationChangeParameters(False, True, AdditionalParameters.Data, 
										AdditionalParameters.TableName);
		BackgroundJobStartClient(BackgroundJobParameters);
	Else
		Result = DeleteRegistrationAtServer(True, AdditionalParameters.Data, AdditionalParameters.TableName);
	
		AdditionalParameters.FormTable.Refresh();
		FillRegistrationCountInTreeRows();
		ReportRegistrationResults(Result);
	EndIf;
	
	AdditionalParameters.FormTable.CurrentRow = AdditionalParameters.Ref;
EndProcedure

&AtServer
Procedure UpdatePageContent(Page = Undefined)
	CurrRow = ?(Page = Undefined, Items.ObjectsListOptions.CurrentPage, Page);
	
	If CurrRow = Items.ReferencesListPage Then
		Items.ReferenceList.Refresh();
		
	ElsIf CurrRow = Items.ConstantsPage Then
		Items.ConstantsList.Refresh();
		
	ElsIf CurrRow = Items.RecordSetPage Then
		Items.RecordSetsList.Refresh();
		
	ElsIf CurrRow = Items.BlankPage Then
		String = Items.MetadataTree.CurrentRow;
		If String <> Undefined Then
			Data = MetadataTree.FindByID(String);
			If Data <> Undefined Then
				SetUpEmptyPage(Data.Description, Data.MetaFullName);
			EndIf;
		EndIf;
	EndIf;
EndProcedure	

&AtClient
Function GetCurrentObjectToEdit()
	
	CurrRow = Items.ObjectsListOptions.CurrentPage;
	
	If CurrRow = Items.ReferencesListPage Then
		Data = CurrentRefsListData();
		If Data <> Undefined Then
			Return Data.Ref; 
		EndIf;
		
	ElsIf CurrRow = Items.ConstantsPage Then
		Data = Items.ConstantsList.CurrentData;
		If Data <> Undefined Then
			Return Data.MetaFullName; 
		EndIf;
		
	ElsIf CurrRow = Items.RecordSetPage Then
		Data = Items.RecordSetsList.CurrentData;
		If Data <> Undefined Then
			Result = New Structure;
			Dimensions = RecordSetKeyNameArray(RecordSetsListTableName);
			For Each Name In Dimensions  Do
				If Data.Property("RecordSetsList" + Name) Then
					Result.Insert(Name, Data["RecordSetsList" + Name]);
				EndIf;
			EndDo;
		EndIf;
		Return Result;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Returns:
//   FormDataStructure:
//     * Ref - AnyRef
//     * MessageNo - Number
//     * NotExported - Boolean
//
&AtClient
Function CurrentRefsListData()
	
	Return Items.ReferenceList.CurrentData;
	
EndFunction

&AtClient
Procedure OpenDataProcessorSettingsForm()
	CurFormName = ThisFormName + "Form.Settings";
	OpenForm(CurFormName, , ThisObject);
EndProcedure

&AtClient
Procedure ActionWithQueryResult(ActionCommand)
	
	CurFormName = GetQueryResultChoiceForm();
	If CurFormName <> Undefined Then
		// Open form.
		If ActionCommand Then
			Text = NStr("vi = 'Ghi nhận thay đổi kết quả truy vấn';
						|ru = 'Регистрация изменений результата запроса';
						|en = 'Register query results'; fa = 'ثبت نتایج کوئری';
						|it = 'Registrazione delle modifiche del risultato di richiesta';
						|pl = 'Rejestracja zmian wyniku zapytania';
						|tr = 'Sorgu sonuçlarını hazırla'");
		Else
			Text = NStr("vi = 'Đã hủy ghi nhận thay đổi kết quả truy vấn';
						|ru = 'Отмена регистрации изменений результата запроса';
						|en = 'Unregister query results'; fa = 'لغو ثبت نتایج کوئری';
						|it = 'Annullamento della registrazione delle modifiche del risultato di richiesta';
						|pl = 'Anulowanie rejestracji zmian wyniku zapytania';
						|tr = 'Sorgu sonuçlarını kaldır'");
		EndIf;
		ParametersStructure = New Structure();
		ParametersStructure.Insert("Title", Text);
		ParametersStructure.Insert("ChoiceAction", ActionCommand);
		ParametersStructure.Insert("ChoiceMode", True);
		ParametersStructure.Insert("CloseOnChoice", False);
		
		If Not ValueIsFilled(QueryResultChoiceFormUniqueKey) Then
			QueryResultChoiceFormUniqueKey = New UUID;
		EndIf;
		
		OpenForm(CurFormName, ParametersStructure, ThisObject, QueryResultChoiceFormUniqueKey);
		Return;
	EndIf;
	
	// If the query execution handler is not specified, prompting the user to specify it.
	Text = NStr("vi = 'Trong tùy chỉnh chưa chỉ ra bộ xử lý để thực hiện truy vấn.
	                        |Tùy chỉnh ngay?';
	                        |ru = 'В настройках не указана обработка для выполнения запросов.
	                        |Настроить сейчас?';
	                        |en = 'Query data processor not specified.
	                        |Do you want to specify it now?'; fa = 'Query data processor not specified.
	                        |Do you want to specify it now?';
	                        |it = 'Le impostazioni non specificano l''elaborazione per eseguire le richieste.
	                        |Configurare ora?';
	                        |pl = 'W ustawieniach nie podano przetwarzania w celu realizacji wniosków.
	                        |Ustawić teraz?';
	                        |tr = 'Sorgu veri işlemcisi belirtilmedi.
	                        |Şimdi belirtmek ister misiniz?'");
	
	QuestionTitle = NStr("vi = 'Tùy chỉnh';
						|ru = 'Настройки';
						|en = 'Settings'; fa = 'تنظیمات';
						|it = 'Impostazioni';
						|pl = 'Ustawienia';
						|tr = 'Ayarlar'");

	Notification = New CallbackDescription("ActionWithQueryResultCompletion", ThisObject);
	ShowQueryBox(Notification, Text, QuestionDialogMode.YesNo, , , QuestionTitle);
EndProcedure

// Dialog continuation notification handler.
&AtClient 
Procedure ActionWithQueryResultCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	OpenDataProcessorSettingsForm();
EndProcedure

&AtServer
Function ProcessQuotationMarksInRow(String)
	Return StrReplace(String, """", """""");
EndFunction

&AtServer
Function ThisObject(CurrentObject = Undefined) 
	If CurrentObject = Undefined Then
		Return FormAttributeToValue("Object");
	EndIf;
	ValueToFormAttribute(CurrentObject, "Object");
	Return Undefined;
EndFunction

&AtServer
Function GetFormName(CurrentObject = Undefined)
	Return ThisObject().GetFormName(CurrentObject);
EndFunction

&AtServer
Procedure ChangeMark(String)
	DataElement = MetadataTree.FindByID(String);
	ThisObject().ChangeMark(DataElement);
EndProcedure

&AtServer
Procedure ReadMetadataTree()
	Data = ThisObject().GenerateMetadataStructure(ExchangeNodeReference);
	
	// Deleting rows that cannot be edited.
	MetaTree = Data.Tree;
	For Each ListItem In Object.NamesOfMetadataToHide Do
		DeleteMetadataValueTreeRows(ListItem.Value, MetaTree.Rows);
	EndDo;
	
	ValueToFormAttribute(MetaTree, "MetadataTree");
	MetadataAutoRecordStructure = Data.AutoRecordStructure;
	MetadataPresentationsStructure   = Data.PresentationsStructure;
	MetadataNamesStructure            = Data.NamesStructure;
EndProcedure

&AtServer 
Procedure DeleteMetadataValueTreeRows(Val MetaFullName, TreeRows)
	If IsBlankString(MetaFullName) Then
		Return;
	EndIf;
	
	// In the current set.
	Filter = New Structure("MetaFullName", MetaFullName);
	For Each DeletionRow In TreeRows.FindRows(Filter, False) Do
		TreeRows.Delete(DeletionRow);
		// If there are no subordinate rows left, deleting the parent row.
		If TreeRows.Count() = 0 Then
			ParentString = TreeRows.Parent;
			If ParentString.Parent <> Undefined Then
				ParentString.Parent.Rows.Delete(ParentString);
				// There are no subordinate rows.
				Return;
			EndIf;
		EndIf;
	EndDo;
	
	// Deleting subordinate row recursively.
	For Each TreeRow In TreeRows Do
		DeleteMetadataValueTreeRows(MetaFullName, TreeRow.Rows);
	EndDo;
EndProcedure

&AtServer
Procedure FormatChangeCount(String)
	String.ChangeCountString = Format(String.ChangeCount, "NZ=0;") + " / " + Format(String.NotExportedCount, "NZ=0;");
EndProcedure

&AtServer
Procedure FillRegistrationCountInTreeRows()
	
	Data = ThisObject().GetChangeCount(MetadataNamesStructure, ExchangeNodeReference);
	
	// Insert values to the tree.
	Filter = New Structure("MetaFullName, ExchangeNode", Undefined, ExchangeNodeReference);
	Zeros   = New Structure("ChangeCount, ExportedCount, NotExportedCount", 0,0,0);
	
	For Each Root In MetadataTree.GetItems() Do
		RootSum = New Structure("ChangeCount, ExportedCount, NotExportedCount", 0,0,0);
		
		For Each Var_Group In Root.GetItems() Do
			GroupSum = New Structure("ChangeCount, ExportedCount, NotExportedCount", 0,0,0);
			
			NodesList = Var_Group.GetItems();
			If NodesList.Count() = 0 And MetadataNamesStructure.Property(Var_Group.MetaFullName) Then
				// Node collection without nodes, sum manually, and take autoregistration from structure.
				For Each MetaName1 In MetadataNamesStructure[Var_Group.MetaFullName] Do
					Filter.MetaFullName = MetaName1;
					Found4 = Data.FindRows(Filter);
					If Found4.Count() > 0 Then
						String = Found4[0];
						GroupSum.ChangeCount     = GroupSum.ChangeCount     + String.ChangeCount;
						GroupSum.ExportedCount   = GroupSum.ExportedCount   + String.ExportedCount;
						GroupSum.NotExportedCount = GroupSum.NotExportedCount + String.NotExportedCount;
					EndIf;
				EndDo;
				
			Else
				// Calculating count values for each node
				For Each Node In NodesList Do
					Filter.MetaFullName = Node.MetaFullName;
					Found4 = Data.FindRows(Filter);
					If Found4.Count() > 0 Then
						String = Found4[0];
						FillPropertyValues(Node, String, "ChangeCount, ExportedCount, NotExportedCount");
						GroupSum.ChangeCount     = GroupSum.ChangeCount     + String.ChangeCount;
						GroupSum.ExportedCount   = GroupSum.ExportedCount   + String.ExportedCount;
						GroupSum.NotExportedCount = GroupSum.NotExportedCount + String.NotExportedCount;
					Else
						FillPropertyValues(Node, Zeros);
					EndIf;
					
					FormatChangeCount(Node);
				EndDo;
				
			EndIf;
			FillPropertyValues(Var_Group, GroupSum);
			
			RootSum.ChangeCount     = RootSum.ChangeCount     + Var_Group.ChangeCount;
			RootSum.ExportedCount   = RootSum.ExportedCount   + Var_Group.ExportedCount;
			RootSum.NotExportedCount = RootSum.NotExportedCount + Var_Group.NotExportedCount;
			
			FormatChangeCount(Var_Group);
		EndDo;
		
		FillPropertyValues(Root, RootSum);
		
		FormatChangeCount(Root);
	EndDo;
	
EndProcedure

&AtServer
Function ChangeQueryResultRegistrationServer(Command, Address)
	
	Result = GetFromTempStorage(Address);
	Result= Result[Result.UBound()];
	Data = Result.Unload().UnloadColumn("Ref");
	
	If Command Then
		Return AddRegistrationAtServer(True, Data);
	EndIf;
		
	Return DeleteRegistrationAtServer(True, Data);
EndFunction

&AtServer
Function RefControlForQuerySelection(Address)
	
	Result = ?(Address = Undefined, Undefined, GetFromTempStorage(Address));
	If TypeOf(Result) = Type("Array") Then 
		Result = Result[Result.UBound()];	
		If Result.Columns.Find("Ref") = Undefined Then
			Return NStr("vi = 'Trong kết quả truy vấn gần nhất không có cột ""Tham chiếu""';
						|ru = 'В последнем результате запроса отсутствует колонка ""Ссылка""';
						|en = 'The last query result is missing the ""Reference"" column'; fa = 'The last query result is missing the ""Reference"" column';
						|it = 'Nell''ultimo risultato della richiesta manca la colonna ""Link""';
						|pl = 'W ostatnim wyniku zapytania brakuje kolumny ""Odnośnik""';
						|tr = 'Son sorgu sonucunda ""Referans"" sütününü eksik'");
		EndIf;
	Else		
		Return NStr("vi = 'Lỗi nhận dữ liệu kết quả truy vấn';
					|ru = 'Ошибка получения данных результата запроса';
					|en = 'Error getting query result'; fa = 'Error getting query result';
					|it = 'Errore della ricezione dei dati del risultato della richiesta';
					|pl = 'Błąd podczas pobierania danych wyniku zapytania';
					|tr = 'Sorgu sonucu verileri alınırken hata oluştu'");
	EndIf;
	
	Return "";
EndFunction

&AtServer
Procedure SetUpChangeEditingServer(CurrentRow)
	
	If CurrentRow = Undefined Then
		
		TableName = "";
		Description = MetadataTree.GetItems()[0].Description;
		CurrentObject = Undefined;
		
	Else
		
		Data = MetadataTree.FindByID(CurrentRow);
		If Data = Undefined Then
			Return;
		EndIf;
		
		TableName   = Data.MetaFullName;
		Description = Data.Description;
		CurrentObject   = ThisObject();
		
	EndIf;
	
	If IsBlankString(TableName) Then
		Meta = Undefined;
	Else		
		Meta = CurrentObject.MetadataByFullName(TableName);
	EndIf;
	
	If Meta = Undefined Then
		SetUpEmptyPage(Description, TableName);
		NewPage1 = Items.BlankPage;
		
	ElsIf Meta = Metadata.Constants Then
		// All constants are included in the list
		SetUpConstantList();
		NewPage1 = Items.ConstantsPage;
		
	ElsIf TypeOf(Meta) = Type("MetadataObjectCollection") Then
		// All catalogs, all documents, and so on
		SetUpEmptyPage(Description, TableName);
		NewPage1 = Items.BlankPage;
		
	ElsIf Metadata.Constants.Contains(Meta) Then
		// One constant.
		SetUpConstantList(TableName, Description);
		NewPage1 = Items.ConstantsPage;
		
	ElsIf Metadata.Catalogs.Contains(Meta) 
		Or Metadata.Documents.Contains(Meta)
		Or Metadata.ChartsOfCharacteristicTypes.Contains(Meta)
		Or Metadata.ChartsOfAccounts.Contains(Meta)
		Or Metadata.ChartsOfCalculationTypes.Contains(Meta)
		Or Metadata.BusinessProcesses.Contains(Meta)
		Or Metadata.Tasks.Contains(Meta) Then
		// Reference data type.
		SetUpRefList(TableName, Description);
		NewPage1 = Items.ReferencesListPage;
		
	Else
		// Checking whether a record set is passed
		Dimensions = CurrentObject.RecordSetDimensions(TableName);
		If Dimensions <> Undefined Then
			SetUpRecordSet(TableName, Dimensions, Description);
			NewPage1 = Items.RecordSetPage;
		Else
			SetUpEmptyPage(Description, TableName);
			NewPage1 = Items.BlankPage;
		EndIf;
		
	EndIf;
	
	Items.ConstantsPage.Visible    = False;
	Items.ReferencesListPage.Visible = False;
	Items.RecordSetPage.Visible = False;
	Items.BlankPage.Visible       = False;
	
	Items.ObjectsListOptions.CurrentPage = NewPage1;
	NewPage1.Visible = True;
	
	SetUpGeneralMenuCommandVisibility();
	
EndProcedure

// Displaying changes for a reference type (catalog, document, chart of characteristic types, 
// chart of accounts, calculation type, business processes, tasks).
//
&AtServer
Procedure SetUpRefList(TableName, Description)
	
	ListProperties = DynamicListPropertiesStructure();
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = 
	"SELECT
	|	ChangesTable.Ref AS Ref,
	|	ChangesTable.MessageNo AS MessageNo,
	|	CASE
	|		WHEN ChangesTable.MessageNo IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS NotExported,
	|	MainTable.Ref AS ObjectRef2
	|FROM
	|	&NameOfTheChangeMetadataTable AS ChangesTable
	|		LEFT JOIN &MetadataTableName AS MainTable
	|		ON ChangesTable.Ref = MainTable.Ref
	|WHERE
	|	ChangesTable.Node = &SelectedNode";
	
	ListProperties.QueryText = StrReplace(ListProperties.QueryText, "&NameOfTheChangeMetadataTable", TableName + ".Changes");
	ListProperties.QueryText = StrReplace(ListProperties.QueryText, "&MetadataTableName", TableName);
		
	SetDynamicListProperties(Items.ReferenceList, ListProperties);
	
	ReferenceList.Parameters.SetParameterValue("SelectedNode", ExchangeNodeReference);
	ReferencesListTableName = TableName;
	
	// Object presentation.
	Meta = ThisObject().MetadataByFullName(TableName);
	CurTitle = Meta.ObjectPresentation;
	If IsBlankString(CurTitle) Then
		CurTitle = Description;
	EndIf;
	Items.ReferencesListRefPresentation.Title = CurTitle;
EndProcedure

// Displaying changes for constants.
//
&AtServer
Procedure SetUpConstantList(TableName = Undefined, Description = "")
	
	If TableName = Undefined Then
		// All constants.
		Names = MetadataNamesStructure.Constants;
		Presentations = MetadataPresentationsStructure.Constants;
		AutoRecord = MetadataAutoRecordStructure.Constants;
	Else
		Names = New Array;
		Names.Add(TableName);
		Presentations = New Array;
		Presentations.Add(Description);
		IndexOf = MetadataNamesStructure.Constants.Find(TableName);
		AutoRecord = New Array;
		AutoRecord.Add(MetadataAutoRecordStructure.Constants[IndexOf]);
	EndIf;
	
	QueryTextTemplate2 = 
	"SELECT
	|	&AutoRecordPictureIndex AS AutoRecordPictureIndex,
	|	2 AS PictureIndex,
	|	""&CustomRepresentationOfAConstant"" AS Description,
	|	""&MetadataTableNamePresentation"" AS MetaFullName,
	|	ChangesTable.MessageNo AS MessageNo,
	|	CASE
	|		WHEN ChangesTable.MessageNo IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS NotExported
	|FROM
	|	&MetadataTableName AS ChangesTable
	|WHERE
	|	ChangesTable.Node = &SelectedNode";
	
	// The limit to the number of tables must be considered.
	Text = "";
	For IndexOf = 0 To Names.UBound() Do
		
		Name = Names[IndexOf];
		
		If Not IsBlankString(Text) Then
			
			Text = Text + Chars.LF + Chars.LF + "UNION ALL" + Chars.LF + Chars.LF;
			
		EndIf;
		
		SubqueryText = StrReplace(QueryTextTemplate2, "&AutoRecordPictureIndex", Format(AutoRecord[IndexOf], "NZ=; NG="));
		SubqueryText = StrReplace(SubqueryText, "&CustomRepresentationOfAConstant", ProcessQuotationMarksInRow(Presentations[IndexOf]));
		SubqueryText = StrReplace(SubqueryText, "&MetadataTableNamePresentation", Name);
		SubqueryText = StrReplace(SubqueryText, "&MetadataTableName", SubstituteParametersToString("%1.Changes", Name));
		
		Text = Text + SubqueryText;
		
	EndDo;
	
	ListProperties = DynamicListPropertiesStructure();
	ListProperties.DynamicDataRead = True;
	
	ResultingQueryText = 
	"SELECT
	|	AutoRecordPictureIndex,
	|	PictureIndex,
	|	MetaFullName,
	|	NotExported,
	|	Description,
	|	MessageNo
	|{SELECT
	|	AutoRecordPictureIndex,
	|	PictureIndex,
	|	Description,
	|	MetaFullName,
	|	MessageNo,
	|	NotExported}
	|FROM
	|	&TheTextOfASubquery AS Data
	|{WHERE
	|	Description,
	|	MessageNo,
	|	NotExported}";
	
	ResultingQueryText = StrReplace(ResultingQueryText, "&TheTextOfASubquery", SubstituteParametersToString("(%1)", Text));
	ListProperties.QueryText = ResultingQueryText;
	
	SetDynamicListProperties(Items.ConstantsList, ListProperties);
		
	ListItems = ConstantsList.Order.Items;
	If ListItems.Count() = 0 Then
		Item = ListItems.Add(Type("DataCompositionOrderItem"));
		Item.Field = New DataCompositionField("Description");
		Item.Use = True;
	EndIf;
	
	ConstantsList.Parameters.SetParameterValue("SelectedNode", ExchangeNodeReference);
EndProcedure	

// Displaying cap with an empty page.
&AtServer
Procedure SetUpEmptyPage(Description, TableName = Undefined)
	
	If TableName = Undefined Then
		CountsText = "";
	Else
		Tree = FormAttributeToValue("MetadataTree");
		String = Tree.Rows.Find(TableName, "MetaFullName", True);
		If String <> Undefined Then
			CountsText = NStr("vi = 'Đã ghi nhận %1 đối tượng
			                          |Đã kết xuất %2 đối tượng
			                          |Chưa kết xuất %3 đối tượng';
			                          |ru = 'Зарегистрировано объектов: %1
			                          |Выгружено объектов: %2
			                          |Не выгружено объектов: %3';
			                          |en = 'Items registered: %1
			                          |Items exported: %2
			                          |Items pending export: %3'; fa = 'Items registered: %1
			                          |Items exported: %2
			                          |Items pending export: %3';
			                          |it = 'Oggetti registrati: %1
			                          |Oggetti scaricati: %2
			                          |Oggetti non scaricati: %3';
			                          |pl = 'Zarejestrowano obiektów: %1
			                          |Wyładowano obiektów: %2 
			                          | Nie wyładowano obiektów: %3';
			                          |tr = 'Kaydedilen nesneler: %1
			                          |Dışa aktarılan nesneler: %2
			                          |Dışa aktarılmayan nesneler: %3'");
	
			CountsText = StrReplace(CountsText, "%1", Format(String.ChangeCount, "NFD=0; NZ="));
			CountsText = StrReplace(CountsText, "%2", Format(String.ExportedCount, "NFD=0; NZ="));
			CountsText = StrReplace(CountsText, "%3", Format(String.NotExportedCount, "NFD=0; NZ="));
		EndIf;
	EndIf;
	
	Text = NStr("vi = '%1.
	                 |
	                 |%2
	                 |Để ghi nhận hoặc hủy ghi nhận trao đổi dữ liệu tại nút
	                 |""%3""
	                 |hãy chọn kiểu đối tượng bên trái trong cây metadata và sử dụng
	                 |lệnh ""Ghi nhận"" hoặc ""Hủy ghi nhận""';
	                 |ru = '%1.
	                 |
	                 |%2
	                 |Для регистрации или отмены регистрации обмена данными на узле
	                 |""%3""
	                 |выберите тип объекта слева в дереве метаданных и воспользуйтесь
	                 |командами ""Зарегистрировать"" или ""Отменить регистрацию""';
	                 |en = '%1.
	                 |
	                 |%2
	                 |
	                 |To register or unregister items for exchange with node ""%3"",
	                 |select an object in the metadata object tree and click Register or Unregister.
	                 |'; fa = '%1.
	                 |
	                 |%2
	                 |
	                 |To register or unregister items for exchange with node ""%3"",
	                 |select an object in the metadata object tree and click Register or Unregister.
	                 |';
	                 |it = '%1.
	                 |
	                 |%2
	                 |Per registrare o annullare la registrazione di scambio dati sul nodo
	                 |""%3""
	                 |selezionare il tipo dell''oggetto a sinistra nell''albero dei metadati e utilizzare
	                 |comandi ""Registrare"" o ""Annullare la registrazione""';
	                 |pl = '%1.
	                 |
	                 |%2
	                 |Dla rejestracji lub anulowania rejestracji wymiany danych na węźle
	                 |""%3""
	                 |wybierz rodzaj obiektu po lewej stronie w drzewie metadanych i skorzystaj
	                 |z komend ""Zarejestrować"" lub ""Anulować rejestrację""';
	                 |tr = '%1.
	                 |
	                 |%2
	                 |Kayıt için veya 
	                 |""%3""
	                 |ünitesinde kayıt iptali için solda meta veri nesne ağacında nesne türünü seçin ve
	                 |""Kaydet"" veya ""Kaydı iptal et"" komutlarını kullanın'");
		
	Text = StrReplace(Text, "%1", Description);
	Text = StrReplace(Text, "%2", CountsText);
	Text = StrReplace(Text, "%3", ExchangeNodeReference);
	Items.EmptyPageDecoration.Title = Text;
EndProcedure

// Displaying changes for record sets.
//
&AtServer
Procedure SetUpRecordSet(TableName, Dimensions, Description)
	
	ChoiceText = "";
	Prefix     = "RecordSetsList";
	For Each String In Dimensions Do
		Name = String.Name;
		ChoiceText = ChoiceText + ",ChangesTable." + Name + " AS " + Prefix + Name + Chars.LF;
		// Adding the prefix to exclude the MessageNumber and NotExported dimensions.
		String.Name = Prefix + Name;
	EndDo;
	
	ListProperties = DynamicListPropertiesStructure();
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = 
	"SELECT ALLOWED
	|	ChangesTable.MessageNo AS MessageNo,
	|	CASE 
	|		WHEN ChangesTable.MessageNo IS NULL THEN TRUE ELSE FALSE
	|	END AS NotExported
	|
	|	" + ChoiceText + "
	|FROM
	|	" + TableName + ".Changes AS ChangesTable
	|WHERE
	|	ChangesTable.Node = &SelectedNode";
	
	SetDynamicListProperties(Items.RecordSetsList, ListProperties);
	
	RecordSetsList.Parameters.SetParameterValue("SelectedNode", ExchangeNodeReference);
	
	// Adding columns to the appropriate group.
	ThisObject().AddColumnsToFormTable(
		Items.RecordSetsList, 
		"MessageNo, NotExported, 
		|Order, Filter, Group, StandardPicture, Parameters, ConditionalAppearance",
		Dimensions,
		Items.RecordSetsListDimensionsGroup);
	
	RecordSetsListTableName = TableName;
EndProcedure

// Common filter by the MessageNumber field.
//
&AtServer
Procedure SetFilterByMessageNo(DynamList, Variant)
	
	Field = New DataCompositionField("NotExported");
	// Iterating through the filter item list to delete a specific item.
	ListItems = DynamList.Filter.Items;
	IndexOf = ListItems.Count();
	While IndexOf > 0 Do
		IndexOf = IndexOf - 1;
		Item = ListItems[IndexOf];
		If Item.LeftValue = Field Then 
			ListItems.Delete(Item);
		EndIf;
	EndDo;
	
	FilterElement = ListItems.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = Field;
	FilterElement.ComparisonType  = DataCompositionComparisonType.Equal;
	FilterElement.Use = False;
	FilterElement.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	If Variant = 1 Then 		// Exported items.
		FilterElement.RightValue = False;
		FilterElement.Use  = True;
		
	ElsIf Variant = 2 Then	// Not exported items.
		FilterElement.RightValue = True;
		FilterElement.Use  = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetUpGeneralMenuCommandVisibility()
	
	CurrRow = Items.ObjectsListOptions.CurrentPage;
	
	If CurrRow = Items.ConstantsPage Then
		Items.FormAddRegistrationForSingleObject.Enabled = True;
		Items.FormAddRegistrationFilter.Enabled         = False;
		Items.FormDeleteRegistrationForSingleObject.Enabled  = True;
		Items.FormDeleteRegistrationFilter.Enabled          = False;
		
	ElsIf CurrRow = Items.ReferencesListPage Then
		Items.FormAddRegistrationForSingleObject.Enabled = True;
		Items.FormAddRegistrationFilter.Enabled         = True;
		Items.FormDeleteRegistrationForSingleObject.Enabled  = True;
		Items.FormDeleteRegistrationFilter.Enabled          = True;
		
	ElsIf CurrRow = Items.RecordSetPage Then
		Items.FormAddRegistrationForSingleObject.Enabled = True;
		Items.FormAddRegistrationFilter.Enabled         = False;
		Items.FormDeleteRegistrationForSingleObject.Enabled  = True;
		Items.FormDeleteRegistrationFilter.Enabled          = False;
		
	Else
		Items.FormAddRegistrationForSingleObject.Enabled = False;
		Items.FormAddRegistrationFilter.Enabled         = False;
		Items.FormDeleteRegistrationForSingleObject.Enabled  = False;
		Items.FormDeleteRegistrationFilter.Enabled          = False;
		
	EndIf;
	
EndProcedure

&AtServer
Function RecordSetKeyNameArray(TableName, NamePrefix = "")
	Result = New Array;
	Dimensions = ThisObject().RecordSetDimensions(TableName);
	If Dimensions <> Undefined Then
		For Each String In Dimensions Do
			Result.Add(NamePrefix + String.Name);
		EndDo;
	EndIf;
	Return Result;
EndFunction	

&AtServer
Function GetManagerByMetadata(TableName) 
	LongDesc = ThisObject().MetadataCharacteristics(TableName);
	If LongDesc <> Undefined Then
		Return LongDesc.Manager;
	EndIf;
	Return Undefined;
EndFunction

&AtServer
Function SerializationText(Serialization)
	
	DataProcessorObject = ThisObject();
	
	Text = New TextDocument;
	
	Record = New XMLWriter;
	For Each Item In Serialization Do
		Record.SetString("UTF-16");
		Value = Undefined;
		
		If Item.TypeFlag = 1 Then
			// Metadata
			Manager = GetManagerByMetadata(Item.Data);
			Value = Manager.CreateValueManager();
			
		ElsIf Item.TypeFlag = 2 Then
			// Creating record set with a filter
			Manager = GetManagerByMetadata(RecordSetsListTableName);
			Value = Manager.CreateRecordSet();
			For Each NameValue In Item.Data Do
				DataProcessorObject.SetFilterItemValue(Value.Filter, NameValue.Key, NameValue.Value);
			EndDo;
			Value.Read();
			
		ElsIf Item.TypeFlag = 3 Then
			// Reference
			Value = Item.Data.GetObject();
			If Value = Undefined Then
				Value = New ObjectDeletion(Item.Data);
			EndIf;
		EndIf;
		
		WriteXML(Record, Value);
		Text.AddLine(Record.Close());
	EndDo;
	
	Return Text;
EndFunction	

&AtServer
Function DeleteRegistrationAtServer(NoAutoRegistration, ItemsToDelete, TableName = Undefined)
	RegistrationParameters = PrepareRegistrationChangeParameters(False, NoAutoRegistration, ItemsToDelete, TableName);
	Return ThisObject().ChangeRegistration(RegistrationParameters);
EndFunction

&AtServer
Function AddRegistrationAtServer(NoAutoRegistration, ItemsToAdd, TableName = Undefined)
	RegistrationParameters = PrepareRegistrationChangeParameters(True, NoAutoRegistration, ItemsToAdd, TableName);
	Return ThisObject().ChangeRegistration(RegistrationParameters);
EndFunction

&AtServer
Function EditMessageNumberAtServer(MessageNo, Data, TableName = Undefined)
	RegistrationParameters = PrepareRegistrationChangeParameters(MessageNo, True, Data, TableName);
	Return ThisObject().ChangeRegistration(RegistrationParameters);
EndFunction

&AtServer
Function GetSelectedMetadataDetails(NoAutoRegistration, MetaGroupName = Undefined, MetaNodeName = Undefined)
    
	If MetaGroupName = Undefined And MetaNodeName = Undefined Then
		// No item selected.
		Text = NStr("vi = 'tất cả đối tượng %1 theo phân nhánh đã chọn của dạng';
					|ru = 'все объекты %1 по выбранной иерархии вида';
					|en = 'all items %1 of the metadata type'; fa = 'all items %1 of the metadata type';
					|it = 'tutti gli oggetti %1 per la gerarchia del tipo selezionata';
					|pl = 'wszystkie obiekty %1 według wybranej hierarchii rodzaju';
					|tr = 'meta veri türündeki tüm öğeler %1'");
		
	ElsIf MetaGroupName <> Undefined And MetaNodeName = Undefined Then
		// Only a group is specified.
		Text = "%2 %1";
		
	ElsIf MetaGroupName = Undefined And MetaNodeName <> Undefined Then
		// Only a node is specified.
		Text = NStr("vi = 'tất cả đối tượng %1 theo phân nhánh đã chọn của dạng';
					|ru = 'все объекты %1 по выбранной иерархии вида';
					|en = 'all items %1 of the metadata type'; fa = 'all items %1 of the metadata type';
					|it = 'tutti gli oggetti %1 per la gerarchia del tipo selezionata';
					|pl = 'wszystkie obiekty %1 według wybranej hierarchii rodzaju';
					|tr = 'meta veri türündeki tüm öğeler %1'");
		
	Else
		// A group and a node are specified, using these values to obtain a metadata presentation.
		Text = NStr("vi = 'tất cả đối tượng có kiểu ""%3"" %1';
					|ru = 'все объекты типа ""%3"" %1';
					|en = 'all items of type ""%3"" %1'; fa = 'all items of type ""%3"" %1';
					|it = 'tutti gli oggetti del tipo ""%3"" %1';
					|pl = 'wszystkie obiekty rodzaju ""%3"" %1';
					|tr = '""%3"" %1 türlü tüm nesneler'");
		
	EndIf;
	
	If NoAutoRegistration Then
		FlagText = "";
	Else
		FlagText = NStr("vi = 'có dấu hiệu tự động ghi nhận';
						|ru = 'с признаком авторегистрации';
						|en = 'with Autoregistration flag'; fa = 'with Autoregistration flag';
						|it = 'con criterio di registrazione automatica';
						|pl = 'z cechą rejestracji automatycznej';
						|tr = 'Otomatik hazırlama işaretli'");
	EndIf;
	
	Presentation = "";
	For Each KeyValue In MetadataPresentationsStructure Do
		If KeyValue.Key = MetaGroupName Then
			IndexOf = MetadataNamesStructure[MetaGroupName].Find(MetaNodeName);
			Presentation = ?(IndexOf = Undefined, "", KeyValue.Value[IndexOf]);
			Break;
		EndIf;
	EndDo;
	
	Text = StrReplace(Text, "%1", FlagText);
	Text = StrReplace(Text, "%2", Lower(MetaGroupName));
	Text = StrReplace(Text, "%3", Presentation);
	
	Return TrimAll(Text);
EndFunction

&AtServer
Function GetCurrentRowMetadataNames(NoAutoRegistration) 
	
	String = MetadataTree.FindByID(Items.MetadataTree.CurrentRow);
	If String = Undefined Then
		Return Undefined;
	EndIf;
	
	Result = New Structure("MetaNames, LongDesc", 
		New Array, GetSelectedMetadataDetails(NoAutoRegistration));
	MetaName1 = String.MetaFullName;
	If IsBlankString(MetaName1) Then
		// Unmarked configuration root
		Result.MetaNames.Add(Undefined);	
	Else
		Parent = String.GetParent();
		MetaParentName = Parent.MetaFullName;
		If IsBlankString(MetaParentName) Then
			
			If MetadataNamesStructure.Property(MetaName1) Then
				Result.MetaNames = MetadataNamesStructure[MetaName1];
			Else
				Result.MetaNames.Add(MetaName1);
			EndIf;
			
			Result.LongDesc = GetSelectedMetadataDetails(NoAutoRegistration, String.Description);
		Else
			Result.MetaNames.Add(MetaName1);	
			Result.LongDesc = GetSelectedMetadataDetails(NoAutoRegistration, MetaParentName, MetaName1);
		EndIf;
	EndIf;
	
	Return Result;
EndFunction

&AtServer
Function GetSelectedMetadataNames(NoAutoRegistration)
	
	Result = New Structure("MetaNames, LongDesc", 
		New Array, GetSelectedMetadataDetails(NoAutoRegistration));
	
	For Each Root In MetadataTree.GetItems() Do
		
		If Root.Check = 1 Then
			Result.MetaNames.Add(Undefined);
			Return Result;
		EndIf;
		
		NumberOfPartial = 0;
		GroupCount     = 0;
		NodeCount     = 0;
		For Each Var_Group In Root.GetItems() Do
			
			If Var_Group.Check = 0 Then
				Continue;
			ElsIf Var_Group.Check = 1 Then
				//	Getting data of the selected group.
				GroupCount = GroupCount + 1;
				GroupDetails = GetSelectedMetadataDetails(NoAutoRegistration, Var_Group.Description);
				
				If Var_Group.GetItems().Count() = 0 Then
					// Reading marked data from the metadata names structure.
					AutoArray = MetadataAutoRecordStructure[Var_Group.MetaFullName];
					NamesArray = MetadataNamesStructure[Var_Group.MetaFullName];
					For IndexOf = 0 To NamesArray.UBound() Do
						If NoAutoRegistration Or AutoArray[IndexOf] = 2 Then
							Result.MetaNames.Add(NamesArray[IndexOf]);
							NodeDetails = GetSelectedMetadataDetails(NoAutoRegistration, Var_Group.MetaFullName, NamesArray[IndexOf]);
						EndIf;
					EndDo;
					
					Continue;
				EndIf;
				
			Else
				NumberOfPartial = NumberOfPartial + 1;
			EndIf;
			
			For Each Node In Var_Group.GetItems() Do
				If Node.Check = 1 Then
					// Node.AutoRecord = 2 -> allowed
					If NoAutoRegistration Or Node.AutoRecord = 2 Then
						Result.MetaNames.Add(Node.MetaFullName);
						NodeDetails = GetSelectedMetadataDetails(NoAutoRegistration, Var_Group.MetaFullName, Node.MetaFullName);
						NodeCount = NodeCount + 1;
					EndIf;
				EndIf
			EndDo;
			
		EndDo;
		
		If GroupCount = 1 And NumberOfPartial = 0 Then
			Result.LongDesc = GroupDetails;
		ElsIf GroupCount = 0 And NodeCount = 1 Then
			Result.LongDesc = NodeDetails;
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

&AtServer
Function ReadMessageNumbers()
	
	QueryAttributes = "SentNo, ReceivedNo";
	
	Data = ThisObject().GetExchangeNodeParameters(ExchangeNodeReference, QueryAttributes);
	
	Return Data;
	
EndFunction

&AtServer
Procedure ProcessNodeChangeProhibition()
	OperationsAllowed = Not SelectExchangeNodeProhibited;
	
	If OperationsAllowed Then
		Items.ExchangeNodeReference.Visible = True;
		Title = NStr("vi = 'Ghi nhận thay đổi để trao đổi dữ liệu';
					|ru = 'Регистрация изменений для обмена данными';
					|en = 'Data registration manager'; fa = 'مدیر ثبت داده';
					|it = 'Registrare le modifiche per scambio dati';
					|pl = 'Rejestracja zmian do wymiany danych';
					|tr = 'Veri hazırlama yöneticisi'");
	Else
		Items.ExchangeNodeReference.Visible = False;
		Title = StrReplace(NStr("vi = 'Ghi nhận thay đổi để trao đổi với ""%1""';
								|ru = 'Регистрация изменений для обмена с  ""%1""';
								|en = 'Data registration manager: Exchange with ""%1""'; fa = 'Data registration manager: Exchange with ""%1""';
								|it = 'Registrazione delle modifiche per scambio con ""%1""';
								|pl = 'Rejestracja zmian dla wymiany z ""%1""';
								|tr = '""%1"" ile veri alışverişi için değişiklikleri kaydedin'"), "%1", String(ExchangeNodeReference));
	EndIf;
	
	Items.FormOpenNodeRegistrationForm.Visible = OperationsAllowed;
	
	Items.ConstantsListContextMenuOpenNodeRegistrationForm.Visible       = OperationsAllowed;
	Items.ReferenceListContextMenuOpenNodeRegistrationForm.Visible         = OperationsAllowed;
	Items.RecordSetsListContextMenuOpenNodeRegistrationForm.Visible = OperationsAllowed;
EndProcedure

&AtServer
Function ControlSettings()
	Result = True;
	
	// Checking a specified exchange node.
	CurrentObject = ThisObject();
	If ExchangeNodeReference <> Undefined And ExchangePlans.AllRefsType().ContainsType(TypeOf(ExchangeNodeReference)) Then
		AllowedExchangeNodes = CurrentObject.GenerateNodeTree();
		PlanName = ExchangeNodeReference.Metadata().Name;
		If AllowedExchangeNodes.Rows.Find(PlanName, "ExchangePlanName1", True) = Undefined Then
			// A node with an invalid exchange plan.
			ExchangeNodeReference = Undefined;
			Result = False;
		ElsIf ExchangeNodeReference = ExchangePlans[PlanName].ThisNode() Then
			// This node.
			ExchangeNodeReference = Undefined;
			Result = False;
		EndIf;
	EndIf;
	
	If ValueIsFilled(ExchangeNodeReference) Then
		ExchangeNodeChoiceProcessingServer();
	EndIf;
	ProcessNodeChangeProhibition();
	
	// Settings dependencies.
	SetFiltersInDynamicLists();
	
	Return Result;
EndFunction

&AtServer
Procedure SetFiltersInDynamicLists()
	SetFilterByMessageNo(ConstantsList,       FilterByMessageNumberOption);
	SetFilterByMessageNo(ReferenceList,         FilterByMessageNumberOption);
	SetFilterByMessageNo(RecordSetsList, FilterByMessageNumberOption);
EndProcedure

&AtServer
Function RecordSetKeyStructure(Val CurrentData)
	
	DataProcessorObject = ThisObject();
	
	LongDesc = DataProcessorObject.MetadataCharacteristics(RecordSetsListTableName);
	
	If LongDesc = Undefined Then
		// Unknown source.
		Return Undefined;
	EndIf;
	
	Result = New Structure("FormName, Parameter, Value");
	
	Dimensions = New Structure;
	KeysNames = RecordSetKeyNameArray(RecordSetsListTableName);
	
	For Each Name In KeysNames Do
		ColumnName = "RecordSetsList" + Name;
		If CurrentData.Property(ColumnName) Then
			Dimensions.Insert(Name, CurrentData[ColumnName]);
		EndIf;	
	EndDo;
	
	If Dimensions.Property("Recorder") Then
		MetaRecorder = Metadata.FindByType(TypeOf(Dimensions.Recorder));
		If MetaRecorder = Undefined Then
			Result = Undefined;
		Else
			Result.FormName = MetaRecorder.FullName() + ".ObjectForm";
			Result.Parameter = "Key";
			Result.Value = Dimensions.Recorder;
		EndIf;
		
	ElsIf Dimensions.Count() = 0 Then
		// Degenerated record set.
		Result.FormName = RecordSetsListTableName + ".ListForm";
		
	Else
		Set = LongDesc.Manager.CreateRecordSet(); // InformationRegisterRecordSet, etc.
		For Each KeyValue In Dimensions Do
			DataProcessorObject.SetFilterItemValue(Set.Filter, KeyValue.Key, KeyValue.Value);
		EndDo;
		Set.Read();
		If Set.Count() = 1 Then
			// Single item.
			Result.FormName = RecordSetsListTableName + ".RecordForm";
			Result.Parameter = "Key";
			
			Var_Key = New Structure;
			For Each SetColumn In Set.Unload().Columns Do
				ColumnName = SetColumn.Name;
				Var_Key.Insert(ColumnName, Set[0][ColumnName]);
			EndDo;
			Result.Value = LongDesc.Manager.CreateRecordKey(Var_Key);
		Else
			// List
			Result.FormName = RecordSetsListTableName + ".ListForm";
			Result.Parameter = "Filter";
			Result.Value = Dimensions;
		EndIf;
		
	EndIf;
	
	Return Result;
EndFunction

&AtServer
Procedure CheckPlatformVersionAndCompatibilityMode()
	
	Information = New SystemInfo;
	VersionParts = StrSplit(Information.AppVersion, ".");
	If Not (Not (VersionParts.Count() < 2 Or Number(VersionParts[0]) < 8 Or Number(VersionParts[1]) < 3)
		And (Metadata.CompatibilityMode = Metadata.ObjectProperties.CompatibilityMode.DontUse
		Or (Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode.Version8_1
		And Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode.Version8_2_13
		And Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_2_16"]
		And Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_3_1"]
		And Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_3_2"]
		And Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_3_3"]
		And Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_3_4"]))) Then
		
		Raise NStr("vi = 'Bộ xử lý được dùng để khởi động phiên bản nền tảng
			|1C:Enterprise 8.3.5 tắt chế độ tương thích hoặc cao hơn';
			|ru = 'Обработка предназначена для запуска на версии платформы
			|1С:Предприятие 8.3.5 с отключенным режимом совместимости или выше';
			|en = 'The data processor supports 1C:Enterprise 8.3.5 or later,
			|with disabled compatibility mode.'; fa = 'The data processor supports 1C:Enterprise 8.3.5 or later,
			|with disabled compatibility mode.';
			|it = 'L''elaborazione è progettata per essere avviata nella versione della piattaforma
			|1C:Enterprise 8.3.5 con la modalità di compatibilità disabilitata o superiore';
			|pl = 'Przetwarzanie jest przeznaczone do uruchamiania w wersji platformy
			|1C:Enterprise 8.3.5 z wyłączonym trybem zgodności lub wyżej';
			|tr = 'İşleme, 
			|1C:Enterprise 8.3 platform sürümünde (veya üzeri) uyumluluk modu kapalı olarak başlamak için kullanılır'");
		
	EndIf;
	
EndProcedure

&AtServer
Function RegisterMOIDAndPredefinedItemsAtServer()
	
	CurrentObject = ThisObject();
	Return CurrentObject.SSLUpdateAndRegisterMasterNodeMetadataObjectID(ExchangeNodeReference);
	
EndFunction

&AtServer
Function PrepareRegistrationChangeParameters(Command, NoAutoRegistration, Data, TableName = Undefined)
	Result = New Structure;
	Result.Insert("Command", Command);
	Result.Insert("NoAutoRegistration", NoAutoRegistration);
	Result.Insert("Node", ExchangeNodeReference);
	Result.Insert("Data", Data);
	Result.Insert("TableName", TableName);
	
	Result.Insert("ConfigurationSupportsSSL",       Object.ConfigurationSupportsSSL);
	Result.Insert("RegisterWithSSLMethodsAvailable",  Object.RegisterWithSSLMethodsAvailable);
	Result.Insert("DIBModeAvailable",                 Object.DIBModeAvailable);
	Result.Insert("ObjectExportControlSetting", Object.ObjectExportControlSetting);
	Result.Insert("BatchRegistrationIsAvailable",       Object.BatchRegistrationIsAvailable);
	
	Result.Insert("MetadataNamesStructure",           MetadataNamesStructure);
	
	Return Result;
EndFunction

&AtServer
Procedure AddNameOfMetadataToHide()
	// Registers with the Node dimension are hidden
	For Each InformationRegisterMetadata In Metadata.InformationRegisters Do
		For Each RegisterDimension In InformationRegisterMetadata.Dimensions Do
			If Lower(RegisterDimension.Name) = "node" Then
				Object.NamesOfMetadataToHide.Add("InformationRegister." + InformationRegisterMetadata.Name);
				Break;
			EndIf;
		EndDo;
	EndDo;
EndProcedure

&AtServer
Procedure SetDynamicListProperties(List, ParametersStructure)
	
	Form = List.Parent;
	
	While TypeOf(Form) <> Type("ClientApplicationForm") Do
		Form = Form.Parent;
	EndDo;
	
	DynamicList = Form[List.DataPath];
	QueryText = ParametersStructure.QueryText;
	
	If Not IsBlankString(QueryText) Then
		DynamicList.QueryText = QueryText;
	EndIf;
	
	MainTable = ParametersStructure.MainTable;
	
	If Not IsBlankString(MainTable) Then
		DynamicList.MainTable = MainTable;
	EndIf;
	
	DynamicDataRead = ParametersStructure.DynamicDataRead;
	
	If TypeOf(DynamicDataRead) = Type("Boolean") Then
		DynamicList.DynamicDataRead = DynamicDataRead;
	EndIf;
	
EndProcedure

&AtServer
Function DynamicListPropertiesStructure()
	
	Return New Structure("QueryText, MainTable, DynamicDataRead");
	
EndFunction

&AtServer
Procedure FillAdditionalInformation()
	
	If Not IsConfigurationSupportsDataSyncLib() Then
		Items.AdditionalInformationGroup.Visible = False;
		Return;
	EndIf;
	
	ModuleDataExchangeCached = CommonModule("DataExchangeCached");
	ModuleDataExchangeRegistrationCached = CommonModule("DataExchangeRegistrationCached");
	ModuleDataExchangeRegistrationServer = CommonModule("DataExchangeRegistrationServer");
	
	If ValueIsFilled(ExchangeNodeReference) Then
		
		ExchangePlanName = ModuleDataExchangeCached.GetExchangePlanName(ExchangeNodeReference);
		
		If ModuleDataExchangeCached.IsSSLDataExchangeNode(ExchangeNodeReference)
			And (ModuleDataExchangeCached.IsStandardDataExchangeNode(ExchangePlanName)
				Or ModuleDataExchangeCached.IsUniversalDataExchangeNode(ExchangeNodeReference)) Then
			
			SelectiveRegistrationMode = ModuleDataExchangeRegistrationCached.ExchangePlanDataSelectiveRegistrationMode(ExchangePlanName);
			If SelectiveRegistrationMode = ModuleDataExchangeRegistrationServer.SelectiveRegistrationModeDisabled()Then
				
				TitleText = NStr("vi = 'đã tắt sử dụng.';
								|ru = 'отключен.';
								|en = 'Disabled.'; fa = 'Disabled.';
								|it = 'disattivato.';
								|pl = 'wyłączony.';
								|tr = 'devre dışı.'", DefaultLanguageCode());
				
			ElsIf SelectiveRegistrationMode = ModuleDataExchangeRegistrationServer.SelectiveRegistrationModeModification() Then
				
				TitleText = NStr("vi = 'chỉnh sửa.';
								|ru = 'модифицированность.';
								|en = 'Modified.'; fa = 'Modified.';
								|it = 'modificabilità.';
								|pl = 'modyfikacja.';
								|tr = 'değiştirilmiş.'", DefaultLanguageCode());
				
			Else
				
				TitleText = NStr("vi = 'theo quy tắc xml.';
								|ru = 'согласно правилам xml.';
								|en = 'According to XML rules.'; fa = 'According to XML rules.';
								|it = 'secondo le regole xml.';
								|pl = 'zgodnie z regułami xml.';
								|tr = 'xml kurallarına göre.'", DefaultLanguageCode());
				
			EndIf;
			
		Else
			
			TitleText = NStr("vi = 'không hỗ trợ.';
							|ru = 'не поддерживается.';
							|en = 'Not supported.'; fa = 'Not supported.';
							|it = 'non supportato.';
							|pl = 'nieobsługiwane.';
							|tr = 'desteklenmiyor.'", DefaultLanguageCode());
			
		EndIf;
		
	Else
		
		TitleText = NStr("vi = 'hãy chỉ ra tùy chỉnh đồng bộ.';
						|ru = 'укажите настройку синхронизации.';
						|en = 'Specify a synchronization setting.'; fa = 'Specify a synchronization setting.';
						|it = 'indicare l''impostazione di sincronizzazione.';
						|pl = 'określ konfigurację synchronizacji.';
						|tr = 'senkronizasyon ayarını belirtin.'", DefaultLanguageCode());
		
	EndIf;
	
	TitleTemplate1 = NStr("vi = 'Chế độ ghi nhận có chọn lọc: %1';
							|ru = 'Режим выборочной регистрации: %1';
							|en = 'Selective registration mode: %1'; fa = 'Selective registration mode: %1';
							|it = 'Modalità di registrazione selettiva: %1';
							|pl = 'Tryb wybiórczej rejestracji: %1';
							|tr = 'Seçici kayıt modu: %1'", DefaultLanguageCode());
	TitleText = StrTemplate(TitleTemplate1, TitleText);
	Items.DecorationSelectiveRegistrationMode.Title = TitleText;
	
EndProcedure

&AtServer
Function IsConfigurationSupportsDataSyncLib()
	
	Return Metadata.Subsystems.Find("StandardSubsystems") <> Undefined
		And Metadata.Subsystems["StandardSubsystems"].Subsystems.Find("DataExchange") <> Undefined
		And Metadata.Subsystems["StandardSubsystems"].Subsystems["DataExchange"].Subsystems.Find("Registration") <> Undefined; 
	
EndFunction

// Returns a reference to the common module by the name.
//
// Parameters:
//  Name          - String - a common module name, for example:
//                 "Common",
//                 "CommonClient".
//
// Returns:
//  CommonModule
//
&AtClientAtServerNoContext
Function CommonModule(Name)
	
// ACC:488-off "Calculate" instead of "Common.CalculateInSafeMode" because it's a standalone data processor.
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	If Metadata.CommonModules.Find(Name) <> Undefined Then
		SetSafeMode(True);
		Module = Eval(Name);
	Else
		Module = Undefined;
	EndIf;
	
	If TypeOf(Module) <> Type("CommonModule") Then
		Raise SubstituteParametersToString(NStr("vi = 'Mô-đun chung ""%1"" không tồn tại.';
												|ru = 'Общий модуль ""%1"" не существует.';
												|en = 'Common module ""%1"" does not exist.'; fa = 'Common module ""%1"" does not exist.';
												|it = 'Modulo generale ""%1"" non esiste.';
												|pl = 'Moduł ogólny ""%1"" nie istnieje.';
												|tr = '""%1"" ortak modülü mevcut değil.'"), Name);
	EndIf;
#Else
	Module = Eval(Name);
	If TypeOf(Module) <> Type("CommonModule") Then
		Raise SubstituteParametersToString(NStr("vi = 'Mô-đun chung ""%1"" không tồn tại.';
												|ru = 'Общий модуль ""%1"" не существует.';
												|en = 'Common module ""%1"" does not exist.'; fa = 'Common module ""%1"" does not exist.';
												|it = 'Modulo generale ""%1"" non esiste.';
												|pl = 'Moduł ogólny ""%1"" nie istnieje.';
												|tr = '""%1"" ortak modülü mevcut değil.'"), Name);
	EndIf;
#EndIf
// ACC:488-on
	
	Return Module;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions from the basic functionality to ensure autonomy.

&AtClientAtServerNoContext
Function SubstituteParametersToString(Val SubstitutionString, Val Parameter1, Val Parameter2 = Undefined, Val Parameter3 = Undefined)
	
	SubstitutionString = StrReplace(SubstitutionString, "%1", Parameter1);
	SubstitutionString = StrReplace(SubstitutionString, "%2", Parameter2);
	SubstitutionString = StrReplace(SubstitutionString, "%3", Parameter3);
	
	Return SubstitutionString;
	
EndFunction

&AtServer 
Function DefaultLanguageCode()
	
	Return Metadata.DefaultLanguage.LanguageCode;
	
EndFunction

#EndRegion