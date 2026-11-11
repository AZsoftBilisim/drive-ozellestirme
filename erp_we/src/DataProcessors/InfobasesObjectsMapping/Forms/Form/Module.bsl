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

	SetConditionalAppearance();
	
	// Checking whether the form is opened from 1C:Enterprise script.
	If Not Parameters.Property("ExchangeMessageFileName") Then
		Raise NStr("vi = 'Bộ xử lý không được dùng để sử dụng trực tiếp.';
					|ru = 'Обработка не предназначена для непосредственного использования.';
					|en = 'The data processor cannot be opened manually.'; fa = 'The data processor cannot be opened manually.';
					|it = 'L''elaborazione non è destinata all''uso diretto.';
					|pl = 'Przetwarzanie nie jest przeznaczone do bezpośredniego używania.';
					|tr = 'Bu veri işlemcisi manuel kullanıma yönelik değildir.'");
	EndIf;
	
	PerformDataMapping = True;
	ExecuteDataImport      = True;
	
	If Parameters.Property("PerformDataMapping") Then
		PerformDataMapping = Parameters.PerformDataMapping;
	EndIf;
	
	If Parameters.Property("ExecuteDataImport") Then
		ExecuteDataImport = Parameters.ExecuteDataImport;
	EndIf;
	
	// Initializing the data processor with the passed parameters.
	FillPropertyValues(Object, Parameters);
	
	// Calling a constructor of the current data processor instance.
	DataProcessorObject = FormAttributeToValue("Object");
	DataProcessorObject.Designer();
	ValueToFormAttribute(DataProcessorObject, "Object");
	
	// Removing possible search fields and attributes with strings of unlimited length from the list.
	MetadataObjectType = Metadata.FindByType(Type(Object.DestinationTypeString));
	
	If MetadataObjectType <> Undefined Then
		
		RowIndex = Object.TableFieldsList.Count() - 1;
		
		While RowIndex >= 0 Do
			
			Item = Object.TableFieldsList[RowIndex];
			RowIndex = RowIndex - 1;
			MetadataObjectAttribute1 = MetadataObjectType.Attributes.Find(Item.Value);
			
			If MetadataObjectAttribute1 <> Undefined
				And MetadataObjectAttribute1.Type = New TypeDescription("String",, New StringQualifiers(0)) Then
				Object.TableFieldsList.Delete(Item);
				Continue;
			EndIf;
			
		EndDo;
	EndIf;
	
	// A list of filters by mapping status:
	//
	//     MappingStatus - Number:
	//          0 - Mapped via information register (soft mapping)
	//         -1 - Unmapped source object
	//         +1 - Unmapped destination object
	//          3 - Unconfirmed mapped link
	//
	//     MappingStatusAdditional - Number:
	//         1 - Unmapped objects
	//         0 - Mapped objects
	
	MappingStatusFilterOptions = New Structure;
	
	// Populate filter list.
	ChoiceList = Items.FilterByMappingStatus.ChoiceList;
	
	NewListItem = ChoiceList.Add("AllObjects", NStr("vi = 'Tất cả dữ liệu';
													|ru = 'Все данные';
													|en = 'All data'; fa = 'همه داده‌ها';
													|it = 'Tutti i dati';
													|pl = 'Wszystkie dane';
													|tr = 'Tüm veriler'"));
	MappingStatusFilterOptions.Insert(NewListItem.Value, New FixedStructure);
	
	NewListItem = ChoiceList.Add("UnapprovedMappedObjects", NStr("vi = 'Thay đổi';
																|ru = 'Изменения';
																|en = 'Changes'; fa = 'تغییرات';
																|it = 'Modifiche';
																|pl = 'Zmiany';
																|tr = 'Değişiklikler'"));
	MappingStatusFilterOptions.Insert(NewListItem.Value, 
						New FixedStructure("MappingStatus",  3));
	
	NewListItem = ChoiceList.Add("MappedObjects", NStr("vi = 'Dữ liệu đã so sánh';
														|ru = 'Сопоставленные данные';
														|en = 'Mapped data'; fa = 'داده‌های نگاشت‌شده';
														|it = 'I dati associati';
														|pl = 'Porównywane dane';
														|tr = 'Karşılaştırılmış veriler'"));
	MappingStatusFilterOptions.Insert(NewListItem.Value, 
						New FixedStructure("MappingStatusAdditional", 0));
	
	NewListItem = ChoiceList.Add("UnmappedObjects", NStr("vi = 'Dữ liệu chưa so sánh';
														|ru = 'Несопоставленные данные';
														|en = 'Unmapped data'; fa = 'Unmapped data';
														|it = 'I dati non associati';
														|pl = 'Nie porównywane dane';
														|tr = 'Karşılaştırılmamış veriler'"));
	MappingStatusFilterOptions.Insert(NewListItem.Value, 
						New FixedStructure("MappingStatusAdditional", 1));
	
	NewListItem = ChoiceList.Add("UnmappedDestinationObjects", NStr("vi = 'Dữ liệu chưa so sánh của cơ sở thông tin này';
																	|ru = 'Несопоставленные данные этой базы';
																	|en = 'Unmapped data (this infobase)'; fa = 'Unmapped data (this infobase)';
																	|it = 'I dati non associati di questo database';
																	|pl = 'Nieporównywane dane tej bazy';
																	|tr = 'Bu tabanın karşılaştırılmamış verileri'"));
	MappingStatusFilterOptions.Insert(NewListItem.Value, 
						New FixedStructure("MappingStatus",  1));
	
	NewListItem = ChoiceList.Add("UnmappedSourceObjects", NStr("vi = 'Dữ liệu chưa so sánh của cơ sở thông tin thứ hai';
																|ru = 'Несопоставленные данные второй базы';
																|en = 'Unmapped data in the peer infobase'; fa = 'Unmapped data in the peer infobase';
																|it = 'I dati non associati del secondo database';
																|pl = 'Nieporównywane dane drugiej bazy';
																|tr = 'İkinci tabanın karşılaştırılmamış verileri'"));
	MappingStatusFilterOptions.Insert(NewListItem.Value, 
						New FixedStructure("MappingStatus", -1));
	
	// Default values.
	FilterByMappingStatus = "UnmappedObjects";
		
	// Set the form title.
	Synonym = Undefined;
	Parameters.Property("Synonym", Synonym);
	If IsBlankString(Synonym) Then
		DataPresentation = String(Metadata.FindByType(Type(Object.DestinationTypeString)));
	Else
		DataPresentation = Synonym;
	EndIf;
	Title = NStr("vi = 'So sánh dữ liệu ""[DataPresentation]""';
				|ru = 'Сопоставление данных ""[DataPresentation]""';
				|en = 'Data mapping ""[DataPresentation]""'; fa = 'Data mapping ""[DataPresentation]""';
				|it = 'Associazione dati ""[DataPresentation]""';
				|pl = 'Porównywanie danych ""[DataPresentation]""';
				|tr = 'Verilerin karşılaştırılması ""[DataPresentation]""'");
	Title = StrReplace(Title, "[DataPresentation]", DataPresentation);
	
	// Setting the form item visibility according to option values.
	Items.LinksGroup.Visible                                    = PerformDataMapping;
	Items.RunAutoMapping.Visible           = PerformDataMapping;
	Items.MappingDigestInfo.Visible               = PerformDataMapping;
	Items.MappingTableContextMenuLinksGroup.Visible = PerformDataMapping;
	
	Items.RunDataImport.Visible = ExecuteDataImport;
	
	CurrentApplicationDescription = DataExchangeCached.ThisNodeDescription(Object.InfobaseNode);
	CurrentApplicationDescription = ?(IsBlankString(CurrentApplicationDescription), NStr("vi = 'Chương trình này';
																						|ru = 'Эта программа';
																						|en = 'This application'; fa = 'This application';
																						|it = 'Questo programma';
																						|pl = 'Ten program';
																						|tr = 'Bu program'"), CurrentApplicationDescription);
	
	SecondApplicationDescription = String(Object.InfobaseNode);
	SecondApplicationDescription = ?(IsBlankString(SecondApplicationDescription), NStr("vi = 'Chương trình thứ hai';
																						|ru = 'Вторая программа';
																						|en = 'Other application'; fa = 'Other application';
																						|it = 'Secondo programma';
																						|pl = 'Drugi program';
																						|tr = 'İkinci program'"), SecondApplicationDescription);
	
	Items.CurrentApplicationData.Title = CurrentApplicationDescription;
	Items.SecondApplicationData.Title = SecondApplicationDescription;
	
	Items.Explanation.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Để so sánh dữ liệu ""%1""
		|với dữ liệu ""%2"", hãy sử dụng lệnh ""So sánh tự động...""
		|Có thể liên kết thủ công dữ liệu còn lại chưa được so sánh.';
		|ru = 'Для сопоставления данных ""%1""
		|с данными ""%2"" воспользуйтесь командой ""Сопоставить автоматически..."".
		|Оставшиеся несопоставленные данные можно связать друг с другом вручную.';
		|en = 'To map %1 data
		|to%2 data, click ""Map automatically"".
		|Then you can map the remaining data manually.'; fa = 'To map %1 data
		|to%2 data, click ""Map automatically"".
		|Then you can map the remaining data manually.';
		|it = 'Per associare i dati ""%1""
		|con i dati ""%2"" utilizzare il comando ""Associare automaticamente ..."".
		|I dati rimanenti non associati possono essere collegati tra loro manualmente.';
		|pl = 'Do porównania danych ""%1""
		|z danymi""%2"" użyj polecenia ""Сопоставить автоматически..."".
		|Pozostałe nieporównane dane można powiązać ze sobą ręcznie.';
		|tr = '""%1"" verilerini
		|""%2"" verileriyle karşılaştırmak için, ""Otomatik karşılaştır..."" komutunu kullanın.
		|Karşılaştırılmayan veriler bir biriyle manuel olarak bağlanabilir.'"),
		CurrentApplicationDescription, SecondApplicationDescription);
	
	ObjectMappingScenario();
	
	ApplyUnapprovedRecordsTable = False;
	ApplyAutomaticMappingResult = False;
	AutoMappedObjectsTableAddress = "";
	WriteAndClose = False;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	ShowWarningOnFormClose = True;
	
	// Setting a flag that shows whether the form has been modified.
	AttachIdleHandler("SetFormModified", 2);
	
	UpdateMappingTable();
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If WriteAndClose Then
		Return;
	EndIf;
	
	If Object.UnapprovedMappingTable.Count() = 0 Then
		// All items are mapped.
		Return;
	EndIf;
	
	If ShowWarningOnFormClose = True Then
		Notification = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		
		CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
		
		Return;
	EndIf;
	
	If Exit Then
		Return;
	EndIf;
		
	BeforeCloseContinued();
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(Val QuestionResult = Undefined, Val AdditionalParameters = Undefined) Export
	// The procedure is called following a positive response.
	// Save the data and close the form.
	WriteAndClose(Undefined);
EndProcedure

&AtClient
Procedure BeforeCloseContinued()
	WriteAndClose = True;
	ShowWarningOnFormClose = True;
	UpdateMappingTable();
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("UniqueKey",       Parameters.Key);
	NotificationParameters.Insert("DataImportedSuccessfully", Object.DataImportedSuccessfully);
	
	Notify("ObjectMappingFormClosing", NotificationParameters);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("DataProcessor.InfobasesObjectsMapping.Form.AutomaticMappingSetting") Then
		
		If TypeOf(ValueSelected) <> Type("ValueList") Then
			Return;
		EndIf;
		
		// Performing automatic object mapping.
		FormParameters = New Structure;
		FormParameters.Insert("DestinationTableName",                         Object.DestinationTableName);
		FormParameters.Insert("ExchangeMessageFileName",                     Object.ExchangeMessageFileName);
		FormParameters.Insert("SourceTableObjectTypeName",              Object.SourceTableObjectTypeName);
		FormParameters.Insert("SourceTypeString",                         Object.SourceTypeString);
		FormParameters.Insert("DestinationTypeString",                         Object.DestinationTypeString);
		FormParameters.Insert("DestinationTableFields",                        Object.DestinationTableFields);
		FormParameters.Insert("DestinationTableSearchFields",                  Object.DestinationTableSearchFields);
		FormParameters.Insert("InfobaseNode",                      Object.InfobaseNode);
		FormParameters.Insert("TableFieldsList",                          Object.TableFieldsList.Copy());
		FormParameters.Insert("UsedFieldsList",                     Object.UsedFieldsList.Copy());
		FormParameters.Insert("MappingFieldsList",                    ValueSelected.Copy());
		FormParameters.Insert("MaxUserFields", MaxUserFields());
		FormParameters.Insert("Title",                                   Title);
		
		FormParameters.Insert("UnapprovedMappingTableTempStorageAddress", PutUnapprovedMappingTableInTempStorage());
		
		// Opening the automatic object mapping form.
		OpenForm("DataProcessor.InfobasesObjectsMapping.Form.AutoMappingResult", FormParameters, ThisObject,,,,,FormWindowOpeningMode.LockOwnerWindow);
		
	ElsIf Upper(ChoiceSource.FormName) = Upper("DataProcessor.InfobasesObjectsMapping.Form.AutoMappingResult") Then
		
		If TypeOf(ValueSelected) = Type("String")
			And Not IsBlankString(ValueSelected) Then
			
			ApplyAutomaticMappingResult = True;
			AutoMappedObjectsTableAddress = ValueSelected;
			
			UpdateMappingTable();
			
		EndIf;
		
	ElsIf Upper(ChoiceSource.FormName) = Upper("DataProcessor.InfobasesObjectsMapping.Form.TableFieldSetup") Then
		
		If TypeOf(ValueSelected) <> Type("ValueList") Then
			Return;
		EndIf;
		
		Object.UsedFieldsList = ValueSelected.Copy();
		SetTableFieldVisible("MappingTable"); // Setting visibility and titles of the mapping table fields.
		
	ElsIf Upper(ChoiceSource.FormName) = Upper("DataProcessor.InfobasesObjectsMapping.Form.MappingFieldTableSetup") Then
		
		If TypeOf(ValueSelected) <> Type("ValueList") Then
			Return;
		EndIf;
		
		Object.TableFieldsList = ValueSelected.Copy();
		
		FillListWithSelectedItems(Object.TableFieldsList, Object.UsedFieldsList);
		
		// Generate sort table.
		FillSortTable(Object.UsedFieldsList);
		
		// Updating the mapping table.
		UpdateMappingTable();
		
	ElsIf Upper(ChoiceSource.FormName) = Upper("DataProcessor.InfobasesObjectsMapping.Form.SortingSetup") Then
		
		If TypeOf(ValueSelected) <> Type("FormDataCollection") Then
			Return;
		EndIf;
		
		Object.SortTable.Clear();
		
		// Filling the form collection with retrieved settings.
		For Each TableRow In ValueSelected Do
			FillPropertyValues(Object.SortTable.Add(), TableRow);
		EndDo;
		
		// Sort mapping table.
		ExecuteTableSorting();
		
		// Updating tabular section filter
		SetTabularSectionFilter();
		
	ElsIf Upper(ChoiceSource.FormName) = Upper("DataProcessor.InfobasesObjectsMapping.Form.MappingChoiceForm") Then
		
		If ValueSelected = Undefined Then
			Return; // Manual mapping is canceled.
		EndIf;
		
		BeginningRowID = Items.MappingTable.CurrentRow;
		
		// Server call.
		FoundRows = MappingTable.FindRows(New Structure("SerialNumber", ValueSelected));
		If FoundRows.Count() > 0 Then
			EndingRowID = FoundRows[0].GetID();
			// Process retrieved mapping.
			AddUnapprovedMappingAtClient(BeginningRowID, EndingRowID);
		EndIf;
		
		// Switching to the mapping table.
		CurrentItem = Items.MappingTable;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterByMappingStatusOnChange(Item)
	
	SetTabularSectionFilter();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMappingTable

&AtClient
Procedure MappingTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	SetMappingInteractively();
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure MappingTableBeforeRowChange(Item, Cancel)
	Cancel = True;
	SetMappingInteractively();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	UpdateMappingTable();
	
EndProcedure

&AtClient
Procedure RunAutoMapping(Command)
	
	Cancel = False;
	
	// Determining the number of user-defined fields to be displayed.
	CheckUserFieldsFilled(Cancel, Object.UsedFieldsList.UnloadValues());
	
	If Cancel Then
		Return;
	EndIf;
	
	// Getting the mapping field list.
	FormParameters = New Structure;
	FormParameters.Insert("MappingFieldsList", Object.TableFieldsList.Copy());
	
	OpenForm("DataProcessor.InfobasesObjectsMapping.Form.AutomaticMappingSetting", FormParameters, ThisObject,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure RunDataImport(Command)
	NString = NStr("vi = 'Nhận dữ liệu trong cơ sở thông tin?';
					|ru = 'Получить данные в информационную базу?';
					|en = 'Do you want to import data into the infobase?'; fa = 'Do you want to import data into the infobase?';
					|it = 'Acquisire i dati nel database informatico?';
					|pl = 'Otrzymać dane do bazy informacyjnej?';
					|tr = 'Veriler Infobase''e aktarılsın mı?'");
	Notification = New CallbackDescription("RunDataImportAfterPromptToConfirmDataImport", ThisObject);
	
	ShowQueryBox(Notification, NString, QuestionDialogMode.YesNo, ,DialogReturnCode.Yes);
EndProcedure

&AtClient
Procedure ChangeTableFields(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("FieldList", Object.UsedFieldsList.Copy());
	
	OpenForm("DataProcessor.InfobasesObjectsMapping.Form.TableFieldSetup", FormParameters, ThisObject,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SetupTableFieldsList(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("FieldList", Object.TableFieldsList.Copy());
	
	OpenForm("DataProcessor.InfobasesObjectsMapping.Form.MappingFieldTableSetup", FormParameters, ThisObject,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure Sort(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("SortTable", Object.SortTable);
	
	OpenForm("DataProcessor.InfobasesObjectsMapping.Form.SortingSetup", FormParameters, ThisObject,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AddMapping(Command)
	
	SetMappingInteractively();
	
EndProcedure

&AtClient
Procedure CancelMapping(Command)
	
	SelectedRows = Items.MappingTable.SelectedRows;
	
	HasMappingByRef = False;
	For Each RowID In SelectedRows Do
		String = MappingTable.FindByID(RowID);
		If String.MappingByRef Then
			HasMappingByRef = True;
			Break;
		EndIf;
	EndDo;
	
	If HasMappingByRef Then

		QueryText = NStr(
			"vi = 'Bạn thử hủy bỏ liên kết đối tượng mà được so sánh theo tham chiếu.
			|Đối với các đối tượng này, cần thiết lập ngay sự tương ứng mới, hay nói cách khác, sẽ so sánh lại chúng theo tham chiếu.
			|
			|Bỏ liên kết?';
			|ru = 'Вы пытаетесь отменить связь объектов сопоставленных по ссылкам.
			|Для этих объектов необходимо сразу установить новое соответствие, иначе они будут снова сопоставлены по ссылке.
			|
			|Разорвать связь?';
			|en = 'You are trying to clear the mapping of objects mapped by references.
			|You need to set a new mapping for these objects immediately. Otherwise, they will be mapped by references again.
			|
			|Do you want to clear the mapping?'; fa = 'You are trying to clear the mapping of objects mapped by references.
			|You need to set a new mapping for these objects immediately. Otherwise, they will be mapped by references again.
			|
			|Do you want to clear the mapping?';
			|it = 'Si sta provando ad annullare la connessione di oggetti associati per link.
			|È necessario impostare immediatamente una nuova associazione per questi oggetti, altrimenti verranno associati di nuovo per link.
			|
			|Interrompere la connessione?';
			|pl = 'Próbujesz anulować połączenie obiektów zestawionych pod odnośnikami.
			|Dla tych obiektów należy od razu ustawić nową zgodność, inaczej one będą ponownie zestawione pod odnośnikiem.
			|
			|Usunąć łącze?';
			|tr = 'URL ile eşleştirilen nesnelerin bağlantısını kaldırmaya çalışıyorsunuz.
			|Bu nesnelerin hemen yeniden eşleştirilmesi gerekir, aksi takdirde yeniden URL ile eşleştirilirler.
			|
			|Bağlantı kaldırılsın mı?'", 
			CommonClient.DefaultLanguageCode());
			
		Title = NStr("vi = 'Hủy bỏ so sánh';
					|ru = 'Отменить сопоставление';
					|en = 'Clear mapping'; fa = 'پاک کردن نگاشت';
					|it = 'Annullare l''associazione';
					|pl = 'Anuluj zestawienie';
					|tr = 'Eşleştirmeyi kaldır'", CommonClient.DefaultLanguageCode());
		
		Notification = New CallbackDescription("CancelMappingCompletion", ThisObject);
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo,,, Title); 
		
	Else
	
		UndoMappingAtServer();
	
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelMappingCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		UndoMappingAtServer()
	EndIf;

EndProcedure

&AtClient
Procedure UndoMappingAtServer()

	SelectedRows = Items.MappingTable.SelectedRows;
	
	CancelMappingAtServer(SelectedRows);
	
	// Updating the tabular section filter
	SetTabularSectionFilter();
	
EndProcedure



&AtClient
Procedure WriteRefresh(Command)
	
	ApplyUnapprovedRecordsTable = True;
	
	UpdateMappingTable();
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	ApplyUnapprovedRecordsTable = True;
	WriteAndClose = True;
	
	UpdateMappingTable();
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// SERVICE PROCEDURES AND FUNCTIONS (Supplied part).

&AtClient
Procedure ChangeNavigationNumber(Iterator_SSLy)
	
	ClearMessages();
	
	SetNavigationNumber(NavigationNumber + Iterator_SSLy);
	
EndProcedure

&AtClient
Procedure SetNavigationNumber(Val Value)
	
	IsMoveNext = (Value > NavigationNumber);
	
	NavigationNumber = Value;
	
	If NavigationNumber < 0 Then
		
		NavigationNumber = 0;
		
	EndIf;
	
	NavigationNumberOnChange(IsMoveNext);
	
EndProcedure

&AtClient
Procedure NavigationNumberOnChange(Val IsMoveNext)
	
	// Run navigation event handlers.
	ExecuteNavigationEventHandlers(IsMoveNext);
	
	// Set up page view.
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("vi = 'Chưa xác định trang để hiển thị.';
					|ru = 'Не определена страница для отображения.';
					|en = 'The page to display is not specified.'; fa = 'The page to display is not specified.';
					|it = 'Non è definita la pagina per visualizzazione.';
					|pl = 'Nie określono strony do odzwierciedlenia.';
					|tr = 'Gösterilecek sayfa tanımlanmamış.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	Items.PanelMain.CurrentPage = Items[NavigationRowCurrent.MainPageName];
	
	If IsMoveNext And NavigationRowCurrent.TimeConsumingOperation Then
		
		AttachIdleHandler("ExecuteTimeConsumingOperationHandler", 0.1, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteNavigationEventHandlers(Val IsMoveNext)
	
		// Navigation event handlers.
	If IsMoveNext Then
		
		NavigationRows = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber - 1));
		
		If NavigationRows.Count() = 0 Then
			Return;
		EndIf;
		
	Else
		
		NavigationRows = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber + 1));
		
		If NavigationRows.Count() = 0 Then
			Return;
		EndIf;
		
	EndIf;
	
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("vi = 'Chưa xác định trang để hiển thị.';
					|ru = 'Не определена страница для отображения.';
					|en = 'The page to display is not specified.'; fa = 'The page to display is not specified.';
					|it = 'Non è definita la pagina per visualizzazione.';
					|pl = 'Nie określono strony do odzwierciedlenia.';
					|tr = 'Gösterilecek sayfa tanımlanmamış.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	If NavigationRowCurrent.TimeConsumingOperation And Not IsMoveNext Then
		
		SetNavigationNumber(NavigationNumber - 1);
		Return;
	EndIf;
	
	// OnOpen handler
	If Not IsBlankString(NavigationRowCurrent.OnOpenHandlerName) Then
		
		ProcedureName = "[HandlerName](Cancel, SkipPage, IsMoveNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.OnOpenHandlerName);
		
		Cancel = False;
		SkipPage = False;
		
		CalculationResult = Eval(ProcedureName);
		
		If Cancel Then
			
			SetNavigationNumber(NavigationNumber - 1);
			
			Return;
			
		ElsIf SkipPage Then
			
			If IsMoveNext Then
				
				SetNavigationNumber(NavigationNumber + 1);
				
				Return;
				
			Else
				
				SetNavigationNumber(NavigationNumber - 1);
				
				Return;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteTimeConsumingOperationHandler()
	
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("vi = 'Chưa xác định trang để hiển thị.';
					|ru = 'Не определена страница для отображения.';
					|en = 'The page to display is not specified.'; fa = 'The page to display is not specified.';
					|it = 'Non è definita la pagina per visualizzazione.';
					|pl = 'Nie określono strony do odzwierciedlenia.';
					|tr = 'Gösterilecek sayfa tanımlanmamış.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	// TimeConsumingOperationProcessing handler.
	If Not IsBlankString(NavigationRowCurrent.TimeConsumingOperationHandlerName) Then
		
		ProcedureName = "[HandlerName](Cancel, GoToNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.TimeConsumingOperationHandlerName);
		
		Cancel = False;
		GoToNext = True;
		
		CalculationResult = Eval(ProcedureName);
		
		If Cancel Then
			
			SetNavigationNumber(NavigationNumber - 1);
			
			Return;
			
		ElsIf GoToNext Then
			
			SetNavigationNumber(NavigationNumber + 1);
			
			Return;
			
		EndIf;
		
	Else
		
		SetNavigationNumber(NavigationNumber + 1);
		
		Return;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure NavigationTableNewRow(NavigationNumber,
	MainPageName,
	OnOpenHandlerName = "",
	IsLongOperation = False,
	TimeConsumingOperationHandlerName = "")
	
	NewRow = NavigationTable.Add();
	NewRow.NavigationNumber          = NavigationNumber;
	NewRow.MainPageName              = MainPageName;
	NewRow.OnOpenHandlerName        = OnOpenHandlerName;
	NewRow.TimeConsumingOperation               = IsLongOperation;
	NewRow.TimeConsumingOperationHandlerName = TimeConsumingOperationHandlerName;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MappingTableDestinationField1.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MappingTable.MappingStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = -1;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không có tương ứng, đối tượng sẽ được sao chép';
													|ru = 'Нет соответствия, объект будет скопирован';
													|en = 'No mapping. The object will be copied'; fa = 'No mapping. The object will be copied';
													|it = 'Nessuna corrispondenza, l''oggetto verrà copiato';
													|pl = 'Brak zgodności, obiekt będzie skopiowany';
													|tr = 'Nesne için eşleşme yok, nesne kopyalanacaktır'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MappingTableSourceField1.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MappingTable.MappingStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không có tương ứng';
													|ru = 'Нет соответствия';
													|en = 'No mapping'; fa = 'No mapping';
													|it = 'Non vi è corrispondenza';
													|pl = 'Brak zgodności';
													|tr = 'Eşleştirme yok'"));

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MappingTablePictureMappingByRef.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MappingTable.MappingByRef");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Show", False);

EndProcedure

&AtClient
Procedure RunDataImportAfterPromptToConfirmDataImport(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Object.DataImportedSuccessfully Then
		NString = NStr("vi = 'Đã nhận dữ liệu. Nhận lại dữ liệu?';
						|ru = 'Данные уже были получены. Выполнить получение данных повторно?';
						|en = 'Data is already received. Do you want to receive data again?'; fa = 'Data is already received. Do you want to receive data again?';
						|it = 'I dati sono già stati ricevuti. Eseguire di nuovo l''acquisizione dei dati?';
						|pl = 'Dane już zostały otrzymane. Wykonać otrzymanie danych ponownie?';
						|tr = 'Veri zaten alındı. Veri tekrar alınsın mı?'");
		Notification = New CallbackDescription("RunDataImportAfterPromptToReimportData", ThisObject);
		
		ShowQueryBox(Notification, NString, QuestionDialogMode.YesNo, ,DialogReturnCode.No);
		Return;
	EndIf;
	
	ExecuteDataImportAfterConfirmGettingData();
EndProcedure

&AtClient
Procedure RunDataImportAfterPromptToReimportData(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ExecuteDataImportAfterConfirmGettingData();
EndProcedure

&AtClient
Procedure ExecuteDataImportAfterConfirmGettingData()
	
	// Importing data on the server.
	Cancel = False;
	ExecuteDataImportAtServer(Cancel);
	
	If Cancel Then
		NString = NStr("vi = 'Khi nhận dữ liệu, đã xảy ra lỗi.
		                     |Chuyển đến nhật ký sự kiện?';
		                     |ru = 'При получении данных возникли ошибки.
		                     |Перейти в журнал регистрации?';
		                     |en = 'Errors occurred while receiving data.
		                     |Do you want to view the event log?'; fa = 'Errors occurred while receiving data.
		                     |Do you want to view the event log?';
		                     |it = 'Si sono verificati degli errori durante l''acquisizione dei dati.
		                     |Passare al registro?';
		                     |pl = 'Podczas otrzymania danych wystąpiy błędy. 
		                     |Przejść do dziennika rejestracji?';
		                     |tr = 'Veri alınırken hatalar oluştu.
		                     |Olay günlüğüne geçilsin mi?'");
		
		Notification = New CallbackDescription("RunDataImportAfterPromptToOpenEventLog", ThisObject);
		ShowQueryBox(Notification, NString, QuestionDialogMode.YesNo, ,DialogReturnCode.No);
		
		Return;
	EndIf;
	
	// Updating mapping table data.
	UpdateMappingTable();
EndProcedure

&AtClient
Procedure RunDataImportAfterPromptToOpenEventLog(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	DataExchangeClient.GoToDataEventLogModally(Object.InfobaseNode, ThisObject, "DataImport");
EndProcedure

&AtClient
Procedure GoToNext()
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtClient
Procedure GoBack()
	
	ChangeNavigationNumber(-1);
	
EndProcedure

&AtServer
Procedure CancelMappingAtServer(SelectedRows)
	
	For Each RowID In SelectedRows Do
		
		CurrentData = MappingTable.FindByID(RowID);
		
		If CurrentData.MappingStatus = 0 Then // mapping based on information register data.
			
			CancelDataMapping(CurrentData, False);
			
		ElsIf CurrentData.MappingStatus = 3 Then // Unapproved mapping.
			
			CancelDataMapping(CurrentData, True);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CancelDataMapping(CurrentData, IsUnapprovedMapping)
	
	Filter = New Structure;
	Filter.Insert("SourceUUID", CurrentData.DestinationUUID);
	Filter.Insert("DestinationUUID", CurrentData.SourceUUID);
	Filter.Insert("SourceType",                     CurrentData.DestinationType);
	Filter.Insert("DestinationType",                     CurrentData.SourceType);
	
	If IsUnapprovedMapping Then
		For Each FoundString In Object.UnapprovedMappingTable.FindRows(Filter) Do
			// Deleting the unapproved mapping item from the unapproved mapping table
			Object.UnapprovedMappingTable.Delete(FoundString);
		EndDo;
		
	Else
		CancelApprovedMappingAtServer(Filter);
		
	EndIf;
	
	// Adding new source and destination rows to the mapping table.
	NewSourceRow = MappingTable.Add();
	NewDestinationRow = MappingTable.Add();
	
	FillPropertyValues(NewSourceRow, CurrentData, "SourceField1, SourceField2, SourceField3, SourceField4, SourceField5, SourceUUID, SourceType, SourcePictureIndex");
	FillPropertyValues(NewDestinationRow, CurrentData, "DestinationField1, DestinationField2, DestinationField3, DestinationField4, DestinationField5, DestinationUUID, DestinationType, DestinationPictureIndex");
	
	// Setting field values for sorting source rows.
	NewSourceRow.SortField1 = CurrentData.SourceField1;
	NewSourceRow.SortField2 = CurrentData.SourceField2;
	NewSourceRow.SortField3 = CurrentData.SourceField3;
	NewSourceRow.SortField4 = CurrentData.SourceField4;
	NewSourceRow.SortField5 = CurrentData.SourceField5;
	NewSourceRow.PictureIndex  = CurrentData.SourcePictureIndex;
	
	// Setting field values for sorting destination rows.
	NewDestinationRow.SortField1 = CurrentData.DestinationField1;
	NewDestinationRow.SortField2 = CurrentData.DestinationField2;
	NewDestinationRow.SortField3 = CurrentData.DestinationField3;
	NewDestinationRow.SortField4 = CurrentData.DestinationField4;
	NewDestinationRow.SortField5 = CurrentData.DestinationField5;
	NewDestinationRow.PictureIndex  = CurrentData.DestinationPictureIndex;
	
	NewSourceRow.MappingStatus = -1;
	NewSourceRow.MappingStatusAdditional = 1; // Unmapped objects.
	
	NewDestinationRow.MappingStatus = 1;
	NewDestinationRow.MappingStatusAdditional = 1; // Unmapped objects.
	
	// Deleting the current mapping table row.
	MappingTable.Delete(CurrentData);
	
	// Updating numbers.
	NewSourceRow.SerialNumber = NextNumberByMappingOrder();
	NewDestinationRow.SerialNumber = NextNumberByMappingOrder();
	
	NewSourceRow.MappingByRef = False;
	NewDestinationRow.MappingByRef = False;
	
EndProcedure

&AtServer
Procedure CancelApprovedMappingAtServer(Filter)
	
	If DataExchangeServer.IsXDTOExchangePlan(Object.InfobaseNode) Then
		FilterPublicIDs = New Structure("InfobaseNode, Id, Ref",
			Object.InfobaseNode,
			Filter.DestinationUUID,
			Filter.SourceUUID);
		InformationRegisters.SynchronizedObjectPublicIDs.DeleteRecord(FilterPublicIDs);
	Else
		Filter.Insert("InfobaseNode", Object.InfobaseNode);
	
		InformationRegisters.InfobaseObjectsMaps.DeleteRecord(Filter);
	EndIf;
	
EndProcedure

&AtServer
Procedure ExecuteDataImportAtServer(Cancel)
	
	DataProcessorObject = FormAttributeToValue("Object");
	
	// Applying the table of unapproved mapping items to the database.
	DataProcessorObject.ApplyUnapprovedRecordsTable(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	TablesToImport = New Array;
	
	DataTableKey = DataExchangeServer.DataTableKey(Object.SourceTypeString, Object.DestinationTypeString, Object.IsObjectDeletion);
	
	TablesToImport.Add(DataTableKey);
	
	// Importing data from a batch file in the data exchange mode.
	DataProcessorObject.ExecuteDataImportForInfobase(Cancel, TablesToImport);
	
	ValueToFormAttribute(DataProcessorObject, "Object");
	
	PictureIndex = DataExchangeServer.StatisticsTablePictureIndex(UnmappedObjectsCount, Object.DataImportedSuccessfully);
	
EndProcedure

&AtServer
Function PutUnapprovedMappingTableInTempStorage()
	
	Return PutToTempStorage(Object.UnapprovedMappingTable.Unload(), UUID);
	
EndFunction

&AtServer
Function GetMappingChoiceTableTempStorageAddress(FilterParameters)
	
	Columns = "SerialNumber, SortField1, SortField2, SortField3, SortField4, SortField5, PictureIndex";
	
	Return PutToTempStorage(MappingTable.Unload(FilterParameters, Columns));
	
EndFunction

&AtClient
Procedure SetFormModified()
	
	Modified = (Object.UnapprovedMappingTable.Count() > 0);
	
EndProcedure

&AtClient
Procedure UpdateMappingTable()
	
	Items.TableButtons.Enabled = False;
	Items.TableHeaderGroup.Enabled = False;
	
	NavigationNumber = 0;
	
	// Selecting the second wizard step.
	SetNavigationNumber(2);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Applied

&AtClient
Procedure FillSortTable(SourceValueList)
	
	Object.SortTable.Clear();
	
	For Each Item In SourceValueList Do
		
		IsFirstField = SourceValueList.IndexOf(Item) = 0;
		
		TableRow = Object.SortTable.Add();
		
		TableRow.FieldName               = Item.Value;
		TableRow.Use         = IsFirstField; // Default sorting by the first field.
		TableRow.SortDirection = True; // Ascending.
		
	EndDo;
	
EndProcedure

&AtClient
Procedure FillListWithSelectedItems(SourceList, DestinationList)
	
	DestinationList.Clear();
	
	For Each Item In SourceList Do
		
		If Item.Check Then
			
			DestinationList.Add(Item.Value, Item.Presentation, True);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure SetTabularSectionFilter()
	
	Items.MappingTable.RowFilter = MappingStatusFilterOptions[FilterByMappingStatus];
	
EndProcedure

&AtClient
Procedure FillInSearchFields()

	If Object.UsedFieldsList.Count() = 0 Then
		
		// For catalogs.
		AddSearchField("Description");
		AddSearchField("Code");
		AddSearchField("Owner");
		AddSearchField("Parent");
		
		// For documents and business processes
		AddSearchField("Date");
		AddSearchField("Number");
		
		// Popular search fields.
		AddSearchField("Organization");
		AddSearchField("TIN");
		AddSearchField("CRTR");
		
		If Object.UsedFieldsList.Count() = 0 
			And Object.TableFieldsList.Count() > 0 Then
			
			Value = Object.TableFieldsList[0].Value;
			AddSearchField(Value);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddSearchField(Value)
	
	Item = Object.TableFieldsList.FindByValue(Value);
	
	If Item <> Undefined Then
		
		Item.Check = True;
		Object.UsedFieldsList.Add(Value, Value, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckUserFieldsFilled(Cancel, UserFields)
	
	If UserFields.Count() = 0 Then
		
		// One or more fields must be specified.
		NString = NStr("vi = 'Hãy chỉ ra ít nhất một trường để hiển thị';
						|ru = 'Укажите хотя бы одно поле для отображения';
						|en = 'Specify at least one field to display'; fa = 'Specify at least one field to display';
						|it = 'Indicare almeno un campo per la visualizzazione';
						|pl = 'Wskaż co najmniej jedno pole do wyświetlenia';
						|tr = 'Görüntülenecek en az bir alan belirtin'");
		
		CommonClient.MessageToUser(NString,,"Object.TableFieldsList",, Cancel);
		
	ElsIf UserFields.Count() > MaxUserFields() Then
		
		// The value must not exceed the specified number.
		MessageString = NStr("vi = 'Hãy giảm số lượng trường (có thể chọn không quá %1 trường)';
							|ru = 'Уменьшите количество полей (можно выбирать не более %1 полей)';
							|en = 'Reduce the number of fields. You can select no more than %1 fields.'; fa = 'Reduce the number of fields. You can select no more than %1 fields.';
							|it = 'Ridurre il numero di campi (è possibile selezionare non più di %1 campi)';
							|pl = 'Zmniejsz ilość pól (można wybierać nie więcej niż%1 pól)';
							|tr = 'Alan sayısını azaltın (en fazla %1 alan seçin)'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, String(MaxUserFields()));
		
		CommonClient.MessageToUser(MessageString,,"Object.TableFieldsList",, Cancel);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetTableFieldVisible(FormTableName)
	
	SourceFieldName2 = StrReplace("#FormTableName#SourceFieldNN","#FormTableName#", FormTableName);
	DestinationFieldName1 = StrReplace("#FormTableName#DestinationFieldNN","#FormTableName#", FormTableName);
	
	// Making all mapping table fields invisible.
	For FieldNumber = 1 To MaxUserFields() Do
		
		SourceField = StrReplace(SourceFieldName2, "NN", String(FieldNumber));
		DestinationField = StrReplace(DestinationFieldName1, "NN", String(FieldNumber));
		
		ItemSourceField = Items[SourceField]; // FormField
		ItemDestinationField = Items[DestinationField]; // FormField
		
		ItemSourceField.Visible = False;
		ItemDestinationField.Visible = False;
		
	EndDo;
	
	// Making all mapping table fields that are selected by user visible.
	For Each Item In Object.UsedFieldsList Do
		
		FieldNumber = Object.UsedFieldsList.IndexOf(Item) + 1;
		
		SourceField = StrReplace(SourceFieldName2, "NN", String(FieldNumber));
		DestinationField = StrReplace(DestinationFieldName1, "NN", String(FieldNumber));
		
		ItemSourceField = Items[SourceField]; // FormField
		ItemDestinationField = Items[DestinationField]; // FormField
		
		// Set the field visibility.
		ItemSourceField.Visible = Item.Check;
		ItemDestinationField.Visible = Item.Check;
		
		// Set field titles.
		ItemSourceField.Title = Item.Presentation;
		ItemDestinationField.Title = Item.Presentation;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure SetMappingInteractively()
	CurrentData = Items.MappingTable.CurrentData;
	
	If CurrentData=Undefined Then
		Return;
	EndIf;
	
	// Only two unmapped objects in the source or destination can be linked.
	// The condition includes an unmapped source object and an unmapped destination object.
	If Not (CurrentData.MappingStatus=-1 Or CurrentData.MappingStatus=+1) Then
		
		ShowMessageBox(, NStr("vi = 'Đối tượng đã được so sánh';
								|ru = 'Объекты уже сопоставлены';
								|en = 'Objects are already mapped.'; fa = 'Objects are already mapped.';
								|it = 'Gli oggetti sono già associati';
								|pl = 'Obiekty są już porównane';
								|tr = 'Nesneler zaten karşılaştırılmış'"), 2);
		
		// Switching to the mapping table.
		CurrentItem = Items.MappingTable;
		Return;
	EndIf;
	
	CannotCreateMappingFast = False;
	
	SelectedRows = Items.MappingTable.SelectedRows;
	If SelectedRows.Count()<>2 Then
		CannotCreateMappingFast = True;
		
	Else
		Id1 = SelectedRows[0];
		Id2 = SelectedRows[1];
		
		String1 = MappingTable.FindByID(Id1);
		String2 = MappingTable.FindByID(Id2);
		
		If Not (( String1.MappingStatus = -1 // Unmapped source object.
				And String2.MappingStatus = +1 ) // Unmapped destination object.
			Or ( String1.MappingStatus = +1 // Unmapped destination object.
				And String2.MappingStatus = -1 )) Then // Unmapped source object.
			CannotCreateMappingFast = True;
		EndIf;
	EndIf;
	
	If CannotCreateMappingFast Then
		// Set the mapping in a regular way.
		FilterParameters = New Structure("MappingStatus", ?(CurrentData.MappingStatus = -1, 1, -1));
		FilterParameters.Insert("PictureIndex", CurrentData.PictureIndex);
		
		FormParameters = New Structure;
		FormParameters.Insert("TempStorageAddress",   GetMappingChoiceTableTempStorageAddress(FilterParameters));
		FormParameters.Insert("StartRowSerialNumber", CurrentData.SerialNumber);
		FormParameters.Insert("UsedFieldsList",    Object.UsedFieldsList.Copy());
		FormParameters.Insert("MaxUserFields", MaxUserFields());
		FormParameters.Insert("ObjectToMap", GetObjectToMap(CurrentData));
		FormParameters.Insert("Application1", ?(CurrentData.MappingStatus = -1, SecondApplicationDescription, CurrentApplicationDescription));
		FormParameters.Insert("Application2", ?(CurrentData.MappingStatus = -1, CurrentApplicationDescription, SecondApplicationDescription));
		
		OpenForm("DataProcessor.InfobasesObjectsMapping.Form.MappingChoiceForm", FormParameters, ThisObject,,,,,FormWindowOpeningMode.LockOwnerWindow);
		
		Return;
	EndIf;
	
	// Prompt for a quick mapping.
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Yes,     NStr("vi = 'Thiết lập';
												|ru = 'Установить';
												|en = 'Apply'; fa = 'اعمال';
												|it = 'Impostare';
												|pl = 'Apply';
												|tr = 'Ayarla'"));
	Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
												|ru = 'Отмена';
												|en = 'Cancel'; fa = 'انصراف';
												|it = 'Annulla';
												|pl = 'Cancel';
												|tr = 'İptal'"));
	
	Notification = New CallbackDescription("SetMappingInteractivelyCompletion", ThisObject, New Structure);
	Notification.AdditionalParameters.Insert("Id1", Id1);
	Notification.AdditionalParameters.Insert("Id2", Id2);
	
	QueryText = NStr("vi = 'Đặt so sánh giữa các đối tượng đã chọn?';
					|ru = 'Установить соответствие между выбранными объектами?';
					|en = 'Do you want to map the selected objects?'; fa = 'Do you want to map the selected objects?';
					|it = 'Impostare la corrispondenza tra gli oggetti selezionati?';
					|pl = 'Ustawić zgodność między wybranymi obiektami?';
					|tr = 'Seçilen nesneler eşleştirilsin mi?'");
	ShowQueryBox(Notification, QueryText, Buttons,, DialogReturnCode.Yes);
EndProcedure

&AtClient
Procedure SetMappingInteractivelyCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	AddUnapprovedMappingAtClient(AdditionalParameters.Id1, AdditionalParameters.Id2);
	CurrentItem = Items.MappingTable;
EndProcedure

&AtClient
Function GetObjectToMap(Data)
	
	Result = New Array;
	
	FieldNamePattern = ?(Data.MappingStatus = -1, "SourceFieldNN", "DestinationFieldNN");
	
	For FieldNumber = 1 To MaxUserFields() Do
		
		Field = StrReplace(FieldNamePattern, "NN", String(FieldNumber));
		
		If Items["MappingTable" + Field].Visible
			And ValueIsFilled(Data[Field]) Then
			
			Result.Add(Data[Field]);
			
		EndIf;
		
	EndDo;
	
	If Result.Count() = 0 Then
		
		Result.Add(NStr("vi = '<chưa đặt>';
						|ru = '<не задан>';
						|en = '<not specified>'; fa = '<مشخص نشده>';
						|it = '<non impostato>';
						|pl = '<nie określono>';
						|tr = '<belirtilmedi>'"));
		
	EndIf;
	
	Return StrConcat(Result, ", ");
EndFunction

&AtClient
Procedure AddUnapprovedMappingAtClient(Val BeginningRowID, Val EndingRowID)
	
	// Get 2 mapped rows by the given IDs. Add a to the unconfirmed links table.
	// Add a row to the mapping table. Remove the mapped rows from the mapping table.
	// 
	// 
	
	BeginningRow    = MappingTable.FindByID(BeginningRowID);
	EndingRow = MappingTable.FindByID(EndingRowID);
	
	If BeginningRow = Undefined Or EndingRow = Undefined Then
		Return;
	EndIf;
	
	If BeginningRow.MappingStatus=-1 And EndingRow.MappingStatus=+1 Then
		SourceRow1 = BeginningRow;
		DestinationRow1 = EndingRow;
	ElsIf BeginningRow.MappingStatus=+1 And EndingRow.MappingStatus=-1 Then
		SourceRow1 = EndingRow;
		DestinationRow1 = BeginningRow;
	Else
		Return;
	EndIf;
	
	// Adding a row to the unapproved mapping table.
	NewRow = Object.UnapprovedMappingTable.Add();
	
	NewRow.SourceUUID = DestinationRow1.DestinationUUID;
	NewRow.SourceType                     = DestinationRow1.DestinationType;
	NewRow.DestinationUUID = SourceRow1.SourceUUID;
	NewRow.DestinationType                     = SourceRow1.SourceType;
	
	// Adding a row to the mapping table as an unapproved one.
	NewRowUnapproved = MappingTable.Add();
	
	// Taking sorting fields from the destination row.
	FillPropertyValues(NewRowUnapproved, SourceRow1, "SourcePictureIndex, SourceField1, SourceField2, SourceField3, SourceField4, SourceField5, SourceUUID, SourceType");
	FillPropertyValues(NewRowUnapproved, DestinationRow1, "DestinationPictureIndex, DestinationField1, DestinationField2, DestinationField3, DestinationField4, DestinationField5, DestinationUUID, DestinationType, SortField1, SortField2, SortField3, SortField4, SortField5, PictureIndex");
	
	NewRowUnapproved.MappingStatus               = 3; // Unapproved connection.
	NewRowUnapproved.MappingStatusAdditional = 0;
	
	// Delete mapped rows.
	MappingTable.Delete(BeginningRow);
	MappingTable.Delete(EndingRow);
	
	// Updating numbers.
	NewRowUnapproved.SerialNumber = NextNumberByMappingOrder();
	
	NewRowUnapproved.MappingByRef = AreObjectsMappedByRef(NewRowUnapproved);
	
	// Setting the filter and updating data in the mapping table.
	SetTabularSectionFilter();
EndProcedure

&AtServer
Function NextNumberByMappingOrder()
	Result = 0;
	
	For Each String In MappingTable Do
		Result = Max(Result, String.SerialNumber);
	EndDo;
	
	Return Result + 1;
EndFunction

&AtClient
Procedure ExecuteTableSorting()
	
	SortFields = GetSortingFields();
	If Not IsBlankString(SortFields) Then
		MappingTable.Sort(SortFields);
	EndIf;
	
EndProcedure

&AtClient
Function GetSortingFields()
	
	// Function return value.
	SortFields = "";
	
	FieldPattern = "SortFieldNN #SortDirection"; // Do not localize.
	
	For Each TableRow In Object.SortTable Do
		
		If TableRow.Use Then
			
			Separator = ?(IsBlankString(SortFields), "", ", ");
			
			SortDirectionStr = ?(TableRow.SortDirection, "Asc", "Desc");
			
			ListItem = Object.UsedFieldsList.FindByValue(TableRow.FieldName);
			
			FieldIndex = Object.UsedFieldsList.IndexOf(ListItem) + 1;
			
			FieldName = StrReplace(FieldPattern, "NN", String(FieldIndex));
			FieldName = StrReplace(FieldName, "#SortDirection", SortDirectionStr);
			
			SortFields = SortFields + Separator + FieldName;
			
		EndIf;
		
	EndDo;
	
	Return SortFields;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Properties

&AtClient
Function MaxUserFields()
	
	Return DataExchangeClient.MaxObjectsMappingFieldsCount();
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Transition event handlers.

// Page 1: Object mapping error.
//
&AtClient
Function Attachable_ObjectMappingErrorOnOpen(Cancel, SkipPage, IsMoveNext)
	
	ApplyUnapprovedRecordsTable = False;
	ApplyAutomaticMappingResult = False;
	AutoMappedObjectsTableAddress = "";
	WriteAndClose = False;
	
	Items.TableButtons.Enabled = True;
	Items.TableHeaderGroup.Enabled = True;
	
	Return Undefined;
	
EndFunction

// Page 2 (waiting): Object mapping.
//
&AtClient
Function Attachable_ObjectMappingWaitingTimeConsumingOperationProcessing(Cancel, GoToNext)
	
	// Selecting search fields if they are not specified.
	FillInSearchFields();
	
	// Determining the number of user-defined fields to be displayed.
	CheckUserFieldsFilled(Cancel, Object.UsedFieldsList.UnloadValues());
	
	If Cancel Then
		Return Undefined;
	EndIf;
	
	TimeConsumingOperation          = False;
	TimeConsumingOperationCompleted = True;
	JobID        = Undefined;
	TempStorageAddress    = "";
	
	Result = BackgroundJobStartAtServer(Cancel);
	
	If Cancel Then
		Return Undefined;
	EndIf;
	
	If Result.Status = "Running" Then
		
		GoToNext                = False;
		TimeConsumingOperation          = True;
		TimeConsumingOperationCompleted = False;
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		IdleParameters.OutputMessages    = True;
		
		CallbackOnCompletion = New CallbackDescription("BackgroundJobCompletion", ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(Result, CallbackOnCompletion, IdleParameters);
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Page 2 Handler of background job completion notification.
&AtClient
Procedure BackgroundJobCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation          = False;
	TimeConsumingOperationCompleted = True;
	
	If Result = Undefined Then
		RecordError(NStr("vi = 'Nhiệm vụ nền đã bị hủy bởi quản trị viên.';
						|ru = 'Фоновое задание отменено администратором.';
						|en = 'Background job is canceled by administrator.'; fa = 'Background job is canceled by administrator.';
						|it = 'Il task in background è annullato dall''amministratore.';
						|pl = 'Zadanie w tle zostało anulowane przez administratora.';
						|tr = 'Arka plan görevi yönetici tarafından iptal edildi.'"));
		GoBack();
	ElsIf Result.Status = "Error" Or Result.Status = "Canceled" Then
		RecordError(Result.DetailErrorDescription);
		GoBack();
	Else
		GoToNext();
	EndIf;
	
EndProcedure

// Page 3 (waiting): Object mapping.
//
&AtClient
Function Attachable_ObjectMappingWaitingTimeConsumingOperationCompletionTimeConsumingOperationProcessing(Cancel, GoToNext)
	
	If WriteAndClose Then
		GoToNext = False;
		Close();
		Return Undefined;
	EndIf;
	
	If TimeConsumingOperationCompleted Then
		ExecuteObjectMappingCompletion(Cancel);
	EndIf;
	
	Items.TableButtons.Enabled          = True;
	Items.TableHeaderGroup.Enabled = True;
	
	// Setting filter in the mapping tabular section.
	SetTabularSectionFilter();
	
	// Setting mapping table field headers and visibility.
	SetTableFieldVisible("MappingTable");
	
	Return Undefined;

EndFunction

// Page 2 Object mapping in background job.
//
&AtServer
Function BackgroundJobStartAtServer(Cancel)
	
	FormAttributes = New Structure;
	FormAttributes.Insert("ApplyOnlyUnapprovedRecordsTable",    WriteAndClose);
	FormAttributes.Insert("ApplyUnapprovedRecordsTable",          ApplyUnapprovedRecordsTable);
	FormAttributes.Insert("ApplyAutomaticMappingResult", ApplyAutomaticMappingResult);
	
	JobParameters = New Structure;
	JobParameters.Insert("ObjectContext", DataExchangeServer.GetObjectContext(FormAttributeToValue("Object")));
	JobParameters.Insert("FormAttributes",  FormAttributes);
	
	If ApplyAutomaticMappingResult Then
		JobParameters.Insert("AutomaticallyMappedObjectsTable", GetFromTempStorage(AutoMappedObjectsTableAddress));
	EndIf;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'So sánh đối tượng';
														|ru = 'Сопоставление объектов';
														|en = 'Object mapping'; fa = 'نگاشت اشیا';
														|it = 'Associazione degli oggetti';
														|pl = 'Zestawienie obiektów';
														|tr = 'Nesne eşlenmesi'");
	
	Result = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.InfobasesObjectsMapping.MapObjects",
		JobParameters,
		ExecutionParameters);
		
	If Result = Undefined Then
		Cancel = True;
		Return Undefined;
	EndIf;
	
	JobID     = Result.JobID;
	TempStorageAddress = Result.ResultAddress;
	
	If Result.Status = "Error" Or Result.Status = "Canceled" Then
		Cancel = True;
		RecordError(Result.DetailErrorDescription);
	EndIf;
	
	Return Result;
	
EndFunction

// Page 3: Object mapping.
//
&AtServer
Procedure ExecuteObjectMappingCompletion(Cancel)
	
	Try
		AfterObjectMapping();
	Except
		Cancel = True;
		RecordError(ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
EndProcedure

&AtServer
Procedure AfterObjectMapping()
	
	If WriteAndClose Then
		Return;
	EndIf;
	
	MappingResult = GetFromTempStorage(TempStorageAddress);
	
	// {Mapping digest}
	ObjectCountInSource       = MappingResult.ObjectCountInSource;
	ObjectCountInDestination       = MappingResult.ObjectCountInDestination;
	MappedObjectCount   = MappingResult.MappedObjectCount;
	UnmappedObjectsCount = MappingResult.UnmappedObjectsCount;
	MappedObjectPercentage       = MappingResult.MappedObjectPercentage;
	PictureIndex                     = DataExchangeServer.StatisticsTablePictureIndex(UnmappedObjectsCount, Object.DataImportedSuccessfully);
	
	MappingTable.Load(MappingResult.MappingTable);
	
	For Each String In MappingTable Do
		String.MappingByRef = AreObjectsMappedByRef(String);
	EndDo;
	
	DataProcessorObject = DataProcessors.InfobasesObjectsMapping.Create();
	DataExchangeServer.ImportObjectContext(MappingResult.ObjectContext, DataProcessorObject);
	
	ValueToFormAttribute(DataProcessorObject, "Object");
	
	If ApplyUnapprovedRecordsTable Then
		Modified = False;
	EndIf;
	
	ApplyUnapprovedRecordsTable           = False;
	ApplyAutomaticMappingResult  = False;
	AutoMappedObjectsTableAddress = "";
	
EndProcedure

&AtServer
Procedure RecordError(DetailErrorDescription)
	
	WriteLogEvent(
		NStr("vi = 'Trợ giúp so sánh các đối tượng.Phân tích dữ liệu';
			|ru = 'Помощник сопоставления объектов.Анализ данных';
			|en = 'Object mapping wizard.Data analysis'; fa = 'Object mapping wizard.Data analysis';
			|it = 'Assistente dell''associazione degli oggetti.Analisi dati';
			|pl = 'Asystent porównania obiektów. Analiza danych';
			|tr = 'Nesne karşılaştırma sihirbazı.Veri analizi'", Common.DefaultLanguageCode()),
		EventLogLevel.Error,
		,
		, DetailErrorDescription);
	
EndProcedure

&AtClientAtServerNoContext
Function AreObjectsMappedByRef(String)
	
	Return ValueIsFilled(String.DestinationUUID)
		And String(String.DestinationUUID.UUID()) = String.SourceUUID;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Initialization of assistant transitions.

&AtServer
Procedure ObjectMappingScenario()
	
	NavigationTable.Clear();
	NavigationTableNewRow(1, "ObjectMappingError", "Attachable_ObjectMappingErrorOnOpen");
	
	// Waiting for object mapping.
	NavigationTableNewRow(2, "ObjectMappingWait",, True, "Attachable_ObjectMappingWaitingTimeConsumingOperationProcessing");
	NavigationTableNewRow(3, "ObjectMappingWait",, True, "Attachable_ObjectMappingWaitingTimeConsumingOperationCompletionTimeConsumingOperationProcessing");
	
	// Operations with object mapping table.
	NavigationTableNewRow(4, "ObjectsMapping");
	
EndProcedure

#EndRegion
