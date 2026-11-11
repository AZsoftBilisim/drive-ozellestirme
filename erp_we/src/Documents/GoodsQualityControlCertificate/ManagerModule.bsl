#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
// 
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("RequestStatesForQualityControl");
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentObject.GoodsQualityControlCertificate, DocumentRef.GoodsQualityControlCertificate - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.GoodsQualityControlCertificate") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList();
	
	GetDocumentData(Query, DocumentRef);
	
	If Not AddlParameters.GetQueryTexts Then
		
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
	EndIf;
	QueryTextTableOfQualityControlRequests(Query, QueryTexts, Registers);
	////////////////////////////////////////////////////
	// Action Unlock:
	// The Registered Record (A): Remove the lock on the warehouse and in the security of the goods.
	
	////////////////////////////////////////////////////
	// Action to issue a refund:
	// The Registered Record (A): To remove the lock on the warehouse and in the provision of the goods.
	// Next, a "Return of goods to the supplier" will be issued regularly, which will ship the unlocked goods.
	
	////////////////////////////////////////////////////
	// Action to make a move:
	// The Registered Record (A): Remove the lock on the warehouse and in the supply of the item.
	// Next, the document "Movement of items" will be issued regularly.
	
	////////////////////////////////////////////////////
	// Action to issue a request:
	// 1) If the scheme for reflecting surplus shortages is an order one:
	// MOVEMENT (B): Reflection of the shortage of the controlled Lot reference in the warehouse (similar to the document Order to reflect the shortage).
	// Further, the "Write-off of shortages" will be issued regularly, without specifying the controlled Lot reference.
	// 2) If the scheme of reflection of surplus shortages is extraordinary:
	// THERE IS NO MOVEMENT.
	// Next, a regular "Write-off of shortages" will be issued, indicating the controlled Lot reference.
	// If the document is created on the basis of an Act, then the Lot reference is filled in automatically,
	// If the write-off is issued as a result of inventory, then the Lot reference is filled out based on the data of the document "Recalculation of goods".
	
	////////////////////////////////////////////////////
	// Action Formalize Spoilage:
	// 1) If the scheme for reflecting surplus shortages is an order one:
	// MOVEMENT (-B): Reflection of shortage of controlled Lot REFERENCES in the warehouse
	// MOVEMENT (+B): Reflection of a surplus item of a different quality without a Lot reference
	// Further, "Damage to items" will be regularly processed (purely fin. document).
	// 2) If the scheme of reflection of surplus shortages is extraordinary:
	// THERE IS NO MOVEMENT.
	// Further, on the basis of the act, "Damage to items" will be formalized, with a feature of movements.
	// The peculiarity is that for the original item, it will write off the item of the Lot reference, and the item will arrive without the Lot reference.
	
	// Further actions are prohibited for separate procurement.
	////////////////////////////////////////////////////
	// 
	// The action is unsuitable:
	// 1) If the acceptance scheme is order-based:
	// The Registered Record (C): Cancellation of the incoming order at the initial position of the item.
	// Next, you need to issue a regular report on discrepancies and fill it out according to the actual acceptance,
	// - After that, issue a discrepancy:
	// - either reduce the primary receipt documents (purchase invoice), or a corrective document
	//        - or issue an adjustment of the primary document
	// - Registration of the act of discrepancies in this case is mandatory
	//        - or issue a shortfall at our expense, having duly issued the document "Write-off of shortages"
	//        Registration of the act of discrepancies is mandatory
	// If the scheme for reflecting shortages is not random, then in the document "Write-off of shortages" it is necessary to specify the controlled batch.
	// 2) If the acceptance scheme is not an order one:
	// THERE ARE NO Registered Records.
	// Next, you need to issue a certificate of discrepancies on the basis of a quality control certificate, otherwise there is no way to get the initial data on discrepancies.
	// - After that, issue a discrepancy:
	// - either reduce the primary receipt documents (purchase invoice), or a corrective document
	//        - or issue an adjustment of the primary document
	//        If the act of discrepancies has not been drawn up, then it is necessary to issue an "Order to reflect shortages"
	// - and indicate the controlled party.
	//        - or issue a non-delivery at our expense, having duly issued the document "Write-off of shortages"
	//        If the act of discrepancies was not issued, then you need to issue an "Order to reflect shortages" and indicate the controlled party in it.
// If the scheme for reflecting shortages is not random, then in the document "Write-off of shortages" it is necessary to specify the controlled batch.
	
	////////////////////////////////////////////////////
	// Return action to the Supplier:
	// 1) If the acceptance scheme is order-based:
	// The Registered Record (C): Cancellation of the incoming order at the initial position of the item.
	// Further, regular actions for registration of discrepancies, as well as for the action, are unsuitable
	// 2) If the acceptance scheme is not an order one:
	// THERE ARE NO Registered Records.
	// Further, regular actions for registration of discrepancies, as well as for the action, are unsuitable
	// 3) It does not matter if the acceptance scheme is an order scheme, if the shipment scheme is an order scheme, then additionally
	// The Registered Record (D): Arrival of the original item of the item without ordering the blocked lot (to the warehouse and to the security)
	// Registered Record (E): Issuing an order for shipment (for return) of the original item of the item by lot (in the warehouse and in the security), will write off the goods from the security
	// Further, an expenditure order for the goods of the batch is regularly issued by order - an act of quality control, will write off the goods from the warehouse.
	
	////////////////////////////////////////////////////
	// Action to change the quality:
	// 1) If the acceptance scheme is order-based:
	// The Registered Record (-In): Cancellation of the receipt order for the initial position of the item by Lot reference.
	// The Register Recorded (+B): Entering a receipt order for a product of a different quality BY Lot REFERENCE (according to the item settings)!
	// Further, regular actions for registration of discrepancies, as well as for the action of InEligibility (for over-delivery of goods of a different quality and under-delivery of the original product)
	// The Registered Record (A): To remove the lock on the warehouse and in the provision of goods of a different quality.
	// 2) If the acceptance scheme is not an order one:
	// THERE ARE NO Registered Records. The action cannot be specified in the document.
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ReflectByWarehouseSubsystem(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region Other

// Receives the Balance of the item actually accepted.
// Parameters:
//  ActOfFoundation - DocumentRef.GoodsQualityControlCertificate - the act. 
//  Warehouse - See AccumulationRegister.GoodsToReceive
// Returns:
//  ValueTable - table with fields:
//	* ReferenceOrder - See AccumulationRegister.GoodsToReceive.DocumentInflow
//	* DocumentBasis - See AccumulationRegister.GoodsToReceive.DocumentInflow
//	* Products - See AccumulationRegister.GoodsToReceive.Products
//	* Characteristic - See AccumulationRegister.GoodsToReceive.Characteristic
//	* Purpose - See AccumulationRegister.GoodsToReceive.Purpose
//	* Warehouse - See AccumulationRegister.GoodsToReceive.Warehouse
//	* Series - See AccumulationRegister.GoodsToReceive.Series
//	* Count - Number - accepted quantity.
//
Function Accepted(ActOfFoundation, Warehouse) Export
	
	SetPrivilegedMode(True);
	ControlledLotReference = Common.ObjectAttributeValue(ActOfFoundation, "ControlledLotReference");
	ReferenceOrder = Common.ObjectAttributeValue(ControlledLotReference, "Lot");
	SetPrivilegedMode(False);
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager;
	AllActions = New Array();
	For Each ActionOnGoods In Enums.ActionsOnGoodsInQualityControlCertificate Do
		AllActions.Add(ActionOnGoods);
	EndDo;
	// For surpluses in an out-of-order warehouse, we leave the action empty,
	// issue certificates of discrepancies, correct the primary documents, then put the final action in the quality control act.
	AllActions.Add(Enums.ActionsOnGoodsInQualityControlCertificate.EmptyRef());
	
	GoodsToCreateBasedOn(
		Query,
		ActOfFoundation,
		Warehouse,
		AllActions);
		
	Query.SetParameter("ReferenceOrder", ReferenceOrder);
	Query.Text =
		"SELECT
		|	&ReferenceOrder AS ReferenceOrder,
		|	&ReferenceOrder AS DocumentBasis,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Series AS Series,
		|	SUM(Goods.Count) AS Count
		|FROM
		|	Goods AS Goods
		|WHERE
		|	NOT Goods.Action IN(
		|		VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.ToReturnToVendor),
		|		VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.DoNotReceiveGoods),
		|		VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.ChangeQuality))
		|GROUP BY
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Purpose,
		|	Goods.Warehouse,
		|	Goods.Series
		|
		|UNION ALL
		|
		|SELECT
		|	&ReferenceOrder AS ReferenceOrder,
		|	&ReferenceOrder AS DocumentBasis,
		|	Goods.ProductsRecordingAsReceived AS Products,
		|	Goods.CharacteristicRecordingAsReceived AS Characteristic,
		|	CASE
		|		WHEN Goods.ForAssignment
		|			THEN Goods.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Series AS Series,
		|	SUM(Goods.Count) AS Count
		|FROM
		|	Goods AS Goods
		|WHERE
		|	Goods.Action = VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.ChangeQuality)
		|GROUP BY
		|	Goods.ProductsRecordingAsReceived,
		|	Goods.CharacteristicRecordingAsReceived,
		|	CASE
		|		WHEN Goods.ForAssignment
		|			THEN Goods.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END,
		|	Goods.Warehouse,
		|	Goods.Series";
	
	FactData = Query.Execute().Unload();
	Return FactData;
	
EndFunction

