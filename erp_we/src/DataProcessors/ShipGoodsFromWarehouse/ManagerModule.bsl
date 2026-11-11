#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#Region Private

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	If AccessRight("Update", Metadata.Documents.GoodsIssueNote) Then
		// Expenditure order for goods
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "Document.GoodsIssueNote";
		PrintCommand.Id = "GoodsIssueNote";
		PrintCommand.Presentation = NStr("vi = 'Phiếu xuất kho';
										|ru = 'Расходный ордер на товары';
										|en = 'Goods issue'; fa = 'حواله انبار';
										|it = 'Mandato di pagamento per le merci';
										|pl = 'Asygnata rozchodowa na wiersze pozycji';
										|tr = 'ambar çıkış fişi'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.PlacingLocation = "NotesInProgressGroupCommandBar";
	EndIf;

	// Task for the selection of goods
	PrintCommand = PrintCommands.Add();
	PrintCommand.PrintManager = "DataProcessor.PrintJobsForInventoryPickingPlacementAndRecount";
	PrintCommand.Id = "GoodsPickingPlacementJob";
	PrintCommand.Presentation = NStr("vi = 'Nhiệm vụ lấy ra hàng hóa';
									|ru = 'Задание на отбор товаров';
									|en = 'Picking job'; fa = 'کار برداشت';
									|it = 'Task per selezione prodotti';
									|pl = 'Zadanie na selekcję towarów';
									|tr = 'Ürün filtre görevi'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.AdditionalParameters.Insert("FormName", "SelectionTask");
	PrintCommand.PlacingLocation = "NotesInProgressGroupCommandBar";
	
	If AccessRight("Update", Metadata.Documents.GoodsTransferNote) Then
		// Order to move goods
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "Document.GoodsTransferNote";
		PrintCommand.Id = "GoodsTransferNote";
		PrintCommand.Presentation = NStr("vi = 'Phiếu chuyển kho';
										|ru = 'Ордер на перемещение товаров';
										|en = 'Internal stock transfer'; fa = 'انتقال داخلی موجودی';
										|it = 'Ordine di trasferimento merci';
										|pl = 'Zlecenie na przemieszczenie towarów';
										|tr = 'Dahili stok transferi'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.PlacingLocation = "NotesInProgressGroupCommandBar";
	EndIf;
	
EndProcedure

#Region ToDoList

// Fills in the user's to-do list.
// 
// Parameters:
// 	ToDoList - See ToDoListServer.ToDoList
//
Procedure OnFillToDoList(ToDoList) Export
	
	FormName = "DataProcessor.ShipGoodsFromWarehouse.Form.Form";
	
	CommonQueryParameters = ToDoListInternal.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.DataProcessors.ShipGoodsFromWarehouse))
		And GetFunctionalOption("UseWarehouseManagemantSystemForGoodsIssue");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(DISTINCT AccumulationRegisterGoodsForIssueBalance.DocumentShipments) AS IndicatorValue,
	|	AccumulationRegisterGoodsForIssueBalance.Warehouse AS Warehouse
	|FROM
	|	AccumulationRegister.GoodsForIssue.Balance(&DateOfShipment, Warehouse.UseWarehouseManagemantSystemForGoodsIssue) AS AccumulationRegisterGoodsForIssueBalance
	|
	|GROUP BY
	|	AccumulationRegisterGoodsForIssueBalance.Warehouse";
	
	ToDoListInternal.SetCommonQueryParameters(Query, CommonQueryParameters);
	
	Query.SetParameter("DateOfShipment", EndOfDay(CommonQueryParameters.CurrentDate));
	
	Result = Query.Execute().Unload();
	
	// Filling out cases.
	// Dispositions of access
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "ShipmentReferences";
	UserTaskParent.Presentation  = NStr("vi = 'Lệnh xuất hàng';
										|ru = 'Распоряжения на отгрузку';
										|en = 'Shipment references'; fa = 'مراجع ارسال';
										|it = 'Disposizioni di spedizione';
										|pl = 'Zamówienia wysyłki';
										|tr = 'Sevkiyat emri'");
	UserTaskParent.Owner       = Metadata.Subsystems.Warehouse;
	
	For Each ResultString1 In Result Do
		
		FilterParameters = New Structure;
		FilterParameters.Insert("Premise", Undefined);
		FilterParameters.Insert("ShippingZone", Undefined);
		
		UserTaskPresentation = "";
		CaseFileID = "";
		UserTaskValue      = 0;
		For Each ResultColumn In Result.Columns Do
			ColumnValue = ResultString1[ResultColumn.Name];
			If ResultColumn.Name = "IndicatorValue" Then
				UserTaskValue = ColumnValue;
				Continue;
			EndIf;
			UserTaskPresentation = ?(UserTaskPresentation = "", "", ", ") + String(ColumnValue);
			CaseFileID = ?(CaseFileID = "", UserTaskParent.Id, CaseFileID)
				+ StrReplace(String(ColumnValue), " ", "");
			FilterParameters.Insert(ResultColumn.Name, ColumnValue);
		EndDo;
		
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = CaseFileID;
		ToDoItem.HasToDoItems       = UserTaskValue > 0;
		ToDoItem.Presentation  = UserTaskPresentation;
		ToDoItem.Count     = UserTaskValue;
		ToDoItem.Important         = False;
		ToDoItem.Form          = FormName;
		ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
		ToDoItem.Owner       = "ShipmentReferences";
		
		If UserTaskValue > 0 Then
			UserTaskParent.HasToDoItems = True;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
