#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds a Command to create stock maintenance parameters based on.
//
// Parameters:
//  CreateCommandsBasedOn - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated Commands for output to the submenu
Function AddInstallInventoryMaintenanceCommand(CreateCommandsBasedOn) Export
	
	If AccessRight("Update", Metadata.InformationRegisters.ProductRestrictions)
		And AccessRight("View", Metadata.DataProcessors.SetUpStockReplenishment) Then
		CreateBasedOnCommand = CreateCommandsBasedOn.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.SetInventoryLevelControl";
		CreateBasedOnCommand.Id = "SetInventoryLevelControl";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Thành lập hàng tồn kho';
												|ru = 'Установить поддержание запасов';
												|en = 'Set inventory level control'; fa = 'Set inventory level control';
												|it = 'Stabilire il mantenimento delle scorte';
												|pl = 'Ustaw utrzymanie zapasów';
												|tr = 'Stok yenileme oluştur'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseAdvancedDemandFulfillment";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds a Command to create stock maintenance parameters based on the opening of a separate parameter setting form.
//
// Parameters:
//  CreateCommandsBasedOn - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated Commands for output to the submenu
Function AddConfigureInventoryMaintenanceCommand(CreateCommandsBasedOn) Export
	
	If AccessRight("View", Metadata.DataProcessors.SetUpStockReplenishment) Then
		CreateBasedOnCommand = CreateCommandsBasedOn.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.SetUpStockReplenishment";
		CreateBasedOnCommand.Id = "SetUpStockReplenishment";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Thiết lập tham số đảm bảo';
												|ru = 'Настройка поддержания запасов';
												|en = 'Inventory replenishment parameters'; fa = 'پارامترهای تکمیل موجودی';
												|it = 'Configurazione di mantenimento delle scorte';
												|pl = 'Ustawienia podtrzymania stanów magazynowych';
												|tr = 'Stok destek ayarları'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseAdvancedDemandFulfillment";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region Internal

Function EstablishInventoryMaintenanceToDocumentAssortmentChanges(DocumentRef) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ChangingProductRange.Products AS Products,
		|	ISNULL(Formats.Warehouse, ProductRangeChange.PlanningObject) AS Warehouse
		|INTO TTProducts_1
		|FROM
		|	Document.ProductRangeChange AS ProductRangeChange
		|		INNER JOIN Document.ProductRangeChange.Goods AS ChangingProductRange
		|		ON (ChangingProductRange.Ref = ProductRangeChange.Ref)
		|		LEFT JOIN InformationRegister.HistoryOfStoreFormatChange.SliceLast AS Formats
		|		ON (Formats.StoreFormat = ProductRangeChange.PlanningObject)
		|WHERE
		|	ProductRangeChange.Ref = &ProductRangeChangeDocument
		|		AND ISNULL(Formats.Warehouse, ProductRangeChange.PlanningObject) REFS Catalog.Warehouses
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTProducts_1.Products AS Products,
		|	TTProducts_1.Warehouse AS Warehouse
		|FROM
		|	TTProducts_1 AS TTProducts_1
		|		LEFT JOIN InformationRegister.ProductRestrictions AS ProductRestrictions
		|		ON TTProducts_1.Products = ProductRestrictions.Products
		|			AND TTProducts_1.Warehouse = ProductRestrictions.Warehouse
		|			AND (ProductRestrictions.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
		|WHERE
		|	ProductRestrictions.Warehouse IS NULL";
	
	Query.SetParameter("ProductRangeChangeDocument", DocumentRef);
	
	QueryResult = Query.ExecuteBatch();
	Selection = QueryResult[0].Select();
	Selection.Next();
	If Selection.Count = 0 Then
		Return False;
	EndIf;
	
	RecordsKeys = New Array;
	Selection = QueryResult[1].Select();
	While Selection.Next() Do
		ProductRecordKey = InformationRegisters.ProductRestrictions.ProductEntryKey();
		ProductRecordKey.Products = Selection.Products;
		ProductRecordKey.Warehouse = Selection.Warehouse;
		RecordsKeys.Add(ProductRecordKey);
	EndDo;
	
	InformationRegisters.ProductRestrictions.AddStockMaintenanceMinMax(RecordsKeys);
	Return True;
	
EndFunction

#EndRegion

#EndIf