// Used to obtain document data, to fill out documents based on.
// Groups document data to get rid of product place packages.
// 
// Parameters:
//  Query - Query - A request to add the Items table with the received data to the temp tables manager.
//  Basis - DocumentRef.GoodsQualityControlCertificate - the act of quality control, the data of which must be obtained.
//  Warehouse - CatalogRef.Warehouses,
//          Array From The Reference Link.Warehouses - receive items only from specified warehouses.
//  Action - EnumRef.ActionsOnGoodsInQualityControlCertificate,
//             Array Of the Link enumeration.Actionsparamvaktecontrol of quality - to receive goods only of the specified actions.
Procedure GoodsToCreateBasedOn(Query, Basis, Warehouse, Action) Export
	
	Query.SetParameter("DocumentBasis", Basis);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Action", Action);
	Query.SetParameter("DocumentDate", BegOfDay(CurrentSessionDate()));
	
	Query.Text =
		"SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
		|	Goods.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
		|	Goods.Purpose AS Purpose,
		|	Goods.ForAssignment AS ForAssignment,
		|	Goods.PackagingReceipt AS PackagingReceipt,
		|	Goods.Series AS Series,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Premise AS Premise,
		|	Goods.Package AS Package,
		|	Goods.Action AS Action,
		|	Goods.Count AS Count,
		|	Goods.NumberOfPackages AS NumberOfPackages
		|INTO GoodsAndProductLocations
		|FROM
		|	Document.GoodsQualityControlCertificate.Goods AS Goods
		|WHERE
		|	Goods.Ref = &DocumentBasis
		|	AND Goods.Warehouse IN(&Warehouse)
		|	AND Goods.Action IN(&Action)
		|;
		|
		|////////////////////////////////////////////////
		|SELECT
		|	Set.Products AS Products,
		|	Set.Characteristic AS Characteristic,
		|	Set.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
		|	Set.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
		|	Set.ForAssignment AS ForAssignment,
		|	Set.PackagingReceipt AS PackagingReceipt,
		|	Set.Purpose AS Purpose,
		|	Set.Warehouse AS Warehouse,
		|	Set.Series AS Series,
		|	Set.Package AS Package,
		|	Set.Action AS Action,
		|	MAX(Set.BatchesIndicationStatus) AS BatchesIndicationStatus,
		|	SUM(Set.Count) AS Count,
		|	SUM(Set.NumberOfPackages) AS NumberOfPackages
		|INTO Goods
		|FROM(
		|	SELECT
		|		Goods.Products AS Products,
		|		Goods.Characteristic AS Characteristic,
		|		Goods.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
		|		Goods.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
		|		Goods.ForAssignment AS ForAssignment,
		|		Goods.PackagingReceipt AS PackagingReceipt,
		|		Goods.Purpose AS Purpose,
		|		Goods.Warehouse AS Warehouse,
		|		Goods.Series AS Series,
		|		Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|		Goods.Package AS Package,
		|		Goods.Action AS Action,
		|		Goods.Count AS Count,
		|		Goods.NumberOfPackages AS NumberOfPackages
		|	FROM
		|		GoodsAndProductLocations AS Goods
		|	WHERE
		|		ISNULL(CAST(Goods.Package AS Catalog.PackagesAndUnitsOfMeasure).PackageType,
		|			UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Components.Products AS Products,
		|		Components.Characteristic AS Characteristic,
		|		Components.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
		|		Components.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
		|		Components.ForAssignment AS ForAssignment,
		|		Components.PackagingReceipt AS PackagingReceipt,
		|		Components.Purpose AS Purpose,
		|		Components.Warehouse AS Warehouse,
		|		Components.Series AS Series,
		|		Components.BatchesIndicationStatus AS BatchesIndicationStatus,
		|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
		|		Components.Action AS Action,
		|		MIN(Components.Count) AS Count,
		|		MIN(Components.Count) AS NumberOfPackages
		|	FROM(
		|		SELECT
		|			Goods.Products AS Products,
		|			Goods.Characteristic AS Characteristic,
		|			Goods.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
		|			Goods.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
		|			Goods.Purpose AS Purpose,
		|			Goods.ForAssignment AS ForAssignment,
		|			Goods.PackagingReceipt AS PackagingReceipt,
		|			Goods.Series AS Series,
		|			Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|			Goods.Warehouse AS Warehouse,
		|			Goods.Premise AS Premise,
		|			Goods.Package AS Package,
		|			Goods.Action AS Action,
		|			SUM(Goods.Count) AS Count
		|		FROM
		|			GoodsAndProductLocations AS Goods
		|		WHERE
		|			CAST(Goods.Package AS Catalog.PackagesAndUnitsOfMeasure).PackageType
		|				= VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|		GROUP BY
		|			Goods.Products,
		|			Goods.Characteristic,
		|			Goods.ProductsRecordingAsReceived,
		|			Goods.CharacteristicRecordingAsReceived,
		|			Goods.Purpose,
		|			Goods.ForAssignment,
		|			Goods.PackagingReceipt,
		|			Goods.Series,
		|			Goods.BatchesIndicationStatus,
		|			Goods.Warehouse,
		|			Goods.Premise,
		|			Goods.Package,
		|			Goods.Action) AS Components
		|	GROUP BY
		|		Components.Products,
		|		Components.Characteristic,
		|		Components.ProductsRecordingAsReceived,
		|		Components.CharacteristicRecordingAsReceived,
		|		Components.Purpose,
		|		Components.ForAssignment,
		|		Components.PackagingReceipt,
		|		Components.Series,
		|		Components.BatchesIndicationStatus,
		|		Components.Warehouse,
		|		Components.Premise,
		|		Components.Action) AS Set
		|GROUP BY
		|	Set.Products,
		|	Set.Characteristic,
		|	Set.ProductsRecordingAsReceived,
		|	Set.CharacteristicRecordingAsReceived,
		|	Set.ForAssignment,
		|	Set.PackagingReceipt,
		|	Set.Purpose,
		|	Set.Warehouse,
		|	Set.Series,
		|	Set.Package,
		|	Set.Action";
		
	Query.Execute();
	
EndProcedure

// Returns the Organization based on the controlled Lot reference document.
// Parameters:
//  Object - DocumentObject.GoodsQualityControlCertificate - Document
// Returns:
//  CatalogRef.Companies - Organization.
Function CompanyFromControlledLotReference(Object) Export
	
	Organization = Catalogs.Companies.EmptyRef();
	SetPrivilegedMode(True);
	If ValueIsFilled(Object.ControlledLotReference) Then
		Organization = Common.ObjectAttributeValue(Object.ControlledLotReference, "Organization");
	EndIf;
	Return Organization;
	
EndFunction

// Adds a command to create a document "Product quality control Act".
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// Returns:
//  Undefined -
//  String of Value tables -
Function AddGenerateCommand(GenerationCommands) Export

	If AccessRight("Insert", Metadata.Documents.GoodsQualityControlCertificate) Then
		CreateBasedOnCommand = GenerateFrom.AddGenerationCommand(
				GenerationCommands, Metadata.Documents.GoodsQualityControlCertificate);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseGoodsQualityControl";
		Return CreateBasedOnCommand;
	EndIf;
	Return Undefined;

EndFunction

#EndRegion

#EndRegion

#Region Internal

#Region StandardSubsystems

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

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
	
	Return;
	
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction
// Parameters:
//  Restriction - See AccessManagementOverridable.OnFillListsWithAccessRestriction.Lists
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND (ValueAllowed(Department) OR ValueAllowed(LotBusinessUnit))
	|	AND ValueAllowed(LotPartner, EmptyRef AS TRUE)
	|	AND ValueAllowed(LotBusinessTransaction, EmptyRef AS TRUE)
	|	AND ValueAllowed(Warehouse, EmptyRef AS TRUE)";

EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Return;
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	// A set of documents for the printer
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "GoodsQualityControlCertificate";
	PrintCommand.Presentation = NStr("vi = 'Biên bản kiểm soát chất lượng hàng hóa';
									|ru = 'Акт контроля качества товаров';
									|en = 'Goods quality control certificate'; fa = 'گواهی کنترل کیفیت کالا';
									|it = 'Goods quality control certificate';
									|pl = 'Goods quality control certificate';
									|tr = 'Ürün kalite kontrol tutanağı'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.Order = 1;
	
EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "GoodsQualityControlCertificate") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"GoodsQualityControlCertificate",
			NStr("vi = 'Biên bản kiểm soát chất lượng hàng hóa';
				|ru = 'Акт контроля качества товаров';
				|en = 'Goods quality control certificate'; fa = 'گواهی کنترل کیفیت کالا';
				|it = 'Goods quality control certificate';
				|pl = 'Goods quality control certificate';
				|tr = 'Ürün kalite kontrol tutanağı'"),
			ToFormPrintedFormOfActOfQualityControlOfGoods(ObjectsArray, PrintObjects, PrintParameters),
			,
			"Document.GoodsQualityControlCertificate.PF_MXL_GoodsQualityControlCertificate");
	EndIf;
	
EndProcedure

// Defines a list of creation commands based on.
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export

	Documents.InventoryTransfer.AddCreateBasedOnWarehouseGroupCommand(GenerationCommands);
	Documents.WriteOffOfGoodsShortages.AddCreateBasedOnWarehouseGroupCommand(GenerationCommands);
	Documents.GoodsDamage.AddCreateBasedOnWarehouseGroupCommand(GenerationCommands);


	
	Command = Documents.DiscrepancyReportFollowingTransfer.AddGenerateCommand(GenerationCommands);
	
	If Command <> Undefined Then
		
		TransactionList = New ValueList();
		TransactionList.Add(Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices);
		TransactionList.Add(Enums.BusinessTransactions.InventoryTransfer);
		
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"LotBusinessTransaction",
			TransactionList,
			DataCompositionComparisonType.InList);
			
	EndIf;
	
	Command = Documents.ReturnOfGoodsToVendor.AddCreateBasedOnWarehouseGroupCommand(GenerationCommands);
	
	If Command <> Undefined Then
		
		TransactionList = New ValueList();
		TransactionList.Add(Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale);
		TransactionList.Add(Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5);
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"LotBusinessTransaction",
			TransactionList,
			DataCompositionComparisonType.NotInList);
			
	EndIf;
	
	Command = Documents.GoodsShipmentFromStorage.AddCreateBasedOnWarehouseGroupCommand(GenerationCommands);
	
	If Command <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"LotBusinessTransaction",
			Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale,
			DataCompositionComparisonType.Equal);
		
	EndIf;
	
	Command = Documents.GoodsShipmentFromStorage.AddCreateBasedOnWarehouseGroupCommand(GenerationCommands);
	
	If Command <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"LotBusinessTransaction",
			Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5,
			DataCompositionComparisonType.Equal);
		
		Command.Presentation = NStr("vi = 'Trả lại cho bên đặt gia công';
									|ru = 'Возврат давальцу';
									|en = 'Goods return — Subcontracting services delivered'; fa = 'برگشت کالا — خدمات پیمانکاری فرعی ارائه‌شده';
									|it = 'Restituzione del fornitore di materiali';
									|pl = 'Zwrot właścicielowi surowców';
									|tr = 'Tedarikçiye iade'");
		
	EndIf;
	
	Command = Documents.DiscrepancyReportFollowingReceipt.AddGenerateCommand(GenerationCommands);
	
	If Command <> Undefined Then
		
		Command.FunctionalOptions = "UseNonConformanceCertificatesFollowingAcceptance";
		
		TransactionList = New ValueList();
		TransactionList.Add(Enums.BusinessTransactions.ReturnOfGoodsFromCustomer);
		TransactionList.Add(Enums.BusinessTransactions.ReceiptFromToller2_5);
		TransactionList.Add(Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5);
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"LotBusinessTransaction",
			TransactionList,
			DataCompositionComparisonType.NotInList);
			
	EndIf;
	
	Command = Documents.DiscrepancyReportFollowingReceipt.AddGenerateCommand(GenerationCommands);
	
	If Command <> Undefined Then
		
		Command.FunctionalOptions = "UseNonConformanceCertificatesFollowingAcceptance";
		Command.Presentation = NStr("vi = 'Biên bản chênh lệch sau khi nhận trả lại từ khách';
									|ru = 'Акт о расхождениях после возврата от клиента';
									|en = 'Discrepancy report following return from customer'; fa = 'Discrepancy report following return from customer';
									|it = 'Atto sulle discrepanze dopo il reso dal cliente';
									|pl = 'Protokół o odchyleniu po zwrocie od klienta';
									|tr = 'Müşteriden iade sonrası tutarsızlık raporu'");
		
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"LotBusinessTransaction",
			Enums.BusinessTransactions.ReturnOfGoodsFromCustomer,
			DataCompositionComparisonType.Equal);
			
	EndIf;
	Command = Documents.DiscrepancyReportFollowingReceipt.AddGenerateCommand(GenerationCommands);
	
	If Command <> Undefined Then
		
		Command.FunctionalOptions = "UseDiscrepancyReportFollowingReceiptFromSubcontractor2_5";
		
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"LotBusinessTransaction",
			Enums.BusinessTransactions.ReceiptFromToller2_5,
			DataCompositionComparisonType.Equal);
			
	EndIf;
	Command = Documents.DiscrepancyReportFollowingReceipt.AddGenerateCommand(GenerationCommands);
	
	If Command <> Undefined Then
		
		Command.FunctionalOptions = "UseCertificatesOfDiscrepanciesAfterAcceptanceForAcceptanceOfGiverSGoods2_5";
		Command.Presentation = NStr("vi = 'Biên bản chênh lệch sau khi nhận';
									|ru = 'Акт о расхождениях после поступления';
									|en = 'Discrepancy report'; fa = 'گزارش مغایرت';
									|it = 'Atti sulle discrepanze dopo l''arrivo';
									|pl = 'Protokół o odchyleniu po wpływie';
									|tr = 'Teslim alım sonrası tutarsızlık raporu'");
		
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"LotBusinessTransaction",
			Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5,
			DataCompositionComparisonType.Equal);
			
	EndIf;
