#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.GoodsPickingPlacement.AddGenerateCommand(GenerationCommands);
	
	DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(GenerationCommands);
	
EndProcedure

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
	
EndProcedure

#Region ToDoList

// Fills in the user's to-do list.
// 
// Parameters:
// 	ToDoList - See ToDoListServer.ToDoList
//
Procedure OnFillToDoList(ToDoList) Export
	
	FormName = "DataProcessor.InboundWarehouseMangement.Form.Form";
	
	CommonQueryParameters = ToDoListInternal.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.DataProcessors.InboundWarehouseMangement))
		And GetFunctionalOption("UseWarehouseManagemantSystemForGoodsReceipt");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// Calculation of indicators.
	// A row with an unspecified warehouse value is not taken into account,
	// indicators for other warehouses are increased by the number of agreements with an unspecified warehouse.
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(DISTINCT AllReferences.DocumentInflow) AS IndicatorValue,
	|	AllReferences.Warehouse AS Warehouse
	|INTO TTDecryption
	|FROM
	|	(SELECT
	|		TermsOfPurchaseFromVendors.Ref AS DocumentInflow,
	|		TermsOfPurchaseFromVendors.Warehouse AS Warehouse
	|	FROM
	|		Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchaseFromVendors
	|	WHERE
	|		TermsOfPurchaseFromVendors.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed)
	|		AND TermsOfPurchaseFromVendors.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
	|		AND NOT TermsOfPurchaseFromVendors.DeletionMark
	|		AND (TermsOfPurchaseFromVendors.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|		OR TermsOfPurchaseFromVendors.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt)
	|
	|	UNION ALL
	|
	|	SELECT
	|		GoodsToReceive.DocumentInflow,
	|		GoodsToReceive.Warehouse
	|	FROM
	|		(SELECT
	|			GoodsToBeReceivedBalancesAsOfDate.DocumentInflow AS DocumentInflow,
	|			GoodsToBeReceivedBalancesAsOfDate.Warehouse AS Warehouse,
	|			MIN(GoodsToBeReceivedBalancesAsOfDate.GoodsReceiptNotesToRegisterBalance -
	|				GoodsToBeReceivedBalancesAsOfDate.AcceptsBalance < 0) AS Overdelivery
	|		FROM
	|			AccumulationRegister.GoodsToReceive.Balance(&DateOfReceipt, Warehouse.UseWarehouseManagemantSystemForGoodsReceipt) AS
	|				GoodsToBeReceivedBalancesAsOfDate
	|		WHERE
	|			(GoodsToBeReceivedBalancesAsOfDate.DocumentInflow, GoodsToBeReceivedBalancesAsOfDate.Products,
	|				GoodsToBeReceivedBalancesAsOfDate.Characteristic, GoodsToBeReceivedBalancesAsOfDate.Warehouse) IN
	|				(SELECT
	|					GoodsDueCurBalances.DocumentInflow,
	|					GoodsDueCurBalances.Products,
	|					GoodsDueCurBalances.Characteristic,
	|					GoodsDueCurBalances.Warehouse
	|				FROM
	|					AccumulationRegister.GoodsToReceive.Balance(, Warehouse.UseWarehouseManagemantSystemForGoodsReceipt) AS
	|						GoodsDueCurBalances)
	|		GROUP BY
	|			GoodsToBeReceivedBalancesAsOfDate.DocumentInflow,
	|			GoodsToBeReceivedBalancesAsOfDate.Warehouse) AS GoodsToReceive
	|	WHERE
	|		NOT GoodsToReceive.Overdelivery) AS AllReferences
	|GROUP BY
	|	AllReferences.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTDecryption.IndicatorValue + ISNULL(TTDecryptionWithoutWarehouse.IndicatorValue, 0) AS IndicatorValue,
	|	TTDecryption.Warehouse AS Warehouse
	|FROM
	|	TTDecryption AS TTDecryption
	|		LEFT JOIN TTDecryption AS TTDecryptionWithoutWarehouse
	|		ON TTDecryptionWithoutWarehouse.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|WHERE
	|	TTDecryption.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)";
	
	ToDoListInternal.SetCommonQueryParameters(Query, CommonQueryParameters);
	
	Query.SetParameter("DateOfReceipt", EndOfDay(CommonQueryParameters.CurrentDate));
	
	Result = Query.Execute().Unload();
	
	// Filling out cases.
	// Dispositions of access
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "ReceiptOrders";
	UserTaskParent.Presentation  = NStr("vi = 'Lệnh tiếp nhận';
										|ru = 'Распоряжения на поступление';
										|en = 'Receipt references'; fa = 'مراجع رسید';
										|it = 'Disposizioni per l''arrivo';
										|pl = 'Zamówienie wpływu';
										|tr = 'Giriş emri'");
	UserTaskParent.Owner       = Metadata.Subsystems.Warehouse;
	
	For Each ResultString1 In Result Do
		
		FilterParameters = New Structure;
		FilterParameters.Insert("Premise", Undefined);
		FilterParameters.Insert("ReceivingArea", Undefined);
		
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
		ToDoItem.Owner       = "ReceiptOrders";
		
		If UserTaskValue > 0 Then
			UserTaskParent.HasToDoItems = True;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
