
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	Query = New Query;
	Query.Text =
	WarehousesServer.QueryTextWarehouseOperationDocumentType() + 
	"SELECT
	|	Balance.DocumentShipments,
	|	SUM(Balance.ToShipBalance - Balance.AssemblyInProgressBalance - Balance.AssembledBalance) AS ToShip
	|INTO ShippingDocuments
	|FROM
	|	(SELECT
	|		GoodsForIssueBalance.DocumentShipments AS DocumentShipments,
	|		GoodsForIssueBalance.ToShipBalance AS ToShipBalance,
	|		GoodsForIssueBalance.AssemblyInProgressBalance AS AssemblyInProgressBalance,
	|		GoodsForIssueBalance.AssembledBalance AS AssembledBalance
	|	FROM
	|		AccumulationRegister.GoodsForIssue.Balance(
	|				,
	|				Products = &Products
	|					AND Characteristic = &Characteristic
	|					AND Purpose = &Purpose
	|					AND Series = &Series
	|					AND Warehouse = &Warehouse
	|					AND Recipient = &Recipient) AS GoodsForIssueBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsForIssue.DocumentShipments,
	|		CASE
	|			WHEN GoodsForIssue.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -GoodsForIssue.ToShip
	|			ELSE GoodsForIssue.ToShip
	|		END,
	|		CASE
	|			WHEN GoodsForIssue.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -GoodsForIssue.AssemblyInProgress
	|			ELSE GoodsForIssue.AssemblyInProgress
	|		END,
	|		CASE
	|			WHEN GoodsForIssue.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -GoodsForIssue.Assembled
	|			ELSE GoodsForIssue.Assembled
	|		END
	|	FROM
	|		AccumulationRegister.GoodsForIssue AS GoodsForIssue
	|	WHERE
	|		GoodsForIssue.Products = &Products
	|		AND GoodsForIssue.Characteristic = &Characteristic
	|		AND GoodsForIssue.Purpose = &Purpose
	|		AND GoodsForIssue.Series = &Series
	|		AND GoodsForIssue.Warehouse = &Warehouse
	|		AND GoodsForIssue.Recipient = &Recipient
	|		AND GoodsForIssue.Recorder = &Recorder) AS Balance
	|
	|GROUP BY
	|	Balance.DocumentShipments
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ShippingDocuments.DocumentShipments AS ReferenceOrder,
	|	ShippingDocuments.ToShip AS ToShip,
	|	CASE
	|		WHEN ShippingDocuments.ToShip = 0
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereAreGoodsForShipment
	|FROM
	|	ShippingDocuments AS ShippingDocuments
	|		INNER JOIN WarehouseOperationDocumentType AS WarehouseOperationDocumentType
	|		ON (VALUETYPE(ShippingDocuments.DocumentShipments) = WarehouseOperationDocumentType.Type)
	|			AND (WarehouseOperationDocumentType.WarehouseOperation = &WarehouseOperation)
	|			AND (CASE
	|				WHEN ShippingDocuments.DocumentShipments REFS Document.ByAssemblyDisassemblyOrder
	|					THEN CAST(ShippingDocuments.DocumentShipments AS Document.ByAssemblyDisassemblyOrder).BusinessOperation
	|				WHEN ShippingDocuments.DocumentShipments REFS Document.AssemblyFromComponents
	|					THEN CAST(ShippingDocuments.DocumentShipments AS Document.AssemblyFromComponents).BusinessOperation
	|				ELSE UNDEFINED
	|			END = WarehouseOperationDocumentType.BusinessOperation)
	|
	|ORDER BY
	|	ToShip DESC";
	
	QueryOptions = Query.FindParameters();
	
	For Each ArrRow In QueryOptions Do
		Query.SetParameter(ArrRow.Name, Parameters[ArrRow.Name]);
	EndDo;
	
	References.Load(Query.Execute().Unload());
	
	FilterByBalance = "OnlyWithAvailableGoods";
	SetSelectionByBalance();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterByBalanceOnChange(Item)
	SetSelectionByBalance()
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReferences

&AtClient
Procedure ReferencesSelection(Item, RowSelected, Field, StandardProcessing)
	CurrentData = Items.References.CurrentData;
	NotifyChoice(CurrentData.ReferenceOrder);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	CurrentData = Items.References.CurrentData;
	
	If CurrentData = Undefined Then
		WarningText_ = NStr("vi = 'Hãy chọn lệnh.';
							|ru = 'Выберите распоряжение.';
							|en = 'Select reference.'; fa = 'Select reference.';
							|it = 'Seleziona una disposizione.';
							|pl = 'Wybierz zamówienie.';
							|tr = 'Emir seç.'");
		ShowMessageBox(,WarningText_);
		Return;
	EndIf;
		
	NotifyChoice(CurrentData.ReferenceOrder);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetSelectionByBalance()
	If FilterByBalance = "All" Then
		Items.References.RowFilter = Undefined;
	Else
		Items.References.RowFilter = New FixedStructure("ThereAreGoodsForShipment", True);
	EndIf;	
EndProcedure

#EndRegion