EndProcedure

#EndRegion

#Region EmbeddedMechanisms

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Date";
	Return AttributesNames;
	
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//  Object	 - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.GoodsQualityControlCertificate";
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.EmptyRef());
	SeriesSpecificationParameters.UseCostAccountingByBatches = GetFunctionalOption("UseCostAccountingByBatchesWarehouse");
	SeriesSpecificationParameters.UseItemsBatch  = GetFunctionalOption("UseItemsBatchWarehouse");
	SeriesSpecificationParameters.AdditionalFieldNames.Add("Warehouse");
	SeriesSpecificationParameters.AdditionalFieldNames.Add("Premise");
	SeriesSpecificationParameters.AdditionalFieldNames.Add("Purpose");
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.FieldNameControlledLotReference = "ControlledLotReference";
	SeriesSpecificationParameters.Date = Object.Date;
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText =
	"SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Warehouse AS Warehouse,
	|	Goods.Products AS Products,
	|	Goods.Series AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Warehouse AS Warehouse,
	|	Goods.Products AS Products,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind,
	|	Goods.Series AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|INDEX BY
	|	Warehouse, ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		ELSE
	|			CASE
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|					THEN CASE
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|								THEN CASE
	|										WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|											THEN 13
	|										ELSE 14
	|									END
	|							ELSE CASE
	|									WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|										THEN 9
	|									ELSE 10
	|								END
	|						END
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|					THEN CASE
	|							WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 7
	|							ELSE 8
	|						END
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult
	|						AND BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|					THEN CASE
	|							WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 3
	|							ELSE 4
	|						END
	|				ELSE 0
	|			END
	|	END AS BatchesIndicationStatus
	|INTO StatusTable
	|FROM
	|	ProductsToRequest AS Goods
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|			INNER JOIN Catalog.Warehouses AS Warehouses
	|			ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|		ON Goods.ProductKind = BatchAccountingPolicies.Ref
	|			AND BatchAccountingPolicies.Warehouse = Goods.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StatusTable.LineNumber AS LineNumber,
	|	StatusTable.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	StatusTable AS StatusTable
	|WHERE
	|	StatusTable.OldStatusOfSpecifyingSeries <> StatusTable.BatchesIndicationStatus
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;

EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	
	// Remnants of goods in the warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(
		FormTemplate,
		"OrderFulfillment",
		True, "Object.Goods.Purpose");
	
	DescriptionOfColumns.Columns.FindByValue("InStock").Check = True;
	DescriptionOfColumns.DefaultColumns.Add("InStock");
	
	DescriptionOfColumns.DataPaths.Products = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse = "Object.Warehouse";
	DescriptionOfColumns.DataPaths.ControlledLotReference = "Object.ControlledLotReference";
	
	Return FormTemplate;
	
EndFunction

// Generates a verification request when changing the status of the list of documents
//
// Parameters:
//	DocumentsArray - Array of DocumentRef.GoodsQualityControlCertificate - Array of links to documents to check.
//	NewStatus - String - Name of the new status.
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.StatusesOfQualityControlCertificates[NewStatus];
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref AS Ref,
	|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
	|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
	|	PRESENTATION(&Status) AS PresentationOfNewStatus,
	|	CASE
	|		WHEN DocumentsTable.Status = &Status
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS StatusMatches,
	|	DocumentsTable.Posted AS Posted,
	|	DocumentsTable.DeletionMark AS DeletionMark,
	|	TRUE AS Recording
	|FROM
	|	Document.GoodsQualityControlCertificate AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN (&DocumentsArray)
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes
//
// Parameters:
//	ValidationSample         - QueryResultSelection - Current selection string
//	NewStatus             - EnumRef.StatusesOfDiscrepancyReport - New status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Return True;
	
EndFunction

#EndRegion

#Region OtherItems

// Caches the Attributes of the controlled batch in the document.
// Parameters:
// Object - DocumentObject.GoodsQualityControlCertificate - Document
Procedure FillInDetailsFromParty(Object) Export
	
	SetPrivilegedMode(True);
	PartyDetails = Common.ObjectAttributesValues(
		Object.ControlledLotReference,
		"BusinessOperation,Partner,Department");
	Object.LotBusinessTransaction = PartyDetails.BusinessOperation;
	Object.LotPartner = PartyDetails.Partner;
	Object.LotBusinessUnit = PartyDetails.Department;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region Posting

Function FullObjectName()
	
	Return "Document.GoodsQualityControlCertificate";
	
EndFunction

Procedure GetDocumentData(Query, DocumentRef)
	
	ListOfRequests = New Array();
	
	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDocumentDataTableItems(ListOfRequests);
	QueryTextDocumentDataGoodsTableCollapseProductLocations(ListOfRequests);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("Ref", DocumentRef);
	Query.Execute();
	
EndProcedure

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.Text =
		"SELECT
		|	DocumentData.Number AS Number
		|FROM
		|	DocumentDataHeader AS DocumentData";
	
	Attributes = Query.Execute().Select();
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID(FullObjectName()));
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Return;
	
EndProcedure

