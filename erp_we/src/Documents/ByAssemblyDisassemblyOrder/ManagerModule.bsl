#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Creates a representation of the metadata object in the main language.
// Returns:
// String - Representation of the metadata object in the main language.
//
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
	
	ObjectPresentation = NStr(
		"vi = 'Đơn hàng đóng bộ (tách bộ)';
		|ru = 'Заказ на сборку (разборку)';
		|en = 'Kitting order'; fa = 'سفارش کیت‌سازی';
		|it = 'Ordine di assemblaggio/disassemblaggio';
		|pl = 'Zamówienie na montaż';
		|tr = 'Montaj (demontaj) emri'",
		DefaultLanguageCode);
		
	Return ObjectPresentation;
	
EndFunction

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization, Warehouse");
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "DocumentBasis";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Department", Parameters);
	
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("InternalInventoryTransfers");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("AddressWarehouse");
	
	ByAssemblyDisassemblyOrderLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of data tables to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ByAssemblyDisassemblyOrder") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableAssemblyOrders(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		ByAssemblyDisassemblyOrderLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ScheduleGoodsReceipt(Query, QueryTexts, Registers);
	ReflectReserve(Query, QueryTexts, Registers);
	ScheduleShipmentOfGoods(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Generates an array of acceptable statuses based on the program settings
//
// Parameters:
//	DocumentName - String - Name of the document to enter.
//
// Returns:
//	Array - array of valid statuses.
//
Function ValidInputStatusesBasedOn(DocumentName) Export
	
	AcceptableStatuses = New Array;
	AcceptableStatuses.Add(Enums.InternalOrderStatuses.ForCompletion);
	AcceptableStatuses.Add(Enums.InternalOrderStatuses.Closed);
	
	Return AcceptableStatuses;
	
EndFunction

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.TransferOrder.AddCreateSecuringOrderCommand(GenerationCommands);
	Documents.ProductionOrder2_2.AddCreateSecuringOrderCommand(GenerationCommands);
	Documents.PurchaseOrder.AddCreateSecuringOrderCommand(GenerationCommands);
	
	Documents.InventoryAssignmentAdjustment.AddGenerateCommand(GenerationCommands);
	
	Documents.AssemblyFromComponents.AddCreateBasedOnOrderCommand_(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	DataProcessors.GenerationOfTransferToProductionOrdersByReference.AddGenerateCommand(GenerationCommands);
	Documents.GoodsIssueNote.AddCommandToCreateSpendingOrderForGoodsBasedOnIt(GenerationCommands);
	
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
	ByAssemblyDisassemblyOrderLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

// Adds a command to create an "Assembly Order" document.
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - description of the added command.
Function AddCreateSecuringOrderCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.ByAssemblyDisassemblyOrder) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ByAssemblyDisassemblyOrder.FullName();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateSecuringOrder";
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(
			Metadata.Documents.ByAssemblyDisassemblyOrder);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseAssemblyDisassemblyOrders";
		CreationParameters = ProvisionInDocumentsServer.ParametersForCreatingSecuringOrder(
			CreateBasedOnCommand.AdditionalParameters);
		CreationParameters.NameOfDocumentManager = "ByAssemblyDisassemblyOrder";
		CreationParameters.FormName = "Document.ByAssemblyDisassemblyOrder.ObjectForm";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Creation parameters based on the providing order.
// Returns:
// See ProvisionInDocumentsServer.ProductSelectionParametersForCreatingSecuringOrder
Function CreationParametersBasedOnProvidingOrder() Export
	
	ProductTableParameters = ProvisionInDocumentsServer.ProductSelectionParametersForCreatingSecuringOrder();
	ProductTableParameters.ItemsTypes.Add(Enums.ItemsTypes.OwnGoods);
	ProductTableParameters.ItemsTypes.Add(Enums.ItemsTypes.ReusablePackage);
	ProductTableParameters.OneWarehouse = True;
	Return ProductTableParameters;
	
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = Reports.DocumentFulfillmentStatus.AddCommandStateOfExecutionOfInternalOrders(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Order = 1;
	EndIf;
	
	ByAssemblyDisassemblyOrderLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

// Returns a table of acceptable deviations of measured items from the list of orders.
//
//	Parameters:
//		ListOfOrders_ - ValueList, DocumentRef.ByAssemblyDisassemblyOrder - the list of orders to determine the allowable deviations
//		InventoryMovementType - EnumRef.InventoryMovementTypes -
//	Returns:
//		ValueTable - table of permissible deviations:
//		* OrderDocument                - DocumentRef.ByAssemblyDisassemblyOrder
//		* Products         - CatalogRef.Products
//		* Characteristic       - CatalogRef.ItemsCharacteristics
//		* Series                - CatalogRef.ItemsBatches
//		* AssemblyType            - EnumRef.InventoryMovementTypes
//		* AllowableVariance - Number
//
Function PermissibleDeviationsOfMeasuredGoods(ListOfOrders_, InventoryMovementType) Export
	
	AllowableDeviationOfMeasuringGoodsShipmentAndReceiving = Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
	
	If Not ValueIsFilled(ListOfOrders_) Or AllowableDeviationOfMeasuringGoodsShipmentAndReceiving = 0 Then
		Table = New ValueTable;
		Table.Columns.Add("OrderDocument");
		Table.Columns.Add("Products");
		Table.Columns.Add("Characteristic");
		Table.Columns.Add("Series");
		Table.Columns.Add("AllowableVariance");
		Return Table;
	EndIf;
	
	If TypeOf(ListOfOrders_) = Type("DocumentRef.ByAssemblyDisassemblyOrder") Then
		ReferenceArray = New Array();
		ReferenceArray.Add(ListOfOrders_);
	Else
		ReferenceArray = ListOfOrders_;
	EndIf;
	
	Query = New Query(
		"SELECT
		|	GoodsToReceive.ByAssemblyDisassemblyOrder  AS OrderDocument,
		|	GoodsToReceive.Products   AS Products,
		|	GoodsToReceive.Characteristic AS Characteristic,
		|	GoodsToReceive.Series          AS Series,
		|	SUM(GoodsToReceive.ToRegisterReceipt
		|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
		|FROM
		|	AccumulationRegister.AssemblyOrders.Turnovers(&StartPeriod_, &ConPeriod,,
		|		ByAssemblyDisassemblyOrder IN (&ReferenceArray) AND AssemblyType = &AssemblyType) AS GoodsToReceive
		|WHERE
		|	GoodsToReceive.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
		|GROUP BY
		|	GoodsToReceive.ByAssemblyDisassemblyOrder,
		|	GoodsToReceive.Products,
		|	GoodsToReceive.Characteristic,
		|	GoodsToReceive.AssemblyType,
		|	GoodsToReceive.Series");
		
	Query.SetParameter("ReferenceArray", ReferenceArray);
	Query.SetParameter("AssemblyType", InventoryMovementType);
	Query.SetParameter("DimensionalTypesOfUnits",
		Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving);
	
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("AssemblyOrders",
		"ByAssemblyDisassemblyOrder IN (&ReferenceArray)", Query.Parameters);
	
	Query.SetParameter("StartPeriod_", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriod", SpeedLimits.MaxDate);
	
	Return Query.Execute().Unload();
	
EndFunction

#Region CalculationOfStates

// Returns the structure of parameters for calculating the order completion status in the list of orders.
//
// Returns:
//  Structure - contains the following keys:
//    * OrderBalancesModule         - AccumulationRegisterManager.AssemblyOrders -
//    * MonitorOrderClosing - Boolean -
//    * StatusInProcessOfAdmission   - EnumRef.StatusesOfInternalOrders -
//    * ShippingStatus      - EnumRef.StatusesOfInternalOrders -
//    * ReadyForShipmentStatus         - EnumRef.StatusesOfInternalOrders -
//
Function ParametersForCalculatingStates() Export
	
	Structure = New Structure();
	Structure.Insert("OrderBalancesModule", AccumulationRegisters.AssemblyOrders);
	Structure.Insert("MonitorOrderClosing",
		GetFunctionalOption("DoNotCloseAssemblyOrdersWithoutCompleteShipment"));
	Structure.Insert("StatusInProcessOfAdmission", Enums.StatusesOfInternalOrders.DuringAssemblyDisassembly);
	Structure.Insert("ShippingStatus", Enums.StatusesOfInternalOrders.DuringAssemblyDisassembly);
	Structure.Insert("ReadyForShipmentStatus", Enums.StatusesOfInternalOrders.ReadyForAssemblyDisassembly);
	
	Return Structure;
	
EndFunction

// Returns a structure containing the query texts of temporary tables for calculating the order completion status in the order list.
//
// Returns:
//  String - Query text
//
Function TemporaryDocumentTablesForCalculatingStates() Export
	
	QueryTextGoods =
		"SELECT
		|	Table.Ref AS Ref,
		|	Table.SupplyOption AS SupplyOption,
		|	TRUE AS ThisIsAProduct,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference
		|	
		|INTO TTDocumentProducts_
		|FROM
		|	Document.ByAssemblyDisassemblyOrder.Goods AS Table
		|WHERE
		|	Table.Ref IN(&AnArrayOfOrders)
		|		AND NOT Table.Canceled
		|		AND Table.Ref.Posted
		|		AND Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|
		|	UNION ALL
		|
		|SELECT
		|	Table.Ref AS Ref,
		|	Table.SupplyOption AS SupplyOption,
		|	TRUE AS ThisIsAProduct,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS Table
		|WHERE
		|	Table.Ref IN(&AnArrayOfOrders)
		|		AND Table.Count <> 0
		|		AND Table.Posted
		|		AND Table.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)";
	
	QueryTextAttributes =
		"SELECT
		|	Table.Ref            AS Ref,
		|	Table.Posted          AS Posted,
		|	
		|	TRUE                    AS ShippingStatus_,
		|	
		|	CASE WHEN Table.Status = VALUE(Enum.InternalOrderStatuses.Closed) THEN
		|				TRUE
		|			ELSE
		|				FALSE
		|		END                 AS TheClosedStatus,
		|	FALSE                      AS StatusUnderApproval
		|	
		|INTO TTDocumentDetails
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS Table
		|WHERE
		|	Table.Ref IN(&AnArrayOfOrders)";
	
	Result = New Structure("DocumentGoods, DocumentAttributes", QueryTextGoods, QueryTextAttributes);
	Return Result;
	
EndFunction

#EndRegion

// Generates a verification request when changing the status of the list of documents
//
// Parameters:
//	DocumentsArray - Array - An array of references to documents that should be reviewed
//	NewStatus - String - Name of the new status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.InternalOrderStatuses[NewStatus];
	
	If AdditionalParameters <> Undefined And AdditionalParameters.Property("OrderFulfillmentControl") Then
		
		QueryText =
		"SELECT
		|	Balance.ByAssemblyDisassemblyOrder AS ByAssemblyDisassemblyOrder
		|INTO TTOrderBalances_
		|FROM
		|	AccumulationRegister.AssemblyOrders.Balance(, ByAssemblyDisassemblyOrder IN (&DocumentsArray)) AS Balance
		|
		|INDEX BY
		|	Balance.ByAssemblyDisassemblyOrder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsForIssueBalance.DocumentShipments
		|INTO TTShipmentBalances
		|FROM
		|	AccumulationRegister.GoodsForIssue.Balance(, DocumentShipments IN (&DocumentsArray)) AS GoodsForIssueBalance
		|WHERE
		|	GoodsForIssueBalance.ToShipBalance + GoodsForIssueBalance.AssembledBalance > 0
		|
		|INDEX BY
		|	GoodsForIssueBalance.DocumentShipments
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsToReceiveBalance.DocumentInflow
		|INTO TTBalancesOnReceipt
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(, DocumentInflow IN (&DocumentsArray)) AS GoodsToReceiveBalance
		|
		|INDEX BY
		|	GoodsToReceiveBalance.DocumentInflow
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentsTable.Ref AS Ref,
		|	DocumentsTable.BusinessOperation AS BusinessOperation,
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
		|	TRUE AS Recording,
		//  If at least one register has residues, the work on the document is not completed
		|	CASE
		|			WHEN TTOrderBalances_.ByAssemblyDisassemblyOrder IS NULL 
		|				THEN FALSE
		|			ELSE TRUE
		|		END
		|		OR CASE
		|			WHEN TTShipmentBalances.DocumentShipments IS NULL 
		|				THEN FALSE
		|			ELSE TRUE
		|		END
		|		OR CASE
		|			WHEN TTBalancesOnReceipt.DocumentInflow IS NULL 
		|				THEN FALSE
		|			ELSE TRUE
		|		END AS ThereAreLeftoversOnOrder
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS DocumentsTable
		|		LEFT JOIN TTOrderBalances_ AS TTOrderBalances_
		|		ON DocumentsTable.Ref = TTOrderBalances_.ByAssemblyDisassemblyOrder
		|		LEFT JOIN TTShipmentBalances AS TTShipmentBalances
		|		ON DocumentsTable.Ref = TTShipmentBalances.DocumentShipments
		|		LEFT JOIN TTBalancesOnReceipt AS TTBalancesOnReceipt
		|		ON DocumentsTable.Ref = TTBalancesOnReceipt.DocumentInflow
		|WHERE
		|	DocumentsTable.Ref IN(&DocumentsArray)";
		
	Else
		
		QueryText =
		"SELECT
		|	DocumentsTable.Ref AS Ref,
		|	DocumentsTable.BusinessOperation AS BusinessOperation,
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
		|	Document.ByAssemblyDisassemblyOrder AS DocumentsTable
		|WHERE
		|	DocumentsTable.Ref IN(&DocumentsArray)
		|";
		
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes
//
// Parameters:
//	ValidationSample - QueryResultSelection - Current selection string
//	NewStatus - EnumRef.InternalOrderStatuses - New status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Cancel = False;
	
	If AdditionalParameters = Undefined Then
		
		Return Not Cancel;
		
	EndIf;
	
	If AdditionalParameters.Property("OrderFulfillmentControl") And ValidationSample.ThereAreLeftoversOnOrder Then
		
		ErrorText = NStr("vi = 'Trong chứng từ %Document% chưa đặt trạng thái ""%Status%"" vì đơn hàng cung ứng không đầy đủ';
						|ru = 'У документа %Document% статус ""%Status%"" не установлен, т.к. заказ выполнен не полностью';
						|en = 'Status ""%Status%"" is not set for document %Document% as the order is not fulfilled completely'; fa = 'Status ""%Status%"" is not set for document %Document% as the order is not fulfilled completely';
						|it = 'Lo stato ""%Status%"" del documento%Document% non è impostato, poiché l''ordine non è eseguito completamente';
						|pl = 'Dla dokumentu %Document% status ""%Status%"" nie jest ustawiony, ponieważ zamówienie jest wykonanie nie w całości';
						|tr = '%Document% belgenin ""%Status%"" durumu ayarlanmadı, çünkü sipariş tam olarak tamamlanmadı'");
		ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
		ErrorText = StrReplace(ErrorText, "%Status%", ValidationSample.PresentationOfNewStatus);
		CommonClientServer.MessageToUser(ErrorText, ValidationSample.Ref);
		Cancel = True;
		
	EndIf;
	
	If AdditionalParameters.Property("CancelUnfulfilledLines") Then
		
		IssuedSets = IssuedSets(ValidationSample.Ref);
		
		If IssuedSets = 0 Then
			
			ErrorText = NStr("vi = 'Chứng từ %Document% có trạng thái ""%Status%"" chưa được đặt, bởi vì';
							|ru = 'У документа %Document% статус ""%Status%"" не установлен, т.к.';
							|en = 'The ""%Status%"" status of the %Document% document is not set as'; fa = 'The ""%Status%"" status of the %Document% document is not set as';
							|it = 'Lo stato ""%Status%"" del documento %Document% non è impostato, poiché';
							|pl = 'Dla dokumentu %Document% status ""%Status%"" nie jest ustawiony, ponieważ';
							|tr = '%Document% belgesinin ""%Status%"" ayarlanmadı, çünkü'") + " ";
			
			If ValidationSample.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
				ErrorTextCompletion = NStr("vi = 'không xem xét tính năng hủy các bộ chưa xử lý đối với chứng từ mà theo đó chưa tập hợp một bộ nào.
					|Có thể hủy toàn bộ bằng cách hủy kết chuyển chứng từ.';
					|ru = 'не предусмотрена возможность отмены неотработанных комплектов для документа, по которому не собран ни один комплект.
					|Полная отмена сборки возможна путем распроведения документа.';
					|en = 'cancellation of unprocessed sets for the document for which no set is assembled is not available. 
					|It is possible to cancel kitting completely by unposting the document.'; fa = 'cancellation of unprocessed sets for the document for which no set is assembled is not available. 
					|It is possible to cancel kitting completely by unposting the document.';
					|it = 'non è prevista la possibilità di cancellare la serie dei documenti non elaborati per il documento per il quale non è stata composta alcuna serie.
					|La cancellazione completa del montaggio è possibile distribuendo il documento.';
					|pl = 'nie przewidziano możliwości anulowania nieodpracowanych zestawów dla dokumentu, według którego nie zebrano ani jednego zestawu.
					|Pełne anulowanie zbierania jest możliwe przez anulowanie zatwierdzenia dokumentu.';
					|tr = 'hiçbir bileşeni toplanmamış bir belge için işlenmeyen setleri iptal etmek mümkün değildir. 
					|Belgenin yeniden kaydedilmesi ile montajın tam olarak iptali mümkün.'");
			Else
				ErrorTextCompletion = NStr("vi = 'không xem xét tính năng hủy các bộ chưa xử lý đối với chứng từ mà theo đó chưa tách ra một bộ nào.
					|Có thể hủy bỏ tách bộ bằng cách hủy kết chuyển chứng từ.';
					|ru = 'не предусмотрена возможность отмены неотработанных комплектов для документа, по которому не разобран ни один комплект.
					|Полная отмена разборки возможна путем распроведения документа.';
					|en = 'cancellation of unprocessed sets for the document for which no set is disassembled is not available. 
					|It is possible to cancel reverse kitting completely by unposting the document.'; fa = 'cancellation of unprocessed sets for the document for which no set is disassembled is not available. 
					|It is possible to cancel reverse kitting completely by unposting the document.';
					|it = 'non è prevista la possibilità di cancellare la serie dei documenti non elaborati per il documento per il quale non è stata smontata alcuna serie.
					|La cancellazione completa dello smontaggio è possibile distribuendo il documento.';
					|pl = 'nie przewidziano możliwości anulowania nieodpracowanych zestawów dla dokumentu, według którego nie jest rozebrany ani jeden zestaw.
					|Pełne anulowanie rozebrania jest możliwe przez anulowanie zatwierdzenia dokumentu.';
					|tr = 'hiçbir bileşeni toplanmamış bir belge için işlenmeyen setleri iptal etmek mümkün değildir. 
					|Belgenin yeniden kaydedilmesi ile demontajın tam olarak iptali mümkün.'");
			EndIf;
				
			ErrorText = ErrorText + ErrorTextCompletion;
			
			ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
			ErrorText = StrReplace(ErrorText, "%Status%", ValidationSample.PresentationOfNewStatus);
			CommonClientServer.MessageToUser(ErrorText, ValidationSample.Ref);
			Cancel = True;
		EndIf;
		
	EndIf;
	
	Return Not Cancel;
	
EndFunction

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Warehouse,BusinessOperation,Date";
	
	Return AttributesNames;
EndFunction

// Returns parameters for specifying series for products specified in the document
//
// Parameters:
//  Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
Function SeriesSpecificationParameters(Object) Export
	
	Header = ProductsClientServer.SeriesSpecificationParameters();
	
	Header.FullObjectName = FullObjectName();
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		Header.UseItemsBatch  = False;
		Header.UseCostAccountingByBatches = False;
		Header.WarehouseTransactions.Add(Enums.WarehouseTransactions.EmptyRef());
	Else
		Header.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
		Header.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
		Header.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipSetsForDisassembly);
		Header.AdditionalFieldNames.Add("SupplyOption");
		Header.SeriesWhenPlanningShipmentVHFSeriesAreIndicated = True;
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents Then
		Header.LinkFields.Add("Purpose");
	EndIf;
	
	Header.ThisIsOrder = True;
	Header.ShipmentPlanning = True;
	Header.RegisterSeries = False;
	Header.ProductInHeader = True;
	Header.Date = Object.Date;
	
	TS = ProductsClientServer.SeriesSpecificationParameters();
	
	TS.FullObjectName = FullObjectName();
	TS.TSSeriesName = "Goods";
	
	If Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		TS.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
		TS.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
		TS.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipComponentsForAssembly);
	Else
		TS.UseItemsBatch  = False;
		TS.UseCostAccountingByBatches = False;
		TS.WarehouseTransactions.Add(Enums.WarehouseTransactions.EmptyRef());
	EndIf;	
	
	TS.ThisIsOrder = True;
	TS.ShipmentPlanning = True;
	TS.RegisterSeries = False;
	TS.ProductInHeader = False;
	TS.Date = Object.Date;
	
	SeriesSpecificationParameters = New Structure;
	
	SeriesSpecificationParameters.Insert("Header",Header);
	SeriesSpecificationParameters.Insert("TS",TS);	
	
	Return SeriesSpecificationParameters;

EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipComponentsForAssembly) <> Undefined Then
		QueryText = 
			"SELECT
			|	Goods.Products,
			|	Goods.Series,
			|	Goods.Canceled,
			|	Goods.SupplyOption,
			|	Goods.Count,
			|	Goods.BatchesIndicationStatus,
			|	Goods.LineNumber
			|INTO Goods
			|FROM
			|	&Goods AS Goods
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Goods.LineNumber AS LineNumber,
			|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
			|	CASE
			|		WHEN Goods.Canceled
			|				OR BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
			|				OR NOT Goods.SupplyOption IN (
			|						VALUE(Enum.SupplyOptions.FromWarehouse),
			|						VALUE(Enum.SupplyOptions.Ship))
			|			THEN 0
			|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
			|			THEN CASE
			|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
			|						THEN 14
			|					WHEN Goods.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
			|						THEN 15
			|					ELSE 13
			|				END
			|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
			|			THEN CASE
			|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
			|						THEN 10
			|					WHEN Goods.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
			|						THEN 11
			|					ELSE 9
			|				END
			|		ELSE 0
			|	END AS BatchesIndicationStatus
			|INTO Statuses
			|FROM
			|	Goods AS Goods
			|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
			|			INNER JOIN Catalog.Warehouses AS Warehouses
			|			ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
			|		ON (BatchAccountingPolicies.Warehouse = &Warehouse)
			|			AND CAST(Goods.Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Statuses.LineNumber AS LineNumber,
			|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus
			|FROM
			|	Statuses AS Statuses
			|WHERE
			|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
			|
			|ORDER BY
			|	LineNumber";
		Else
			QueryText = 
			"SELECT
			|	Goods.Products,
			|	Goods.Series,
			|	Goods.Canceled,
			|	Goods.Count,
			|	Goods.BatchesIndicationStatus,
			|	Goods.LineNumber,
			|	Goods.SupplyOption
			|INTO Goods
			|FROM
			|	&Goods AS Goods
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	SetOfSeries.Count
			|INTO SetOfSeries
			|FROM
			|	&SetOfSeries AS SetOfSeries
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	SUM(SetOfSeries.Count) AS Count
			|INTO SeriesSummary
			|FROM SetOfSeries AS SetOfSeries
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Goods.LineNumber AS LineNumber,
			|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
			|	CASE
			|		WHEN Goods.Canceled
			|				OR BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
			|				OR NOT Goods.SupplyOption IN (
			|						VALUE(Enum.SupplyOptions.FromWarehouse),
			|						VALUE(Enum.SupplyOptions.Ship))
			|			THEN 0
			|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
			|			THEN CASE
			|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
			|						THEN 14
			|					WHEN Goods.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
			|						THEN 15
			|					ELSE 13
			|				END
			|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
			|			THEN CASE
			|					WHEN Goods.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
			|							AND ISNULL(SetOfSeries.Count, 0) = 0
			|						THEN 11
			|					WHEN Goods.Count = ISNULL(SetOfSeries.Count, 0)
			|							AND Goods.Count > 0
			|						THEN 10
			|					ELSE 9
			|				END
			|		ELSE 0
			|	END AS BatchesIndicationStatus
			|INTO Statuses
			|FROM
			|	Goods AS Goods
			|		LEFT JOIN SeriesSummary AS SetOfSeries
			|			ON (TRUE)
			|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
			|			ON (BatchAccountingPolicies.Warehouse = &Warehouse)
			|			AND CAST(Goods.Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Statuses.LineNumber AS LineNumber,
			|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus
			|FROM
			|	Statuses AS Statuses
			|WHERE
			|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
			|
			|ORDER BY
			|	LineNumber";
		EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

// Returns whether the current user has the right to add a document
//
// Parameters:
//
// Returns:
//  Boolean - true if the current user has the right to add a document, false if there is no such right.
//
Function AccessRightInsert() Export
	
	Return AccessRight("Insert", Metadata.Documents.ByAssemblyDisassemblyOrder);
	
EndFunction

// Initializes the status structure of the document
//
// Returns:
//  Structure - contains the following keys:
//     * OutputTablesSupply         - Number -
//     * DisplayShipmentTables            - Number -
//     * DisplayReceiptTables         - Number -
//     * DisplayTablesCanceledShipment    - Number -
//     * DisplayTablesCanceledReceipt - Number -
//     * ThisIsOrder                           - Boolean -
//     * TextProductServiceShipment           - String -
//     * TextProductServiceReceipt        - String -
//     * NameOfServiceReceiptRegister        - String -
//     * StructureOfAdditionalRequests               - Structure - contains the following keys:
//        ** QueryTextTableUnsecuredGoods          - String -
//        ** QueryTextTableSupplyState          - String -
//        ** QueryTextTTProductsOrderShipped   - String -
//        ** QueryTextTTGoodsArrival                  - String -
//        ** QueryTextTTGoodsOrdersArrivalOrder - String -
//        ** QueryTextTableCanceledShipment              - String -
//        ** QueryTextTableCanceledReceipt           - String -
//
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	StructureState.Insert("OutputTablesSupply", 1);
	StructureState.Insert("DisplayShipmentTables", 2);
	StructureState.Insert("DisplayReceiptTables", 3);
	StructureState.Insert("DisplayTablesCanceledShipment", 4);
	StructureState.Insert("DisplayTablesCanceledReceipt", 5);
	StructureState.Insert("ThisIsOrder", True);
	StructureState.Insert("TextProductServiceShipment", NStr("vi = 'Hàng hóa';
															|ru = 'Товар';
															|en = 'Product'; fa = 'کالا';
															|it = 'Merce';
															|pl = 'Product';
															|tr = 'Ürün'"));
	StructureState.Insert("TextProductServiceReceipt", NStr("vi = 'Hàng hóa';
															|ru = 'Товар';
															|en = 'Product'; fa = 'کالا';
															|it = 'Merce';
															|pl = 'Product';
															|tr = 'Ürün'"));
	StructureState.Insert("NameOfServiceReceiptRegister", "AssemblyOrders");
	
	TableUnsecuredGoods = TableUnsecuredGoodsForStateOfExecutionReport();
	TableStateOfProvision = SoftwareStateTableForExecutionStateReport();
	TTProductsOrderShipped = TemporaryTableProductsOrderOrderShippedForStateOfExecutionReport();
	TTGoodsArrival = TemporaryGoodsReceiptTableForProgressStateReport();
	TTGoodsOrdersArrivalOrder = TemporaryTableProductsOrdersReceiptOrderForStateOfCompletionReport();
	TableCanceledShipment = CanceledShipmentTableForProgressStateReport();
	TableCanceledReceipt = CanceledReceiptTableForProgressStateReport();
	
	StructureOfAdditionalRequests = New Structure();
	StructureOfAdditionalRequests.Insert("QueryTextTableUnsecuredGoods",          TableUnsecuredGoods);
	StructureOfAdditionalRequests.Insert("QueryTextTableSupplyState",          TableStateOfProvision);
	StructureOfAdditionalRequests.Insert("QueryTextTTProductsOrderShipped",   TTProductsOrderShipped);
	StructureOfAdditionalRequests.Insert("QueryTextTTGoodsArrival",                  TTGoodsArrival);
	StructureOfAdditionalRequests.Insert("QueryTextTTGoodsOrdersArrivalOrder", TTGoodsOrdersArrivalOrder);
	StructureOfAdditionalRequests.Insert("QueryTextTableCanceledShipment",              TableCanceledShipment);
	StructureOfAdditionalRequests.Insert("QueryTextTableCanceledReceipt",           TableCanceledReceipt);
	StructureState.Insert("StructureOfAdditionalRequests", StructureOfAdditionalRequests);
	
	Return StructureState;
	
EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Own);
	// The need for kits in stock.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Purpose", "Kits");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Warehouse";
	
	// Needs for components in stock.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose", "Components");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Warehouse";
	
	Return FormTemplate;
	
EndFunction

// Forms the structure of the document parameters for embedding the document in the software algorithms.
// Parameters:
//  DocumentObject - DocumentObject.ByAssemblyDisassemblyOrder - Document
// Returns:
//  See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions
//
Function AvailableRemainingEmbeddingOptions(DocumentObject) Export
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		Return AvailableBasicEmbeddingOptions();
	Else
		Return AvailableLeftoversEmbeddingOptionsDisassembly();
	EndIf;
	
EndFunction

// Document parameters for the mechanism of filling in the Attributes of the controlled party in the document.
// 
// Parameters:
//  ObjectOrRef - DocumentObject.ByAssemblyDisassemblyOrder, DocumentRef.ByAssemblyDisassemblyOrder - Document.
//  FieldNameControlledLotReference - String - field name, controlled Lot reference.
// 
// Returns:
//  See QualityControl.NewAttributesOfControlledLotReference
Function AttributesOfControlledLotReference(ObjectOrRef, FieldNameControlledLotReference) Export
	
	Attributes = QualityControl.NewAttributesOfControlledLotReference();
	ObjectAttributes = QualityControl.AttributesOfItemOrLink(ObjectOrRef,
		"Ref,
		|Warehouse,
		|Date,
		|Number,
		|BusinessOperation,
		|LineOfBusiness,
		|Organization,
		|Department");
		
	Attributes.Lot = ObjectAttributes.Ref;
	Attributes.ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Attributes.LineOfBusiness = ObjectAttributes.LineOfBusiness;
	Attributes.ReceiptDocumentNumber = ObjectAttributes.Number;
	Attributes.DateOfReceiptDocument = ObjectAttributes.Date;
	Attributes.Organization = ObjectAttributes.Organization;
	Attributes.Department = ObjectAttributes.Department;
	
	// The Attributes for Registering Records according to the Accumulation register "Goods for receipt", when the Lot reference is known, for example, for return
	// without registration in the document "Quality control Act". The logic of filling in the fields is synchronized with the Registered Records of the current
	// document, as an order in "Goods for receipt".
	Attributes.Sender = ObjectAttributes.Warehouse;
	Attributes.BusinessOperation = ObjectAttributes.BusinessOperation;
	
	Return Attributes;
	
EndFunction

// Document parameters for the Attribute filling mechanism to check the quality and data confirmation of the quality
// in the document.
// 
// Parameters:
//  Object - DocumentObject.ByAssemblyDisassemblyOrder - Object.
// 
// Returns:
//  Structure - structure with fields:
//   * FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   * Key - String - An identifier used when there are two or more data sources to fill in in the same object. 
Function QualityControlActionParameters(Object) Export
	
	AllParameters = New Array();
	
	// Items.
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "Goods");
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	
	ActionParameters.ReadableFields = "Products,Canceled";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	ActionParameters.QueryOptions.Insert("WarehouseQualityControl", Object.Warehouse);
	ActionParameters.QueryOptions.QualityControlDateOfReceipt = Object.AssemblyDisassemblyEnd;
	ActionParameters.QueryOptions.Insert("QualityControlBusinessTransaction", Object.BusinessOperation);
	
	ActionParameters.QueryTextDocumentData =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	Table.Products AS Products,
		|	&WarehouseQualityControl AS Warehouse,
		|	UNDEFINED AS Contract,
		|	&QualityControlDateOfReceipt AS DateOfReceipt,
		|	FALSE AS Set,
		|	&QualityControlBusinessTransaction = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|		OR Table.Canceled AS Reset
		|INTO DataOfDocumentToBeFilledInCheckQualityDateOfQualityConfirmation
		|FROM
		|	#DataSource AS Table
		|INDEX BY
		|	Products,Warehouse,Contract";
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	AllParameters.Add(New Structure("Key,Parameters", "Goods", Action_Parameters));
	
	// Hat.
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "Header");
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	
	ActionParameters.ReadableFields = "Products,Warehouse";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	ActionParameters.QueryOptions.Insert("WarehouseQualityControl", Object.Warehouse);
	ActionParameters.QueryOptions.QualityControlDateOfReceipt = Object.AssemblyDisassemblyEnd;
	ActionParameters.QueryOptions.Insert("QualityControlBusinessTransaction", Object.BusinessOperation);
	
	ActionParameters.QueryTextDocumentData =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	Table.Products AS Products,
		|	&WarehouseQualityControl AS Warehouse,
		|	UNDEFINED AS Contract,
		|	&QualityControlDateOfReceipt AS DateOfReceipt,
		|	FALSE AS Set,
		|	&QualityControlBusinessTransaction = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents) AS Reset
		|INTO DataOfDocumentToBeFilledInCheckQualityDateOfQualityConfirmation
		|FROM
		|	#DataSource AS Table
		|INDEX BY
		|	Products,Warehouse,Contract";
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	AllParameters.Add(New Structure("Key,Parameters", "Header", Action_Parameters));
	
	Return New FixedArray(AllParameters);
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Warehouse)";

EndProcedure

// End StandardSubsystems.AccessManagement

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

#Region KitConfigurations

// Initializes the parameters for verifying the correctness of the set.
//
// Parameters:
//	Object - DocumentObject.ByAssemblyDisassemblyOrder,
//				This Formstructure is a document for which it is necessary to obtain the parameters of the kit verification.
//
// Returns:
//	Structure - See AccountingForTraceableGoodsLocalization.SetValidationParameters.
//
Function SetValidationParameters(Object) Export
	
	CheckParameters = AccountingForTraceableGoodsLocalization.SetValidationParameters();
	FillPropertyValues(CheckParameters, Object);
	FillPropertyValues(CheckParameters, Object.ProductKit,
		"ProductsOfMainComponent, MainComponentCharacteristic");
	
	CheckParameters.KitAssembly
		= Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents;
	
	CheckParameters.ToControl
		= Object.ProductKit <> Catalogs.ProductKitConfigurations.EmptyRef();
	
	CheckParameters.ThisIsConfigurationOrder = True;
	CheckParameters.OptionForPresentationOfSetInPrintedFormsInHeader = False;
	
	Return CheckParameters;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Internal

#Region Supply

// Returns a table for the goods of the document for the creation mechanism based on the securing order.
//
// Parameters:
//  Ref - DocumentRef.ByAssemblyDisassemblyOrder - the document for which you need to get the goods
//  CreationParameters - See ProvisionInDocumentsServer.ProductSelectionParametersForCreatingSecuringOrder
//  TempTablesManager - TempTablesManager - temporary table manager where a table with columns will be created:
//   * LineNumber - Number - Line number
//   * Products - CatalogRef.Products - Products
//   * Characteristic - CatalogRef.ItemsCharacteristics - Characteristic
//   * Package - CatalogRef.PackagesAndUnitsOfMeasure - Package
//   * Warehouse - CatalogRef.Warehouses - Warehouse
//   * Department - CatalogRef.BusinessStructure - Department
//   * Purpose - CatalogRef.Assignments - Purpose
//   * SupplyOption - EnumRef.SupplyOptions - security option
//   * WithAssignment - Boolean - WithAssignment
//   * QuantityOfUnits - Number - number of units
//   * CountByDocument - Number - Number of packages
Procedure GoodsOfDocumentForCreatingSecuringOrder(Ref, CreationParameters, TempTablesManager) Export

	Attributes = Common.ObjectAttributesValues(Ref, "Status,Posted,BusinessOperation");

	TMCommonUse.CheckPossibilityOfEnteringBasedOn(Ref, Attributes.Status, Not Attributes.Posted);

	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("ItemsTypes", CreationParameters.ItemsTypes);
	Query.SetParameter("Ref", Ref);
	If Attributes.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		Query.Text =
		"SELECT
		|	Goods.LineNumber AS LineNumber,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Package AS Package,
		|	Goods.Ref.Warehouse AS Warehouse,
		|	Goods.Ref.Department AS Department,
		|	CASE
		|		WHEN Goods.WithAssignment
		|			THEN
		|				CASE
		|					WHEN Goods.Ref.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|							AND NOT Goods.Ref.AssignByOrderAssignment
		|						THEN Goods.Ref.Purpose
		|					ELSE Goods.Ref.AssignmentGoods
		|				END
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	Goods.SupplyOption AS SupplyOption,
		|	Goods.WithAssignment AS WithAssignment,
		|	Goods.Ref.AssemblyDisassemblyStart AS DateOfShipment,
		|	Goods.Count AS NumberOfUnitsPerDocument,
		|	Goods.NumberOfPackages AS CountByDocument
		|INTO DocumentGoods
		|FROM
		|	Document.ByAssemblyDisassemblyOrder.Goods AS Goods
		|WHERE
		|	Goods.Ref = &Ref
		|		AND NOT Goods.Canceled
		|		AND Goods.Products.ItemsType IN(&ItemsTypes)";
	Else
		Query.Text =
		"SELECT
		|	1 AS LineNumber,
		|	Attributes.Products AS Products,
		|	Attributes.Characteristic AS Characteristic,
		|	Attributes.Package AS Package,
		|	Attributes.Warehouse AS Warehouse,
		|	Attributes.Department AS Department,
		|	CASE
		|		WHEN Attributes.WithAssignment
		|			THEN
		|				CASE
		|					WHEN Attributes.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|							AND NOT Attributes.AssignByOrderAssignment
		|						THEN Attributes.Purpose
		|					ELSE Attributes.AssignmentGoods
		|				END
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	Attributes.SupplyOption AS SupplyOption,
		|	Attributes.WithAssignment AS WithAssignment,
		|	Attributes.AssemblyDisassemblyStart AS DateOfShipment,
		|	Attributes.Count AS NumberOfUnitsPerDocument,
		|	Attributes.NumberOfPackages AS CountByDocument
		|INTO DocumentGoods
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS Attributes
		|WHERE
		|	Ref = &Ref
		|		AND Attributes.Products.ItemsType IN(&ItemsTypes)";
	EndIf;

	Query.Execute();
	
EndProcedure

// The function of embedding in the provision mechanism. It is necessary to add this function to the manager module
// to embed the commands for setting the order actions of the form "Reserve in stock", "To ensure"
// , etc. in the list of documents. If the list of documents (orders) of the same type needs to use different
// embedding parameters, depending on the values of the Attributes of a particular document.
// In this case
// , the Client documentation method is used in processing commands.Perform action on a list of different types of orders.
// 
// Parameters:
//  AllOrders - Array of DocumentRef.ByAssemblyDisassemblyOrder
//  ActionCode - String - the conditional designation of the executed command: "ACTION_LOAD", "ACTION_RESERVATION", etc.
// Returns:
//  See ProvisionInDocumentsServer.NewParametersForExecutingCommandsAndSettingActions
Function ParametersForExecutingCommandsAndActions(AllOrders, ActionCode) Export
	
	Query = New Query();
	Query.SetParameter("Orders", AllOrders);
	Query.Text =
		"SELECT
		|	Orders.Ref AS Ref
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS Orders
		|WHERE
		|	Orders.Ref IN(&Orders)
		|		AND Orders.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|;
		|SELECT
		|	Orders.Ref AS Ref
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS Orders
		|WHERE
		|	Orders.Ref IN(&Orders)
		|		AND Orders.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)";
	QueryResult = Query.ExecuteBatch();
	Results = New Array();
	
	Result = ProvisionInDocumentsServer.StructureOrdersAndEmbeddingParameters();
	Result.Orders = QueryResult[0].Unload().UnloadColumn("Ref");
	Result.EmbeddingParameters = AvailableBasicEmbeddingOptions();
	Results.Add(Result);
	
	Result = ProvisionInDocumentsServer.StructureOrdersAndEmbeddingParameters();
	Result.Orders = QueryResult[1].Unload().UnloadColumn("Ref");
	Result.EmbeddingParameters = AvailableLeftoversEmbeddingOptionsDisassembly();
	Results.Add(Result);
	
	Result = ProvisionInDocumentsServer.NewParametersForExecutingCommandsAndSettingActions();
	Result.ActionCode = ActionCode;
	Result.ExecutionParameters = Results;
	
	Return Result;
	
EndFunction

// Returns the number of assembled (disassembled) sets for the passed order
//
// Parameters:
//  Object - DocumentObject.ByAssemblyDisassemblyOrder, DocumentRef.ByAssemblyDisassemblyOrder -
//
// Returns:
//  Number -
//
Function IssuedSets(Object) Export

	FilterIssued_1 = New ValueTable();
	FilterIssued_1.Columns.Add("RowCode", New TypeDescription("Number"));
	FilterIssued_1.Columns.Add("Ref", New TypeDescription("DocumentRef.ByAssemblyDisassemblyOrder"));
	
	CollectionLine = FilterIssued_1.Add();
	CollectionLine.Ref = Object.Ref;
	CollectionLine.RowCode = 1;
	
	HeaderTable = New ValueTable();
	HeaderTable.Columns.Add("Products",   New TypeDescription("CatalogRef.Products"));
	HeaderTable.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	HeaderTable.Columns.Add("Warehouse",          New TypeDescription("CatalogRef.Warehouses"));
	HeaderTable.Columns.Add("Purpose",     New TypeDescription("CatalogRef.Assignments"));
	HeaderTable.Columns.Add("Series",          New TypeDescription("CatalogRef.ItemsBatches"));
	HeaderTable.Columns.Add("Ref",         New TypeDescription("DocumentRef.ByAssemblyDisassemblyOrder"));
	
	Adjusting = HeaderTable.Copy(); // an empty table part for Transferring to registers
	Adjusting.Columns.Add("ToReceive",  New TypeDescription("Number"));
	Adjusting.Columns.Add("ToShip",      New TypeDescription("Number"));
	
	ConsiderPurpose = ValueIsFilled(Object.Purpose) 
	And Common.ObjectAttributeValue(Object.Purpose, "RecordsInWarehouseRegisters") = True;
	
	If Object.BatchesIndicationStatus = 14 Then
		HeaderString = HeaderTable.Add();
		FillPropertyValues(HeaderString, Object);
		HeaderString.Purpose = ?(ConsiderPurpose, Object.Purpose, Catalogs.Assignments.EmptyRef());
	Else
		// Statuscazationseries = 10
		// The tabular part of the Series is used.

		For Each String In Object.SetOfSeries Do
			HeaderString = HeaderTable.Add();
			FillPropertyValues(HeaderString, String, "Products, Characteristic, Series, Purpose");
			FillPropertyValues(HeaderString, Object, "Warehouse, Ref");
		EndDo;
		
	EndIf;
	
	Filter = New Structure;
	If Object.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents Then
		Filter.Insert("AssemblyType", Enums.InventoryMovementTypes.Shipment);
		IssueSetsOfInvoices = AccumulationRegisters.AssemblyOrders.TableDecorated(FilterIssued_1, Filter);
		IssueSetsByOrders = AccumulationRegisters.GoodsForIssue.TableDecorated(HeaderTable, Adjusting);
	Else
		Filter.Insert("AssemblyType", Enums.InventoryMovementTypes.Inpayment);
		IssueSetsOfInvoices = AccumulationRegisters.AssemblyOrders.TableDecorated(FilterIssued_1, Filter);
		IssueSetsByOrders = AccumulationRegisters.GoodsToReceive.TableDecorated(HeaderTable, Adjusting);
	EndIf;
	
	IssueSetsOfInvoices.GroupBy(, "Count");
	IssueSetsByOrders.GroupBy(, "Count");
	IssuedSets = Max(IssueSetsOfInvoices.Total("Count"), IssueSetsByOrders.Total("Count"));
	
	Return IssuedSets;

EndFunction

// Performs additional actions related to filling in the security in the document.
// Parameters:
//  Object - FormDataStructure, DocumentObject.ByAssemblyDisassemblyOrder - The document in which the security was filled in.
//  Changes - ValueTable - Table of changes to the document after filling in the security.
//  Mode - String - The mode that defines the software filling contest.
//  FillParameters - Structure - Fill-in parameters.
Procedure AfterFillingOutCollateral(Object, Changes, Mode, FillParameters) Export
	
	If Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
	
		If ProvisionInDocumentsClientServer.YouNeedToCheckFillInShipmentDateForShipLines(Mode) Then
			FillInBeginningEndOfBuildDuringInstallationShipOrReserve(Object, Changes);
		EndIf;
		
		SeriesSpecificationParameters = SeriesSpecificationParameters(Object);
		ProvisionInDocumentsServer.RecalculateNumberOfUnits(Changes, Object.Goods);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.TS);
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents Then
		
		If ProvisionInDocumentsClientServer.YouNeedToCheckFillInShipmentDateForShipLines(Mode) Then
			
			If Not ValueIsFilled(Object.AssemblyDisassemblyStart) Then
				
				DateOfReceiptCalculated = Max(
					BegOfDay(CurrentSessionDate()) + 86400 * Object.AssemblyDisassemblyDurationDays,
					Object.RequestedDeliveryDate);
				
				If Object.SupplyOption = Enums.SupplyOptions.Ship
						Or Object.SupplyOption = Enums.SupplyOptions.FromWarehouse Then
						
						Object.AssemblyDisassemblyStart = DateOfReceiptCalculated - 86400 * Object.AssemblyDisassemblyDurationDays;
						Object.AssemblyDisassemblyEnd = DateOfReceiptCalculated;
						
				EndIf;
				
			Else
				
				If Object.SupplyOption = Enums.SupplyOptions.Ship Then
					
					Object.AssemblyDisassemblyEnd = Object.AssemblyDisassemblyStart + 86400 * Object.AssemblyDisassemblyDurationDays;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		SeriesSpecificationParameters = SeriesSpecificationParameters(Object);
		PackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Object.Package, Object.Products);
		If Not ValueIsFilled(PackagingFactor) Then
			PackagingFactor = 1;
		EndIf;
		Object.Count = Object.NumberOfPackages * PackagingFactor;
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Header);
		
	EndIf;
	
EndProcedure

// Parameters:
//  Object - DocumentObject.ByAssemblyDisassemblyOrder
//  Changes - ValueTable - table with fields:
//   * SupplyOption - EnumRef.SupplyOptions - installable software option
Procedure FillInBeginningEndOfBuildDuringInstallationShipOrReserve(Object, Changes) Export
	
	If Not ValueIsFilled(Object.AssemblyDisassemblyStart) Then
		
		DateOfReceiptCalculated = Max(
			BegOfDay(CurrentSessionDate()) + 86400 * Object.AssemblyDisassemblyDurationDays,
			Object.RequestedDeliveryDate);
		
		For Each String In Changes Do
			
			If String.SupplyOption = Enums.SupplyOptions.Ship
					Or String.SupplyOption = Enums.SupplyOptions.FromWarehouse Then
				
				Object.AssemblyDisassemblyStart = DateOfReceiptCalculated - 86400 * Object.AssemblyDisassemblyDurationDays;
				Object.AssemblyDisassemblyEnd = DateOfReceiptCalculated;
				Break;
				
			EndIf;
			
		EndDo;
		
	Else
		
		For Each String In Changes Do
			
			If String.SupplyOption = Enums.SupplyOptions.Ship Then
				
				Object.AssemblyDisassemblyEnd = Object.AssemblyDisassemblyStart + 86400 * Object.AssemblyDisassemblyDurationDays;
				Break;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region LinesOfBusiness

// Parameters:
//  Form - ClientApplicationForm - the form of the document.
//	Returns:
//   See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity.
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.FillInAssignmentInHeader = True;
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "Goods";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("Goods", TableOfConditions);
	
	Return DocumentProcessingProcedure;
	
EndFunction

#EndRegion

#EndRegion

// Parameters:
//  OrderDocument - DocumentRef.ByAssemblyDisassemblyOrder -order.
// Returns:
//  CatalogRef.Assignments - purpose.
Function OrderAssignment(OrderDocument) Export
	
	SetPrivilegedMode(True);
	Query = New Query();
	Query.Text =
		"SELECT
		|	CASE WHEN Orders.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents) THEN
		|				CASE WHEN Orders.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|								OR Orders.AssignByOrderAssignment THEN
		|							Orders.AssignmentGoods
		|						ELSE
		|							Orders.Purpose
		|					END
		|			ELSE
		|				Orders.Purpose
		|		END AS Purpose
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS Orders
		|WHERE
		|	Orders.Ref = &OrderDocument";
	Query.SetParameter("OrderDocument", OrderDocument);
	
	Selection = Query.Execute().Select();
	
	Result = Undefined;
	If Selection.Next() Then
		Result = Selection.Purpose;
	EndIf;
	
	Return Result;
	
EndFunction

#Region Posting

Procedure FillInInitializationParameters(Query, DocumentRef)

	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	
	Query.Text =
	"SELECT
	|	HeaderData_.Status AS Status,
	|	HeaderData_.Date AS Period,
	|	HeaderData_.Warehouse AS Warehouse,
	|	HeaderData_.BusinessOperation AS BusinessOperation,
	|	CASE
	|		WHEN HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AssemblyOfComponents,
	|	HeaderData_.AssemblyDisassemblyStart AS AssemblyDisassemblyStart,
	|	HeaderData_.AssemblyDisassemblyEnd AS AssemblyDisassemblyEnd,
	|	HeaderData_.Purpose AS DestinationHeader_,
	|	HeaderData_.AssignmentGoods AS AssignmentGoods,
	|	HeaderData_.Organization AS Organization,
	|	HeaderData_.Department AS Department,
	|	HeaderData_.LineOfBusiness AS LineOfBusiness,
	|	HeaderData_.Priority AS Priority,
	|	HeaderData_.Number AS Number,
	|	HeaderData_.EmployeeResponsible AS EmployeeResponsible,
	|	HeaderData_.Author AS Author,
	|	HeaderData_.Comment AS Comment,
	|	HeaderData_.Posted AS Posted,
	|	HeaderData_.DeletionMark AS DeletionMark,
	|	HeaderData_.AssignByOrderAssignment AS AssignByOrderAssignment,
	|	ISNULL(HeaderData_.Purpose.RecordsInWarehouseRegisters, FALSE) AS TrafficOnWarehouseRegistersHeader,
	|	ISNULL(HeaderData_.AssignmentGoods.RecordsInWarehouseRegisters, FALSE) AS RegisteredRecordsOnWarehouseRegistersDestinationGoods,
	|	CASE
	|		WHEN HeaderData_.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND HeaderData_.AssemblyDisassemblyStart >= HeaderData_.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdvancedWarehousingOnShipment,
	|	CASE
	|		WHEN HeaderData_.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND HeaderData_.Date >= HeaderData_.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdvancedWarehousingOnGoodsReceipt,
	|	HeaderData_.GoodsReceiptOption AS GoodsReceiptOption,
	|	TRUE IN (
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				Document.ByAssemblyDisassemblyOrder.Goods AS Components
	|			WHERE
	|				Components.Ref = HeaderData_.Ref
	|				AND NOT Components.Canceled
	|				AND Components.SupplyOption = VALUE(Enum.SupplyOptions.Ship)) AS AccessoriesForShipment
	|FROM
	|	Document.ByAssemblyDisassemblyOrder AS HeaderData_
	|WHERE
	|	HeaderData_.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	InvoiceIsOrder = PurchasesServer.OrderForAcceptanceOfGoodsConsignmentNote(Attributes.GoodsReceiptOption);
	
	Query.SetParameter("InvoiceIsOrder", InvoiceIsOrder);
	Query.SetParameter("NumberForPrinting",                  ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("MetadataIdentifier",        Common.MetadataObjectID(TypeOf(DocumentRef)));
	
EndProcedure

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure ScheduleGoodsReceipt(Query, QueryTexts, Registers)
	
	// Assembly of the kit.
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref                                AS Ref,
	|	UNDEFINED                                        AS Invoice,
	|	FALSE                                                AS Patch,
	|	UNDEFINED                                        AS CorrectedDocument,
	|	GoodsTable.Ref                                AS OrderDocument,
	|	GoodsTable.AssemblyDisassemblyEnd               AS Date,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	UNDEFINED                                        AS Terms,
	|	GoodsTable.GoodsReceiptOption                 AS GoodsReceiptOption,
	|	GoodsTable.Warehouse                                 AS Warehouse,
	|	GoodsTable.Warehouse                                 AS Sender,
	|	GoodsTable.BusinessOperation                 AS BusinessOperation,
	|	GoodsTable.Products                          AS Products,
	|	GoodsTable.Characteristic                        AS Characteristic,
	|	GoodsTable.Purpose                            AS Purpose,
	|	GoodsTable.ToControlQuality             AS ToControlQuality,
	|	FALSE                                                AS RecordOfAPreviouslyReceivedLot,
	|	UNDEFINED                                        AS ControlledLotReference,
	|	0                                                   AS BatchesIndicationStatus,
	|	FALSE                                                AS ExceedingOrder,
	|	UNDEFINED                                        AS Series,
	|	GoodsTable.Count                            AS Count,
	|	FALSE                                                AS ReceiptUnderOrders,
	|	FALSE                                                AS ThisIsAnInvoice
	|FROM
	|	Document.ByAssemblyDisassemblyOrder AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN (&Ref)
	|		AND GoodsTable.Count > 0
	|		AND GoodsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
	|		AND GoodsTable.Status IN(
	|			VALUE(Enum.InternalOrderStatuses.ForCompletion),
	|			VALUE(Enum.InternalOrderStatuses.Closed))";	
	
	WarehousesServer.ScheduleGoodsReceipt(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		"GoodsTable");
	
	// Disassembly for components.
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref                                AS Ref,
	|	UNDEFINED                                        AS Invoice,
	|	FALSE                                                AS Patch,
	|	UNDEFINED                                        AS CorrectedDocument,
	|	GoodsTable.Ref                                AS OrderDocument,
	|	GoodsTable.Ref.AssemblyDisassemblyEnd        AS Date,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	UNDEFINED                                        AS Terms,
	|	GoodsTable.Ref.GoodsReceiptOption          AS GoodsReceiptOption,
	|	GoodsTable.Ref.Warehouse                          AS Warehouse,
	|	GoodsTable.Ref.Warehouse                          AS Sender,
	|	GoodsTable.Ref.BusinessOperation          AS BusinessOperation,
	|	GoodsTable.Products                          AS Products,
	|	GoodsTable.Characteristic                        AS Characteristic,
	|	GoodsTable.Purpose                            AS Purpose,
	|	GoodsTable.ToControlQuality             AS ToControlQuality,
	|	FALSE                                                AS RecordOfAPreviouslyReceivedLot,
	|	UNDEFINED                                        AS ControlledLotReference,
	|	0                                                   AS BatchesIndicationStatus,
	|	FALSE                                                AS ExceedingOrder,
	|	UNDEFINED                                        AS Series,
	|	GoodsTable.Count                            AS Count,
	|	FALSE                                                AS ReceiptUnderOrders,
	|	FALSE                                                AS ThisIsAnInvoice
	|FROM
	|	Document.ByAssemblyDisassemblyOrder.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|		AND NOT GoodsTable.Canceled
	|		AND GoodsTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
	|		AND GoodsTable.Ref.Status IN(
	|			VALUE(Enum.InternalOrderStatuses.ForCompletion),
	|			VALUE(Enum.InternalOrderStatuses.Closed))";	
	
	WarehousesServer.ScheduleGoodsReceipt(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		"GoodsTable");
	
EndProcedure

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		// Assembly
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.Warehouse AS Warehouse,
		|	CASE
		|		WHEN TabPart.WithAssignment
		|			THEN CASE
		|				WHEN TabPart.Ref.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|				OR TabPart.Ref.AssignByOrderAssignment
		|					THEN TabPart.Ref.AssignmentGoods
		|				ELSE TabPart.Ref.Purpose
		|			END
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	TabPart.Ref AS PlannedConsumptionOfDistributedStock,
		|	TRUE AS ControlOfFreeResidue
		|FROM
		|	Document.ByAssemblyDisassemblyOrder.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|		AND NOT TabPart.Canceled
		|		AND TabPart.Ref.Status IN(
		|			VALUE(Enum.InternalOrderStatuses.ForCompletion),
		|			VALUE(Enum.InternalOrderStatuses.Closed))
		|		AND TabPart.SupplyOption = VALUE(Enum.SupplyOptions.Ship)";
		
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
	QueryTextTabPart =
		// Disassembly
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	CASE
		|		WHEN TabPart.WithAssignment
		|			THEN TabPart.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	TabPart.Ref AS PlannedConsumptionOfDistributedStock,
		|	TRUE AS ControlOfFreeResidue
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS TabPart
		|WHERE
		|	TabPart.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
		|		AND TabPart.Count > 0
		|		AND TabPart.Status IN(
		|			VALUE(Enum.InternalOrderStatuses.ForCompletion),
		|			VALUE(Enum.InternalOrderStatuses.Closed))
		|		AND TabPart.SupplyOption = VALUE(Enum.SupplyOptions.Ship)";
		
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
	QueryTextTabPart =
		// Assembly
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.Warehouse AS Warehouse,
		|	CASE
		|		WHEN TabPart.WithAssignment
		|			THEN CASE
		|				WHEN TabPart.Ref.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|				OR TabPart.Ref.AssignByOrderAssignment
		|					THEN TabPart.Ref.AssignmentGoods
		|				ELSE TabPart.Ref.Purpose
		|			END
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	TabPart.SupplyOption AS SupplyOption,
		|	TabPart.Ref AS OrderDocument,
		|	TabPart.Ref.AssemblyDisassemblyStart AS RequestShipmentOn,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule,
		|	0 AS QuantityInGraph
		|FROM
		|	Document.ByAssemblyDisassemblyOrder.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|	AND NOT TabPart.Canceled
		|	AND TabPart.SupplyOption <> VALUE(Enum.SupplyOptions.Ship)";
	
	StockAllocationRecords.PlanStockConsumption(
		Query,
		QueryTexts,
		Registers,
		QueryTextTabPart,
		False);
	
	QueryTextTabPart =
		// Disassembly
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	CASE
		|		WHEN TabPart.WithAssignment
		|			THEN TabPart.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	TabPart.SupplyOption AS SupplyOption,
		|	TabPart.Ref AS OrderDocument,
		|	TabPart.AssemblyDisassemblyStart AS RequestShipmentOn,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule,
		|	0 AS QuantityInGraph
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS TabPart
		|WHERE
		|	TabPart.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
		|	AND TabPart.Count > 0
		|	AND TabPart.SupplyOption <> VALUE(Enum.SupplyOptions.Ship)";
	
	StockAllocationRecords.PlanStockConsumption(
		Query,
		QueryTexts,
		Registers,
		QueryTextTabPart,
		False);
	
	QueryTextTabPart =
		// Assembling.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.ToControlQuality AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	TabPart.Ref AS OrderDocument,
		|	TabPart.AssemblyDisassemblyEnd AS DateOfReceipt,
		|	TRUE AS AvailableForConsumption,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule,
		|	0 AS QuantityInGraph
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS TabPart
		|WHERE
		|	TabPart.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|	AND TabPart.Count > 0";
	
	StockAllocationRecords.ScheduleStockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
	QueryTextTabPart =
		// Disassembly.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.ToControlQuality AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	TabPart.Ref AS OrderDocument,
		|	TabPart.Ref.AssemblyDisassemblyEnd AS DateOfReceipt,
		|	TRUE AS AvailableForConsumption,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule,
		|	0 AS QuantityInGraph
		|FROM
		|	Document.ByAssemblyDisassemblyOrder.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
		|	AND NOT TabPart.Canceled";
	
	StockAllocationRecords.ScheduleStockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
EndProcedure

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref AS Ref,
	|	&Period AS IBDocumentDate,
	|	&Number AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization AS Organization,
	|	&BusinessOperation AS BusinessOperation,
	|	VALUE(Catalog.Partners.EmptyRef) AS Partner,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|	&LineOfBusiness AS LineOfBusiness,
	|	&Warehouse AS StorageLocation,
	|	&Department AS Department,
	|	&EmployeeResponsible AS EmployeeResponsible,
	|	&Author AS Author,
	|	&Comment AS Comment,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	0 AS Sum,
	|	&Status AS Status,
	|	&Posted AS Posted,
	|	&DeletionMark AS DeletionMark,
	|	FALSE AS AdditionalRecord,
	|	"""" AS More,
	|	&Period AS SourceDocumentDate,
	|	&NumberForPrinting AS SourceDocumentNumber,
	|	FALSE AS ReverseTransactionCorrection,
	|	UNDEFINED AS ReversedDocument,
	|	UNDEFINED AS CorrectedDocument,
	|	&Period    AS RecordingInAccountingDate,
	|	&Priority AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ReflectReserve(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	CASE WHEN HeaderData_.AssemblyDisassemblyStart <> DATETIME(1, 1, 1) THEN
	|				HeaderData_.AssemblyDisassemblyStart
	|			ELSE
	|				HeaderData_.Date
	|		END                           AS Period,
	|	DocumentGoods.Ref				AS OrderDocument,
	|	UNDEFINED						AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	HeaderData_.Warehouse					AS Recipient,
	|	HeaderData_.Warehouse					AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	CASE
	|		WHEN DocumentGoods.WithAssignment
	|			THEN CASE
	|					WHEN HeaderData_.Purpose = &DefaultAssignment
	|							OR HeaderData_.AssignByOrderAssignment
	|						THEN HeaderData_.AssignmentGoods
	|					ELSE HeaderData_.Purpose
	|				END
	|		ELSE &DefaultAssignment
	|	END								AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	FALSE								AS ExceedingOrder,
	|	DocumentGoods.Canceled			AS Canceled,
	|	FALSE								AS ThisIsAnInvoice,
	|	TRUE								AS ShipmentByOrder
	|FROM
	|	Document.ByAssemblyDisassemblyOrder.Goods AS DocumentGoods
	|		LEFT JOIN Document.ByAssemblyDisassemblyOrder AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
	|	AND (HeaderData_.Status IN(VALUE(Enum.InternalOrderStatuses.ForCompletion),
	|									VALUE(Enum.InternalOrderStatuses.Closed))
	|			AND DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse))
	|	AND DocumentGoods.Count <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentGoods.Ref					AS Ref,
	|	DocumentGoods.AssemblyDisassemblyStart	AS Period,
	|	DocumentGoods.Ref					AS OrderDocument,
	|	UNDEFINED							AS Invoice,
	|	FALSE									AS Patch,
	|	UNDEFINED							AS CorrectedDocument,
	|	DocumentGoods.Warehouse					AS Recipient,
	|	DocumentGoods.Warehouse					AS Warehouse,
	|	DocumentGoods.Products			AS Products,
	|	DocumentGoods.Characteristic			AS Characteristic,
	|	CASE
	|		WHEN DocumentGoods.WithAssignment
	|			THEN DocumentGoods.Purpose
	|		ELSE &DefaultAssignment
	|	END									AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series					AS Series,
	|	DocumentGoods.BatchesIndicationStatus		AS BatchesIndicationStatus,
	|	DocumentGoods.Count				AS Count,
	|	FALSE									AS ExceedingOrder,
	|	FALSE									AS Canceled,
	|	FALSE									AS ThisIsAnInvoice,
	|	TRUE									AS ShipmentByOrder
	|FROM
	|	Document.ByAssemblyDisassemblyOrder AS DocumentGoods
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND DocumentGoods.BusinessOperation <> VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
	|	AND DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
	|	AND DocumentGoods.Count <> 0
	|	AND DocumentGoods.BatchesIndicationStatus <> 10
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	HeaderData_.AssemblyDisassemblyStart	AS Period,
	|	DocumentGoods.Ref				AS OrderDocument,
	|	UNDEFINED						AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	HeaderData_.Warehouse					AS Recipient,
	|	HeaderData_.Warehouse					AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	CASE
	|		WHEN HeaderData_.WithAssignment
	|			THEN HeaderData_.Purpose
	|		ELSE &DefaultAssignment
	|	END								AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	HeaderData_.BatchesIndicationStatus		AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	FALSE								AS ExceedingOrder,
	|	FALSE								AS Canceled,
	|	FALSE								AS ThisIsAnInvoice,
	|	TRUE								AS ShipmentByOrder
	|FROM
	|	Document.ByAssemblyDisassemblyOrder.SetOfSeries AS DocumentGoods
	|		INNER JOIN Document.ByAssemblyDisassemblyOrder AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|			AND DocumentGoods.Products = HeaderData_.Products
	|			AND DocumentGoods.Characteristic = HeaderData_.Characteristic
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND HeaderData_.BusinessOperation <> VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
	|	AND HeaderData_.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
	|	AND DocumentGoods.Count <> 0
	|	AND HeaderData_.BatchesIndicationStatus = 10";
	
	TextOfDocumentDataRequest = StrReplace(TextOfDocumentDataRequest,
												"&DefaultAssignment",
												"VALUE(Catalog.Assignments.EmptyRef)");
	
	WarehousesServer.ReflectReserve(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	HeaderData_.AssemblyDisassemblyStart	AS Period,
	|	DocumentGoods.Ref				AS OrderDocument,
	|	UNDEFINED						AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	HeaderData_.Warehouse					AS Recipient,
	|	HeaderData_.Warehouse					AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	CASE
	|		WHEN DocumentGoods.WithAssignment
	|			THEN CASE
	|					WHEN HeaderData_.Purpose = &DefaultAssignment
	|							OR HeaderData_.AssignByOrderAssignment
	|						THEN HeaderData_.AssignmentGoods
	|					ELSE HeaderData_.Purpose
	|				END
	|		ELSE &DefaultAssignment
	|	END								AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	FALSE								AS ExceedingOrder,
	|	DocumentGoods.Canceled			AS Canceled,
	|	FALSE								AS ThisIsAnInvoice,
	|	TRUE								AS ShipmentByOrder
	|FROM
	|	Document.ByAssemblyDisassemblyOrder.Goods AS DocumentGoods
	|		LEFT JOIN Document.ByAssemblyDisassemblyOrder AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
	|	AND HeaderData_.Status IN(VALUE(Enum.InternalOrderStatuses.ForCompletion),
	|							VALUE(Enum.InternalOrderStatuses.Closed))
	|	AND DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND DocumentGoods.Count <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentGoods.Ref					AS Ref,
	|	DocumentGoods.AssemblyDisassemblyStart	AS Period,
	|	DocumentGoods.Ref					AS OrderDocument,
	|	UNDEFINED							AS Invoice,
	|	FALSE									AS Patch,
	|	UNDEFINED							AS CorrectedDocument,
	|	DocumentGoods.Warehouse					AS Recipient,
	|	DocumentGoods.Warehouse					AS Warehouse,
	|	DocumentGoods.Products			AS Products,
	|	DocumentGoods.Characteristic			AS Characteristic,
	|	CASE
	|		WHEN DocumentGoods.WithAssignment
	|			THEN DocumentGoods.Purpose
	|		ELSE &DefaultAssignment
	|	END									AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series					AS Series,
	|	DocumentGoods.BatchesIndicationStatus		AS BatchesIndicationStatus,
	|	DocumentGoods.Count				AS Count,
	|	FALSE									AS ExceedingOrder,
	|	FALSE									AS Canceled,
	|	FALSE									AS ThisIsAnInvoice,
	|	TRUE									AS ShipmentByOrder
	|FROM
	|	Document.ByAssemblyDisassemblyOrder AS DocumentGoods
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND DocumentGoods.BusinessOperation <> VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
	|	AND DocumentGoods.Status IN(VALUE(Enum.InternalOrderStatuses.ForCompletion),
	|								VALUE(Enum.InternalOrderStatuses.Closed))
	|	AND DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND DocumentGoods.Count <> 0
	|	AND DocumentGoods.BatchesIndicationStatus <> 10
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	HeaderData_.AssemblyDisassemblyStart	AS Period,
	|	DocumentGoods.Ref				AS OrderDocument,
	|	UNDEFINED						AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	HeaderData_.Warehouse					AS Recipient,
	|	HeaderData_.Warehouse					AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	CASE
	|		WHEN HeaderData_.WithAssignment
	|			THEN HeaderData_.Purpose
	|		ELSE &DefaultAssignment
	|	END								AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	HeaderData_.BatchesIndicationStatus		AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	FALSE								AS ExceedingOrder,
	|	FALSE								AS Canceled,
	|	FALSE								AS ThisIsAnInvoice,
	|	TRUE								AS ShipmentByOrder
	|FROM
	|	Document.ByAssemblyDisassemblyOrder.SetOfSeries AS DocumentGoods
	|		INNER JOIN Document.ByAssemblyDisassemblyOrder AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|			AND DocumentGoods.Products = HeaderData_.Products
	|			AND DocumentGoods.Characteristic = HeaderData_.Characteristic
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND HeaderData_.BusinessOperation <> VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
	|	AND HeaderData_.Status IN(VALUE(Enum.InternalOrderStatuses.ForCompletion),
	|								VALUE(Enum.InternalOrderStatuses.Closed))
	|	AND HeaderData_.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND DocumentGoods.Count <> 0
	|	AND HeaderData_.BatchesIndicationStatus = 10";
	
	TextOfDocumentDataRequest = StrReplace(TextOfDocumentDataRequest,
												"&DefaultAssignment",
												"VALUE(Catalog.Assignments.EmptyRef)");
	
	WarehousesServer.ScheduleShipmentOfGoods(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Function QueryTextTableAssemblyOrders(Query, QueryTexts, Registers)
	RegisterName = "AssemblyOrders";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText =
	//assembling ////////////////
	// Receipt of ordered kits for the "Ordered" field.
	// Since the "Quantity" field has already been reduced by the cancellation amount, the initial value is calculated.
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Ref                   AS ByAssemblyDisassemblyOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Series                    AS Series,
	|	1                                      AS RowCode,
	|	VALUE(Enum.InventoryMovementTypes.Inpayment) AS AssemblyType,
	|	0                                      AS ToRegister,
	|	GoodsTable.Count
	|		+ GoodsTable.CountCanceled AS Ordered
	|FROM
	|	Document.ByAssemblyDisassemblyOrder AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.BatchesIndicationStatus <> 10
	|	AND GoodsTable.Count + GoodsTable.CountCanceled > 0
	|	AND &AssemblyOfComponents
	|
	|UNION ALL
	|
	// Getting the cancelled quantity for the ordered sets (the "Ordered" field)
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Ref                   AS ByAssemblyDisassemblyOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Series                    AS Series,
	|	1                                      AS RowCode,
	|	VALUE(Enum.InventoryMovementTypes.Inpayment) AS AssemblyType,
	|	0                                      AS ToRegister,
	|	-GoodsTable.CountCanceled      AS Ordered
	|FROM
	|	Document.ByAssemblyDisassemblyOrder AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.BatchesIndicationStatus <> 10
	|	AND GoodsTable.CountCanceled > 0
	|	AND &AssemblyOfComponents
	|
	|UNION ALL
	|
	// Receiving the ordered kits for the "Co-registration" field.
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&AssemblyDisassemblyStart                  AS Period,
	|	GoodsTable.Ref                   AS ByAssemblyDisassemblyOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Series                    AS Series,
	|	1                                      AS RowCode,
	|	VALUE(Enum.InventoryMovementTypes.Inpayment) AS AssemblyType,
	|	GoodsTable.Count               AS ToRegister,
	|	0                                      AS Ordered
	|FROM
	|	Document.ByAssemblyDisassemblyOrder AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &AccessoriesForShipment
	|	AND &Status IN(
	|		VALUE(Enum.InternalOrderStatuses.ForCompletion),
	|		VALUE(Enum.InternalOrderStatuses.Closed))
	|	AND GoodsTable.BatchesIndicationStatus <> 10
	|	AND GoodsTable.Count > 0
	|	AND &AssemblyOfComponents
	|
	|UNION ALL
	|
	// Receipt of ordered components ("Ordered" field)
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Ref                   AS ByAssemblyDisassemblyOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Series                    AS Series,
	|	GoodsTable.RowCode                AS RowCode,
	|	VALUE(Enum.InventoryMovementTypes.Shipment) AS AssemblyType,
	|	0                                      AS ToRegister,
	|	GoodsTable.Count               AS Ordered
	|FROM
	|	Document.ByAssemblyDisassemblyOrder.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &AssemblyOfComponents
	|
	|UNION ALL
	|
	// Receipt of the cancelled quantity of ordered components (the "Ordered" field)
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Ref                   AS ByAssemblyDisassemblyOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Series                    AS Series,
	|	GoodsTable.RowCode                AS RowCode,
	|	VALUE(Enum.InventoryMovementTypes.Shipment) AS AssemblyType,
	|	0                                      AS ToRegister,
	|	-GoodsTable.Count              AS Ordered
	|FROM
	|	Document.ByAssemblyDisassemblyOrder.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Canceled
	|	AND &AssemblyOfComponents
	|
	|UNION ALL
	|
	// Receipt of the ordered components (the "Co-registration" field)
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&AssemblyDisassemblyStart                  AS Period,
	|	GoodsTable.Ref                   AS ByAssemblyDisassemblyOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Series                    AS Series,
	|	GoodsTable.RowCode                AS RowCode,
	|	VALUE(Enum.InventoryMovementTypes.Shipment) AS AssemblyType,
	|	GoodsTable.Count               AS ToRegister,
	|	0                                      AS Ordered
	|FROM
	|	Document.ByAssemblyDisassemblyOrder.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND NOT GoodsTable.Canceled
	|	AND GoodsTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND &Status IN (VALUE(Enum.InternalOrderStatuses.ForCompletion),
	|					VALUE(Enum.InternalOrderStatuses.Closed))
	|	AND &AssemblyOfComponents
	|
	|UNION ALL
	|
	//DISASSEMBLY ////////////////
	// Receipt of ordered kits for the "Ordered" field.
	// Since the "Quantity" field has already been reduced by the cancellation amount, the initial value is calculated.
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Ref                   AS ByAssemblyDisassemblyOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Series                    AS Series,
	|	1                                      AS RowCode,
	|	VALUE(Enum.InventoryMovementTypes.Shipment) AS AssemblyType,
	|	0                                      AS ToRegister,
	|	GoodsTable.Count
	|		+ GoodsTable.CountCanceled AS Ordered
	|FROM
	|	Document.ByAssemblyDisassemblyOrder AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.BatchesIndicationStatus <> 10
	|	AND GoodsTable.Count + GoodsTable.CountCanceled > 0
	|	AND NOT &AssemblyOfComponents
	|
	|UNION ALL
	|
	// Getting the cancelled quantity for the ordered sets (the "Ordered" field)
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Ref                   AS ByAssemblyDisassemblyOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Series                    AS Series,
	|	1                                      AS RowCode,
	|	VALUE(Enum.InventoryMovementTypes.Shipment) AS AssemblyType,
	|	0                                      AS ToRegister,
	|	-GoodsTable.CountCanceled      AS Ordered
	|FROM
	|	Document.ByAssemblyDisassemblyOrder AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.BatchesIndicationStatus <> 10
	|	AND GoodsTable.CountCanceled > 0
	|	AND NOT &AssemblyOfComponents
	|
	|UNION ALL
	|
	// Receiving the ordered kits for the "Co-registration" field.
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&AssemblyDisassemblyStart                  AS Period,
	|	GoodsTable.Ref                   AS ByAssemblyDisassemblyOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Series                    AS Series,
	|	1                                      AS RowCode,
	|	VALUE(Enum.InventoryMovementTypes.Shipment) AS AssemblyType,
	|	GoodsTable.Count               AS ToRegister,
	|	0                                      AS Ordered
	|FROM
	|	Document.ByAssemblyDisassemblyOrder AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &Status IN(
	|		VALUE(Enum.InternalOrderStatuses.ForCompletion),
	|		VALUE(Enum.InternalOrderStatuses.Closed))
	|	AND GoodsTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND GoodsTable.BatchesIndicationStatus <> 10
	|	AND GoodsTable.Count > 0
	|	AND NOT &AssemblyOfComponents
	|
	|UNION ALL
	|
	// Receipt of ordered components ("Ordered" field)
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Ref                   AS ByAssemblyDisassemblyOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Series                    AS Series,
	|	GoodsTable.RowCode                AS RowCode,
	|	VALUE(Enum.InventoryMovementTypes.Inpayment) AS AssemblyType,
	|	0                                      AS ToRegister,
	|	GoodsTable.Count               AS Ordered
	|FROM
	|	Document.ByAssemblyDisassemblyOrder.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND NOT &AssemblyOfComponents
	|
	|UNION ALL
	|
	// Receipt of the cancelled quantity of ordered components (the "Ordered" field)
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Ref                   AS ByAssemblyDisassemblyOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Series                    AS Series,
	|	GoodsTable.RowCode                AS RowCode,
	|	VALUE(Enum.InventoryMovementTypes.Inpayment) AS AssemblyType,
	|	0                                      AS ToRegister,
	|	-GoodsTable.Count              AS Ordered
	|FROM
	|	Document.ByAssemblyDisassemblyOrder.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Canceled
	|	AND NOT &AssemblyOfComponents
	|
	|UNION ALL
	|
	// Receipt of the ordered components (the "Co-registration" field)
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&AssemblyDisassemblyStart                  AS Period,
	|	GoodsTable.Ref                   AS ByAssemblyDisassemblyOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Series                    AS Series,
	|	GoodsTable.RowCode                AS RowCode,
	|	VALUE(Enum.InventoryMovementTypes.Inpayment) AS AssemblyType,
	|	GoodsTable.Count               AS ToRegister,
	|	0                                      AS Ordered
	|FROM
	|	Document.ByAssemblyDisassemblyOrder.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND NOT GoodsTable.Canceled
	|	AND GoodsTable.Ref.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND &Status IN (VALUE(Enum.InternalOrderStatuses.ForCompletion),
	|					VALUE(Enum.InternalOrderStatuses.Closed))
	|	AND NOT &AssemblyOfComponents
	|
	|UNION ALL
	|
	//general ////////////////
	// PM Series refers to the header of the document with the operation "Disassembly"
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Ref                   AS ByAssemblyDisassemblyOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Series                    AS Series,
	|	1                                      AS RowCode,
	|	VALUE(Enum.InventoryMovementTypes.Shipment)
	|	                                       AS AssemblyType,
	|	0                                      AS ToRegister,
	|	GoodsTable.Count               AS Ordered
	|FROM
	|	Document.ByAssemblyDisassemblyOrder.SetOfSeries AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Ref.BatchesIndicationStatus = 10
	|
	|UNION ALL
	|
	// PM Series refers to the header of the document with the operation "Disassembly"
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&AssemblyDisassemblyStart                  AS Period,
	|	GoodsTable.Ref                   AS ByAssemblyDisassemblyOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Series                    AS Series,
	|	1                                      AS RowCode,
	|	VALUE(Enum.InventoryMovementTypes.Shipment)
	|	                                       AS AssemblyType,
	|	GoodsTable.Count               AS ToRegister,
	|	0                                      AS Ordered
	|FROM
	|	Document.ByAssemblyDisassemblyOrder.SetOfSeries AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &Status IN (
	|		VALUE(Enum.InternalOrderStatuses.ForCompletion),
	|		VALUE(Enum.InternalOrderStatuses.Closed))
	|	AND GoodsTable.Ref.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND GoodsTable.Ref.BatchesIndicationStatus = 10";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	ByAssemblyDisassemblyOrderLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	
	FullDocumentName      = FullObjectName();
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	ParameterValues = New Structure();
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	RedefiningParameterCalculation.Insert("AssemblyOfComponents",
		"GoodsTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)");
	RedefiningParameterCalculation.Insert("TrafficOnWarehouseRegistersHeader",
		"ISNULL(GoodsTable.Ref.Purpose.RecordsInWarehouseRegisters, FALSE)");
	RedefiningParameterCalculation.Insert("RegisteredRecordsOnWarehouseRegistersDestinationGoods",
		"ISNULL(GoodsTable.Ref.AssignmentGoods.RecordsInWarehouseRegisters, FALSE)");
	RedefiningParameterCalculation.Insert("DestinationHeader_",
		"GoodsTable.Ref.Purpose");
	RedefiningParameterCalculation.Insert("AssignmentGoods",
		"GoodsTable.Ref.AssignmentGoods");
	RedefiningParameterCalculation.Insert("AdvancedWarehousingOnGoodsReceipt",
		"CASE WHEN GoodsTable.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|	AND GoodsTable.Ref.Date >= GoodsTable.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt THEN
		|		TRUE
		|	ELSE
		|		FALSE
		|	END");
	RedefiningParameterCalculation.Insert("InvoiceIsOrder",
		"GoodsTable.Ref.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)");
	RedefiningParameterCalculation.Insert("AccessoriesForShipment",
		"TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			Document.ByAssemblyDisassemblyOrder.Goods AS Components
		|		WHERE
		|			Components.Ref = GoodsTable.Ref
		|			AND NOT Components.Canceled
		|			AND Components.SupplyOption = VALUE(Enum.SupplyOptions.Ship))");
	
	If RegisterName = "AssemblyOrders" Then
		
		QueryText = QueryTextTableAssemblyOrders(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "GoodsTable";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		RequestHasSource = False;
		
	Else
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
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RequestHasSource,
			RedefiningParameterCalculation);
		
	Else
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RedefiningParameterCalculation);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Other

// Forms the structure of the document parameters for embedding the document in the software algorithms.
//
// Returns:
//  See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions
//
Function AvailableBasicEmbeddingOptions()
	
	EmbeddingParameters = ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions();
	EmbeddingParameters.AttributesToBeCleared = "RowCode";
	
	// Updating the "Available" column.
	EmbeddingParameters.FormTableName = "Goods";
	
	// Conditional registration.
	FormItems = EmbeddingParameters.ConditionalAppearance.FormItems;
	FormItems.SupplyOption = "GoodsSupplyOption";
	FormItems.Available           = "GoodsAvailable";
	FormItems.Series              = "GoodsSeries";
	FormItems.WithAssignment        = "GoodsWithAssignment";
	
	DataPaths = EmbeddingParameters.ConditionalAppearance.DataPaths;
	DataPaths.ReallocateInventory = "Object.Goods.ReallocateInventory";
	DataPaths.NoEditingAllowed = "Object.Goods.Canceled";
	DataPaths.ItemsType = "Object.Goods.ItemsType";
	
	// The choice of the security option.
	Links = EmbeddingParameters.ConnectionsOfSoftwareOptionSelectionParameters;
	Links.Available              = "Items.Goods.CurrentData.Available";
	Links.NumberOfPackages    = "Items.Goods.CurrentData.NumberOfPackages";
	Links.Count            = "Items.Goods.CurrentData.Count";
	Links.ShipIfAvailable = "Items.Goods.CurrentData.ShipIfAvailable";
	Links.WithAssignment           = "Items.Goods.CurrentData.WithAssignment";
	Links.ItemsType       = "Items.Goods.CurrentData.ItemsType";
	Links.Package              = "Items.Goods.CurrentData.Package";
	Links.Products          = "Items.Goods.CurrentData.Products";
	Links.SupplyOption    = "Items.Goods.CurrentData.SupplyOption";
	Links.Warehouse                 = "Object.Warehouse";
	Links.MultipleWarehouses      = Undefined;
	
	// The name of the shipment registration register.
	EmbeddingParameters.NameOfShipmentRegistrationRegister = "AssemblyOrders";
	
	// Temporary document data table.
	EmbeddingParameters.ObjectName = "Document.ByAssemblyDisassemblyOrder";
	EmbeddingParameters.TableName = "Document.ByAssemblyDisassemblyOrder.Goods";
	
	EmbeddingParameters.DescriptionOfGettingDocumentData =
		"SELECT
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	Attributes.Department AS Department,
		|	Attributes.Warehouse AS Warehouse,
		|	CASE WHEN Attributes.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|					OR Attributes.AssignByOrderAssignment THEN
		|				Attributes.AssignmentGoods
		|			ELSE
		|				Attributes.Purpose
		|		END AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	Attributes.Ref AS ShipmentOrder,
		|	TabPart.SupplyOption AS SupplyOption,
		|	TabPart.WithAssignment AS WithAssignment,
		|	TabPart.Count AS Count,
		|	TabPart.NumberOfPackages AS NumberOfPackages,
		|	TabPart.Package AS Package,
		|	TRUE AS ReadyForSupply,
		|	Attributes.Status IN(
		|			VALUE(Enum.InternalOrderStatuses.ForCompletion),
		|			VALUE(Enum.InternalOrderStatuses.Closed)
		|		) AS ReadyToShip,
		|	Attributes.AssemblyDisassemblyStart AS RequestShipmentOn,
		|	TabPart.Series AS Series,
		|	TabPart.RowCode AS RowCode,
		|	
		|	TabPart.Canceled AS Canceled,
		|	
		|	TabPart.LineNumber AS LineNumber,
		|	Attributes.Ref AS Recorder,
		|	Attributes.Date AS DocumentDate,
		|	Attributes.Warehouse AS GroupOfWarehouses,
		|	Attributes.Priority AS Priority,
		|	Attributes.AssemblyDisassemblyStart AS TheShipmentDateOfAllLinesIsASingleDate
		|INTO TemporaryDocumentDataTable
		|FROM
		|	Document.ByAssemblyDisassemblyOrder.Goods AS TabPart
		|		
		|		LEFT JOIN Document.ByAssemblyDisassemblyOrder AS Attributes
		|		ON TRUE";
	
	// Template for serialization of form data.
	Goods = New Structure();
	Goods.Insert("LineNumber",        New TypeDescription("Number"));
	Goods.Insert("Products",       New TypeDescription("CatalogRef.Products"));
	Goods.Insert("Characteristic",     New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Goods.Insert("SupplyOption", New TypeDescription("EnumRef.SupplyOptions"));
	Goods.Insert("WithAssignment",        New TypeDescription("Boolean"));
	Goods.Insert("Count",         New TypeDescription("Number"));
	Goods.Insert("NumberOfPackages", New TypeDescription("Number"));
	Goods.Insert("Package",           New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Goods.Insert("Series",              New TypeDescription("CatalogRef.ItemsBatches"));
	Goods.Insert("Canceled",           New TypeDescription("Boolean"));
	Goods.Insert("RowCode",          New TypeDescription("Number"));
	
	Object = New Structure();
	Object.Insert("Department",                  New TypeDescription("CatalogRef.BusinessStructure"));
	Object.Insert("Warehouse",                          New TypeDescription("CatalogRef.Warehouses"));
	Object.Insert("Purpose",                     New TypeDescription("CatalogRef.Assignments"));
	Object.Insert("AssignmentGoods",               New TypeDescription("CatalogRef.Assignments"));
	Object.Insert("AssignByOrderAssignment", New TypeDescription("Boolean"));
	Object.Insert("Ref",                         New TypeDescription("DocumentRef.ByAssemblyDisassemblyOrder"));
	Object.Insert("Status",                         New TypeDescription("EnumRef.InternalOrderStatuses"));
	Object.Insert("AssemblyDisassemblyStart",           New TypeDescription("Date"));
	Object.Insert("Date",                           New TypeDescription("Date"));
	Object.Insert("Priority",                      New TypeDescription("CatalogRef.Priorities"));
	Object.Insert("Goods",                         Goods);
	
	EmbeddingParameters.FormDataSerializationPattern.Insert("Object", Object);
	
	EmbeddingParameters.ExpressionForQuestionWhenPerformingActionInOrderList ="UNDEFINED";

	Return EmbeddingParameters;
	
EndFunction

// Forms the structure of the document parameters for embedding the document in the software algorithms.
//
// Returns:
//  See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions
//
Function AvailableLeftoversEmbeddingOptionsDisassembly()
	
	EmbeddingParameters = ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions();
	EmbeddingParameters.AttributesToBeCleared = "RowCode";
	
	// Updating the "Available" column.
	EmbeddingParameters.FormTableName = Undefined;
	
	// Conditional registration.
	FormItems = EmbeddingParameters.ConditionalAppearance.FormItems;
	FormItems.SupplyOption = "SupplyOption";
	FormItems.Available           = "Available";
	
	DataPaths = EmbeddingParameters.ConditionalAppearance.DataPaths;
	DataPaths.ReallocateInventory = "ReallocateInventory";
	DataPaths.ItemsType = "ItemsType";
	
	// The choice of the security option.
	Links = EmbeddingParameters.ConnectionsOfSoftwareOptionSelectionParameters;
	Links.Available              = "Available";
	Links.NumberOfPackages    = "Object.NumberOfPackages";
	Links.Count            = "Object.Count";
	Links.ShipIfAvailable = "ShipIfAvailable";
	Links.WithAssignment           = "Object.WithAssignment";
	Links.ItemsType       = "ItemsType";
	Links.Package              = "Object.Package";
	Links.Products          = "Object.Products";
	Links.SupplyOption    = "Object.SupplyOption";
	Links.Warehouse                 = "Object.Warehouse";
	Links.MultipleWarehouses      = Undefined;
	Links.UsePartialShipment = False;
	
	// The name of the shipment registration register.
	EmbeddingParameters.NameOfShipmentRegistrationRegister = "AssemblyOrders";
	
	// Temporary document data table.
	EmbeddingParameters.ObjectName = "Document.ByAssemblyDisassemblyOrder";
	EmbeddingParameters.TableName = Undefined;
	
	EmbeddingParameters.DescriptionOfGettingDocumentData =
		"SELECT
		|	Attributes.Products AS Products,
		|	Attributes.Characteristic AS Characteristic,
		|	Attributes.Department AS Department,
		|	Attributes.Warehouse AS Warehouse,
		|	Attributes.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	Attributes.Ref AS ShipmentOrder,
		|	Attributes.SupplyOption AS SupplyOption,
		|	Attributes.WithAssignment AS WithAssignment,
		|	Attributes.Count AS Count,
		|	Attributes.NumberOfPackages AS NumberOfPackages,
		|	Attributes.Package AS Package,
		|	TRUE AS ReadyForSupply,
		|	Attributes.Status IN(
		|			VALUE(Enum.InternalOrderStatuses.ForCompletion),
		|			VALUE(Enum.InternalOrderStatuses.Closed)
		|		) AS ReadyToShip,
		|	Attributes.AssemblyDisassemblyStart AS RequestShipmentOn,
		|	Attributes.Series AS Series,
		|	1 AS RowCode,
		|	FALSE AS Canceled,
		|	1 AS LineNumber,
		|	Attributes.Ref AS Recorder,
		|	Attributes.Date AS DocumentDate,
		|	Attributes.Warehouse AS GroupOfWarehouses,
		|	Attributes.Priority AS Priority,
		|	Attributes.AssemblyDisassemblyStart AS TheShipmentDateOfAllLinesIsASingleDate
		|INTO TemporaryDocumentDataTable
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS Attributes";
	
	Object = New Structure();
	Object.Insert("Department",         New TypeDescription("CatalogRef.BusinessStructure"));
	Object.Insert("Warehouse",                 New TypeDescription("CatalogRef.Warehouses"));
	Object.Insert("Purpose",            New TypeDescription("CatalogRef.Assignments"));
	Object.Insert("Ref",                New TypeDescription("DocumentRef.ByAssemblyDisassemblyOrder"));
	Object.Insert("Status",                New TypeDescription("EnumRef.InternalOrderStatuses"));
	Object.Insert("AssemblyDisassemblyStart",  New TypeDescription("Date"));
	Object.Insert("BusinessOperation", New TypeDescription("EnumRef.BusinessTransactions"));
	Object.Insert("Products",          New TypeDescription("CatalogRef.Products"));
	Object.Insert("Characteristic",        New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Object.Insert("SupplyOption",    New TypeDescription("EnumRef.SupplyOptions"));
	Object.Insert("WithAssignment",           New TypeDescription("Boolean"));
	Object.Insert("Count",            New TypeDescription("Number"));
	Object.Insert("NumberOfPackages",    New TypeDescription("Number"));
	Object.Insert("Package",              New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Object.Insert("Series",                 New TypeDescription("CatalogRef.ItemsBatches"));
	Object.Insert("Date",                  New TypeDescription("Date"));
	Object.Insert("Priority",             New TypeDescription("CatalogRef.Priorities"));
	
	EmbeddingParameters.FormDataSerializationPattern.Insert("Object", Object);
	
	EmbeddingParameters.ExpressionForQuestionWhenPerformingActionInOrderList ="UNDEFINED";

	Return EmbeddingParameters;
	
EndFunction

Function SeriesAreIndicatedInSeparateTabularPart(Object) Export
	
	If Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		Return True;
	EndIf;
		
	Query = New Query();
	Query.SetParameter("Products", Object.Products);
	Query.SetParameter("Warehouse", Object.Warehouse);
	Query.Text =
	"SELECT
	|	1
	|FROM
	|	Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|WHERE
	|	BatchAccountingPolicies.Warehouse = &Warehouse
	|	AND CAST(&Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref
	|	AND NOT BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|   AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function FullObjectName()
	Return "Document.ByAssemblyDisassemblyOrder";
EndFunction

Function ThereIsAssemblyOnRequest(ByAssemblyDisassemblyOrder) Export

	SetPrivilegedMode(True);

	Query = New Query(
	"SELECT TOP 1
	|	1 AS ThereAreRecords
	|FROM
	|	AccumulationRegister.AssemblyOrders AS Table
	|WHERE
	|	Table.ByAssemblyDisassemblyOrder = &ByAssemblyDisassemblyOrder
	|	AND Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND Table.ToRegister <> 0
	|");
	Query.SetParameter("ByAssemblyDisassemblyOrder", ByAssemblyDisassemblyOrder);
	Return Not Query.Execute().IsEmpty();

EndFunction

// Returns an array of completed invoices for the order
//
// Parameters:
//  ByAssemblyDisassemblyOrder	 - DocumentRef.ByAssemblyDisassemblyOrder -
//
// Returns:
//   - Array
//
Function GetInvoicesForOrder(ByAssemblyDisassemblyOrder) Export
	
	Query = New Query(
	"SELECT DISTINCT
	|	Table.Recorder AS Ref
	|FROM
	|	AccumulationRegister.AssemblyOrders AS Table
	|WHERE
	|	Table.ByAssemblyDisassemblyOrder = &ByAssemblyDisassemblyOrder
	|	AND Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND Table.ToRegister <> 0
	|	AND Table.Recorder REFS Document.AssemblyFromComponents");
	Query.SetParameter("ByAssemblyDisassemblyOrder", ByAssemblyDisassemblyOrder);
	
	Result = Query.Execute().Unload();
	
	Return Result.UnloadColumn("Ref");
	
EndFunction

Function QueryTextDocumentGoods(Resource) Export

	If Resource = "Kit" Then
		QueryText = 
		"SELECT
		|	Table.Ref                       AS ByAssemblyDisassemblyOrder,
		|	Table.Products                 AS Products,
		|	Table.Characteristic               AS Characteristic,
		|	CASE WHEN Table.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents) THEN
		|			Table.Purpose
		|		WHEN Table.WithAssignment THEN
		|			Table.Purpose
		|		ELSE
		|			VALUE(Catalog.Assignments.EmptyRef)
		|		END                            AS Purpose,
		|	1                                    AS RowCode,
		|	DataOfAccounting.Series                    AS Series,
		|	SUM(Table.Count)            AS Count,
		|	Table.Package                     AS Package,
		|	Table.SalesOpportunity                       AS SalesOpportunity,
		|	Table.Warehouse                        AS Warehouse,
		|	Table.AssemblyDisassemblyStart         AS DateOfShipment,
		|	SUM(ISNULL(DataOfAccounting.ToRegister, 0)) AS ToRegister,
		|	SUM(ISNULL(DataOfAccounting.Ordered, 0))    AS Ordered
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS Table
		|	LEFT JOIN TTAccountingData AS DataOfAccounting
		|	ON Table.Ref = DataOfAccounting.ByAssemblyDisassemblyOrder
		|	AND Table.Products = DataOfAccounting.Products // The use of communication by nomenclature allows you to always receive the remnants of sets
		|	AND Table.Characteristic = DataOfAccounting.Characteristic
		|WHERE
		|	NOT DataOfAccounting.ByAssemblyDisassemblyOrder IS NULL
		|	AND (Table.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|	AND DataOfAccounting.AssemblyType = VALUE(Enum.InventoryMovementTypes.Inpayment)
		|	OR Table.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
		|				AND DataOfAccounting.AssemblyType = VALUE(Enum.InventoryMovementTypes.Shipment))
		|	AND Table.Ref IN(&References)
		|
		|GROUP BY
		|	Table.Ref,
		|	Table.Products,
		|	Table.Characteristic,
		|	CASE WHEN Table.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents) THEN
		|			Table.Purpose
		|		WHEN Table.WithAssignment THEN
		|			Table.Purpose
		|		ELSE
		|			VALUE(Catalog.Assignments.EmptyRef)
		|		END,
		|	DataOfAccounting.Series,
		|	Table.Package,
		|	Table.SalesOpportunity,
		|	Table.Warehouse,
		|	Table.AssemblyDisassemblyStart";
	Else
		QueryText = 
		"SELECT
		|	Table.Ref                       AS ByAssemblyDisassemblyOrder,
		|	Table.Products                 AS Products,
		|	Table.Characteristic               AS Characteristic,
		|	CASE 
		|		WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents) THEN
		|				Table.Purpose
		|		WHEN Table.WithAssignment THEN
		|					CASE WHEN Table.Ref.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|						OR Table.Ref.AssignByOrderAssignment THEN
		|						Table.Ref.AssignmentGoods
		|					ELSE
		|						Table.Ref.Purpose
		|					END
		|		ELSE
		|			VALUE(Catalog.Assignments.EmptyRef)
		|		END AS                        Purpose,
		|	Table.RowCode                    AS RowCode,
		|	Table.Series                        AS Series,
		|	Table.Count                   AS Count,
		|	Table.Package                     AS Package,
		|	OrderDocument.SalesOpportunity                         AS SalesOpportunity,
		|	OrderDocument.Warehouse                          AS Warehouse,
		|	OrderDocument.AssemblyDisassemblyStart           AS DateOfShipment,
		|	ISNULL(DataOfAccounting.ToRegister, 0) AS ToRegister,
		|	ISNULL(DataOfAccounting.Ordered, 0)    AS Ordered
		|FROM
		|	Document.ByAssemblyDisassemblyOrder.Goods AS Table
		|	LEFT JOIN Document.ByAssemblyDisassemblyOrder AS OrderDocument
		|	ON Table.Ref = OrderDocument.Ref
		|	LEFT JOIN TTAccountingData AS DataOfAccounting
		|	ON Table.Ref = DataOfAccounting.ByAssemblyDisassemblyOrder
		|	AND Table.RowCode = DataOfAccounting.RowCode
		|WHERE
		|	NOT DataOfAccounting.ByAssemblyDisassemblyOrder IS NULL
		|	AND (OrderDocument.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|	AND DataOfAccounting.AssemblyType = VALUE(Enum.InventoryMovementTypes.Shipment)
		|	OR OrderDocument.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
		|				AND DataOfAccounting.AssemblyType = VALUE(Enum.InventoryMovementTypes.Inpayment))
		|	AND Table.Ref IN(&References)";
	EndIf;
	
	Return QueryText;

EndFunction

#EndRegion

#Region DocumentExecutionStateReport

Function TableUnsecuredGoodsForStateOfExecutionReport()
	
	QueryText = "
		|SELECT
		|	TTDocuments.DocumentRef AS Document,
		|	DocumentGoods.LineNumber AS LineNumber,
		|	DocumentGoods.Products AS Products,
		|	DocumentGoods.Characteristic AS Characteristic,
		|	DocumentGoods.NumberOfPackages AS Count,
		|	CASE 
		|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) 
		|	THEN
		|		DocumentGoods.Products.UnitOfMeasure
		|	ELSE
		|		DocumentGoods.Package
		|	END AS Package,
		|	0 AS Sum
		|FROM
		|	Document.ByAssemblyDisassemblyOrder.Goods AS DocumentGoods
		|	INNER JOIN TTDocuments AS TTDocuments
		|		ON TTDocuments.DocumentRef = DocumentGoods.Ref
		|WHERE
		|	DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.NotRequired)
		|	AND NOT DocumentGoods.Canceled
		|	AND DocumentGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|
		|UNION ALL
		|
		|SELECT
		|	TTDocuments.DocumentRef AS Document,
		|	1 AS LineNumber,
		|	DocumentGoods.Products AS Products,
		|	DocumentGoods.Characteristic AS Characteristic,
		|	DocumentGoods.NumberOfPackages AS Count,
		|	CASE 
		|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) 
		|	THEN
		|		DocumentGoods.Products.UnitOfMeasure
		|	ELSE
		|		DocumentGoods.Package
		|	END AS Package,
		|	0 AS Sum
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS DocumentGoods
		|	INNER JOIN TTDocuments AS TTDocuments
		|		ON TTDocuments.DocumentRef = DocumentGoods.Ref
		|WHERE
		|	DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.NotRequired)
		|	AND DocumentGoods.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
		|
		|
		|TOTALS BY
		|	Document;
		|";
	
	Return QueryText
	
EndFunction

Function SoftwareStateTableForExecutionStateReport()
	
	QueryText = "
		|SELECT
		|	TTDocuments.DocumentRef AS Document,
		|	DocumentGoods.LineNumber AS LineNumber,
		|	DocumentGoods.Products AS Products,
		|	DocumentGoods.Characteristic AS Characteristic,
		|	DocumentGoods.Series AS Series,
		|	DocumentGoods.NumberOfPackages AS Count,
		|	CASE 
		|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) 
		|	THEN
		|		DocumentGoods.Products.UnitOfMeasure
		|	ELSE
		|		DocumentGoods.Package
		|	END AS Package,
		|	DocumentGoods.Ref.AssemblyDisassemblyStart AS DateOfShipment,
		|	DocumentGoods.SupplyOption AS Action,
		|	0 AS Sum
		|FROM
		|	Document.ByAssemblyDisassemblyOrder.Goods AS DocumentGoods
		|	INNER JOIN TTDocuments AS TTDocuments
		|		ON TTDocuments.DocumentRef = DocumentGoods.Ref
		|WHERE
		|	DocumentGoods.SupplyOption IN(
		|		VALUE(Enum.SupplyOptions.ReserveAsReceived),
		|		VALUE(Enum.SupplyOptions.ToSupply),
		|		VALUE(Enum.SupplyOptions.FromWarehouse))
		|		
		|	AND NOT DocumentGoods.Canceled
		|	AND DocumentGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|
		|UNION ALL
		|
		|SELECT
		|	TTDocuments.DocumentRef AS Document,
		|	1 AS LineNumber,
		|	DocumentGoods.Products AS Products,
		|	DocumentGoods.Characteristic AS Characteristic,
		|	DocumentGoods.Series AS Series,
		|	DocumentGoods.NumberOfPackages AS Count,
		|	CASE 
		|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) 
		|	THEN
		|		DocumentGoods.Products.UnitOfMeasure
		|	ELSE
		|		DocumentGoods.Package
		|	END AS Package,
		|	DocumentGoods.AssemblyDisassemblyStart AS DateOfShipment,
		|	DocumentGoods.SupplyOption AS Action,
		|	0 AS Sum
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS DocumentGoods
		|	INNER JOIN TTDocuments AS TTDocuments
		|		ON TTDocuments.DocumentRef = DocumentGoods.Ref
		|WHERE
		|	DocumentGoods.SupplyOption IN(
		|		VALUE(Enum.SupplyOptions.ReserveAsReceived),
		|		VALUE(Enum.SupplyOptions.ToSupply),
		|		VALUE(Enum.SupplyOptions.FromWarehouse))
		|	
		|	AND DocumentGoods.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
		|
		|TOTALS BY
		|	Document;
		|";
	
	Return QueryText
	
EndFunction

Function TemporaryTableProductsOrderOrderShippedForStateOfExecutionReport()
	
	QueryText = "
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentGoods.Products AS Products,
		|	DocumentGoods.Characteristic AS Characteristic,
		|	SUM(DocumentGoods.Count) AS Count,
		|	0 AS AmountIncludingVAT,
		|	DocumentGoods.Series AS Series,
		|	DocumentGoods.Ref.Warehouse AS Warehouse,
		|	TTDocuments.DocumentRef AS Ref
		|INTO TTGoodsNotShipped
		|FROM
		|	Document.ByAssemblyDisassemblyOrder.Goods AS DocumentGoods
		|		INNER JOIN TTDocuments AS TTDocuments
		|		ON (TTDocuments.DocumentRef = DocumentGoods.Ref)
		|WHERE
		|	NOT DocumentGoods.Canceled
		|	AND DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|	AND TTDocuments.Posted
		|
		|	AND DocumentGoods.Ref.Status IN(
		|		VALUE(Enum.InternalOrderStatuses.ForCompletion),
		|		VALUE(Enum.InternalOrderStatuses.Closed))
		|
		|	AND DocumentGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|
		|GROUP BY
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	DocumentGoods.Series,
		|	DocumentGoods.Ref.Warehouse,
		|	TTDocuments.DocumentRef
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentGoods.Products AS Products,
		|	DocumentGoods.Characteristic AS Characteristic,
		|	DocumentGoods.Count AS Count,
		|	0 AS AmountIncludingVAT,
		|	DocumentGoods.Series AS Series,
		|	DocumentGoods.Warehouse AS Warehouse,
		|	TTDocuments.DocumentRef AS Ref
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS DocumentGoods
		|		INNER JOIN TTDocuments AS TTDocuments
		|		ON (TTDocuments.DocumentRef = DocumentGoods.Ref)
		|WHERE
		|	DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|	AND TTDocuments.Posted
		|	AND DocumentGoods.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
		|
		|	AND DocumentGoods.Status IN(
		|		VALUE(Enum.InternalOrderStatuses.ForCompletion),
		|		VALUE(Enum.InternalOrderStatuses.Closed))
		|
		|;
		|";
	
	Return QueryText;
	
EndFunction

Function TemporaryGoodsReceiptTableForProgressStateReport()
	
	QueryText = "
		|SELECT ALLOWED
		|	Set.DocumentInflow AS DocumentInflow,
		|	Set.Products        AS Products,
		|	Set.Characteristic      AS Characteristic,
		|	Set.Warehouse               AS Warehouse,
		|
		|	FALSE                      AS SeparatePurchase,
		|
		|	SUM(Set.Accepts) AS Accepts,
		|	SUM(Set.Accepted)     AS Accepted,
		|	SUM(Set.Accept)     AS Accept,
		|	SUM(Set.Received)   AS Received,
		|
		|	SUM(Set.ToReceive) AS ToReceive,
		|	SUM(Set.ApplyAppearance)     AS ApplyAppearance,
		|	SUM(Set.Issued_1)    AS Issued_1,
		|
		|	MAX(Set.AdvancedWarehousingOnGoodsReceipt) AS AdvancedWarehousingOnGoodsReceipt
		|
		|INTO TTGoodsArrival
		|FROM(
		|	SELECT
		|		GoodsToReceive.DocumentInflow AS DocumentInflow,
		|		GoodsToReceive.Products        AS Products,
		|		GoodsToReceive.Characteristic      AS Characteristic,
		|		GoodsToReceive.Warehouse               AS Warehouse,
		|
		|		GoodsToReceive.AcceptsClosingBalance  AS Accepts,
		|		GoodsToReceive.GoodsReceiptNotesToRegisterExpense          AS Accepted,
		|		GoodsToReceive.GoodsReceiptNotesToRegisterClosingBalance AS Accept,
		|		GoodsToReceive.GoodsReceiptNotesToRegisterExpense          AS Received,
		|
		|		0                                              AS ToReceive,
		|		0                                              AS ApplyAppearance,
		|		0                                              AS Issued_1,
		|
		|		CASE WHEN GoodsToReceive.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|						AND &CurrentDate >= GoodsToReceive.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt THEN
		|					TRUE
		|				ELSE
		|					FALSE
		|			END                                      AS AdvancedWarehousingOnGoodsReceipt
		|	FROM
		|		AccumulationRegister.GoodsToReceive.BalanceAndTurnovers( , , , ,
		|				DocumentInflow IN(
		|					SELECT
		|						TTDocuments.DocumentRef
		|					FROM
		|						TTDocuments AS TTDocuments)) AS GoodsToReceive
		|
		|	UNION ALL
		|
		|	SELECT
		|		GoodsForRegistration.ByAssemblyDisassemblyOrder       AS DocumentInflow,
		|		GoodsForRegistration.Products        AS Products,
		|		GoodsForRegistration.Characteristic      AS Characteristic,
		|		GoodsForRegistration.ByAssemblyDisassemblyOrder.Warehouse AS Warehouse,
		|
		|		0                                    AS Accepts,
		|		0                                    AS Accepted,
		|		0                                    AS Accept,
		|		0                                    AS Received,
		|
		|		GoodsForRegistration.ToRegisterReceipt          AS ToReceive,
		|		GoodsForRegistration.ToRegisterClosingBalance AS ApplyAppearance,
		|		GoodsForRegistration.ToRegisterExpense          AS Issued_1,
		|
		|		CASE WHEN GoodsForRegistration.ByAssemblyDisassemblyOrder.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|						AND &CurrentDate >= GoodsForRegistration.ByAssemblyDisassemblyOrder.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt THEN
		|					TRUE
		|				ELSE
		|					FALSE
		|			END                                    AS AdvancedWarehousingOnGoodsReceipt
		|	FROM
		|		AccumulationRegister.AssemblyOrders.BalanceAndTurnovers(, , , ,
		|				(ByAssemblyDisassemblyOrder, AssemblyType) IN(
		|					SELECT
		|						TTDocuments.DocumentRef AS ByAssemblyDisassemblyOrder,
		|						VALUE(Enum.InventoryMovementTypes.Inpayment) AS AssemblyType
		|					FROM
		|						TTDocuments AS TTDocuments)) AS GoodsForRegistration) AS Set
		|GROUP BY
		|	Set.DocumentInflow,
		|	Set.Products, Set.Characteristic, Set.Warehouse
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////";
	
	Return QueryText;
	
EndFunction

Function TemporaryTableProductsOrdersReceiptOrderForStateOfCompletionReport()
	
	QueryText = "
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentGoods.Products AS Products,
		|	DocumentGoods.Characteristic AS Characteristic,
		|	SUM(DocumentGoods.Count) AS Count,
		|	0 AS AmountIncludingVAT,
		|	DocumentGoods.Ref.Warehouse AS Warehouse,
		|	TTDocuments.DocumentRef AS Ref
		|INTO TTGoodsNewArrival
		|FROM
		|	Document.ByAssemblyDisassemblyOrder.Goods AS DocumentGoods
		|		INNER JOIN TTDocuments AS TTDocuments
		|		ON (TTDocuments.DocumentRef = DocumentGoods.Ref)
		|WHERE
		|	NOT DocumentGoods.Canceled
		|	AND TTDocuments.Posted
		|	AND DocumentGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
		|
		|	AND DocumentGoods.Ref.Status IN(
		|			VALUE(Enum.InternalOrderStatuses.ForCompletion),
		|			VALUE(Enum.InternalOrderStatuses.Closed))
		|		AND DocumentGoods.Ref.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|
		|
		|GROUP BY
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	DocumentGoods.Ref.Warehouse,
		|	TTDocuments.DocumentRef
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentGoods.Products AS Products,
		|	DocumentGoods.Characteristic AS Characteristic,
		|	DocumentGoods.Count AS Count,
		|	0 AS AmountIncludingVAT,
		|	DocumentGoods.Warehouse AS Warehouse,
		|	TTDocuments.DocumentRef AS Ref
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS DocumentGoods
		|		INNER JOIN TTDocuments AS TTDocuments
		|		ON (TTDocuments.DocumentRef = DocumentGoods.Ref)
		|WHERE
		|	TTDocuments.Posted
		|	AND DocumentGoods.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|		AND TRUE IN (
		|			SELECT TOP 1
		|				TRUE
		|			FROM
		|				Document.ByAssemblyDisassemblyOrder.Goods AS Components
		|			WHERE
		|				Components.Ref = DocumentGoods.Ref
		|					AND NOT Components.Canceled
		|					AND Components.SupplyOption = VALUE(Enum.SupplyOptions.Ship))
		|	AND DocumentGoods.Status IN(
		|		VALUE(Enum.InternalOrderStatuses.ForCompletion),
		|		VALUE(Enum.InternalOrderStatuses.Closed))
		|;
		|";
	
	Return QueryText;
	
EndFunction

Function CanceledShipmentTableForProgressStateReport()
	
	QueryText = "
		|SELECT
		|	TTDocuments.DocumentRef AS Document,
		|	DocumentGoods.LineNumber AS LineNumber,
		|	DocumentGoods.Products AS Products,
		|	DocumentGoods.Characteristic AS Characteristic,
		|	DocumentGoods.NumberOfPackages AS Count,
		|	CASE 
		|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) 
		|	THEN
		|		DocumentGoods.Products.UnitOfMeasure
		|	ELSE
		|		DocumentGoods.Package
		|	END AS Package,
		|	"""" AS CancellationReason,
		|	0 AS Sum
		|FROM
		|	Document.ByAssemblyDisassemblyOrder.Goods AS DocumentGoods
		|	INNER JOIN TTDocuments AS TTDocuments
		|		ON TTDocuments.DocumentRef = DocumentGoods.Ref
		|WHERE
		|	DocumentGoods.Canceled
		|	AND DocumentGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|
		|UNION ALL
		|
		|SELECT
		|	TTDocuments.DocumentRef AS Document,
		|	1 AS LineNumber,
		|	DocumentGoods.Products AS Products,
		|	DocumentGoods.Characteristic AS Characteristic,
		|	DocumentGoods.NumberOfPackagesCanceled AS Count,
		|	CASE 
		|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) 
		|	THEN
		|		DocumentGoods.Products.UnitOfMeasure
		|	ELSE
		|		DocumentGoods.Package
		|	END AS Package,
		|	"""" AS CancellationReason,
		|	0 AS Sum
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS DocumentGoods
		|	INNER JOIN TTDocuments AS TTDocuments
		|		ON TTDocuments.DocumentRef = DocumentGoods.Ref
		|WHERE
		|	DocumentGoods.CountCanceled > 0
		|	AND DocumentGoods.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
		|
		|TOTALS BY
		|	Document;
		|";
	
	Return QueryText
	
EndFunction

Function CanceledReceiptTableForProgressStateReport()
	
	QueryText = "
		|SELECT
		|	TTDocuments.DocumentRef AS Document,
		|	DocumentGoods.LineNumber AS LineNumber,
		|	DocumentGoods.Products AS Products,
		|	DocumentGoods.Characteristic AS Characteristic,
		|	DocumentGoods.NumberOfPackages AS Count,
		|	CASE 
		|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) 
		|	THEN
		|		DocumentGoods.Products.UnitOfMeasure
		|	ELSE
		|		DocumentGoods.Package
		|	END AS Package,
		|	"""" AS CancellationReason,
		|	0 AS Sum
		|FROM
		|	Document.ByAssemblyDisassemblyOrder.Goods AS DocumentGoods
		|	INNER JOIN TTDocuments AS TTDocuments
		|		ON TTDocuments.DocumentRef = DocumentGoods.Ref
		|WHERE
		|	DocumentGoods.Canceled
		|	AND DocumentGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
		|
		|UNION ALL
		|
		|SELECT
		|	TTDocuments.DocumentRef AS Document,
		|	1 AS LineNumber,
		|	DocumentGoods.Products AS Products,
		|	DocumentGoods.Characteristic AS Characteristic,
		|	DocumentGoods.NumberOfPackagesCanceled AS Count,
		|	CASE 
		|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) 
		|	THEN
		|		DocumentGoods.Products.UnitOfMeasure
		|	ELSE
		|		DocumentGoods.Package
		|	END AS Package,
		|	"""" AS CancellationReason,
		|	0 AS Sum
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS DocumentGoods
		|	INNER JOIN TTDocuments AS TTDocuments
		|		ON TTDocuments.DocumentRef = DocumentGoods.Ref
		|WHERE
		|	DocumentGoods.CountCanceled > 0
		|	AND DocumentGoods.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|
		|TOTALS BY
		|	Document;
		|";
	Return QueryText
	
EndFunction

#EndRegion

#Region CancelingUnprocessedRows

// Calculating the number of canceled sets in the document header
// Returns the flag for successful cancellation of unprocessed sets.
//
// Returns:
//   - Boolean
//
Function AdjustYourServer(DocumentObject, UndoLines, CorrectMeasuringGoods) Export
	
	IssuedSets = Documents.ByAssemblyDisassemblyOrder.IssuedSets(DocumentObject);
	
	If CorrectMeasuringGoods Then
		
		InventoryMovementType = ?(DocumentObject.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents,
			Enums.InventoryMovementTypes.Inpayment, Enums.InventoryMovementTypes.Shipment);
		AcceptableDeviations = Documents.ByAssemblyDisassemblyOrder.PermissibleDeviationsOfMeasuredGoods(DocumentObject.Ref, InventoryMovementType);
		
		If AcceptableDeviations <> Undefined Then
			
			TheStructureOfTheSearch = New Structure("Products, Characteristic", DocumentObject.Products, DocumentObject.Characteristic);
			
			SetStrings_ = AcceptableDeviations.FindRows(TheStructureOfTheSearch);
			Deviation = DocumentObject.Count - IssuedSets;
			
			If SetStrings_.Count() <> 0 And Max(Deviation, -Deviation) <= SetStrings_[0].AllowableVariance Then
				
				DocumentObject.Count = IssuedSets;
				StructureOfActions = New Structure("RecalculateNumberOfPackages");
				BatchProcessingOfTablePartServer.ProcessTSString(DocumentObject, StructureOfActions, Undefined);
				
				Return True;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If UndoLines And DocumentObject.Count > IssuedSets Then
		
		DocumentObject.CountCanceled = DocumentObject.CountCanceled +
			DocumentObject.Count - IssuedSets;
		DocumentObject.Count = IssuedSets;
		
		NumberOfPackagesBeforeCanceled = DocumentObject.NumberOfPackages;
		StructureOfActions = New Structure("RecalculateNumberOfPackages");
		BatchProcessingOfTablePartServer.ProcessTSString(DocumentObject, StructureOfActions, Undefined);
		DocumentObject.NumberOfPackagesCanceled = DocumentObject.NumberOfPackagesCanceled +
			NumberOfPackagesBeforeCanceled - DocumentObject.NumberOfPackages;
		
		Return True;
		
	EndIf;
	
	Return False;
	
EndFunction

// Parameters:
//  DocumentObject - DocumentObject.ByAssemblyDisassemblyOrder 
Procedure CancelUnprocessedSeriesOfSets(DocumentObject) Export
	
	SeriesSpecificationParameters =
		New FixedStructure(ProductsServer.SeriesSpecificationParameters(DocumentObject, Documents.ByAssemblyDisassemblyOrder));
	
	// The procedure is available if disassembly and series are used
	If Not SeriesSpecificationParameters.Header.UseItemsBatch 
		And DocumentObject.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents Then
		Return;
	EndIf;
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	TTSeriesOrder.Series,
	|	TTSeriesOrder.Count,
	|	TTSeriesOrder.Products,
	|	TTSeriesOrder.Characteristic,
	|	TTSeriesOrder.Purpose
	|INTO TTSeriesOrder
	|FROM
	|	&OrderSeries AS TTSeriesOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrderSeries.Series,
	|	SUM(OrderSeries.Count) AS Count,
	|	OrderSeries.Products,
	|	OrderSeries.Characteristic,
	|	OrderSeries.Purpose
	|INTO OrderSeries
	|FROM
	|	TTSeriesOrder AS OrderSeries
	|
	|GROUP BY
	|	OrderSeries.Series,
	|	OrderSeries.Characteristic,
	|	OrderSeries.Purpose,
	|	OrderSeries.Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForIssueBalance.Series              AS Series,
	|	GoodsForIssueBalance.Products       AS Products,
	|	GoodsForIssueBalance.Characteristic     AS Characteristic,
	|	GoodsForIssueBalance.Purpose         AS Purpose,
	|	GoodsForIssueBalance.ToShipBalance   AS ToShipBalance,
	|	GoodsForIssueBalance.ToRegisterBalance AS ToRegisterBalance,
	|	CASE
	|		WHEN GoodsForIssueBalance.ToShipBalance < GoodsForIssueBalance.ToRegisterBalance
	|			THEN GoodsForIssueBalance.ToShipBalance
	|		ELSE GoodsForIssueBalance.ToRegisterBalance
	|	END AS QuantityShortage_
	|INTO RegisterSeries_
	|FROM
	|	AccumulationRegister.GoodsForIssue.Balance(, DocumentShipments = &OrderDocument) AS GoodsForIssueBalance
	|		INNER JOIN OrderSeries AS OrderSeries
	|		ON GoodsForIssueBalance.Series = OrderSeries.Series
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AssemblyOrdersBalance.Series              AS Series,
	|	AssemblyOrdersBalance.Products       AS Products,
	|	AssemblyOrdersBalance.Characteristic     AS Characteristic,
	|	AssemblyOrdersBalance.ToRegisterBalance AS QuantityShortage_
	|INTO ConsignmentNoteSeries
	|FROM
	|	AccumulationRegister.AssemblyOrders.Balance(, ByAssemblyDisassemblyOrder = &OrderDocument) AS AssemblyOrdersBalance
	|		INNER JOIN OrderSeries AS OrderSeries
	|		ON AssemblyOrdersBalance.Series = OrderSeries.Series
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrderSeries.Series,
	|	OrderSeries.Products,
	|	OrderSeries.Characteristic,
	|	OrderSeries.Purpose,
	|	CASE
	|		WHEN ISNULL(ConsignmentNoteSeries.QuantityShortage_, 0) > ISNULL(RegisterSeries_.QuantityShortage_, 0)
	|			THEN ISNULL(RegisterSeries_.QuantityShortage_, 0)
	|		ELSE ISNULL(ConsignmentNoteSeries.QuantityShortage_, 0)
	|	END AS QuantityShortage_,
	|	RegisterSeries_.ToShipBalance,
	|	RegisterSeries_.ToRegisterBalance
	|FROM
	|	OrderSeries AS OrderSeries
	|		LEFT JOIN RegisterSeries_ AS RegisterSeries_
	|		ON OrderSeries.Products = RegisterSeries_.Products
	|			AND OrderSeries.Characteristic = RegisterSeries_.Characteristic
	|			AND OrderSeries.Series = RegisterSeries_.Series
	|			AND OrderSeries.Purpose = RegisterSeries_.Purpose
	|		LEFT JOIN ConsignmentNoteSeries AS ConsignmentNoteSeries
	|		ON OrderSeries.Products = ConsignmentNoteSeries.Products
	|			AND OrderSeries.Characteristic = ConsignmentNoteSeries.Characteristic
	|			AND OrderSeries.Series = ConsignmentNoteSeries.Series
	|WHERE
	|	ISNULL(RegisterSeries_.QuantityShortage_, OrderSeries.Count) > 0";
	
	Query.SetParameter("OrderDocument", DocumentObject.Ref);
	
	If DocumentObject.BatchesIndicationStatus = 14 Then
		
		VTSeries = DocumentObject.SetOfSeries.Unload();
		VTSeries.Clear();
		
		SeriesInHeader = VTSeries.Add();
		FillPropertyValues(SeriesInHeader, DocumentObject);
		
		Query.SetParameter("OrderSeries", VTSeries);
		
	Else
		// Statuscazationseries = 10
		// The tabular part of the Series is used.
		Query.SetParameter("OrderSeries", DocumentObject.SetOfSeries.Unload());
	EndIf;
	
	Result = Query.Execute().Select();
	
	ArrayDeletition = New Array();
	
	While Result.Next() Do
		
		If DocumentObject.BatchesIndicationStatus = 14 Then
			// The series field in the header is used
			
			// The quantity in the header is modified by the procedure to cancel the unprocessed server components
			// In this procedure, only the Series field is modified in the header.
			If DocumentObject.Series = Result.Series 
				And (DocumentObject.Count = Result.QuantityShortage_ Or DocumentObject.Count = 0) Then
				DocumentObject.Series = PredefinedValue("Catalog.ItemsBatches.EmptyRef");
			EndIf;
			
		Else
			// Statuscazationseries = 10
			// The tabular part of the Series is used.
			
			Filter = New Structure();
			Filter.Insert("Series",				Result.Series);
			Filter.Insert("Products",		Result.Products);
			Filter.Insert("Characteristic",	Result.Characteristic);
			Filter.Insert("Purpose",		Result.Purpose);
			
			SeriesLines_ = DocumentObject.SetOfSeries.FindRows(Filter);
			
			Shortage_ = Result.QuantityShortage_;
			For Each SeriesString In SeriesLines_ Do
				
				If SeriesString.Count = Shortage_ Then
					ArrayDeletition.Add(SeriesString);
					Shortage_ = 0;
				Else
					Subtractible = Min(SeriesString.Count, Shortage_);
					SeriesString.Count = SeriesString.Count - Subtractible;
					Shortage_ = Shortage_ - Subtractible;
					
					If SeriesString.Count = 0 Then
						ArrayDeletition.Add(SeriesString);
					EndIf;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	ArrayDeletition = CommonClientServer.CollapseArray(ArrayDeletition);
	
	For Each RowToDelete In ArrayDeletition Do
		DocumentObject.SetOfSeries.Delete(RowToDelete);
	EndDo;
	
EndProcedure

#EndRegion

#Region FormationOfHyperlinkInJournalOfDocumentsOfInternalCommodityMovement

Function ThereAreOrdersInProgress(Parameters)
	
	Query = New Query(
		"SELECT ALLOWED TOP 1
		|	OrderStates.OrderDocument AS OrderDocument,
		|	OrderStates.State AS State
		|FROM
		|	InformationRegister.StatusesOfInternalOrders AS OrderStates
		|WHERE
		|	OrderStates.OrderDocument REFS Document.ByAssemblyDisassemblyOrder
		|	AND OrderStates.State <> VALUE(Enum.StatusesOfInternalOrders.Closed)");
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function CreateHyperlinkSeeAlsoIn(Parameters) Export
	
	If Not (AccessRight("Read", Metadata.InformationRegisters.StatusesOfInternalOrders)
			And AccessRight("Update", Metadata.Documents.ByAssemblyDisassemblyOrder)
			And GetFunctionalOption("UseAssemblyDisassemblyOrders")) Then
		Return Undefined;
	EndIf;
	
	HyperlinkText = NStr("vi = 'Đơn hàng đóng bộ (tách bộ)';
						|ru = 'Заказы на сборку (разборку)';
						|en = 'Kitting orders'; fa = 'سفارش‌های کیت‌سازی';
						|it = 'Ordini di assemblaggio (disassemblaggio)';
						|pl = 'Zamówienia na montaż (demontaż)';
						|tr = 'Montaj için siparişler (demontaj)'");
	HyperlinkAnchorText = "Document.ByAssemblyDisassemblyOrder.Form.ListForm";
	
	If ThereAreOrdersInProgress(Parameters) Then
		Return New FormattedString(HyperlinkText,,,, HyperlinkAnchorText);
	Else
		Return New FormattedString(HyperlinkText,, StyleColors.EmptyTableField,, HyperlinkAnchorText);
	EndIf;
	
EndFunction

#EndRegion

#Region Assignments

// Returns a template for generating product assignments in the document.
//
// Parameters:
// 		Object - DocumentObject.ByAssemblyDisassemblyOrder, FormDataStructure - the build order to get the destination template for.
//
// Returns:
// 		See Catalogs.Assignments.NewSubmenuTemplate
//
Function DestinationPattern(Object) Export
	
	DestinationPattern = Catalogs.Assignments.NewSubmenuTemplate();
	
	If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(Object.LineOfBusiness) Then
		DestinationPattern.LineOfBusiness = Object.LineOfBusiness;
	EndIf;
	
	OptionOfAssignment = Constants.OptionOfGoodsAssignmentInAssembly.Get();
	
	If OptionOfAssignment <> Enums.OptionsOfGoodsAssignmentInAssembly.LineOfBusiness
		Or Not ValueIsFilled(DestinationPattern.LineOfBusiness) Then
		
		DestinationPattern.OrderDocument = Object.Ref;
		
	EndIf;
	
	Return DestinationPattern;
	
EndFunction

#EndRegion

#Region VATActivityType

Function ParametersForFillingInVATActivityType(Document) Export
	
	Attributes = New Structure("Date, Organization, Warehouse, LineOfBusiness");
	
	If TypeOf(Document) = Type("DocumentRef.ByAssemblyDisassemblyOrder") Then
		Attributes = Common.ObjectAttributesValues(Document, Attributes);
	Else
		FillPropertyValues(Attributes, Document);
	EndIf;
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Date = Attributes.Date;
	FillParameters.Warehouse = Attributes.Warehouse;
	FillParameters.Organization = Attributes.Organization;
	FillParameters.LineOfBusiness = Attributes.LineOfBusiness;
	
	FillParameters.AssemblyDisassemblyOfGoods = True;
	
	Return FillParameters;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
