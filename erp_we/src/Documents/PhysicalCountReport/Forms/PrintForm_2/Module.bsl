
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
		// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InventoryArray = Undefined;
	Parameters.Property("Sheets", InventoryArray);
	If ValueIsFilled(InventoryArray) Then
		SheetList.LoadValues(InventoryArray);
	EndIf;
	
	Parameters.Property("Id", Id);
	If Not ValueIsFilled(Id) Then
		
		Items.FormPrintButton_.Visible = False;
		
		// StandardSubsystems.AttachableCommands
		AttachableCommands.OnCreateAtServer(ThisObject);
		// End StandardSubsystems.AttachableCommands
	Else
		PrintCommands = PrintManagement.CreatePrintCommandsCollection();
		Documents.PhysicalCountReport.AddPrintCommands(PrintCommands);
		TheStructureOfTheSearch = New Structure("Id", Id);
		Rows = PrintCommands.FindRows(TheStructureOfTheSearch);
		If Rows.Count() > 0 Then
			PrintManager = Rows[0].PrintManager;
		Else
			Items.FormPrintButton_.Visible = False;
		EndIf;
	EndIf;
	
	Parameters.Property("StartDate",	StartDate);
	Parameters.Property("EndDate",	EndDate);
	If Parameters.Property("Warehouse") Then
		Warehouses.Add(Parameters.Warehouse);
	ElsIf Parameters.Property("Warehouses") Then
		Warehouses.LoadValues(Parameters.Warehouses);
	EndIf;		
	
	CompanyArray = Undefined;
	Parameters.Property("MarkOrganizations", CompanyArray);
	If TypeOf(CompanyArray) = Type("Array") Then
		MarkOrganizations.LoadValues(CompanyArray);
	EndIf;
	
	UpdateSceneryStateServer();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecorationStateNavigationLinkProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	If Var_URL = "RegisterWarehouseActs" Then
		FormParameters = New Structure;
		If Warehouses.Count() = 1 Then 
			FormParameters.Insert("Warehouse", Warehouses[0].Value);
		EndIf;
		OpenForm("DataProcessor.WarehouseGoodsIssueReceiptWizard.Form", FormParameters, ThisForm);
	ElsIf Var_URL = "CreateInventory" Then
		
		If Warehouses.Count() = 1 Then
			OpenInventoryForm(Warehouses[0].Value);
		Else
			OpenInventoryForm();
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSheets

&AtClient
Procedure SheetsSelection(Item, RowSelected, Field, StandardProcessing)
		
	If ValueIsFilled(Id) Then
		StandardProcessing = False;
		ProcessSelectedRows();
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure SheetsOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PrintButton_(Command)
	
	Var Cancel;
	MessageText = "";
	
	ClearMessages();
	
	If SheetList.Count() = 0 Then
		MessageText = NStr("vi = 'Không thể in biểu mẫu ""%PrintForm%"", vì chưa lập chứng từ ""Bản kiểm kê"" nào.';
							|ru = 'Невозможно напечатать форму ""%PrintForm%"", т.к. не сформировано ни одного документа ""Инвентаризационная опись"".';
							|en = 'Cannot print form ""%PrintForm%"" as no ""Physical inventory register"" document is generated.'; fa = 'Cannot print form ""%PrintForm%"" as no ""Physical inventory register"" document is generated.';
							|it = 'Impossibile stampare il modulo ""%PrintForm%"", perché non è stato generato un singolo documento ""Inventario"".';
							|pl = 'Niemożliwe jest wydrukowanie formularza ""%PrintForm%"", ponieważ, nie sporządzono ani jednego dokumentu ""Инвентаризационная опись"".';
							|tr = 'Form yazdırılamıyor ""%PrintForm%"", çünkü tek bir ""Envanter girişi"" belgesi oluşturulmadı.'");
		Cancel = True;
	ElsIf Items.Sheets.SelectedRows.Count() = 0 Then
		MessageText = NStr("vi = 'Chưa hiển thị bản in nào. Không thể in biểu mẫu ""%PrintForm%"".';
							|ru = 'Не выделено ни одной описи на печать. Печать формы ""%PrintForm%"" невозможна.';
							|en = 'No inventory register for printing is selected. Cannot print form ""%PrintForm%"".'; fa = 'No inventory register for printing is selected. Cannot print form ""%PrintForm%"".';
							|it = 'Non è stato selezionato un solo inventario per la stampa. La stampa del modulo ""%PrintForm%"" non è possibile.';
							|pl = 'Nie wybrano ani jednego spisu do drukowania. Drukowanie formularza ""%PrintForm%"" jest niemożliwe.';
							|tr = 'Yazdırma için herhangi bir giriş seçilmedi. ""%PrintForm%"" formu yazdırılamaz.'");
		Cancel = True;
	EndIf;
	
	If Cancel = True Then
		PrintForm = "";
		If Id = "INV3" Then
			PrintForm = NStr("vi = 'Bản kiểm kê';
							|ru = 'Инвентаризационная опись (ИНВ-3)';
							|en = 'Physical inventory register (INV-3)'; fa = 'Physical inventory register (INV-3)';
							|it = 'Inventario (INV-3)';
							|pl = 'Spis inwentaryzacyjny (ИНВ-3)';
							|tr = 'Fiziksel stok kaydı (ENV-3)'");	
		ElsIf Id = "INV19" Then 
			PrintForm = NStr("vi = 'Bảng kiểm kê';
							|ru = 'Сличительная ведомость (ИНВ-19)';
							|en = 'Inventory reconciliation report (INV-19)'; fa = 'Inventory reconciliation report (INV-19)';
							|it = 'Distinta comparativa (INV-19)';
							|pl = 'Zestawienie porównawcze (ИНВ-19)';
							|tr = 'Karşılaştırma tablosu (ENV-19)'");
		Else
			Raise NStr("vi = 'Sai tên mẫu in. Hãy liên hệ với người quản trị.';
						|ru = 'Неверный идентификатор печатной формы. Обратитесь к администратору.';
						|en = 'Incorrect print form ID. Please contact the administrator.'; fa = 'Incorrect print form ID. Please contact the administrator.';
						|it = 'Identificatore del modulo di stampa non è valido. Contattare l''amministratore.';
						|pl = 'Błędny identyfikator formularza wydruku. Zwróć się do administratora.';
						|tr = 'Geçersiz yazdırılabilir tanımlayıcı. Yöneticinizle iletişime geçin.'");
		EndIf;
		MessageText = StrReplace(MessageText, "%PrintForm%", PrintForm);
		CommonClientServer.MessageToUser(MessageText);
		Return;
	EndIf;
	
	ProcessSelectedRows();
	
	Close();
		
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.Sheets);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.Sheets, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.Sheets);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.Sheets);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateSceneryStateServer()
	
	Sheets.Filter.Items.Clear();
	FilterElement = Sheets.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("Ref");
	FilterElement.ComparisonType = DataCompositionComparisonType.InList;
	FilterElement.RightValue = SheetList;
	FilterElement.Use = True;
	
	UseMultipleCompanies = GetFunctionalOption("UseMultipleCompanies");
	YouHaveRightToCreateInventory = AccessRight("Insert", Metadata.Documents.PhysicalCountReport);
	
	Items.DecorationCreateAnInventoryOfSeveralOrganizations.Visible = UseMultipleCompanies
		And YouHaveRightToCreateInventory;
	Items.DecorationToCreateAnInventoryOfOneOrganization.Visible = Not UseMultipleCompanies
		And YouHaveRightToCreateInventory;
	
	WarehouseArray = Warehouses.UnloadValues();
	ProductsTable = DataProcessors.WarehouseGoodsIssueReceiptWizard.GoodsForRegistrationOfWarehouseActs(WarehouseArray,, StartDate, EndDate);
	Items.DecorationFormActs.Visible = ProductsTable.Count() > 0;
	
EndProcedure

&AtClient
Procedure OpenInventoryForm(Val Warehouse = Undefined)
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("StartDate",	StartDate);
	GenerationParameters.Insert("EndDate",	EndDate);
	If Not Warehouse = Undefined Then
		GenerationParameters.Insert("Warehouse", 	Warehouse);
	EndIf;
	GenerationParameters.Insert("MarkOrganizations", MarkOrganizations.UnloadValues());
	
	Notification = New CallbackDescription("CreateInventoryCompletion", ThisForm);
	OpenForm("Document.PhysicalCountReport.Form.FormGenerate",
		GenerationParameters, ThisForm,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CreateInventoryCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Or Not TypeOf(Result) = Type("Array") Then
		Return;
	EndIf;
	
	For Each Inventory_1 In Result Do
		SheetList.Add(Inventory_1);
	EndDo;
	
	UpdateSceneryStateServer();
	
EndProcedure

&AtClient
Procedure ProcessSelectedRows()
	If ValueIsFilled(Id) Then
		PrintManagementClient.ExecutePrintCommand(
			PrintManager,
			Id,
			Items.Sheets.SelectedRows,
			ThisForm.FormOwner);
	EndIf;
EndProcedure

#EndRegion