Procedure QueryTextDocumentDataHeader(ListOfRequests)
	
	QueryText =
		"SELECT
		|	HeaderData_.DataVersion AS DataVersion,
		|	HeaderData_.Date AS Date,
		|	HeaderData_.PointInTime AS PointInTime,
		|	HeaderData_.Number AS Number,
		|	HeaderData_.DeletionMark AS DeletionMark,
		|	HeaderData_.Posted AS Posted,
		|	HeaderData_.Ref AS Ref,
		|	HeaderData_.Status AS Status,
		|	HeaderData_.Department AS Department,
		|	HeaderData_.EmployeeResponsible AS EmployeeResponsible,
		|	HeaderData_.Author AS Author,
		|	HeaderData_.Warehouse AS Warehouse,
		|	HeaderData_.Organization AS Organization,
		|	HeaderData_.Comment AS Comment,
		|	HeaderData_.ControlledLotReference AS ControlledLotReference,
		|	HeaderData_.ControlledLotReference.Sender AS ControlledLotOfTheSender,
		|	HeaderData_.ControlledLotReference.BusinessOperation AS ControlledLotReferenceBusinessTransaction,
		|	HeaderData_.ControlledLotReference.Lot AS ControlledLotReferenceLotReference,
		|	HeaderData_.ControlledLotReference.Counterparty AS ControlledLotReferenceCounterparty,
		|	HeaderData_.ControlledLotReference.Partner AS ControlledLotReferencePartner,
		|	HeaderData_.ControlledLotReference.Contract AS ControlledLotReferenceContract,
		|	HeaderData_.ControlledLotReference.LineOfBusiness AS ControlledLotReferenceLineOfBusiness
		|INTO DocumentDataHeader
		|FROM
		|	Document.GoodsQualityControlCertificate AS HeaderData_
		|WHERE
		|	HeaderData_.Ref = &Ref
		|INDEX BY
		|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDocumentDataTableItems(ListOfRequests)
	
	QueryText =
		"SELECT
		|	Goods.LineNumber AS LineNumber,
		|	Goods.Ref AS Ref,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
		|	Goods.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
		|	Goods.Purpose AS Purpose,
		|	Goods.ForAssignment AS ForAssignment,
		|	Goods.Series AS Series,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Premise AS Premise,
		|	Goods.Action AS Action,
		|	Goods.Package AS Package,
		|	Goods.Cell AS Cell,
		|	Goods.Count AS Count,
		|	Goods.NumberOfPackages AS NumberOfPackages,
		|	Goods.QualityCheckResult AS QualityCheckResult,
		|	Goods.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages AS WarehouseUseOrderSchemeWhenReflectingSurplusShortages,
		|	Goods.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages AS WarehouseStartDateOfOrderSchemeWhenSurplusShortagesAreReflected,
		|	Goods.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt AS WarehouseUseOrderSchemeWhenReceiving,
		|	Goods.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt AS WarehouseStartDateOfOrderSchemeUponReceipt,
		|	Goods.Warehouse.UseWarehouseManagemantSystemForGoodsIssue AS WarehouseUseOrderSchemeWhenShipping,
		|	Goods.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue AS WarehouseStartDateOfOrderSchemeDuringShipment
		|INTO DocumentDataTableItems
		|FROM
		|	Document.GoodsQualityControlCertificate.Goods AS Goods
		|WHERE
		|	Goods.Ref = &Ref
		|INDEX BY
		|	Ref,Action";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDocumentDataGoodsTableCollapseProductLocations(ListOfRequests)
	
	QueryText =
		"SELECT
		|	Goods.Ref AS Ref,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
		|	Goods.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
		|	Goods.Purpose AS Purpose,
		|	Goods.ForAssignment AS ForAssignment,
		|	Goods.Series AS Series,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Premise AS Premise,
		|	Goods.Action AS Action,
		|	Goods.WarehouseUseOrderSchemeWhenReflectingSurplusShortages AS WarehouseUseOrderSchemeWhenReflectingSurplusShortages,
		|	Goods.WarehouseStartDateOfOrderSchemeWhenSurplusShortagesAreReflected AS WarehouseStartDateOfOrderSchemeWhenSurplusShortagesAreReflected,
		|	Goods.WarehouseUseOrderSchemeWhenReceiving AS WarehouseUseOrderSchemeWhenReceiving,
		|	Goods.WarehouseStartDateOfOrderSchemeUponReceipt AS WarehouseStartDateOfOrderSchemeUponReceipt,
		|	Goods.WarehouseUseOrderSchemeWhenShipping AS WarehouseUseOrderSchemeWhenShipping,
		|	Goods.WarehouseStartDateOfOrderSchemeDuringShipment AS WarehouseStartDateOfOrderSchemeDuringShipment,
		|	Goods.Count AS Count
		|INTO DocumentDataGoodsTableCollapseProductLocations
		|FROM
		|	DocumentDataTableItems AS Goods
		|WHERE
		|	ISNULL(CAST(Goods.Package AS Catalog.PackagesAndUnitsOfMeasure).PackageType,
		|		UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|
		|UNION ALL
		|
		|SELECT
		|	Components.Ref AS Ref,
		|	Components.Products AS Products,
		|	Components.Characteristic AS Characteristic,
		|	Components.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
		|	Components.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
		|	Components.Purpose AS Purpose,
		|	Components.ForAssignment AS ForAssignment,
		|	Components.Series AS Series,
		|	Components.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	Components.Warehouse AS Warehouse,
		|	Components.Premise AS Premise,
		|	Components.Action AS Action,
		|	Components.WarehouseUseOrderSchemeWhenReflectingSurplusShortages AS WarehouseUseOrderSchemeWhenReflectingSurplusShortages,
		|	Components.WarehouseStartDateOfOrderSchemeWhenSurplusShortagesAreReflected AS WarehouseStartDateOfOrderSchemeWhenSurplusShortagesAreReflected,
		|	Components.WarehouseUseOrderSchemeWhenReceiving AS WarehouseUseOrderSchemeWhenReceiving,
		|	Components.WarehouseStartDateOfOrderSchemeUponReceipt AS WarehouseStartDateOfOrderSchemeUponReceipt,
		|	Components.WarehouseUseOrderSchemeWhenShipping AS WarehouseUseOrderSchemeWhenShipping,
		|	Components.WarehouseStartDateOfOrderSchemeDuringShipment AS WarehouseStartDateOfOrderSchemeDuringShipment,
		|	MIN(Components.Count) AS Count
		|FROM(
		|	SELECT
		|		Goods.Ref AS Ref,
		|		Goods.Products AS Products,
		|		Goods.Characteristic AS Characteristic,
		|		Goods.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
		|		Goods.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
		|		Goods.Purpose AS Purpose,
		|		Goods.ForAssignment AS ForAssignment,
		|		Goods.Series AS Series,
		|		Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|		Goods.Warehouse AS Warehouse,
		|		Goods.Premise AS Premise,
		|		Goods.Package AS Package,
		|		Goods.Action AS Action,
		|		Goods.WarehouseUseOrderSchemeWhenReflectingSurplusShortages AS WarehouseUseOrderSchemeWhenReflectingSurplusShortages,
		|		Goods.WarehouseStartDateOfOrderSchemeWhenSurplusShortagesAreReflected AS WarehouseStartDateOfOrderSchemeWhenSurplusShortagesAreReflected,
		|		Goods.WarehouseUseOrderSchemeWhenReceiving AS WarehouseUseOrderSchemeWhenReceiving,
		|		Goods.WarehouseStartDateOfOrderSchemeUponReceipt AS WarehouseStartDateOfOrderSchemeUponReceipt,
		|		Goods.WarehouseUseOrderSchemeWhenShipping AS WarehouseUseOrderSchemeWhenShipping,
		|		Goods.WarehouseStartDateOfOrderSchemeDuringShipment AS WarehouseStartDateOfOrderSchemeDuringShipment,
		|		SUM(Goods.Count) AS Count
		|FROM
		|	DocumentDataTableItems AS Goods
		|WHERE
		|	CAST(Goods.Package AS Catalog.PackagesAndUnitsOfMeasure).PackageType
		|		= VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|	GROUP BY
		|		Goods.Ref,
		|		Goods.Products,
		|		Goods.Characteristic,
		|		Goods.ProductsRecordingAsReceived,
		|		Goods.CharacteristicRecordingAsReceived,
		|		Goods.Purpose,
		|		Goods.ForAssignment,
		|		Goods.Series,
		|		Goods.BatchesIndicationStatus,
		|		Goods.Warehouse,
		|		Goods.Premise,
		|		Goods.Package,
		|		Goods.Action,
		|		Goods.WarehouseUseOrderSchemeWhenReflectingSurplusShortages,
		|		Goods.WarehouseStartDateOfOrderSchemeWhenSurplusShortagesAreReflected,
		|		Goods.WarehouseUseOrderSchemeWhenReceiving,
		|		Goods.WarehouseStartDateOfOrderSchemeUponReceipt,
		|		Goods.WarehouseUseOrderSchemeWhenShipping,
		|		Goods.WarehouseStartDateOfOrderSchemeDuringShipment) AS Components
		|	GROUP BY
		|		Components.Ref,
		|		Components.Products,
		|		Components.Characteristic,
		|		Components.ProductsRecordingAsReceived,
		|		Components.CharacteristicRecordingAsReceived,
		|		Components.Purpose,
		|		Components.ForAssignment,
		|		Components.Series,
		|		Components.BatchesIndicationStatus,
		|		Components.Warehouse,
		|		Components.Premise,
		|		Components.Action,
		|		Components.WarehouseUseOrderSchemeWhenReflectingSurplusShortages,
		|		Components.WarehouseStartDateOfOrderSchemeWhenSurplusShortagesAreReflected,
		|		Components.WarehouseUseOrderSchemeWhenReceiving,
		|		Components.WarehouseStartDateOfOrderSchemeUponReceipt,
		|		Components.WarehouseUseOrderSchemeWhenShipping,
		|		Components.WarehouseStartDateOfOrderSchemeDuringShipment
		|INDEX BY
		|	Ref,Action";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers, BatchMode = False)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
		"SELECT
		|	DocumentData.Ref AS Ref,
		|	DocumentData.Date AS IBDocumentDate,
		|	DocumentData.Number AS IBDocumentNumber,
		|	&MetadataIdentifier AS RefType,
		|	DocumentData.Organization AS Organization,
		|	VALUE(Enum.BusinessTransactions.GoodsQualityControl) AS BusinessOperation,
		|	DocumentData.ControlledLotReferenceCounterparty AS Counterparty,
		|	DocumentData.ControlledLotReferencePartner AS Partner,
		|	DocumentData.ControlledLotReferenceContract AS Contract,
		|	DocumentData.ControlledLotReferenceLineOfBusiness AS LineOfBusiness,
		|	DocumentData.Warehouse AS StorageLocation,
		|	DocumentData.Department AS Department,
		|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
		|	DocumentData.Author AS Author,
		|	DocumentData.Comment AS Comment,
		|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
		|	0 AS Sum,
		|	DocumentData.Status AS Status,
		|	DocumentData.Posted AS Posted,
		|	DocumentData.DeletionMark AS DeletionMark,
		|	FALSE AS AdditionalRecord,
		|	"""" AS More,
		|	DocumentData.Date AS SourceDocumentDate,
		|	"""" AS SourceDocumentName,
		|	&NumberForPrinting AS SourceDocumentNumber,
		|	DocumentData.Date AS RecordingInAccountingDate,
		|	UNDEFINED AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData";
		
	If BatchMode Then
		
		QueryText = StrReplace(QueryText, "&NumberForPrinting", "DocumentData.Number");
		QueryText = StrReplace(QueryText, "DocumentData.Comment", "CAST(DocumentData.Comment AS STRING (100))");
		QueryText = StrReplace(QueryText, "ControlledLotReferenceCounterparty", "ControlledLotReference.Counterparty");
		QueryText = StrReplace(QueryText, "ControlledLotReferencePartner", "ControlledLotReference.Partner");
		QueryText = StrReplace(QueryText, "ControlledLotReferenceContract", "ControlledLotReference.Contract");
		QueryText = StrReplace(QueryText, "ControlledLotReferenceLineOfBusiness", "ControlledLotReference.LineOfBusiness");
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.GoodsQualityControlCertificate");
		Return QueryText;
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction
Function QueryTextTableOfQualityControlRequests(Query, QueryTexts, Registers)
	
	RegisterName = "RequestStatesForQualityControl";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
		"SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.ControlledLotReferenceLotReference AS Lot,
		|	DocumentData.ControlledLotReference AS ControlledLotReference
		|FROM
		|	DocumentDataHeader AS DocumentData";
		
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction
Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	// The Registered Record (A-): Remove the lock on the warehouse and in the supply of the item.
	// The Registered Record (B-) Cancels the incoming order in part of the Balance.
	QueryTextTabPart =
		"SELECT
		|	Goods.Ref AS Ref,
		|	Header.Date AS Period,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Purpose AS Purpose,
		|	Header.ControlledLotReference AS ControlledLotReference,
		|	Goods.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	TRUE AS ControlOfFreeResidue
		|FROM
		|	DocumentDataHeader AS Header
		|		INNER JOIN DocumentDataGoodsTableCollapseProductLocations AS Goods
		|		ON Header.Ref = Goods.Ref
		|WHERE
		|	Header.Status IN(
		|			VALUE(Enum.StatusesOfQualityControlCertificates.AwaitingDecision),
		|			VALUE(Enum.StatusesOfQualityControlCertificates.IsProcessed))
		|	AND (Goods.Action IN(
		|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.Unlock),
		|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.RegisterReturn),
		|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.RegisterGoodsTransfer))
		|		OR Goods.WarehouseUseOrderSchemeWhenReceiving
		|			AND Header.Date >= Goods.WarehouseStartDateOfOrderSchemeUponReceipt
		|			AND Goods.Action IN(
		|				VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.DoNotReceiveGoods),
		|				VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.ToReturnToVendor),
		|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.ChangeQuality)))";
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, True);
	
	// MOVEMENT (A +): Remove the lock on the warehouse and in the provision of the goods.
	QueryTextTabPart =
		"SELECT
		|	Goods.Ref AS Ref,
		|	Header.Date AS Period,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	Goods.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	DocumentDataHeader AS Header
		|		INNER JOIN DocumentDataGoodsTableCollapseProductLocations AS Goods
		|		ON Header.Ref = Goods.Ref
		|WHERE
		|	Header.Status IN(
		|			VALUE(Enum.StatusesOfQualityControlCertificates.AwaitingDecision),
		|			VALUE(Enum.StatusesOfQualityControlCertificates.IsProcessed))
		|	AND Goods.Action IN(
		|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.Unlock),
		|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.RegisterReturn),
		|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.RegisterGoodsTransfer))";
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
	// MOVEMENT (B-): Reflection of shortage in the warehouse.
	QueryTextTabPart =
		"SELECT
		|	Goods.Ref AS Ref,
		|	Header.Date AS Period,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Purpose AS Purpose,
		|	Header.ControlledLotReference AS ControlledLotReference,
		|	Goods.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	TRUE AS ControlOfFreeResidue
		|FROM
		|	DocumentDataHeader AS Header
		|		INNER JOIN DocumentDataGoodsTableCollapseProductLocations AS Goods
		|		ON Header.Ref = Goods.Ref
		|WHERE
		|	Header.Status IN(
		|			VALUE(Enum.StatusesOfQualityControlCertificates.AwaitingDecision),
		|			VALUE(Enum.StatusesOfQualityControlCertificates.IsProcessed))
		|	AND Goods.WarehouseUseOrderSchemeWhenReflectingSurplusShortages
		|	AND Header.Date >= Goods.WarehouseStartDateOfOrderSchemeWhenSurplusShortagesAreReflected
		|	AND Goods.Action IN(
		|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.MakeDebit),
		|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.RegisterStockQualityChange))";
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, True);
	
	// THE Registered Records (B+): Reflection of the surplus in the warehouse.
	QueryTextTabPart =
		"SELECT
		|	Goods.Ref AS Ref,
		|	Header.Date AS Period,
		|	Goods.ProductsRecordingAsReceived AS Products,
		|	Goods.CharacteristicRecordingAsReceived AS Characteristic,
		|	Goods.Warehouse AS Warehouse,
		|	CASE
		|		WHEN Goods.ForAssignment
		|			THEN Goods.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	Goods.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	DocumentDataHeader AS Header
		|		INNER JOIN DocumentDataGoodsTableCollapseProductLocations AS Goods
		|		ON Header.Ref = Goods.Ref
		|WHERE
		|	Header.Status IN(
		|			VALUE(Enum.StatusesOfQualityControlCertificates.AwaitingDecision),
		|			VALUE(Enum.StatusesOfQualityControlCertificates.IsProcessed))
		|		AND Goods.WarehouseUseOrderSchemeWhenReflectingSurplusShortages
		|		AND Header.Date >= Goods.WarehouseStartDateOfOrderSchemeWhenSurplusShortagesAreReflected
		|		AND Goods.Action = VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.RegisterStockQualityChange)";
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
	QueryTextTabPart =
	// MOVEMENT (B-) Cancellation of the receipt order, in terms of cancellation of the acceptance order.
		"SELECT
		|	Goods.Ref AS Ref,
		|	Header.Date AS Period,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Purpose AS Purpose,
		|	TRUE AS ToControlQuality,
		|	TRUE AS SubjectToUnlocking,
		|	Goods.Count AS Count,
		|	Header.ControlledLotReferenceLotReference AS OrderInSchedule
		|FROM
		|	DocumentDataHeader AS Header
		|		INNER JOIN DocumentDataGoodsTableCollapseProductLocations AS Goods
		|		ON Header.Ref = Goods.Ref
		|WHERE
		|	Header.Status IN(
		|			VALUE(Enum.StatusesOfQualityControlCertificates.AwaitingDecision),
		|			VALUE(Enum.StatusesOfQualityControlCertificates.IsProcessed))
		|		AND Goods.WarehouseUseOrderSchemeWhenReceiving
		|		AND Header.Date >= Goods.WarehouseStartDateOfOrderSchemeUponReceipt
		|		AND Goods.Action IN(
		|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.DoNotReceiveGoods),
		|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.ToReturnToVendor),
		|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.ChangeQuality))";
	
	StockAllocationRecords.CancelScheduledStockArrival(Query, QueryTexts, Registers, QueryTextTabPart);
		
	QueryTextTabPart =
		// The Registered Record (B+) is the entry of an incoming order.
		"SELECT
		|	Goods.Ref AS Ref,
		|	Header.Date AS Period,
		|	Goods.ProductsRecordingAsReceived AS Products,
		|	Goods.CharacteristicRecordingAsReceived AS Characteristic,
		|	Goods.Warehouse AS Warehouse,
		|	CASE
		|		WHEN Goods.ForAssignment
		|			THEN Goods.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	Goods.Count AS Count,
		|	TRUE AS OnSchedule,
		|	Header.ControlledLotReferenceLotReference AS OrderInSchedule
		|FROM
		|	DocumentDataHeader AS Header
		|		INNER JOIN DocumentDataGoodsTableCollapseProductLocations AS Goods
		|		ON Header.Ref = Goods.Ref
		|WHERE
		|	Header.Status IN(
		|			VALUE(Enum.StatusesOfQualityControlCertificates.AwaitingDecision),
		|			VALUE(Enum.StatusesOfQualityControlCertificates.IsProcessed))
		|		AND Goods.WarehouseUseOrderSchemeWhenReceiving
		|		AND Header.Date >= Goods.WarehouseStartDateOfOrderSchemeUponReceipt
		|		AND Goods.Action = VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.ChangeQuality)";
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, True);
	
	// MOVEMENT (D) and (E) mutual destruction
	
EndProcedure

Procedure ReflectByWarehouseSubsystem(Query, QueryTexts, Registers)
	
	// MOVEMENT (A-): Remove the lock on the warehouse and in the provision of goods.
	RegisterName = "ProductStock";
	If DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		
		QueryTextDocument_ =
			"SELECT
			|	Goods.Ref AS Ref,
			|	Header.Date AS Period,
			|	UNDEFINED AS OrderDocument,
			|	UNDEFINED AS TransportationJob,
			|	UNDEFINED AS Recipient,
			|	Goods.Warehouse AS Warehouse,
			|	Goods.Cell AS Cell,
			|	Goods.Premise AS Premise,
			|	Goods.Products AS Products,
			|	Goods.Characteristic AS Characteristic,
			|	Goods.Purpose AS Purpose,
			|	Header.ControlledLotReference AS ControlledLotReference,
			|	Goods.Package AS Package,
			|	Goods.Series AS Series,
			|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	Goods.Count AS Count,
			|	Goods.NumberOfPackages AS NumberOfPackages,
			|	VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship) AS Action,
			|	FALSE AS ForAssembly,
			|	FALSE AS AssemblyInProgress,
			|	FALSE AS Assembled,
			|	TRUE AS ToShip
			|FROM
			|	DocumentDataHeader AS Header
			|		INNER JOIN DocumentDataTableItems AS Goods
			|		ON Header.Ref = Goods.Ref
			|WHERE
			|	Header.Status IN(
			|			VALUE(Enum.StatusesOfQualityControlCertificates.AwaitingDecision),
			|			VALUE(Enum.StatusesOfQualityControlCertificates.IsProcessed))
			|		AND Goods.Action IN(
			|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.Unlock),
			|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.RegisterReturn),
			|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.RegisterGoodsTransfer))";
			
		WarehousesServer.ShipGoodsFromWarehouse_(Query, QueryTexts, RegisterName, QueryTextDocument_, True);
		
	EndIf;
	
	RegisterName = "GoodsInStorageBins";
	If DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		
		QueryTextDocument_ =
			"SELECT
			|	Goods.Ref AS Ref,
			|	Header.Date AS Date,
			|	Goods.Warehouse AS Warehouse,
			|	Goods.Cell AS Cell,
			|	Goods.Premise AS Premise,
			|	Goods.Products AS Products,
			|	Goods.Characteristic AS Characteristic,
			|	Goods.Purpose AS Purpose,
			|	Header.ControlledLotReference AS ControlledLotReference,
			|	Goods.Package AS Package,
			|	Goods.Series AS Series,
			|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	-Goods.Count AS Count,
			|	-Goods.NumberOfPackages AS NumberOfPackages,
			|	TRUE AS RemainderChanges
			|FROM
			|	DocumentDataHeader AS Header
			|		INNER JOIN DocumentDataTableItems AS Goods
			|		ON Header.Ref = Goods.Ref
			|WHERE
			|	Header.Status IN(
			|			VALUE(Enum.StatusesOfQualityControlCertificates.AwaitingDecision),
			|			VALUE(Enum.StatusesOfQualityControlCertificates.IsProcessed))
			|		AND Goods.Action IN(
			|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.Unlock),
			|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.RegisterReturn),
			|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.RegisterGoodsTransfer))";
		WarehousesServer.RegisterSurplusShortagesInWarehouse(Query, QueryTexts, RegisterName, QueryTextDocument_);
		
	EndIf;
	
	// MOVEMENT (A +): Remove the lock on the warehouse and in the provision of the goods.
	QueryTextDocument_ =
		"SELECT
		|	Goods.Ref AS Ref,
		|	Header.Date AS Date,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Cell AS Cell,
		|	Goods.Premise AS Premise,
		|	UNDEFINED AS Sender,
		|	UNDEFINED AS ReferenceOrder,
		|	UNDEFINED AS BusinessOperation,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.Package AS Package,
		|	FALSE AS ThisIsAPackingList,
		|	Goods.Series AS Series,
		|	TRUE AS ToControlQuality,
		// It doesn't matter, since there are no Registered Records for items to be received.
		|	FALSE AS RecordOfAPreviouslyReceivedLot,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	Goods.Count AS Count,
		|	Goods.NumberOfPackages AS NumberOfPackages,
		|	FALSE AS Accepts,
		|	TRUE AS Accepted,
		|	TRUE AS ThisIsAcceptanceWithoutOrder
		|FROM
		|	DocumentDataHeader AS Header
		|		INNER JOIN DocumentDataTableItems AS Goods
		|		ON Header.Ref = Goods.Ref
		|WHERE
		|	Header.Status IN(
		|			VALUE(Enum.StatusesOfQualityControlCertificates.AwaitingDecision),
		|			VALUE(Enum.StatusesOfQualityControlCertificates.IsProcessed))
		|		AND Goods.Action IN(
		|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.Unlock),
		|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.RegisterReturn),
		|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.RegisterGoodsTransfer))";
	WarehousesServer.TakeGoodsToWarehouse(Query, QueryTexts, Registers, QueryTextDocument_, "Goods");
	
	// MOVEMENT (B-): Reflection of shortage in the warehouse.
	QueryTextDocument_ =
		"SELECT
		|	Goods.Ref AS Ref,
		|	Header.Date AS Date,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Premise AS Premise,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Header.ControlledLotReference AS ControlledLotReference,
		|	Goods.Series AS Series,
		|	Goods.Package AS Package,
		|	-Goods.Count AS Count,
		|	-Goods.NumberOfPackages AS NumberOfPackages,
		|	Goods.Cell AS Cell,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	TRUE AS RemainderChanges
		|FROM
		|	DocumentDataHeader AS Header
		|		INNER JOIN DocumentDataTableItems AS Goods
		|		ON Header.Ref = Goods.Ref
		|WHERE
		|	Header.Status IN(
		|			VALUE(Enum.StatusesOfQualityControlCertificates.AwaitingDecision),
		|			VALUE(Enum.StatusesOfQualityControlCertificates.IsProcessed))
		|		AND Goods.Action IN(
		|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.MakeDebit),
		|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.RegisterStockQualityChange))
				// A feature of the implementation. The order is checked in the document, not in the warehouse operation.
				// It is impossible to check inside the operation, since reflection orders make RegisteredRecords for this operation
				// upon their existence, even if the document date is less than the start date of the order scheme.
		|		AND Goods.WarehouseUseOrderSchemeWhenReflectingSurplusShortages
		|		AND Header.Date >= Goods.WarehouseStartDateOfOrderSchemeWhenSurplusShortagesAreReflected";
	WarehousesServer.RegisterSurplusShortagesInWarehouse(Query, QueryTexts, Registers, QueryTextDocument_);
	
	// THE Registered Records (B+): Reflection of the surplus in the warehouse.
	QueryTextDocument_ =
		"SELECT
		|	Goods.Ref AS Ref,
		|	Header.Date AS Date,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Premise AS Premise,
		|	Goods.ProductsRecordingAsReceived AS Products,
		|	Goods.CharacteristicRecordingAsReceived AS Characteristic,
		|	CASE
		|		WHEN Goods.ForAssignment
		|			THEN Goods.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	Goods.Series AS Series,
		|	Goods.Package AS Package,
		|	Goods.Count AS Count,
		|	Goods.NumberOfPackages AS NumberOfPackages,
		|	Goods.Cell AS Cell,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	TRUE AS RemainderChanges
		|FROM
		|	DocumentDataHeader AS Header
		|		INNER JOIN DocumentDataTableItems AS Goods
		|		ON Header.Ref = Goods.Ref
		|WHERE
		|	Header.Status IN(
		|			VALUE(Enum.StatusesOfQualityControlCertificates.AwaitingDecision),
		|			VALUE(Enum.StatusesOfQualityControlCertificates.IsProcessed))
		|		AND Goods.Action = VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.RegisterStockQualityChange)
				// A feature of the implementation. The order is checked in the document, not in the warehouse operation.
				// It is impossible to check inside the operation, since reflection orders make RegisteredRecords for this operation
				// upon their existence, even if the document date is less than the start date of the order scheme.
		|		AND Goods.WarehouseUseOrderSchemeWhenReflectingSurplusShortages
		|		AND Header.Date >= Goods.WarehouseStartDateOfOrderSchemeWhenSurplusShortagesAreReflected";
	WarehousesServer.RegisterSurplusShortagesInWarehouse(Query, QueryTexts, Registers, QueryTextDocument_);
	
	// The Registered Record (B-): Cancellation of the incoming order.
	QueryTextDocument_ =
		"SELECT
		|	Goods.Ref AS Ref,
		|	Header.Date AS Date,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Cell AS Cell,
		|	Goods.Premise AS Premise,
		|	Header.ControlledLotOfTheSender AS Sender,
		|	Header.ControlledLotReferenceLotReference AS ReferenceOrder,
		|	Header.ControlledLotReferenceBusinessTransaction AS BusinessOperation,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.Package AS Package,
		|	FALSE AS ThisIsAPackingList,
		|	Goods.Series AS Series,
		|	TRUE AS ToControlQuality,
		|	FALSE AS RecordOfAPreviouslyReceivedLot,
		|	Header.ControlledLotReference AS ControlledLotReference,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	-Goods.Count AS Count,
		|	-Goods.NumberOfPackages AS NumberOfPackages,
		|	FALSE AS Accepts,
		|	TRUE AS Accepted,
		|	FALSE AS ThisIsAcceptanceWithoutOrder
		|FROM
		|	DocumentDataHeader AS Header
		|		INNER JOIN DocumentDataTableItems AS Goods
		|		ON Header.Ref = Goods.Ref
		|WHERE
		|	Header.Status IN(
		|			VALUE(Enum.StatusesOfQualityControlCertificates.AwaitingDecision),
		|			VALUE(Enum.StatusesOfQualityControlCertificates.IsProcessed))
		|		AND Goods.WarehouseUseOrderSchemeWhenReceiving
		|		AND Header.Date >= Goods.WarehouseStartDateOfOrderSchemeUponReceipt
		|		AND Goods.Action IN(
		|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.DoNotReceiveGoods),
		|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.ToReturnToVendor),
		|			VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.ChangeQuality))";
	WarehousesServer.TakeGoodsToWarehouse(Query, QueryTexts, Registers, QueryTextDocument_, "Goods");
	
	// MOVEMENT (B+): Entry of an incoming order.
	QueryTextDocument_ =
		"SELECT
		|	Goods.Ref AS Ref,
		|	Header.Date AS Date,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Cell AS Cell,
		|	Goods.Premise AS Premise,
		|	Header.ControlledLotOfTheSender AS Sender,
		|	Header.ControlledLotReferenceLotReference AS ReferenceOrder,
		|	Header.ControlledLotReferenceBusinessTransaction AS BusinessOperation,
		|	Goods.ProductsRecordingAsReceived AS Products,
		|	Goods.CharacteristicRecordingAsReceived AS Characteristic,
		|	CASE
		|		WHEN Goods.ForAssignment
		|			THEN Goods.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	Goods.Package AS Package,
		|	FALSE AS ThisIsAPackingList,
		|	Goods.Series AS Series,
		|	TRUE AS ToControlQuality,
		|	FALSE AS RecordOfAPreviouslyReceivedLot,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	Goods.Count AS Count,
		|	Goods.NumberOfPackages AS NumberOfPackages,
		|	FALSE AS Accepts,
		|	TRUE AS Accepted,
		|	FALSE AS ThisIsAcceptanceWithoutOrder
		|FROM
		|	DocumentDataHeader AS Header
		|		INNER JOIN DocumentDataTableItems AS Goods
		|		ON Header.Ref = Goods.Ref
		|WHERE
		|	Header.Status IN(
		|			VALUE(Enum.StatusesOfQualityControlCertificates.AwaitingDecision),
		|			VALUE(Enum.StatusesOfQualityControlCertificates.IsProcessed))
		|		AND Goods.WarehouseUseOrderSchemeWhenReceiving
		|		AND Header.Date >= Goods.WarehouseStartDateOfOrderSchemeUponReceipt
		|		AND Goods.Action = VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.ChangeQuality)";
	WarehousesServer.TakeGoodsToWarehouse(Query, QueryTexts, Registers, QueryTextDocument_, "Goods");
	
	// MOVEMENT (D): Receipt of the initial position of the nomenclature without an order
	QueryTextDocument_ =
		"SELECT
		|	Goods.Ref AS Ref,
		|	Header.Date AS Date,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Cell AS Cell,
		|	Goods.Premise AS Premise,
		|	UNDEFINED AS Sender,
		|	UNDEFINED AS ReferenceOrder,
		|	UNDEFINED AS BusinessOperation,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.Package AS Package,
		|	FALSE AS ThisIsAPackingList,
		|	Goods.Series AS Series,
		|	TRUE AS ToControlQuality,
		// It doesn't matter, since there are no Registered Records for items to be received.
		|	FALSE AS RecordOfAPreviouslyReceivedLot,
		|	Header.ControlledLotReference AS ControlledLotReference,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	Goods.Count AS Count,
		|	Goods.NumberOfPackages AS NumberOfPackages,
		|	FALSE AS Accepts,
		|	TRUE AS Accepted,
		|	TRUE AS ThisIsAcceptanceWithoutOrder
		|FROM
		|	DocumentDataHeader AS Header
		|		INNER JOIN DocumentDataTableItems AS Goods
		|		ON Header.Ref = Goods.Ref
		|WHERE
		|	Header.Status IN(
		|			VALUE(Enum.StatusesOfQualityControlCertificates.AwaitingDecision),
		|			VALUE(Enum.StatusesOfQualityControlCertificates.IsProcessed))
		|		AND Goods.WarehouseUseOrderSchemeWhenShipping
		|		AND Goods.WarehouseStartDateOfOrderSchemeDuringShipment <= Header.Date
		|		AND Goods.Action = VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.ToReturnToVendor)";
	WarehousesServer.TakeGoodsToWarehouse(Query, QueryTexts, Registers, QueryTextDocument_, "Goods");
	
	// The Registered Record (E): Issuance of an order for shipment
	QueryTextDocument_ =
		"SELECT
		|	Goods.Ref AS Ref,
		|	Header.Date AS Period,
		|	Goods.Ref AS OrderDocument,
		|	Goods.Ref AS Invoice,
		|	FALSE AS Patch,
		|	UNDEFINED AS CorrectedDocument,
		|	Header.ControlledLotOfTheSender AS Recipient,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.Series AS Series,
		|	Header.ControlledLotReference AS ControlledLotReference,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	Goods.Count AS Count,
		|	FALSE AS ExceedingOrder,
		|	FALSE AS Canceled,
		|	TRUE AS ThisIsAnInvoice,
		|	FALSE AS ShipmentByOrder
		|FROM
		|	DocumentDataHeader AS Header
		|		INNER JOIN DocumentDataGoodsTableCollapseProductLocations AS Goods
		|		ON Header.Ref = Goods.Ref
		|WHERE
		|	Header.Status IN(
		|			VALUE(Enum.StatusesOfQualityControlCertificates.AwaitingDecision),
		|			VALUE(Enum.StatusesOfQualityControlCertificates.IsProcessed))
		|		AND Goods.WarehouseUseOrderSchemeWhenShipping
		|		AND Goods.WarehouseStartDateOfOrderSchemeDuringShipment <= Header.Date
		|		AND Goods.Action = VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.ToReturnToVendor)";
		
	WarehousesServer.ScheduleShipmentOfGoods(Query, QueryTexts, Registers, QueryTextDocument_);
	
	QueryTextDocument_ =
		"SELECT
		|	Goods.Ref AS Ref,
		|	Header.Date AS Period,
		|	Goods.Ref AS OrderDocument,
		|	Goods.Ref AS Invoice,
		|	FALSE AS Patch,
		|	UNDEFINED AS CorrectedDocument,
		|	Header.ControlledLotOfTheSender AS Recipient,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Header.ControlledLotReference AS ControlledLotReference,
		|	Goods.Series AS Series,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	Goods.Count AS Count,
		|	FALSE AS ExceedingOrder,
		|	FALSE AS Canceled,
		|	TRUE AS ThisIsAnInvoice,
		|	FALSE AS ShipmentByOrder
		|FROM
		|	DocumentDataHeader AS Header
		|		INNER JOIN DocumentDataGoodsTableCollapseProductLocations AS Goods
		|		ON Header.Ref = Goods.Ref
		|WHERE
		|	Header.Status IN(
		|			VALUE(Enum.StatusesOfQualityControlCertificates.AwaitingDecision),
		|			VALUE(Enum.StatusesOfQualityControlCertificates.IsProcessed))
		|		AND Goods.WarehouseUseOrderSchemeWhenShipping
		|		AND Goods.WarehouseStartDateOfOrderSchemeDuringShipment <= Header.Date
		|		AND Goods.Action = VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.ToReturnToVendor)";
	
	ParametersOfModularHolding = WarehousesServer.ParametersOfModularHolding();
	ParametersOfModularHolding.SynonymForDocumentTable = "Goods";
	ParametersOfModularHolding.MetadataObject = Documents.GoodsQualityControlCertificate.EmptyRef().Metadata();
	
	WarehousesServer.ArrangeShipmentOfGoodsWithConfigurationOfSeriesConnection(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		ParametersOfModularHolding);
		
EndProcedure

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	FullDocumentName = "Document.GoodsQualityControlCertificate";
	ParameterValues = New Structure();
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName <> "DocumentsRegistry" Then
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Undefined, Undefined, "DocumentsRegistry", True);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion
#Region ResearchProject

Function QueryTextResearchResults()
	Text =
		"SELECT
		|	Goods.Ref AS Ref,
		|	CASE
		|		WHEN MIN(Goods.Warehouse) = MAX(Goods.Warehouse)
		|			THEN MIN(Goods.Warehouse)
		|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
		|	END AS Warehouse,
		|	CASE
		|		WHEN MIN(Goods.Premise) = MAX(Goods.Premise)
		|			THEN MIN(Goods.Premise)
		|		ELSE VALUE(Catalog.Warerooms.EmptyRef)
		|	END AS Premise
		|INTO GoodsInSummary
		|FROM
		|	Document.GoodsQualityControlCertificate.Goods AS Goods
		|WHERE
		|	Goods.Ref IN (&ObjectsArray)
		|GROUP BY
		|	Goods.Ref
		|
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Header.Ref AS Ref,
		|	Header.Date AS Date,
		|	Header.Number AS Number,
		|	PRESENTATION(Header.Organization) AS OrganizationPresentation,
		|	Header.EmployeeResponsible.Individual AS EmployeeResponsible,
		|	GoodsInSummary.Warehouse AS Warehouse,
		|	GoodsInSummary.Premise AS Premise,
		|	Header.ControlledLotReference.Lot AS Lot,
		|	PRESENTATION(GoodsInSummary.Warehouse) AS WarehousePresentation,
		|	PRESENTATION(GoodsInSummary.Premise) AS PremisePresentation,
		|	CASE
		|		WHEN Header.ControlledLotReference.Lot IS NULL
		|			THEN """"
		|		ELSE PRESENTATION(Header.ControlledLotReference.Lot)
		|	END AS LotPresentation
		|FROM
		|	Document.GoodsQualityControlCertificate AS Header
		|		INNER JOIN GoodsInSummary AS GoodsInSummary
		|		ON GoodsInSummary.Ref = Header.Ref
		|WHERE
		|	Header.Ref IN (&ObjectsArray)
		|
		|ORDER BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.Ref AS Ref,
		|	MIN(Goods.LineNumber) AS LineNumber,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Series AS Series,
		|	Goods.Package AS Package,
		|	Goods.QualityCheckResult AS QualityCheckResult,
		|	Goods.RowID AS RowID,
		|	SUM(Goods.NumberOfPackages) AS NumberOfPackages
		|INTO ProductsGrouped
		|FROM
		|	Document.GoodsQualityControlCertificate.Goods AS Goods
		|WHERE
		|	Goods.Ref IN (&ObjectsArray)
		|GROUP BY
		|	Goods.Ref,
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Series,
		|	Goods.Package,
		|	Goods.RowID,
		|	Goods.QualityCheckResult
		|
		|INDEX BY
		|	Products
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Research.Ref AS Ref,
		|	Research.RowID AS RowID,
		|	Research.ResearchProject AS ResearchProject
		|INTO ResearchResults
		|FROM
		|	&Research AS Research
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.Ref AS Ref,
		|	Goods.LineNumber AS LineNumber,
		|	Goods.NumberOfPackages AS NumberOfPackages,
		|	&OutputCodes AS SKU,
		|	Goods.Products.DescriptionFull AS ProductPresentation,
		|	Goods.Characteristic.DescriptionFull AS CharacteristicPresentation,
		|	Goods.Series.Description AS BatchPresentation,
		|	CASE
		|		WHEN Goods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN REFPRESENTATION(Goods.Products.UnitOfMeasure)
		|		ELSE REFPRESENTATION(Goods.Package)
		|	END AS PresentationOfPackingUnit,
		|	ResearchResults.ResearchProject AS QualityStudies,
		|	Goods.QualityCheckResult AS QualityCheckResult
		|FROM
		|	ProductsGrouped AS Goods
		|		LEFT JOIN ResearchResults AS ResearchResults
		|		ON Goods.Ref = ResearchResults.Ref
		|		AND Goods.RowID = ResearchResults.RowID
		|WHERE
		|	Goods.Ref IN (&ObjectsArray)
		|
		|ORDER BY
		|	Ref,
		|	LineNumber
		|TOTALS
		|BY
		|	Ref";
		
	Return Text;
	
EndFunction

#EndRegion
Function GoodsResearchIsIncluded()
	
	UseResearch = False;
	UseResearch = GetFunctionalOption("UseGoodsQualityResearch");
	Return UseResearch;
	
EndFunction

Function ToFormPrintedFormOfActOfQualityControlOfGoods(ObjectsArray, PrintObjects, PrintParameters)
	
	SetPrivilegedMode(True);
	
	MetadataOfDocument = Documents.GoodsQualityControlCertificate.EmptyRef().Metadata();
	If Not ValueIsFilled(MetadataOfDocument.ObjectPresentation) Then
		DocumentSynonym = MetadataOfDocument.Synonym;
	Else
		DocumentSynonym = MetadataOfDocument.ObjectPresentation;
	EndIf;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_GoodsQualityControlCertificate_DocumentPrintForm";
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	OutputBatches = GetFunctionalOption("UseItemsBatch");
	OutputResearch = GoodsResearchIsIncluded();
	If OutputResearch Then
		Query = New Query;
		Query.Text =
		"SELECT
		|	ResearchResults.Ref AS Ref,
		|	ResearchResults.RowID AS RowID,
		|	PRESENTATION(ResearchResults.ResearchProject) AS ResearchProject
		|FROM
		|	Document.GoodsQualityControlCertificate.ResearchResults AS ResearchResults
		|WHERE
		|	ResearchResults.Ref IN (&ObjectsArray)
		|GROUP BY
		|	ResearchResults.Ref,
		|	ResearchResults.RowID,
		|	ResearchResults.ResearchProject";

		Query.SetParameter("ObjectsArray", ObjectsArray);
		Selection = Query.Execute().Select();
		ResultOfStudy = New ValueTable;
		ResultOfStudy.Columns.Add("Ref",
			New TypeDescription("DocumentRef.GoodsQualityControlCertificate"));
		ResultOfStudy.Columns.Add("RowID", New TypeDescription("String", , , ,
			New StringQualifiers(36)));
		ResultOfStudy.Columns.Add("ResearchProject", New TypeDescription("String"));
		While Selection.Next() Do
			Filter = New Structure("Ref, RowID", Selection.Ref, Selection.RowID);
			FoundRows = ResultOfStudy.FindRows(Filter);
			If FoundRows.Count() = 0 Then
				NewRow = ResultOfStudy.Add();
				FillPropertyValues(NewRow, Selection);
			Else
				FoundRows[0].ResearchProject = FoundRows[0].ResearchProject + Chars.LF + Selection.ResearchProject;
			EndIf;
		EndDo;
	EndIf;
	Query = New Query();
	Text =
		"SELECT
		|	Goods.Ref AS Ref,
		|	CASE
		|		WHEN MIN(Goods.Warehouse) = MAX(Goods.Warehouse)
		|			THEN MIN(Goods.Warehouse)
		|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
		|	END AS Warehouse,
		|	CASE
		|		WHEN MIN(Goods.Premise) = MAX(Goods.Premise)
		|			THEN MIN(Goods.Premise)
		|		ELSE VALUE(Catalog.Warerooms.EmptyRef)
		|	END AS Premise
		|INTO GoodsInSummary
		|FROM
		|	Document.GoodsQualityControlCertificate.Goods AS Goods
		|WHERE
		|	Goods.Ref IN(&ObjectsArray)
		|GROUP BY
		|	Goods.Ref
		|INDEX BY
		|	Ref
		|;
		|
		|/////////////////////////////////////////////////////////////
		|SELECT
		|	Header.Ref AS Ref,
		|	Header.Date AS Date,
		|	Header.Number AS Number,
		|	PRESENTATION(Header.Organization) AS OrganizationPresentation,
		|	Header.EmployeeResponsible.Individual AS EmployeeResponsible,
		|	GoodsInSummary.Warehouse AS Warehouse,
		|	GoodsInSummary.Premise AS Premise,
		|	Header.ControlledLotReference.Lot AS Lot,
		|	PRESENTATION(GoodsInSummary.Warehouse) AS WarehousePresentation,
		|	PRESENTATION(GoodsInSummary.Premise) AS PremisePresentation,
		|	CASE
		|		WHEN Header.ControlledLotReference.Lot IS NULL
		|			THEN """"
		|		ELSE PRESENTATION(Header.ControlledLotReference.Lot)
		|	END AS LotPresentation
		|FROM
		|	Document.GoodsQualityControlCertificate AS Header
		|		
		|		INNER JOIN GoodsInSummary AS GoodsInSummary
		|		ON GoodsInSummary.Ref = Header.Ref
		|WHERE
		|	Header.Ref IN(&ObjectsArray)
		|ORDER BY
		|	Ref
		|;
		|
		|/////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.Ref AS Ref,
		|	MIN(Goods.LineNumber) AS LineNumber,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Series AS Series,
		|	Goods.Package AS Package,
		|	Goods.QualityCheckResult AS QualityCheckResult,
		|	SUM(Goods.NumberOfPackages) AS NumberOfPackages
		|INTO ProductsGrouped
		|FROM
		|	Document.GoodsQualityControlCertificate.Goods AS Goods
		|WHERE
		|	Goods.Ref IN(&ObjectsArray)
		|GROUP BY
		|	Goods.Ref,
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Series,
		|	Goods.Package,
		|	Goods.QualityCheckResult
		|INDEX BY
		|	Products
		|;
		|
		|//////////////////////////////////////////////////////
		|SELECT
		|	Goods.Ref AS Ref,
		|	Goods.LineNumber AS LineNumber,
		|	Goods.NumberOfPackages AS NumberOfPackages,
		|	&OutputCodes AS SKU,
		|	Goods.Products.DescriptionFull AS ProductPresentation,
		|	Goods.Characteristic.DescriptionFull AS CharacteristicPresentation,
		|	Goods.Series.Description AS BatchPresentation,
		|	CASE
		|		WHEN Goods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN REFPRESENTATION(Goods.Products.UnitOfMeasure)
		|		ELSE REFPRESENTATION(Goods.Package)
		|	END AS PresentationOfPackingUnit,
		|	Goods.QualityCheckResult AS QualityCheckResult
		|FROM
		|	ProductsGrouped AS Goods
		|WHERE
		|	Goods.Ref IN(&ObjectsArray)
		|ORDER BY
		|	Ref, LineNumber
		|TOTALS BY
		|	Ref";
	If OutputResearch Then
		Text = QueryTextResearchResults();
	EndIf;
	SubstitutionOutputCodes = ?(OutputCodes, "Goods.Products." + NameOfCodeColumn, """""");
	Text = StrReplace(Text, "&OutputCodes", SubstitutionOutputCodes);

	Query.Text = Text;
	Query.SetParameter("ObjectsArray", ObjectsArray);
	If OutputResearch Then
		Query.SetParameter("Research", ResultOfStudy);
	EndIf;
	Results = Query.ExecuteBatch(); 
	
	SelectionByDocuments = Results[1].Select();
	If OutputResearch Then
		SelectionByTableParts = Results[4].Select(QueryResultIteration.ByGroups);
	Else
		SelectionByTableParts = Results[3].Select(QueryResultIteration.ByGroups);
	EndIf;
	
	FirstDocument = True;
	
	DocumentAttributes = New Structure("Number,Date,Prefix");
	
	AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
	AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	While SelectionByDocuments.Next() Do
		
		If Not SelectionByTableParts.FindNext(New Structure("Ref", SelectionByDocuments.Ref)) Then
			Continue;
		EndIf;
		
		ThereIs_Warehouse = ValueIsFilled(SelectionByDocuments.Warehouse);
		
		// We get the layout in a loop, because the width of the columns depends on the warehouse and the room in the document.
		Template = PrintManagement.PrintFormTemplate("Document.GoodsQualityControlCertificate.PF_MXL_GoodsQualityControlCertificate");
		
		HeaderArea_ = Template.GetArea("Title");
		SignatureArea = Template.GetArea("Signatures");
		
		If ThereIs_Warehouse Then
			AreaNameHeader = "HeaderAndWarehouseAndLotReference";
		Else
			AreaNameHeader = "CapWithoutWarehouseAndLotReference";
		EndIf;
		SectionHeader = Template.GetArea(AreaNameHeader);
		
		TableArea = New Array();
		
		Header = Template.GetArea("TableHeader|BeginningOfTheLine");
		String = Template.GetArea("TableRow|BeginningOfTheLine");
		Footer = Template.GetArea("TableFooter|BeginningOfTheLine");
		
		TableArea.Add(New Structure("Header,String,Footer", Header, String, Footer));
		
		HiddenWidth = 0;
		
		If OutputCodes Then
			
			Header = Template.GetArea("TableHeader|ColumnOfCodes");
			String = Template.GetArea("TableRow|ColumnOfCodes");
			Footer = Template.GetArea("TableFooter|ColumnOfCodes");
			
			TableArea.Add(New Structure("Header,String,Footer", Header, String, Footer));
			Header.Parameters.NameOfCodeColumn = PresentationOfCodesColumn; 
			
		Else
			HiddenWidth = Template.Area("ColumnOfCodes").ColumnWidth;
		EndIf;
		
		Header = Template.GetArea("TableHeader|OwnGoods");
		String = Template.GetArea("TableRow|OwnGoods");
		Footer = Template.GetArea("TableFooter|OwnGoods");
		
		TableArea.Add(New Structure("Header,String,Footer", Header, String, Footer));
		
		Header = Template.GetArea("TableHeader|Count");
		String = Template.GetArea("TableRow|Count");
		Footer = Template.GetArea("TableFooter|Count");
		
		TableArea.Add(New Structure("Header,String,Footer", Header, String, Footer));
		
		Template.Area("OwnGoods").ColumnWidth = Template.Area("OwnGoods").ColumnWidth + HiddenWidth;
		HiddenWidth = 0;
		
		If OutputResearch Then
			
			Header = Template.GetArea("TableHeader|ResearchProject");
			String = Template.GetArea("TableRow|ResearchProject");
			Footer = Template.GetArea("TableFooter|ResearchProject");
			
			TableArea.Add(New Structure("Header,String,Footer", Header, String, Footer));
			
		Else
			HiddenWidth = HiddenWidth + Template.Area("ResearchProject").ColumnWidth;
		EndIf;
		
		Template.Area("Result").ColumnWidth = Template.Area("Result").ColumnWidth + HiddenWidth;
		
		Header = Template.GetArea("TableHeader|Result");
		String = Template.GetArea("TableRow|Result");
		Footer = Template.GetArea("TableFooter|Result");
		
		TableArea.Add(New Structure("Header,String,Footer", Header, String, Footer));
		
		TotalTableAreas = TableArea.Count() - 1;
		
		SamplingByTSLines = SelectionByTableParts.Select(QueryResultIteration.ByGroups);
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		FillPropertyValues(DocumentAttributes,SelectionByDocuments);
		
		TitleText = TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes, DocumentSynonym);
		HeaderDataStructure = New Structure();
		HeaderDataStructure.Insert("TitleText", TitleText);
		
		HeaderArea_.Parameters.Fill(HeaderDataStructure);
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(
			SpreadsheetDocument, Template, HeaderArea_, SelectionByDocuments.Ref);
		SpreadsheetDocument.Put(HeaderArea_);
		
		SectionHeader.Parameters.Fill(SelectionByDocuments);
		
		If ThereIs_Warehouse Then
			
			SectionHeader.Parameters.WarehousePresentation = WarehousesServer.GetWarehousePresentation(
				SelectionByDocuments.WarehousePresentation,
				SelectionByDocuments.PremisePresentation);
				
		EndIf;
		
		SpreadsheetDocument.Put(SectionHeader);
		
		For AreaIndex = 0 To TotalTableAreas Do
			AreaDetails = TableArea[AreaIndex]; // Structure
			CurrentArea = AreaDetails.Header; // SpreadsheetDocument
			If AreaIndex = 0 Then
				SpreadsheetDocument.Put(CurrentArea);
			Else
				SpreadsheetDocument.Join(CurrentArea);
			EndIf;
		EndDo;
		
		While SamplingByTSLines.Next() Do
			
			OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
				SamplingByTSLines.ProductPresentation,
				SamplingByTSLines.CharacteristicPresentation,
				, // Package
				SamplingByTSLines.BatchPresentation,
				AdditionalParametersProductPresentation);
			ParametersStructure = New Structure("OwnGoods", OwnGoods);
			
			For AreaIndex = 0 To TotalTableAreas Do
				AreaDetails = TableArea[AreaIndex]; // Structure
				CurrentArea = AreaDetails.String; // SpreadsheetDocument
				CurrentArea.Parameters.Fill(SamplingByTSLines);
				CurrentArea.Parameters.Fill(ParametersStructure);
				If AreaIndex = 0 Then
					SpreadsheetDocument.Put(CurrentArea);
				Else
					SpreadsheetDocument.Join(CurrentArea);
				EndIf;
			EndDo;
			
		EndDo;
		
		For AreaIndex = 0 To TotalTableAreas Do
			AreaDetails = TableArea[AreaIndex]; // Structure
			CurrentArea = AreaDetails.Footer; // SpreadsheetDocument
			If AreaIndex = 0 Then
				SpreadsheetDocument.Put(CurrentArea);
			Else
				SpreadsheetDocument.Join(CurrentArea);
			EndIf;
		EndDo;
		
		SignatureArea.Parameters.EmployeeResponsible = PersonsTM.IndividualShortName(
			SelectionByDocuments.EmployeeResponsible, SelectionByDocuments.Date);
		SpreadsheetDocument.Put(SignatureArea);
		
		PrintManagement.SetDocumentPrintArea(
			SpreadsheetDocument, RowNumberStart, PrintObjects, SelectionByDocuments.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	Return SpreadsheetDocument;
	
EndFunction

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "Documents.GoodsQualityControlCertificate.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.27.26";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("35b8a3c9-6cc3-45e3-a782-4f74b1899f6d");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.GoodsQualityControlCertificate.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật các chứng từ ""Biên bản kiểm soát chất lượng"":';
								|ru = 'Обновление документов ""Акт контроля качества"":';
								|en = 'Update the ""Quality control certificate"" documents:'; fa = 'Update the ""Quality control certificate"" documents:';
								|it = 'Update the ""Quality control certificate"" documents:';
								|pl = 'Update the ""Quality control certificate"" documents:';
								|tr = '""Ürün kalite kontrol tutanağı"" belgelerinin güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- điền các mục tin hệ thống mới ""Đối tác của lô hàng"" và ""Bộ phận của lô hàng"" với các giá trị từ mục tin ""Lô hàng được kiểm soát"".';
								|ru = '- заполняет новые служебные реквизиты ""Партнер партии"" и ""Подразделение партии"" значениями из реквизита ""Контролируемая партия"".';
								|en = '- Fills in the new ""Lot partner"" and ""Lot business unit"" internal attributes with the values from the ""Controlled lot"" attribute.'; fa = '- Fills in the new ""Lot partner"" and ""Lot business unit"" internal attributes with the values from the ""Controlled lot"" attribute.';
								|it = '- Fills in the new ""Lot partner"" and ""Lot business unit"" internal attributes with the values from the ""Controlled lot"" attribute.';
								|pl = '- Fills in the new ""Lot partner"" and ""Lot business unit"" internal attributes with the values from the ""Controlled lot"" attribute.';
								|tr = '- ""Kontrol edilen lot"" özniteliğindeki değerlerle yeni ""Lot partneri"" ve ""Lot departmanı"" hizmet özniteliklerini doldurur.'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.ControlledLots.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.GoodsQualityControlCertificate.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.GoodsQualityControlCertificate";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("DATE DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	SelectionParameters.AdditionalDataSources.Insert("ControlledLotReference");
	
	Query = New Query();
	Query.Text =
	"SELECT
	|	Acts.Ref AS Ref
	|FROM
	|	Document.GoodsQualityControlCertificate AS Acts
	|WHERE
	|	NOT ISNULL(Acts.ControlledLotReference.DeleteBusinessUnitProcessed, TRUE)";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "Document.GoodsQualityControlCertificate";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	UpdatedData.Ref AS Ref
	|INTO UpdatedData
	|FROM
	|	&UpdatedData AS UpdatedData
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UpdatedData.Ref AS Ref,
	|	DocumentAttributes.DataVersion AS DataVersion,
	|	DocumentAttributes.ControlledLotReference AS ControlledLotReference
	|FROM
	|	UpdatedData AS UpdatedData
	|		LEFT JOIN Document.GoodsQualityControlCertificate AS DocumentAttributes
	|		ON UpdatedData.Ref = DocumentAttributes.Ref";
	
	Query.SetParameter("UpdatedData", UpdatedData);
	
	Selection = Query.Execute().Select();
	
	ExceptionsWhenUpdating = New Array();
	While Selection.Next() Do
		
		ExceptionReason = "";
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = "BLOCK";
			
			Block = New DataLock;
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Selection.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			LockItem = Block.Add("Catalog.ControlledLots");
			LockItem.SetValue("Ref", Selection.ControlledLotReference);
			LockItem.Mode = DataLockMode.Shared;
			Block.Lock();
			
			DocumentObject = InfobaseUpdateTM.CheckGetObject(Selection.Ref, Selection.DataVersion, Parameters.Queue);
			
			ExceptionReason = "BAD_DATA";
			
			PartyDetails = Common.ObjectAttributesValues(Selection.ControlledLotReference,
				"Partner,Department");
			
			ObjectModified = False;
			
			If DocumentObject <> Undefined Then
				DocumentObject.LotBusinessUnit = PartyDetails.Department;
				DocumentObject.LotPartner = PartyDetails.Partner;
				ObjectModified = True;
			EndIf;
			
			ExceptionReason = "RECORD";
			
			If ObjectModified Then
				InfobaseUpdate.WriteData(DocumentObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Selection.Ref);
			
			If ExceptionReason = "BAD_DATA" Then
				
				Recommendation = NStr("vi = 'Hãy kiểm tra thủ công dữ liệu của chứng từ.';
										|ru = 'Проверьте данные документа вручную.';
										|en = 'Check the document data manually.'; fa = 'Check the document data manually.';
										|it = 'Check the document data manually.';
										|pl = 'Check the document data manually.';
										|tr = 'Belge verilerini manuel olarak kontrol edin.'");
				IssueDetails = InfobaseUpdateTM.DataProblem(
					Selection.Ref, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				
			ElsIf ExceptionReason = "RECORD" Then
				
				InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, 1, Parameters);
				ExceptionText = NStr("vi = 'Không thể xử lý chứng từ ""Biên bản kiểm soát chất lượng hàng hóa"".';
									|ru = 'Не удалось обработать документ ""Акт контроля качества товаров"".';
									|en = 'Cannot process the ""Goods quality control certificates"" document.'; fa = 'Cannot process the ""Goods quality control certificates"" document.';
									|it = 'Cannot process the ""Goods quality control certificates"" document.';
									|pl = 'Cannot process the ""Goods quality control certificates"" document.';
									|tr = '""Ürün kalite kontrol tutanağı"" belgesi işlenemedi.'");
				Raise StrConcat(ExceptionText, Chars.LF);
				
			EndIf;
			
		EndTry;
		
	EndDo;
	InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, 1, Parameters);
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
