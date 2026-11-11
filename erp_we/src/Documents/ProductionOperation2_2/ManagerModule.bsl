#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("Production");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ProductionOperation2_2") Then
		DocumentObject = Document;
		DocumentRef = Document.Ref;
	Else
		DocumentObject = Document.GetObject();
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
		
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableLaborCostsToRegister(Query, QueryTexts, Registers, DocumentObject);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region Commands

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds the "Production operation" document creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  - ValueTableRow
//  - Undefined
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.ProductionOperation2_2) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ProductionOperation2_2.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ProductionOperation2_2);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseOperationManagement";
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateProductionOperationBasedOn";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ProductionOperation";
	PrintCommand.Presentation = NStr("vi = 'Giao dịch sản xuất';
									|ru = 'Производственная операция';
									|en = 'Routing operation'; fa = 'عملیات مسیر تولید';
									|it = 'Operazione produttiva';
									|pl = 'Operacja produkcyjna';
									|tr = 'Rota işlemi'");
	PrintCommand.CheckPostingBeforePrint = True;
	
	//
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ProductionOperationLabel";
	PrintCommand.Presentation = NStr("vi = 'Nhãn giao dịch';
									|ru = 'Этикетка операции';
									|en = 'Operation label'; fa = 'Operation label';
									|it = 'Etichetta dell''operazione';
									|pl = 'Etykieta operacji';
									|tr = 'İşlem etiketi'");
	PrintCommand.CheckPostingBeforePrint = True;
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "DefectiveGoodsCertificate";
	PrintCommand.Presentation = NStr("vi = 'Biên bản hàng hỏng';
									|ru = 'Акт о браке';
									|en = 'Nonconformity report'; fa = 'گزارش عدم انطباق';
									|it = 'Verbale difetto riscontrato';
									|pl = 'Protokół o wadach';
									|tr = 'Uygunsuzluk tutanağı'");
	PrintCommand.CheckPostingBeforePrint = True;
	
EndProcedure

#EndRegion

#Region DocumentStatus

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
	
	Query = New Query(
		"SELECT
		|	DocumentsTable.Ref                AS Ref,
		|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
		|	DocumentsTable.Status                AS CurrentStatus,
		|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
		|	&Status                                 AS NewStatus,
		|	PRESENTATION(&Status)                  AS PresentationOfNewStatus,
		|	CASE
		|		WHEN DocumentsTable.Status = &Status
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                   AS StatusMatches,
		|	DocumentsTable.Posted              AS Posted,
		|	DocumentsTable.DeletionMark       AS DeletionMark,
		|	DocumentsTable.Skippable       AS Skippable,
		|	TRUE                                  AS Recording
		|FROM
		|	Document.ProductionOperation2_2 AS DocumentsTable
		|WHERE
		|	DocumentsTable.Ref IN(&DocumentsArray)");
		
	Query.SetParameter("Status", ProductionAccountingClientServer.StatusOfOperationLink(NewStatus));
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes
//
// Parameters:
//	ValidationSample - QueryResultSelection - Current selection string
//	NewStatus - String - Name of the new status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Return Not (NewStatus = "IsSkipped"
		And Not ValidationSample.Skippable);
	
EndFunction

// Performs the actions required when setting a new document status
//
// Parameters:
//  Object - FormDataStructure, DocumentObject - the object where the status changes.
//
Procedure FillInDetailsWhenSettingStatus(Object) Export
	
	If Object.Status = Enums.ProductionOperationStatuses.Executed Then
		
		QuantityToPerform = ProductionAccountingClientServer.QuantityToPerform(Object);
		If QuantityToPerform > 0 Then
			
			NewRecord = ProductionAccountingClientServer.RecordProtocolConstructor("Perform");
			NewRecord.Count = QuantityToPerform;
			AddProtocolEntry(Object, NewRecord);
			
		EndIf;
		
		If Object.QuantityUnderRevision > 0 Then
			
			NewRecord = ProductionAccountingClientServer.RecordProtocolConstructor("PresentForControl");
			NewRecord.Count = Object.QuantityUnderRevision;
			AddProtocolEntry(Object, NewRecord);
			
		EndIf;
		
	Else
		
		AttributesList = "";
		
		If Object.Status = Enums.ProductionOperationStatuses.BeingGenerated
				Or Object.Status = Enums.ProductionOperationStatuses.CreatedOn_ Then
			AttributesList = "FollowUp,QuantityUnderRevision,DefectiveGoodsCount,CountCanceled,CountReal";
			NameOfEvent  = "Cancellation";
		ElsIf Object.Status = Enums.ProductionOperationStatuses.NotExecuted
				Or Object.Status = Enums.ProductionOperationStatuses.IsSkipped Then
			AttributesList = "FollowUp,QuantityUnderRevision,DefectiveGoodsCount,CountReal";
			NameOfEvent  = "Cancellation";
		EndIf;
		
		If Not IsBlankString(AttributesList) Then
		
			Totals = ProductionAccountingClientServer.StructureOfResultsConstructor(Object);
			
			For Each AttributeName In StrSplit(AttributesList, ",") Do
				
				NumberIsReversed = Totals[AttributeName];
				If NumberIsReversed > 0 Then
					
					NewRecord = ProductionAccountingClientServer.RecordProtocolConstructor(NameOfEvent);
					NewRecord.PreviousState = AttributeName;
					NewRecord.Count          = NumberIsReversed;
					NewRecord.Comment         = StrTemplate(NStr("vi = 'Đặt trạng thái ""%1""';
																|ru = 'Установка статуса ""%1""';
																|en = 'Set the ""%1"" status'; fa = 'Set the ""%1"" status';
																|it = 'Impostazione stato ""%1""';
																|pl = 'Ustawienie statusu ""%1""';
																|tr = '""%1"" durumunun yapılandırılması'"), Object.Status);
					AddProtocolEntry(Object, NewRecord);
				
				EndIf;
				
			EndDo;
		
		EndIf;
		
		Object.RepetitionIsRequired = False;
		
	EndIf;
	
	ProductionManagement.SetDateByMark(
		Object.Status = Enums.ProductionOperationStatuses.Running
			Or Object.Status = Enums.ProductionOperationStatuses.Executed,
		Object.ExecutionStarted);
	
	ProductionManagement.SetDateByMark(
		Object.Status = Enums.ProductionOperationStatuses.Executed,
		Object.ExecutionEnd);
	
	FillInStatusesForSpecifyingSeries(Object);
	
EndProcedure

// The procedure fills in the statuses of specifying series in the rows of table parts
//
Procedure FillInStatusesForSpecifyingSeries(Object) Export
	
	SeriesSpecificationParameters = Documents.ProductionOperation2_2.SeriesSpecificationParameters(Object);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.ManufacturedProducts);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.MaterialsAndWorks);
	
EndProcedure

#EndRegion

#Region StandardSubsystems

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Date, Status, Stage, BasedOnMasterData, Department";
	
	Return AttributesNames;
	
EndFunction

// Returns parameters for specifying series for products specified in the document
//
// Parameters:
//  Object	 - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = New Structure;
	
	ProductionSettings = ProductionServer.UseOfSeriesInProduction22();
	
	If Object.BasedOnMasterData Then
		FilterManufacturedProducts   = True;
		FilterMaterialsAndWorks  = True;
	Else
		DivisionParameters = ProductionServer.ProductionBusinessUnitDescription(Object.Department);
		FilterManufacturedProducts   = DivisionParameters.UseFinishedProductsInOperations;
		FilterMaterialsAndWorks  = DivisionParameters.UseMaterialsInOperations;
	EndIf;
	
	#Region ManufacturedProducts
	
	ParametersForSpecifyingTSSeries = ProductsClientServer.SeriesSpecificationParameters();
	ParametersForSpecifyingTSSeries.FullObjectName = "Document.ProductionOperation2_2";
	
	ParametersForSpecifyingTSSeries.WarehouseFieldName = "Department";
	ParametersForSpecifyingTSSeries.NameTSGoods = "ManufacturedProducts";
	ParametersForSpecifyingTSSeries.TSSeriesName = "BatchFinishedProducts";
	
	ParametersForSpecifyingTSSeries.UseCostAccountingByBatches = ProductionSettings.UseCostAccountingByBatches;
	ParametersForSpecifyingTSSeries.UseItemsBatch  = ProductionSettings.UseItemsBatch;
	
	ParametersForSpecifyingTSSeries.SeriesWhenPlanningShipmentVHFSeriesAreIndicated = True;
	
	ParametersForSpecifyingTSSeries.WarehouseTransactions.Add(Enums.WarehouseTransactions.ManufactureOfProducts);
	
	ParametersForSpecifyingTSSeries.ThisIsAnInvoice = True;
	
	ParametersForSpecifyingTSSeries.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	
	ParametersForSpecifyingTSSeries.FactOfSelection = (Object.Status = Enums.ProductionOperationStatuses.Executed) And FilterManufacturedProducts;
	
	ParametersForSpecifyingTSSeries.Date = Object.Date;
	
	ParametersForSpecifyingTSSeries.FieldNamesForOrderDefinition.Add("Ref");
	
	SeriesSpecificationParameters.Insert("ManufacturedProducts", ParametersForSpecifyingTSSeries);
	
	#EndRegion
	
	#Region MaterialsAndWorks
	
	ParametersForSpecifyingTSSeries = ProductsClientServer.SeriesSpecificationParameters();
	ParametersForSpecifyingTSSeries.FullObjectName = "Document.ProductionOperation2_2";
	
	ParametersForSpecifyingTSSeries.WarehouseFieldName = "Department";
	ParametersForSpecifyingTSSeries.NameTSGoods = "MaterialsAndWorks";
	ParametersForSpecifyingTSSeries.TSSeriesName  = "MaterialsAndWorks";
	
	ParametersForSpecifyingTSSeries.UseCostAccountingByBatches = ProductionSettings.UseCostAccountingByBatches;
	ParametersForSpecifyingTSSeries.UseItemsBatch  = ProductionSettings.UseItemsBatch;
	
	ParametersForSpecifyingTSSeries.WarehouseTransactions.Add(Enums.WarehouseTransactions.ConsumptionDuringProduction);
	
	ParametersForSpecifyingTSSeries.ThisIsAnInvoice = True;
	
	ParametersForSpecifyingTSSeries.RegisterSeries = True; // the series registration form is always used (you can also choose from the leftovers in it)
	ParametersForSpecifyingTSSeries.ShipmentPlanning = False;
	ParametersForSpecifyingTSSeries.SelectionPlanning = False;
	
	ParametersForSpecifyingTSSeries.FactOfSelection = (Object.Status = Enums.ProductionOperationStatuses.Executed) And FilterMaterialsAndWorks;
	
	ParametersForSpecifyingTSSeries.Date = Object.Date;
	
	SeriesSpecificationParameters.Insert("MaterialsAndWorks", ParametersForSpecifyingTSSeries);
	
	#EndRegion
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the value of the receipt or shipment order.
//
// Parameters:
//  FieldValuesToIdentifyReferences	 - Structure - the composition of the fields is determined by the value
//  of the field name field to determine the Distribution of parameters for specifying series in this document.
//
// Returns:
//  DocumentRef.ProductionStage2_2 - Link to the order.
//
Function OrderToPerformWarehouseOperation(FieldValuesToIdentifyReferences) Export
	Return FieldValuesToIdentifyReferences.Ref;
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	If SeriesSpecificationParameters.NameTSGoods = "ManufacturedProducts" Then
		
		QueryText = TextOfRequestToFillInStatusesForSpecifyingSerialNumberOfProduct();
		
	ElsIf SeriesSpecificationParameters.NameTSGoods = "MaterialsAndWorks" Then
		
		QueryText = RequestTextForFillingInStatusesSpecifyingSeriesMaterialsAndWorks();
		
	EndIf;
	
	Return QueryText;

EndFunction

#EndRegion

#Region Other

// Assigns the work center to the selected operations operations
//
// Parameters:
//  Operation	 - DocumentRef.ProductionOperation2_2, Array of DocumentRef.ProductionOperation2_2 - document or array of documents " Production operation"
//  WorkCenter - CatalogRef.WorkCenters						 - assigned work center.
//  SetupSettings - CatalogRef.SetupOptions					 - assignable setup option.
//
Procedure AssignWorkCenterToOperations(Operation, WorkCenter, SetupSettings = Undefined) Export
	
	ReferencesArrray = ProductionManagementClientServer.ArrayOfValues(Operation); // Array of DocumentRef.ProductionOperation2_2
	TypeOfWorkCenter = New TypeDescription("CatalogRef.WorkCenters");
	
	If Not WorkCenter.IsEmpty() Then
		Attributes = Common.ObjectAttributesValues(WorkCenter, "WorkCenterType, WorkTimeFactor");
	Else
		Attributes = WorkCentersTypesOfOperations(ReferencesArrray);
	EndIf;
	
	For Each Operation In ReferencesArrray Do
		
		DocumentObject = Operation.GetObject();
		
		Try
			DocumentObject.Lock();
		Except
			ExceptionText = StrTemplate(
				NStr("vi = 'Không thể chỉnh sửa chứng từ %1. Có thể chứng từ hiện đang được chỉnh sửa.';
					|ru = 'Не удалось изменить документ %1. Возможно, документ в настоящий момент редактируется.';
					|en = 'Cannot change the %1 document. Maybe, the document is being edited.'; fa = 'Cannot change the %1 document. Maybe, the document is being edited.';
					|it = 'Impossibile modificare il documento %1. Il documento potrebbe essere in corso di modifica.';
					|pl = 'Nie można zmienić dokumentu %1. Możliwie, że dokument jest teraz edytowany.';
					|tr = '%1 belgesi değiştirilemedi. Belge şu anda düzenleniyor olabilir.'"),
				Operation);
			Raise ExceptionText;
		EndTry;
		
		If Not WorkCenter.IsEmpty() Then
			
			WorkCenterBeforeChange = TypeOfWorkCenter.AdjustValue(DocumentObject.WorkCenter); // CatalogRef.WorkCenters
			If ValueIsFilled(WorkCenterBeforeChange) Then
				CoefficientOfWorkingTimeBeforeChange = Common.ObjectAttributeValue(WorkCenterBeforeChange, "WorkTimeFactor");
			Else
				CoefficientOfWorkingTimeBeforeChange = 1;
			EndIf;
			
			DocumentObject.RunTime = Attributes.WorkTimeFactor*DocumentObject.RunTime/CoefficientOfWorkingTimeBeforeChange;
			DocumentObject.WorkCenter = WorkCenter;
			
		Else
			
			DocumentObject.WorkCenter = Attributes[Operation];
			
		EndIf;
		
		DocumentObject.SetupSettings = SetupSettings;
		
		DocumentObject.Write(DocumentWriteMode.Write);
		DocumentObject.Unlock();
		
	EndDo;
	
EndProcedure

// Total lead time of operation
// 
// Parameters:
//  Object - DocumentObject.ProductionOperation2_2
//  WorkCenterBeforeChange - CatalogRef.WorkCenters
Procedure RecalculateExecutionTime(Object, WorkCenterBeforeChange = Undefined) Export
	
	CalculationStructure1 = ProductionAccountingClientServer.StructureOfCalculationOfTotalExecutionTime();
	FillPropertyValues(CalculationStructure1, Object);
	FillPropertyValues(CalculationStructure1, ProductionAccounting.AttributesOfWorkCenter(Object.WorkCenter));
	
	CalculationAccordingToAttributesOfNSI = ValueIsFilled(Object.TimePerPiece) Or ValueIsFilled(Object.SetupTime);
	
	If CalculationAccordingToAttributesOfNSI Then
		
		ProductionAccountingClientServer.CalculateTotalOperationTime(
			CalculationStructure1, Object.Count - Object.CountCanceled);
			
		FillPropertyValues(Object, CalculationStructure1, "RunTime, ExecutionTimeUnitOfMeasure");
		
	Else
		
		CalculationStructure2 = ProductionAccountingClientServer.StructureOfCalculationOfTotalExecutionTime();
		FillPropertyValues(CalculationStructure2, ProductionAccounting.AttributesOfWorkCenter(WorkCenterBeforeChange));
		
		Object.RunTime = CalculationStructure1.WorkTimeFactor * CalculationStructure1.RunTime / CalculationStructure2.WorkTimeFactor;
		
	EndIf;
	
EndProcedure

// Gets the data of the executed documents.
//
// Parameters:
//  Stage - DocumentRef.ProductionStage2_2 - the stage for the selection of operations.
//
// Returns:
//  Structure - contains the collapsed data of the tabular parts of the performed operations.
//
Function DataOfOperationsPerformed(Stage) Export
	
	Query = New Query(
		"SELECT
		|	BEGINOFPERIOD(Document.ExecutionEnd, DAY) AS ExecutionDate,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	SUM(Table.NumberOfPackages) AS NumberOfPackages,
		|	SUM(Table.Count) AS Count,
		|	Table.Package AS Package,
		|	Table.Series AS Series,
		|	Document.Department AS Department,
		|	Table.Products.ItemsType AS ItemsType
		|FROM
		|	Document.ProductionOperation2_2 AS Document
		|		LEFT JOIN Document.ProductionOperation2_2.ManufacturedProducts AS Table
		|		ON Document.Ref = Table.Ref
		|WHERE
		|	Document.Stage = &Stage
		|	AND Document.Status = VALUE(Enum.ProductionOperationStatuses.Executed)
		|	AND Document.FollowUp = 0
		|	AND Document.Posted
		|	AND Table.Ref IS NOT NULL 
		|
		|GROUP BY
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Package,
		|	Table.Series,
		|	BEGINOFPERIOD(Document.ExecutionEnd, DAY),
		|	Document.Department
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BEGINOFPERIOD(Document.ExecutionEnd, DAY) AS ExecutionDate,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Series AS Series,
		|	Document.Department AS Department,
		|	SUM(Table.Count) AS Count
		|FROM
		|	Document.ProductionOperation2_2 AS Document
		|		LEFT JOIN Document.ProductionOperation2_2.BatchFinishedProducts AS Table
		|		ON Document.Ref = Table.Ref
		|WHERE
		|	Document.Stage = &Stage
		|	AND Document.Status = VALUE(Enum.ProductionOperationStatuses.Executed)
		|	AND Document.Posted
		|	AND Table.Ref IS NOT NULL 
		|
		|GROUP BY
		|	BEGINOFPERIOD(Document.ExecutionEnd, DAY),
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Series,
		|	Document.Department
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BEGINOFPERIOD(Document.ExecutionEnd, DAY) AS ExecutionDate,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Package AS Package,
		|	Table.Series AS Series,
		|	Table.ProductCostElement AS ProductCostElement,
		|	Document.Department AS Department,
		|	SUM(Table.NumberOfPackages) AS NumberOfPackages,
		|	SUM(Table.Count) AS Count
		|FROM
		|	Document.ProductionOperation2_2 AS Document
		|		LEFT JOIN Document.ProductionOperation2_2.MaterialsAndWorks AS Table
		|		ON Document.Ref = Table.Ref
		|WHERE
		|	Document.Stage = &Stage
		|	AND Document.Status = VALUE(Enum.ProductionOperationStatuses.Executed)
		|	AND Document.Posted
		|	AND Table.Ref IS NOT NULL 
		|
		|GROUP BY
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Package,
		|	Table.Series,
		|	Table.ProductCostElement,
		|	BEGINOFPERIOD(Document.ExecutionEnd, DAY),
		|	Document.Department
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BEGINOFPERIOD(Document.ExecutionEnd, DAY) AS ExecutionDate,
		|	Table.WorkKind AS WorkKind,
		|	Table.Performer AS Performer,
		|	Table.WorkAssignment AS WorkAssignment,
		|	Table.ProductCostElement AS ProductCostElement,
		|	Document.Department AS Department,
		|	SUM(Table.Count) AS Count
		|FROM
		|	Document.ProductionOperation2_2 AS Document
		|		LEFT JOIN Document.ProductionOperation2_2.LaborCosts AS Table
		|		ON Document.Ref = Table.Ref
		|WHERE
		|	Document.Stage = &Stage
		|	AND Document.Status = VALUE(Enum.ProductionOperationStatuses.Executed)
		|	AND Document.Posted
		|	AND Table.Ref IS NOT NULL 
		|
		|GROUP BY
		|	BEGINOFPERIOD(Document.ExecutionEnd, DAY),
		|	Table.WorkKind,
		|	Table.Performer,
		|	Table.WorkAssignment,
		|	Table.ProductCostElement,
		|	Document.Department
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.PackageBarcode AS PackageBarcode
		|FROM
		|	Document.ProductionOperation2_2 AS Document
		|		LEFT JOIN Document.ProductionOperation2_2.PackageBarcodes AS Table
		|		ON Document.Ref = Table.Ref
		|WHERE
		|	Document.Stage = &Stage
		|	AND Document.Status = VALUE(Enum.ProductionOperationStatuses.Executed)
		|	AND Document.Posted
		|	AND Table.Ref IS NOT NULL 
		|
		|GROUP BY
		|	BEGINOFPERIOD(Document.ExecutionEnd, DAY),
		|	Table.PackageBarcode
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.PackageBarcode AS PackageBarcode
		|FROM
		|	Document.ProductionOperation2_2 AS Document
		|		LEFT JOIN Document.ProductionOperation2_2.PackagingUnitBarcodesMaterials AS Table
		|		ON Document.Ref = Table.Ref
		|WHERE
		|	Document.Stage = &Stage
		|	AND Document.Status = VALUE(Enum.ProductionOperationStatuses.Executed)
		|	AND Document.Posted
		|	AND Table.Ref IS NOT NULL 
		|
		|GROUP BY
		|	BEGINOFPERIOD(Document.ExecutionEnd, DAY),
		|	Table.PackageBarcode
		|");
	
	Query.SetParameter("Stage", Stage);
	
	ResultsArray = Query.ExecuteBatch();
	
	Result = New Structure;
	
	Result.Insert("ManufacturedProducts", ResultsArray[0].Unload());
	Result.Insert("BatchFinishedProducts", ResultsArray[1].Unload());
	Result.Insert("MaterialsAndWorks", ResultsArray[2].Unload());
	Result.Insert("LaborCosts", ResultsArray[3].Unload());
	Result.Insert("PackageBarcodes", ResultsArray[4].Unload());
	Result.Insert("PackagingUnitBarcodesMaterials", ResultsArray[5].Unload());
	
	Return Result;
	
EndFunction

// Enables / disables the use of document properties.
//
Procedure SetUseOfProperties() Export
	
	ViewsAreUsed = Constants.UseKindsOfSpecificTechnologicalOperations.Get();
	
	Query = New Query(
		"SELECT DISTINCT
		|	OperationKinds.PropertiesSet AS Ref
		|FROM
		|	Catalog.TechnologicalOperationKinds AS OperationKinds
		|WHERE
		|	NOT OperationKinds.IsFolder
		|	AND OperationKinds.PropertiesSet.Used <> &Used
		|");
	Query.SetParameter("Used", ViewsAreUsed);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		CatObject = Selection.Ref.GetObject(); // CatalogObject - 
		CatObject.Used = ViewsAreUsed;
		CatObject.Write();
		
	EndDo;
	
EndProcedure

// Divides one document into two.
Procedure Split(Ref, FillingValues, BlockData = True) Export
	
	BeginTransaction();
	
	Try
		
		ObjectOld = Ref.GetObject(); // DocumentObject.ProductionOperation2_2
		
		If BlockData Then
			ObjectOld.Lock();
		EndIf;
		
		ObjectOld.SetSplitMode();
		
		Object_New = SelectOperation_(ObjectOld, FillingValues);
		
		// Document recording
		WriteMode = ?(ObjectOld.Posted, DocumentWriteMode.Posting, DocumentWriteMode.Write);
		ObjectOld.Write(WriteMode);
		Object_New.Write(WriteMode);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteLogEvent(
			NStr("vi = 'Giao dịch sản xuất';
				|ru = 'Производственные операции';
				|en = 'Routing operations'; fa = 'عملیات مسیر';
				|it = 'Operazioni produttivi';
				|pl = 'Operacje produkcyjne';
				|tr = 'Rota işlemleri'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			Metadata.Documents.ProductionOperation2_2,,
			DetailErrorDescription(ErrorInfo()));
		
		Raise BriefErrorDescription(ErrorInfo());
		
	EndTry;
	
EndProcedure

// The structure of the parameters of the partition of operation
// 
// Returns:
//  Structure - Splitting Parameters of Operation Constructor:
// * ProductionArea - CatalogRef.ProductionSites - 
// * WorkCenter - Undefined - 
// * Performer - Undefined - 
// * Count - Number - 
// * RunTime - Number - 
// * FollowUp - Number - 
// * QuantityUnderRevision - Number - 
// * DefectiveGoodsCount - Number - 
// * CountReal - Number - 
// * CountCanceled - Number - 
// * ControlAgain - Boolean - 
Function SplittingParametersOfOperationConstructor() Export
	
	Result = New Structure;
	
	Result.Insert("ProductionArea",               Catalogs.ProductionSites.EmptyRef());
	Result.Insert("WorkCenter",          Undefined);
	Result.Insert("Performer",           Undefined);
	Result.Insert("Count",            0);
	Result.Insert("RunTime",       0);
	Result.Insert("FollowUp",  0);
	Result.Insert("QuantityUnderRevision", 0);
	Result.Insert("DefectiveGoodsCount",        0);
	Result.Insert("CountReal",        0);
	Result.Insert("CountCanceled",    0);
	Result.Insert("ControlAgain",     False);
	
	Return Result;
	
EndFunction

// Divides one document into two: one with the status "Completed", the other with the specified status.
Procedure ExecutePartially(Ref, Completed2, NewStatus_ = Undefined) Export
	
	BeginTransaction();
	Try
		
		ObjectOld = Ref.GetObject(); // DocumentObject.ProductionOperation2_2
		ObjectOld.Lock();
		ObjectOld.SetSplitMode();
		
		NumberOfNewItems = ObjectOld.Count - ObjectOld.CountCanceled - Completed2;
		LeadTimeIsNew = NumberOfNewItems*ObjectOld.RunTime/(ObjectOld.Count-ObjectOld.CountCanceled);
		
		FillingValues = SplittingParametersOfOperationConstructor();
		FillingValues.Count      = NumberOfNewItems;
		FillingValues.RunTime = LeadTimeIsNew;
	
		Object_New = SelectOperation_(ObjectOld, FillingValues);
		
		If Not ObjectOld.SetStatus("Executed", New Structure) Then
			RollbackTransaction();
			Return;
		EndIf;
		
		Object_New.SetStatus(NewStatus_, New Structure);
		
		// Document recording
		WriteMode = ?(ObjectOld.Posted, DocumentWriteMode.Posting, DocumentWriteMode.Write);
		ObjectOld.Write(WriteMode);
		Object_New.Write(WriteMode);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteLogEvent(
			NStr("vi = 'Giao dịch sản xuất';
				|ru = 'Производственные операции';
				|en = 'Routing operations'; fa = 'عملیات مسیر';
				|it = 'Operazioni produttivi';
				|pl = 'Operacje produkcyjne';
				|tr = 'Rota işlemleri'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,
			Metadata.Documents.ProductionOperation2_2,,
			DetailErrorDescription(ErrorInfo()));
		
		Raise BriefErrorDescription(ErrorInfo());
		
	EndTry;
	
EndProcedure

// Creates two documents from one.
// 
// Parameters:
// 	Object - DocumentObject.ProductionOperation2_2 - 
// 	FillingValues - Structure - LongDesc:
// * RunTime - Number -
// * Count - Number -
// Returns:
// 	DocumentObject.ProductionOperation2_2 -
// 
Function SelectOperation_(Object, FillingValues) Export
	
	NewObject = Object.Copy();
	
	// Filling in the details of the header
	FillPropertyValues(NewObject, FillingValues);
	
	NewObject.Protocol.Clear();
	
	ZoomRatio = ?(Object.Count-Object.CountCanceled <> 0,
						NewObject.Count/(Object.Count-Object.CountCanceled),
						-1);
	
	NewObject.Date = CurrentSessionDate();
	
	If ProductionAccountingClientServer.ThereAreAccumulatedPerformanceIndicators(Object) Then
	
		RecordingProtocol = ProductionAccountingClientServer.RecordProtocolConstructor("Cancel");
		RecordingProtocol.Count = NewObject.Count;
		RecordingProtocol.Comment = NStr("vi = 'Phân chia giao dịch';
										|ru = 'Разделение операции';
										|en = 'Separate the operation'; fa = 'Separate the operation';
										|it = 'Divisione operazioni';
										|pl = 'Podział operacji';
										|tr = 'İşlemin ayrılması'");
		AddProtocolEntry(Object, RecordingProtocol);
		
		If Object.CountReal <> 0 Then
			
			CountReal = Object.CountReal;
			Object.CountReal = Min(Object.Count-Object.CountCanceled, Object.CountReal);
			NewObject.CountReal = CountReal - Object.CountReal;
			
		EndIf;
		
	Else
		
		Object.Count = Object.Count - NewObject.Count;
		
	EndIf;
	
	If Object.TimePerPiece = 0 And Object.SetupTime = 0 Then
		Object.RunTime = Object.RunTime - NewObject.RunTime;
	Else
		RCDetails = ProductionAccounting.AttributesOfWorkCenter(
			Object.WorkCenter);
		NumberOfPieces = ?(ValueIsFilled(Object.Operation),
			Common.ObjectAttributeValue(Object.Operation, "Count"),
			1);
		Object.RunTime = ProductionAccountingClientServer.CalculateOperationTimeFromQuantity(
			Object.Count - Object.CountCanceled,
			NumberOfPieces,
			Object.TimePerPiece,
			Object.SetupTime,
			RCDetails.ParallelLoad,
			RCDetails.WorkTimeFactor);
	EndIf;
	
	If ZoomRatio <> -1 Then
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfPackages",
		BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
		
		CachedValues = Undefined;
		
		DeleteRows_ = NewStructureForRowsToDelete();
		
		NamesOfTS = StrSplit("MaterialsAndWorks,ManufacturedProducts,BatchFinishedProducts,LaborCosts", ",");
		
		// Recalculation of tabular parts
		For Each TS In NamesOfTS Do
			
			For IndexOf = 0 To NewObject[TS].Count()-1 Do
				
				LineNew = NewObject[TS][IndexOf];
				LineNew.Count = LineNew.Count * ZoomRatio;
				If LineNew.Count = 0 Then
					If DeleteRows_.New.Get(TS) = Undefined Then
						DeleteRows_.New.Insert(TS, New Array);
					EndIf;
					TSStrings = DeleteRows_.New[TS]; //Array of ValueTableRow - 
					TSStrings.Add(LineNew);
				EndIf;
				
				StringOld = Object[TS][IndexOf];
				StringOld.Count = StringOld.Count - LineNew.Count;
				If StringOld.Count = 0 Then
					If DeleteRows_.Old_.Get(TS) = Undefined Then
						DeleteRows_.Old_.Insert(TS, New Array);
					EndIf;
					TSStrings = DeleteRows_.Old_[TS]; //Array of ValueTableRow - 
					TSStrings.Add(StringOld);
				EndIf;
				
			EndDo;
			
			If TS = "MaterialsAndWorks" Or TS = "ManufacturedProducts" Then
				BatchProcessingOfTablePartServer.TreatTS(NewObject[TS], StructureOfActions, CachedValues);
				BatchProcessingOfTablePartServer.TreatTS(Object[TS], StructureOfActions, CachedValues);
			EndIf;
			
		EndDo;
		
		// Reconciliation of product series
		TheStructureOfTheSearch = New Structure("Products, Characteristic");
		
		For Cnt = 1 To 2 Do
			
			Document = ?(Cnt = 1, NewObject, Object);
			
			If Document.BatchFinishedProducts.Count() = 0 Then
				Continue;
			EndIf;
			
			SetOfSeries = Document.BatchFinishedProducts.Unload(, "Products, Characteristic, Count");
			SetOfSeries.GroupBy("Products, Characteristic", "Count");
			
			Products_1 = Document.ManufacturedProducts.Unload(, "Products, Characteristic, Count");
			Products_1.GroupBy("Products, Characteristic", "Count");
			Products_1.Indexes.Add("Products, Characteristic");
			
			For Each StringSeries In SetOfSeries Do
				
				FillPropertyValues(TheStructureOfTheSearch, StringSeries);
				ProductLines_ = Products_1.FindRows(TheStructureOfTheSearch);
				
				Deviation = ?(ProductLines_.UBound() = 0, ProductLines_[0].Count - StringSeries.Count, 0);
				If Deviation = 0 Then
					Continue;
				EndIf;
				
				FoundRows = Document.BatchFinishedProducts.FindRows(TheStructureOfTheSearch);
				
				For Each String In FoundRows Do
					
					If String.Count = 0 Then
						Continue;
					EndIf;
					
					NumberOfCredits = Max(Deviation, -String.Count);
					Deviation = Deviation - NumberOfCredits;
					String.Count = String.Count + NumberOfCredits;
					
					If String.Count = 0 Then
						Name = ?(Cnt = 1, "New", "Old_");
						If DeleteRows_[Name].Get("BatchFinishedProducts") = Undefined Then
							DeleteRows_[Name].Insert("BatchFinishedProducts", New Array);
						EndIf;
						OutputProductLines = DeleteRows_[Name]["BatchFinishedProducts"]; //Array of ValueTableRow - 
						OutputProductLines.Add(String);
					EndIf;
					
					If Deviation = 0 Then
						Break;
					EndIf;
					
				EndDo;
			EndDo;
		EndDo;
		
		// Deleting empty lines
		For Each KeyAndValue In DeleteRows_.Old_ Do
			For Each String In KeyAndValue.Value Do
				Object[KeyAndValue.Key].Delete(String);
			EndDo;
		EndDo;
		For Each KeyAndValue In DeleteRows_.New Do
			For Each String In KeyAndValue.Value Do
				NewObject[KeyAndValue.Key].Delete(String);
			EndDo;
		EndDo;
		
	EndIf;
	
	Return NewObject;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization) AND
	|	ValueAllowed(Department)";

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

#EndRegion

#Region Private

#Region Posting

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	RedefiningParameterCalculation = New Structure;
	
	FullDocumentName = "Document.ProductionOperation2_2";
	
	If RegisterName = "GoodsBatchMovement" Then
		
		QueryText = QueryTextTableGoodsBatchMovement(Query, QueryTexts, RegisterName, Undefined);
		SynonymForDocumentTable = "TabularSection";
		
	ElsIf RegisterName = "LaborCostsToRegister" Then
		
		QueryText = QueryTextTableLaborCostsToRegister(
			Undefined,
			QueryTexts,
			RegisterName,
			Undefined);
		
		SynonymForDocumentTable = "TableLaborCosts";
		
	Else
		
		ExceptionPattern = NStr("vi = 'Trong chứng từ %1 đã không thực hiện việc điều chỉnh văn bản của yêu cầu Lập các chuyển động trong thanh ghi %2.';
								|ru = 'В документе %1 не реализована адаптация текста запроса формирования движений по регистру %2.';
								|en = 'In the %1 document, adaptation of request for generating records of the %2 register is not implemented.'; fa = 'In the %1 document, adaptation of request for generating records of the %2 register is not implemented.';
								|it = 'Nel documento %1 non è stato effettuato l''adattamento del testo di richiesta di generazione dei movimenti sul registro %2.';
								|pl = 'W dokumencie %1 nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %2.';
								|tr = '%1 belgesinde, %2 kaydına göre hareketlerin düzenlenmesi isteğinin metin uyarlaması uygulanmadı.'");
		ExceptionText = StrTemplate(ExceptionPattern, FullDocumentName, RegisterName);
		
		Raise ExceptionText;
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	
	Result.QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
		QueryText,
		FullDocumentName,
		SynonymForDocumentTable,
		RedefiningParameterCalculation);
	
	Return Result;
	
EndFunction

// Used in information security update mechanisms
//
// Parameters:
//  RegisterName	 - String	 - register name.
//
// Returns:
//  Map -
//
Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Attributes = Common.ObjectAttributesValues(
		DocumentRef,
		"Date, Department, Organization, Stage, Status, OperationAsOutputReference");
	
	Query.SetParameter("Period", Attributes.Date);
	Query.SetParameter("Department", Attributes.Department);
	Query.SetParameter("Organization", Attributes.Organization);
	Query.SetParameter("ProductionLot", Common.ObjectAttributeValue(Attributes.Stage, "ProductionLot"));
	Query.SetParameter("Status", Attributes.Status);
	Query.SetParameter("OperationAsOutputReference", Attributes.OperationAsOutputReference);
	
	Query.SetParameter("Ref", DocumentRef);
	
EndProcedure

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	ArrayOfRequestTexts = New Array;
	
	If DocumentObject = Undefined
	 Or DocumentObject.MaterialsAndWorks.Count() > 0 Then
		
		QueryText =
		"SELECT
		|	&Period                                                                       AS Period,
		|	TabularSection.Products                                                   AS Products,
		|	TabularSection.Characteristic                                                 AS Characteristic,
		|	VALUE(Catalog.Assignments.EmptyRef)                                  AS Purpose,
		|	TabularSection.Series                                                          AS Series,
		|	TabularSection.Count                                                     AS Count,
		|	&Department                                                                AS Sender,
		|	&Department                                                                AS Recipient,
		|	VALUE(Enum.WarehouseTransactions.ConsumptionDuringProduction) AS WarehouseOperation,
		|	&Ref                                                                       AS Document,
		|	FALSE                                                                          AS ThisIsWarehouseRecord
		|FROM
		|	Document.ProductionOperation2_2.MaterialsAndWorks AS TabularSection
		|WHERE
		|	TabularSection.Ref = &Ref
		|	AND TabularSection.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject = Undefined
	 Or DocumentObject.ManufacturedProducts.Count() > 0 Then
		
		QueryText =
		"SELECT
		|	&Period                                                        AS Period,
		|	TabularSection.Products                                    AS Products,
		|	TabularSection.Characteristic                                  AS Characteristic,
		|	VALUE(Catalog.Assignments.EmptyRef)                   AS Purpose,
		|	TabularSection.Series                                           AS Series,
		|	TabularSection.Count                                      AS Count,
		|	&Department                                                 AS Sender,
		|	&Department                                                 AS Recipient,
		|	VALUE(Enum.WarehouseTransactions.ManufactureOfProducts) AS WarehouseOperation,
		|	&Ref                                                        AS Document,
		|	FALSE                                                           AS ThisIsWarehouseRecord
		|FROM
		|	Document.ProductionOperation2_2.ManufacturedProducts AS TabularSection
		|WHERE
		|	TabularSection.Ref = &Ref
		|	AND TabularSection.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject = Undefined
	 Or DocumentObject.BatchFinishedProducts.Count() > 0 Then
		
		QueryText =
		"SELECT
		|	&Period                                                        AS Period,
		|	TabularSection.Products                                    AS Products,
		|	TabularSection.Characteristic                                  AS Characteristic,
		|	VALUE(Catalog.Assignments.EmptyRef)                   AS Purpose,
		|	TabularSection.Series                                           AS Series,
		|	TabularSection.Count                                      AS Count,
		|	&Department                                                 AS Sender,
		|	&Department                                                 AS Recipient,
		|	VALUE(Enum.WarehouseTransactions.ManufactureOfProducts) AS WarehouseOperation,
		|	&Ref                                                        AS Document,
		|	FALSE                                                           AS ThisIsWarehouseRecord
		|FROM
		|	Document.ProductionOperation2_2.BatchFinishedProducts AS TabularSection
		|WHERE
		|	TabularSection.Ref = &Ref";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If ArrayOfRequestTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableLaborCostsToRegister(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "LaborCostsToRegister";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If DocumentObject <> Undefined
	   And Not (DocumentObject.OperationAsOutputReference
			 And DocumentObject.Status = Enums.ProductionOperationStatuses.Executed
			 And DocumentObject.LaborCosts.Count() > 0) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	TableLaborCosts.Ref.ExecutionEnd  AS Period,
	|	&Organization                                    AS Organization,
	|	&ProductionLot                             AS ProductionLot,
	|	TableLaborCosts.Ref                      AS ReferenceOrder,
	|	TableLaborCosts.WorkKind                    AS WorkKind,
	|	TableLaborCosts.Performer                 AS Performer,
	|	&Department                                  AS Department,
	|	TableLaborCosts.RowCode                   AS ReferenceRowCode,
	|	TableLaborCosts.Count                  AS Count
	|FROM
	|	Document.ProductionOperation2_2.LaborCosts AS TableLaborCosts
	|WHERE
	|	&OperationAsOutputReference
	|	AND TableLaborCosts.Ref = &Ref
	|
	|	AND &Status = VALUE(Enum.ProductionOperationStatuses.Executed)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction
#EndRegion

#Region SetOfSeries

Function TextOfRequestToFillInStatusesForSpecifyingSerialNumberOfProduct()
	
	QueryText = 
	"SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series,
	|	Goods.Count AS Count,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.LineNumber AS LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind,
	|	SUM(Goods.Count) AS Count
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.Count AS Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS StatusOfSpecifyingSeriesIsOld,
	|	CASE
	|		WHEN ItemKinds.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN ItemKinds.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					WHEN NOT &FactOfSelection
	|						THEN 15
	|					ELSE 13
	|				END
	|		WHEN ItemKinds.BatchAccountingPolicy.SpecifyDuringProduction
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|							AND ProductsToRequest.Count > 0
	|						THEN 2
	|					WHEN NOT &FactOfSelection
	|							AND ProductsToRequest.Count > ISNULL(SeriesToRequest.Count, 0)
	|						THEN 21
	|					ELSE 1
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON ProductsToRequest.ProductKind = ItemKinds.Ref
	|		LEFT JOIN SeriesToRequest AS SeriesToRequest
	|		ON Goods.Products = SeriesToRequest.Products
	|			AND Goods.Characteristic = SeriesToRequest.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
	|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	Statuses.BatchesIndicationStatus <> Statuses.StatusOfSpecifyingSeriesIsOld
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

Function RequestTextForFillingInStatusesSpecifyingSeriesMaterialsAndWorks()

	QueryText = 
	"SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series,
	|	Goods.Count AS Count,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.LineNumber AS LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS StatusOfSpecifyingSeriesIsOld,
	|	CASE
	|		WHEN ItemKinds.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN ItemKinds.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					WHEN NOT &FactOfSelection
	|						THEN 15
	|					ELSE 13
	|				END
	|		WHEN ItemKinds.BatchAccountingPolicy.SpecifyOnMaterialConsumption
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 2
	|					WHEN NOT &FactOfSelection
	|						THEN 21
	|					ELSE 1
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON Goods.Products = CatProducts.Ref
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON (CatProducts.ProductKind = ItemKinds.Ref)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
	|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	Statuses.BatchesIndicationStatus <> Statuses.StatusOfSpecifyingSeriesIsOld
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Print

// Generates a printable form.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ProductionOperation") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ProductionOperation",
			NStr("vi = 'Giao dịch sản xuất';
				|ru = 'Производственная операция';
				|en = 'Routing operation'; fa = 'عملیات مسیر تولید';
				|it = 'Operazione produttiva';
				|pl = 'Operacja produkcyjna';
				|tr = 'Rota işlemi'"),
			FormPrintedFormOperation(ObjectsArray, PrintObjects));
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ProductionOperationLabel") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ProductionOperationLabel",
			NStr("vi = 'Nhãn giao dịch';
				|ru = 'Этикетка операции';
				|en = 'Operation label'; fa = 'Operation label';
				|it = 'Etichetta dell''operazione';
				|pl = 'Etykieta operacji';
				|tr = 'İşlem etiketi'"),
			FormPrintedFormLabelOperation(ObjectsArray, PrintObjects));
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "DefectiveGoodsCertificate") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"DefectiveGoodsCertificate",
			NStr("vi = 'Biên bản hàng hỏng';
				|ru = 'Акт о браке';
				|en = 'Nonconformity report'; fa = 'گزارش عدم انطباق';
				|it = 'Verbale difetto riscontrato';
				|pl = 'Protokół o wadach';
				|tr = 'Uygunsuzluk tutanağı'"),
			GeneratePrintFormOfDefectiveGoodsCertificate(ObjectsArray, PrintObjects));
		
	EndIf;
	
	PrintFormGeneration.FillInSendingParameters(
		OutputParameters.SendOptions,
		ObjectsArray,
		PrintFormsCollection);
	
EndProcedure

// Manufacturing operation

Function FormPrintedFormOperation(ObjectsArray, PrintObjects)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PageOrientation = PageOrientation.Portrait;
	SpreadsheetDocument.PrintParametersName = "Parameters_Seals_ProductionOperation2_2_ProductionOperation";
	
	Template = PrintManagement.PrintFormTemplate("Document.ProductionOperation2_2.PF_MXL_ProductionOperation");
	FirstDocument = True;
	
	DataForPrint = PrintDataProductionOperation(ObjectsArray);
	
	UnitParameters = ProductionServer.ParametersOfProductionUnits(DataForPrint.Departments);
	UseHourInterval = Constants.UsePlanningIntervalHour.Get();
	
	HeaderSelection = DataForPrint.HeaderSelection;
	
	While HeaderSelection.Next() Do
	
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// Title
		Area = Template.GetArea("Title");
	
		Area.Parameters.TitleText = TMCommonUseClientServer.GenerateDocumentTitle(
			HeaderSelection, NStr("vi = 'Giao dịch sản xuất';
									|ru = 'Производственная операция';
									|en = 'Routing operation'; fa = 'عملیات مسیر تولید';
									|it = 'Operazione produttiva';
									|pl = 'Operacja produkcyjna';
									|tr = 'Rota işlemi'", Common.DefaultLanguageCode()));
		Area.Parameters.Ref = HeaderSelection.Ref;
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(
			SpreadsheetDocument,
			Template,
			Area,
			HeaderSelection.Ref);
	
		SpreadsheetDocument.Put(Area);
		
		// Header
		Area = Template.GetArea("Header");
		
		AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
		AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
		
		Area.Parameters.Fill(HeaderSelection);
		
		Area.Parameters.ProductPresentation = ProductsClientServer.PresentationOfProductsForPrinting(
			HeaderSelection.ProductNameFull,
			HeaderSelection.ProductCharacteristicsFullName,
			,
			,
			AdditionalParametersProductPresentation);
			
		Area.Parameters.UnitOfQuantity = ProductionManagementClientServer.PresentationOfUnitOfOperation(
			HeaderSelection.UnitOfMeasurePresentation, HeaderSelection.CountPlan);
			
		Area.Parameters.RunTimePresentation = "" + HeaderSelection.RunTime + " " + HeaderSelection.ExecutionTimeUnitOfMeasure;
		
		If UnitParameters.Get(HeaderSelection.Department).UseManufacturingExecutionSystem Then
			Format = "DF='dd.MM.yy HH:mm:ss'";
		ElsIf UseHourInterval Then
			Format = "DF='dd.MM.yyyy HH:mm'";
		Else
			Format = "DLF=D";
		EndIf;
		
		Area.Area("ExecutionStarted").Format = Format;
		Area.Area("ExecutionEnd").Format = Format;
		
		SpreadsheetDocument.Put(Area);
		
		// UsedMaterials
		PrintedFormOperationOutputMaterials(Template, SpreadsheetDocument, HeaderSelection, DataForPrint.SampleMaterials);
		
		// Products_1
		PrintedFormProductPrintingOperation(Template, SpreadsheetDocument, HeaderSelection, DataForPrint.ProductSelection_);
		
		PrintManagement.SetDocumentPrintArea(
			SpreadsheetDocument,
			RowNumberStart,
			PrintObjects,
			HeaderSelection.Ref);
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

Function PrintDataProductionOperation(References)
	
	QueryText =
		"SELECT
		|	Operations.Ref                          AS Ref,
		|	Operations.Number                           AS Number,
		|	Operations.Date                            AS Date,
		|	Operations.Department                   AS Department,
		|	Operations.Department.Presentation     AS DepartmentPresentation,
		|	Operations.Operation                        AS Operation,
		|	&TextOfRouteDetailsField,
		|	Operations.Description                    AS Description,
		|	Operations.Performer                     AS Performer,
		|	Operations.Performer.Presentation       AS PerformerPresentation,
		|
		|	Operations.Stage.ProductionLot.MainProductProducts                      AS Product,
		|	Operations.Stage.ProductionLot.MainProductProducts.DescriptionFull   AS ProductNameFull,
		|	Operations.Stage.ProductionLot.MainProductCharacteristic.DescriptionFull AS ProductCharacteristicsFullName,
		|	Operations.Operation.UnitOfMeasure.Presentation                                  AS UnitOfMeasurePresentation,
		|
		|	Operations.WorkCenter                    AS WorkCenter,
		|	PRESENTATION(Operations.WorkCenter)     AS WorkCenterPresentation,
		|
		|	Operations.Count - Operations.CountCanceled AS CountPlan,
		|	Operations.CountReal                           AS CountReal,
		|	Operations.ExecutionStarted                         AS ExecutionStarted,
		|	Operations.ExecutionEnd                      AS ExecutionEnd,
		|	Operations.RunTime                          AS RunTime,
		|	Operations.ExecutionTimeUnitOfMeasure                     AS ExecutionTimeUnitOfMeasure
		|FROM
		|	Document.ProductionOperation2_2 AS Operations
		|WHERE
		|	Operations.Ref IN(&References)
		|
		|ORDER BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	UsedMaterials.Ref                            AS Ref,
		|	UsedMaterials.Products                      AS Products,
		|	UsedMaterials.Products.Code                  AS Code,
		|	UsedMaterials.Products.SKU              AS SKU,
		|	UsedMaterials.Products.DescriptionFull   AS ProductFullName,
		|	UsedMaterials.Characteristic.DescriptionFull AS CharacteristicFullName,
		|	&RequestTextUnitOfMeasurementMaterials      AS UnitOfMeasure,
		|	UsedMaterials.NumberOfPackages                AS Count
		|FROM
		|	Document.ProductionOperation2_2.MaterialsAndWorks AS UsedMaterials
		|WHERE
		|	UsedMaterials.Ref IN(&References)
		|	AND UsedMaterials.Products <> VALUE(Catalog.Products.EmptyRef) // Only the filled nomenclature is displayed (the MK nomenclature is not displayed)
		|
		|ORDER BY
		|	Ref,
		|	LineNumber
		|TOTALS BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Products_1.Ref                            AS Ref,
		|	Products_1.LineNumber                       AS LineNumber,
		|	Products_1.Products                      AS Products,
		|	Products_1.Products.Code                  AS Code,
		|	Products_1.Products.SKU              AS SKU,
		|	Products_1.Products.DescriptionFull   AS ProductFullName,
		|	Products_1.Characteristic.DescriptionFull AS CharacteristicFullName,
		|	&QueryTextUnitOfProductMeasurement      AS UnitOfMeasure,
		|	Products_1.NumberOfPackages                AS Count
		|FROM
		|	Document.ProductionOperation2_2.ManufacturedProducts AS Products_1
		|WHERE
		|	Products_1.Ref IN(&References)
		|
		|ORDER BY
		|	Ref,
		|	LineNumber
		|TOTALS BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Operations.Department AS Department
		|FROM
		|	Document.ProductionOperation2_2 AS Operations
		|WHERE
		|	Operations.Ref IN(&References)";
	
	TextEd = Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
		"Description", "UsedMaterials.Package", "UsedMaterials.Products");
	QueryText = StrReplace(QueryText, "&RequestTextUnitOfMeasurementMaterials", TextEd);
	
	TextEd = Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
		"Description", "Products_1.Package", "Products_1.Products");
	QueryText = StrReplace(QueryText, "&QueryTextUnitOfProductMeasurement", TextEd);
	
	TextOfRouteDetailsField = TextOfOperationRouteDetailsField("Operations");
	QueryText = StrReplace(QueryText, "&TextOfRouteDetailsField", TextOfRouteDetailsField);
	
	Query = New Query(QueryText);
	Query.SetParameter("References", References);
	
	SetPrivilegedMode(True);
	ResultsArray = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	DataForPrint = New Structure;
	DataForPrint.Insert("HeaderSelection",        ResultsArray[0].Select());
	DataForPrint.Insert("SampleMaterials",    ResultsArray[1].Select(QueryResultIteration.ByGroups));
	DataForPrint.Insert("ProductSelection_",      ResultsArray[2].Select(QueryResultIteration.ByGroups));
	DataForPrint.Insert("Departments",       ResultsArray[3].Unload().UnloadColumn("Department"));
	
	Return DataForPrint;
	
EndFunction

// Parameters:
// 	Template - DataCompositionAppearanceTemplate, GeographicalSchema, DataCompositionSchema, GraphicalSchema, HTMLDocumentShell, BinaryData, SpreadsheetDocument, ActiveDocumentShell, TextDocument - LongDesc
// 	SpreadsheetDocument - SpreadsheetDocument - LongDesc
// 	HeaderSelection -  QueryResultSelection -
// 	SampleMaterials -  QueryResultSelection -
Procedure PrintedFormOperationOutputMaterials(Template, SpreadsheetDocument, HeaderSelection, SampleMaterials)
	
	If Not SampleMaterials.FindNext(New Structure("Ref", HeaderSelection.Ref)) Then
		Return;
	EndIf;
			
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
		
	Area = Template.GetArea("TitleProducts");
	Area.Parameters.TableName = NStr("vi = 'Nguyên vật liệu';
									|ru = 'Материалы';
									|en = 'Materials'; fa = 'مواد';
									|it = 'Materiali';
									|pl = 'Materials';
									|tr = 'Malzemeler'", Common.DefaultLanguageCode());
	SpreadsheetDocument.Put(Area);
			
	If OutputCodes Then
	   	
		SectionHeader = Template.GetArea("Products_codeHeader");
		SectionHeader.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
		AreaRow = Template.GetArea("StringProducts_WithCode"); // See ProductionServer.ServiceStructureTabularDocument
			
	Else
				
		SectionHeader = Template.GetArea("Products_HeaderWithoutCode");
		AreaRow = Template.GetArea("String__WithoutCode");  // See ProductionServer.ServiceStructureTabularDocument
		
	EndIf;
			
	SectionHeader.Parameters.ColumnNameProducts = NStr("vi = 'Nguyên vật liệu';
														|ru = 'Материал';
														|en = 'Material'; fa = 'ماده';
														|it = 'Materiale';
														|pl = 'Material';
														|tr = 'Malzeme'", Common.DefaultLanguageCode());
		
	SpreadsheetDocument.Put(SectionHeader);
	
	LineNumber = 1;
	Selection = SampleMaterials.Select();
	While Selection.Next() Do
		
		AreaRow.Parameters.Fill(Selection);
			
		If OutputCodes Then
			AreaRow.Parameters.SKU = Selection[NameOfCodeColumn];
		EndIf;
						
		AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
		AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	
		AreaRow.Parameters.ProductsPresentation = ProductsClientServer.PresentationOfProductsForPrinting(
			Selection.ProductFullName,
			Selection.CharacteristicFullName,
			,
			,
			AdditionalParametersProductPresentation);
		AreaRow.Parameters.LineNumber = LineNumber;
		LineNumber = LineNumber + 1;
		
		SpreadsheetDocument.Put(AreaRow);
		
	EndDo;
	
	SpreadsheetDocument.Put(Template.GetArea("BasementGoods"));
	
EndProcedure

// Parameters:
// 	Template - DataCompositionAppearanceTemplate, GeographicalSchema, DataCompositionSchema, GraphicalSchema, HTMLDocumentShell, BinaryData, SpreadsheetDocument, ActiveDocumentShell, TextDocument - LongDesc
// 	SpreadsheetDocument - SpreadsheetDocument - LongDesc
// 	HeaderSelection -  QueryResultSelection -
// 	ProductSelection_ -  QueryResultSelection -
Procedure PrintedFormProductPrintingOperation(Template, SpreadsheetDocument, HeaderSelection, ProductSelection_)
	
	If Not ProductSelection_.FindNext(New Structure("Ref", HeaderSelection.Ref)) Then
		Return;
	EndIf;
			
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	Area = Template.GetArea("TitleProducts");
	Area.Parameters.TableName = NStr("vi = 'Sản phẩm đầu ra';
									|ru = 'Выходные изделия';
									|en = 'Finished products'; fa = 'Finished products';
									|it = 'Prodotti finiti';
									|pl = 'Wyroby gotowe';
									|tr = 'Üretilen nihai ürünler'", Common.DefaultLanguageCode());
	SpreadsheetDocument.Put(Area);
	
	If OutputCodes Then
	   	
		SectionHeader = Template.GetArea("Products_codeHeader");
		SectionHeader.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
		AreaRow = Template.GetArea("StringProducts_WithCode");
			
	Else
				
		SectionHeader = Template.GetArea("Products_HeaderWithoutCode");
		AreaRow = Template.GetArea("String__WithoutCode");
		
	EndIf;
			
	SectionHeader.Parameters.ColumnNameProducts = NStr("vi = 'Sản phẩm';
														|ru = 'Изделие';
														|en = 'Product'; fa = 'کالا';
														|it = 'Prodotto';
														|pl = 'Product';
														|tr = 'Nihai ürün'", Common.DefaultLanguageCode());
		
	SpreadsheetDocument.Put(SectionHeader);
	
	Selection = ProductSelection_.Select();
	While Selection.Next() Do
		
		AreaRow.Parameters.Fill(Selection);
			
		If OutputCodes Then
			AreaRow.Parameters.SKU = Selection[NameOfCodeColumn];
		EndIf;
						
		AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
		AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	
		AreaRow.Parameters.ProductsPresentation = ProductsClientServer.PresentationOfProductsForPrinting(
			Selection.ProductFullName,
			Selection.CharacteristicFullName,
			,
			,
			AdditionalParametersProductPresentation);
		
		SpreadsheetDocument.Put(AreaRow);
		
	EndDo;
			
	SpreadsheetDocument.Put(Template.GetArea("BasementGoods"));
	
EndProcedure

// Operation label

Function FormPrintedFormLabelOperation(ObjectsArray, PrintObjects)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PageOrientation = PageOrientation.Portrait;
	SpreadsheetDocument.PrintParametersName = "Parameters_Seals_ProductionOperation2_2_ProductionOperationLabel";
	
	Template = PrintManagement.PrintFormTemplate("Document.ProductionOperation2_2.PF_MXL_ProductionOperationLabel");
	FirstDocument = True;
	
	Selection = DataForLabelPrintingOperations(ObjectsArray);
	
	While Selection.Next() Do
	
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		Area = Template.GetArea("Label_");
		
		Area.Parameters.Fill(Selection);
		
		Area.Parameters.TitleText = StrTemplate(NStr("vi = '%1 ngày %2';
													|ru = '%1 от %2';
													|en = '%1 from %2'; fa = '%1 from %2';
													|it = '%1 del %2';
													|pl = '%1 z dn. %2';
													|tr = '%2 tarihli %1'", Common.DefaultLanguageCode()),
			Selection.Number,
			Format(Selection.Date, "DLF=D"));
		
		Area.Parameters.UnitOfQuantity = ProductionManagementClientServer.PresentationOfUnitOfOperation(
			Selection.UnitOfMeasurePresentation, Selection.CountPlan,, Common.DefaultLanguageCode());
			
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(
			SpreadsheetDocument,
			Template,
			Area,
			Selection.Ref);
	    
		SpreadsheetDocument.Put(Area);
		
		PrintManagement.SetDocumentPrintArea(
			SpreadsheetDocument,
			RowNumberStart,
			PrintObjects,
			Selection.Ref);
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

Function DataForLabelPrintingOperations(References)
	
	Query = New Query(
		"SELECT
		|	Operations.Ref                    AS Ref,
		|	Operations.Number                     AS Number,
		|	Operations.Date                      AS Date,
		|	Operations.Operation                  AS Operation,
		|	Operations.Description              AS Description,
		|	Operations.Performer               AS Performer,
		|	Operations.Performer.Presentation AS PerformerPresentation,
		|
		|	Operations.WorkCenter                               AS WorkCenter,
		|	Operations.WorkCenter.Presentation                 AS WorkCenterPresentation,
		|
		|	Operations.Count - Operations.CountCanceled   AS CountPlan,
		|	Operations.RunTime                            AS RunTime,
		|	Operations.ExecutionTimeUnitOfMeasure                       AS ExecutionTimeUnitOfMeasure,
		|
		|	Operations.Operation.UnitOfMeasure.Presentation    AS UnitOfMeasurePresentation
		|FROM
		|	Document.ProductionOperation2_2 AS Operations
		|WHERE
		|	Operations.Ref IN(&References)
		|
		|ORDER BY
		|	Ref");
	
	Query.SetParameter("References", References);
	
	SetPrivilegedMode(True);
	Return Query.Execute().Select();
	
EndFunction

Function GeneratePrintFormOfDefectiveGoodsCertificate(ObjectsArray, PrintObjects)
	
	ErrorTemplate = NStr("vi = 'Chỉ có thể sử dụng in đối với giao dịch đã thực hiện khi bị lỗi.';
						|ru = 'Печать используется только для выполненной операции при наличии брака.';
						|en = 'Print is used only when an operation is completed and there is nonconformity.'; fa = 'Print is used only when an operation is completed and there is nonconformity.';
						|it = 'Печать используется только для выполненной операции при наличии брака.';
						|pl = 'Print is used only when an operation is completed and there is nonconformity.';
						|tr = 'Yazdırma araçları sadece uygunsuzluk halinde yapılan işlem için kullanılır.'");
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PageOrientation = PageOrientation.Portrait;
	SpreadsheetDocument.PrintParametersName = "Parameters_Seals_ProductionOperation2_2_DefectiveGoodsCertificate";
	
	Template = PrintManagement.PrintFormTemplate("Document.ProductionOperation2_2.PF_MXL_DefectiveGoodsCertificate");
	FirstDocument = True;
	
	DataForPrint = DataForPrintingDefectiveGoodsCertificate(ObjectsArray);

	HeaderSelection    = DataForPrint.HeaderSelection;
	SamplingProtocol = DataForPrint.SamplingProtocol;
	
	AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
	AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	While HeaderSelection.Next() Do
		
		If HeaderSelection.DefectiveGoodsCount = 0 Or Not ValueIsFilled(HeaderSelection.DocumentDate) Then
			If FirstDocument Then
				Common.MessageToUser(ErrorTemplate);
			EndIf;
			Continue;
		EndIf;

		AttributesValues = Common.ObjectAttributesValues(
			HeaderSelection.Stage, "Stage,ReferenceOrder,AssignmentProducts,ProductionLot");

		ProductionBatchData = Documents.ProductionStage2_2.ProductionBatchData(
			AttributesValues.ReferenceOrder, AttributesValues.AssignmentProducts,
			AttributesValues.ProductionLot);
		SpecificationData = Documents.ProductionStage2_2.GetStandardsForSpecifications(
			ProductionBatchData, False, "ManufacturedProducts, Operations");
			
		If SpecificationData = Undefined Then
			If FirstDocument Then
				Common.MessageToUser(NStr("vi = 'Lỗi tính toán tiêu chuẩn để điền giao dịch.';
											|ru = 'Ошибка расчета нормативов для заполнения операции.';
											|en = 'An error occurred when calculating standards for filling the operation.'; fa = 'An error occurred when calculating standards for filling the operation.';
											|it = 'Ошибка расчета нормативов для заполнения операции.';
											|pl = 'An error occurred when calculating standards for filling the operation.';
											|tr = 'İşlemin doldurulması için standartların hesaplanmasında hata.'"));
			EndIf;
			Continue;
		EndIf;
		
		FoundRows = SpecificationData.Operations.FindRows(
			New Structure("Operation,OperationID", HeaderSelection.Operation, HeaderSelection.OperationID));

		OperationData = FoundRows[0];
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// Header
		
		Area = Template.GetArea("Header");
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, Area, HeaderSelection.Ref);
		
		CompanyInformation = PrintFormGeneration.InformationAboutLegalEntity(HeaderSelection.Organization, HeaderSelection.DocumentDate);
		
		Area.Parameters.Fill(HeaderSelection);
		Area.Parameters.Fill(CompanyInformation);
		Area.Parameters.DocumentDate = Format(HeaderSelection.DocumentDate, "DF=dd.MM.yyyy");
		SpreadsheetDocument.Put(Area);
		
		// Table
		
		DefectiveGoodsCounter = 0;
		Controllers = New Array();
		
		If SamplingProtocol.FindNext(New Structure("Ref", HeaderSelection.Ref)) Then
			
			LineNumber = 0;
			SelectionDefectiveGoods = SamplingProtocol.Select();
			
			SpreadsheetDocument.Put(Template.GetArea("TableHeading"));
			
			While SelectionDefectiveGoods.Next() And DefectiveGoodsCounter <> HeaderSelection.DefectiveGoodsCount Do

				If Controllers.Find(SelectionDefectiveGoods.EmployeeResponsible) = Undefined Then
					Controllers.Add(SelectionDefectiveGoods.EmployeeResponsible);
				EndIf;

				DefectiveGoodsCounter = DefectiveGoodsCounter + SelectionDefectiveGoods.OperationsCount;

				AreaTableRow = Template.GetArea("TableRow");

				For Each NSIString In SpecificationData.ManufacturedProducts Do

					AreaTableRow.Parameters.Fill(NSIString);

					LineNumber = LineNumber + 1;
					AreaTableRow.Parameters.LineNumber = LineNumber;

					ProductFullName = Common.ObjectAttributeValue(NSIString.Products, "DescriptionFull");
					CharacteristicFullName = Common.ObjectAttributeValue(NSIString.Characteristic, "DescriptionFull");
					AreaTableRow.Parameters.ProductsPresentation = ProductsClientServer.PresentationOfProductsForPrinting(
						ProductFullName, CharacteristicFullName, , ,
						AdditionalParametersProductPresentation);

					CurOperationCoefficient					= SelectionDefectiveGoods.OperationsCount / OperationData.QuantityPerBatch;
					AreaTableRow.Parameters.Count   = Format(NSIString.Count * CurOperationCoefficient,"ND=15; NFD=3;");
					AreaTableRow.Parameters.ReasonForDefects = SelectionDefectiveGoods.ReasonForDefects;

					SpreadsheetDocument.Put(AreaTableRow);

				EndDo;

			EndDo;
			
		EndIf;
		
		
		// Signatures Made Up
		
		LabelArea = Template.GetArea("Signatures");
		
		Title = NStr("vi = 'Người lập';
					|ru = 'Составил';
					|en = 'Created'; fa = 'ایجادشده';
					|it = 'Compilato';
					|pl = 'Sporządził';
					|tr = 'Oluşturan'");
		
		If Controllers.UBound() <> -1 Then

			For Each Controller In Controllers Do
				
				Person = Common.ObjectAttributeValue(Controller, "Individual");
				SignatureData = DataOfSignatory(Person, HeaderSelection.Organization, HeaderSelection.DocumentDate, Title);
				LabelArea.Parameters.Fill(SignatureData);
				SpreadsheetDocument.Put(LabelArea);
				
			EndDo;
			
		Else
			
			LabelArea.Parameters.TitleOfSignaturesSection        = Title;
			LabelArea.Parameters.JobTitle                       = "";
			LabelArea.Parameters.DecryptionOfSignature_Presentation = "";
			
			SpreadsheetDocument.Put(LabelArea);
			
		EndIf;
		
		// Signatures - Approved
		
		Title = NStr("vi = 'Người duyệt';
					|ru = 'Утвердил';
					|en = 'Approved'; fa = 'تأییدشده';
					|it = 'Approvato';
					|pl = 'Potwierdził';
					|tr = 'Onaylayan'");
		Person = Common.ObjectAttributeValue(HeaderSelection.Department, "BusinessUnitManager");
		
		SignatureData = DataOfSignatory(Person, HeaderSelection.Organization, HeaderSelection.DocumentDate, Title);
		
		LabelArea.Parameters.Fill(SignatureData);
		
		SpreadsheetDocument.Put(LabelArea);
		
		PrintManagement.SetDocumentPrintArea(
			SpreadsheetDocument,
			RowNumberStart,
			PrintObjects,
			HeaderSelection.Ref);
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

// Data of the signatory.
// 
// Parameters:
//  Individual - CatalogRef.Persons - A natural person
//  Organization - CatalogRef.Companies - Organization
//  Date - Date - Date of the operation
//  Title - String - Signature title
// 
// Returns:
//  Structure - Data Of the Signatory:
// * TitleOfSignaturesSection - String - Signature title
// * JobTitle - String - JobTitle
// * DecryptionOfSignature_Presentation - String - Last name initials
Function DataOfSignatory(Individual, Organization, Date, Title)
	
	Result = New Structure();
	Result.Insert("TitleOfSignaturesSection", Title);
	Result.Insert("JobTitle","");
	Result.Insert("DecryptionOfSignature_Presentation", "");
	
	
	Return Result;
	
EndFunction

Function DataForPrintingDefectiveGoodsCertificate(References)
	
	QueryText =
		"SELECT
		|	Operations.Ref                                 AS Ref,
		|	Operations.Number                                  AS DocumentNumber,
		|	Operations.ExecutionEnd                    AS DocumentDate,
		|	Operations.Organization                            AS Organization,
		|	Operations.Department                          AS Department,
		|	Operations.Stage                                   AS Stage,
		|	Operations.Operation                               AS Operation,
		|	Operations.OperationID                  AS OperationID,
		|	Operations.Performer                            AS Performer,
		|	Operations.Performer.Presentation              AS PerformerPresentation,
		|	Operations.DefectiveGoodsCount                         AS DefectiveGoodsCount
		|FROM
		|	Document.ProductionOperation2_2 AS Operations
		|WHERE
		|	Operations.Ref IN (&References)
		|ORDER BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Protocol.Ref        AS Ref,
		|	Protocol.Date          AS Date,
		|	Protocol.EmployeeResponsible AS EmployeeResponsible,
		|	Protocol.Comment   AS ReasonForDefects,
		|	Protocol.Count    AS OperationsCount
		|FROM
		|	Document.ProductionOperation2_2.Protocol AS Protocol
		|WHERE
		|	Protocol.Ref IN (&References)
		|	AND Protocol.Event = VALUE(Enum.RoutingOperationProtocolEvents.DefectiveGoods)
		|ORDER BY
		|	Ref,
		|	Date DESC
		|TOTALS
		|BY
		|	Ref";
	
	Query = New Query(QueryText);
	Query.SetParameter("References", References);
	
	SetPrivilegedMode(True);
	ResultsArray = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	DataForPrint = New Structure;
	DataForPrint.Insert("HeaderSelection",        ResultsArray[0].Select());
	DataForPrint.Insert("SamplingProtocol",     ResultsArray[1].Select(QueryResultIteration.ByGroups));
	
	Return DataForPrint;
	
EndFunction

#EndRegion

#Region ExecutionAndControl

// Perform an action.
// 
// Parameters:
//  Object - DocumentObject.ProductionOperation2_2
//  RecordingProtocol - See ProductionAccountingClientServer.RecordProtocolConstructor
Procedure AddProtocolEntry(Object, RecordingProtocol) Export
	
	If RecordingProtocol.Count <= 0 Then
		Return;
	EndIf;
	
	NewRecord = ProductionAccountingClientServer.RecordProtocolConstructor();
	FillPropertyValues(NewRecord, RecordingProtocol);
	
	If Not ValueIsFilled(NewRecord.Date) Then
		NewRecord.Date = CurrentSessionDate();
	EndIf;
	If Not ValueIsFilled(NewRecord.EmployeeResponsible) Then
		NewRecord.EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
	CalculateResultsForProtocolLine(Object, NewRecord);
	
	FillPropertyValues(Object.Protocol.Add(), NewRecord);
	
EndProcedure

// Calculate the totals for the protocol line.
// 
// Parameters:
//  Object - DocumentObject.ProductionOperation2_2
//  RecordingProtocol - Structure - see the record of the Protocol Designer
Procedure CalculateResultsForProtocolLine(Object, RecordingProtocol)
	
	Event             = RecordingProtocol.Event;
	Count          = RecordingProtocol.Count;
	
	PreviousState = RecordingProtocol.PreviousState;
	NewState      = "";
	
	Totals = ProductionAccountingClientServer.StructureOfResultsConstructor(Object);
	
	If Count > Totals[RecordingProtocol.PreviousState] Then
		Raise StrTemplate("Exceeded available_1 count In attribute_1 ""%1""", PreviousState);
	EndIf;
	
	If Event = Enums.RoutingOperationProtocolEvents.Perform Then
		
		If GetFunctionalOption("UseOperationExecutionControl")
			And Object.Control = Enums.ManufacturingOperationControlOptions.Required2 Then
			NewState = "FollowUp";
		Else
			NewState = "CountReal";
		EndIf;
		
	ElsIf Event = Enums.RoutingOperationProtocolEvents.Control Then
		
		NewState = "CountReal";
		
	ElsIf Event = Enums.RoutingOperationProtocolEvents.SendForRevision Then
		
		NewState = "QuantityUnderRevision";
		
	ElsIf Event = Enums.RoutingOperationProtocolEvents.PresentForControl Then
		
		NewState = "FollowUp";
		
		Object.ControlAgain = True;
		
	ElsIf Event = Enums.RoutingOperationProtocolEvents.DefectiveGoods Then
		
		NewState = "DefectiveGoodsCount";
		
	ElsIf Event = Enums.RoutingOperationProtocolEvents.Cancel Then
		
		NewState = "CountCanceled";
		
	ElsIf Event = Enums.RoutingOperationProtocolEvents.Cancellation Then
		
		NewState = "QuantityToPerform";
		
	EndIf;
		
	Totals[PreviousState] = Totals[RecordingProtocol.PreviousState] - Count;
	Totals[NewState]      = Totals[NewState] + Count;
	
	FillPropertyValues(Object, Totals);
	
EndProcedure

Procedure RecalcTotals(Object) Export
	
	StructureOfData = ProductionAccountingClientServer.StructureOfResultsConstructor(Object, True);
	
	StructureOfData.Insert("Control",          Object.Control);
	StructureOfData.Insert("ControlAgain", False);
	
	For IndexOf = 0 To Object.Protocol.Count() - 1  Do
		
		CalculateResultsForProtocolLine(StructureOfData, Object.Protocol[IndexOf]);
		
	EndDo;
	
	FillPropertyValues(Object, StructureOfData);
	
EndProcedure

Procedure CalculateStatusWhenAttributesAreChanged(Object) Export
	
	CurrentStatus = Object.Status;
	
	If Object.Count = Object.CountCanceled Then
		
		NewStatus = Enums.ProductionOperationStatuses.NotExecuted;
	
	ElsIf Object.Count <= (Object.FollowUp + Object.DefectiveGoodsCount + Object.CountReal + Object.CountCanceled) Then
			
		NewStatus = Enums.ProductionOperationStatuses.Executed;
		
	Else
			
		NewStatus = Enums.ProductionOperationStatuses.Running;
		
	EndIf;
	
	If CurrentStatus <> NewStatus Then
		
		Object.Status = NewStatus;
		
		FillInDetailsWhenSettingStatus(Object);
		
	EndIf;
	
EndProcedure

Procedure PerformSequenceOfPreviousOperationsInBackground(Parameters, StorageAddress) Export
	
	Result = PerformSequenceOfPreviousOperations(Parameters);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

Function PerformSequenceOfPreviousOperations(Parameters) 
	
	HasErrors      = False;
	TransactionTable = Parameters.TransactionTable;
	TheStructureOfTheSearch = New Structure("Operation,OperationID");
	
	QueryText = "
	|SELECT
	|	T.Department                         AS Department,
	|	T.Stage                                  AS Stage,
	|	T.Operation                              AS Operation,
	|	T.ProductionOperation              AS ProductionOperation,
	|	T.OperationID                 AS OperationID,
	|	T.Performer                           AS Performer,
	|	T.OperationNumber                         AS OperationNumber
	|INTO TTTableOfOperations
	|FROM
	|	&TransactionTable AS T
	|WHERE
	|	T.Mark AND T.Count > 0
	|
	|;
	|
	|//////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	TransactionTable.Operation                      AS Operation,
	|	TransactionTable.ProductionOperation      AS ProductionOperation,
	|	TransactionTable.OperationID         AS OperationID,
	|	DocOperation.Ref                            AS DocumentRef,
	|	DocOperation.PointInTime                     AS DocumentLinkPointInTime,
	|	CASE
	|		WHEN TransactionTable.Performer = DocOperation.Performer
	|				AND NOT TransactionTable.Performer IN (&PerformerNotFilledIn_)
	|			THEN 0
	|		WHEN DocOperation.Status = VALUE(Enum.ProductionOperationStatuses.Running)
	|			THEN 1
	|		ELSE 2
	|	END                                         AS Priority
	|FROM
	|	TTTableOfOperations AS TransactionTable
	|
	|	INNER JOIN Document.ProductionOperation2_2 AS DocOperation
	|	ON DocOperation.Department = TransactionTable.Department
	|		AND DocOperation.Stage = TransactionTable.Stage
	|		AND DocOperation.Operation = TransactionTable.Operation
	|		AND DocOperation.OperationID = TransactionTable.OperationID
	|		AND DocOperation.Posted
	|		AND (DocOperation.Status = VALUE(Enum.ProductionOperationStatuses.Running)
	|				AND (DocOperation.Count
	|						- DocOperation.FollowUp
	|						- DocOperation.QuantityUnderRevision
	|						- DocOperation.DefectiveGoodsCount
	|						- DocOperation.CountReal
	|						- DocOperation.CountCanceled > 0)
	|			OR DocOperation.Status IN (VALUE(Enum.ProductionOperationStatuses.BeingGenerated),
	|										VALUE(Enum.ProductionOperationStatuses.CreatedOn_)))
	|";
	
	StatusesOfOperations = New Array;
	StatusesOfOperations.Add(Enums.ProductionOperationStatuses.CreatedOn_);
	StatusesOfOperations.Add(Enums.ProductionOperationStatuses.Running);
	
	PerformerNotFilledIn_ = New Array;
	PerformerNotFilledIn_.Add(Undefined);
	PerformerNotFilledIn_.Add(Catalogs.Persons.EmptyRef());
	PerformerNotFilledIn_.Add(Catalogs.Teams.EmptyRef());
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("StatusesOfOperations",       StatusesOfOperations);
	Query.SetParameter("PerformerNotFilledIn_", PerformerNotFilledIn_);
	Query.SetParameter("TransactionTable",       TransactionTable);
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock();
		LockItem = Block.Add("InformationRegister.QueueOfProductionOperations");
		LockItem.DataSource = TransactionTable;
		LockItem.UseFromDataSource("Stage",                  "Stage");
		LockItem.UseFromDataSource("Operation",              "Operation");
		LockItem.UseFromDataSource("OperationID", "OperationID");
		LockItem.Mode = DataLockMode.Exclusive;
		
		Assigned = Query.Execute().Unload();
		Assigned.Indexes.Add("Operation,OperationID");
		
		For IndexOf = 0 To TransactionTable.Count() - 1 Do
			
			LineOperation = TransactionTable[IndexOf];
			
			If LineOperation.Mark = False
				Or LineOperation.Count = 0 Then
					Continue;
			EndIf;
			
			QuantityToPerform = LineOperation.Count;
			
			FillPropertyValues(TheStructureOfTheSearch, LineOperation);
			AssignedByOperation = Assigned.Copy(TheStructureOfTheSearch);
			If AssignedByOperation.Count() > 0 Then
				AssignedByOperation.Sort("Priority,DocumentLinkPointInTime");
				For It = 0 To AssignedByOperation.Count()-1 Do
					
					DocumentObject = AssignedByOperation[It].DocumentRef.GetObject(); // DocumentObject.ProductionOperation2_2
					NumberOfOperationsToBePerformed = ProductionAccountingClientServer.QuantityToPerform(DocumentObject);
					
					If NumberOfOperationsToBePerformed > QuantityToPerform Then
						NewAction = ProductionAccountingClientServer.RecordProtocolConstructor("Perform");
						NewAction.Count  = QuantityToPerform;
						Documents.ProductionOperation2_2.AddProtocolEntry(DocumentObject, NewAction);
						QuantityToPerform = 0;
						DocumentObject.Status = Enums.ProductionOperationStatuses.Running;
					Else
						DocumentObject.Status = Enums.ProductionOperationStatuses.Executed;
						Documents.ProductionOperation2_2.FillInDetailsWhenSettingStatus(DocumentObject);
						QuantityToPerform = QuantityToPerform - NumberOfOperationsToBePerformed;
					EndIf;
					
					DocumentObject.Write(DocumentWriteMode.Posting);
					
					If QuantityToPerform <= 0 Then
						Break;
					EndIf;
					
				EndDo;
			EndIf;
			
			If QuantityToPerform > 0 Then
			
				FillingData = Common.ValueTableRowToStructure(LineOperation);
				FillingData.Insert("FillingMethod", "FillInByOperation");
				FillingData.Insert("Status",           Enums.ProductionOperationStatuses.Executed);
				FillingData.Insert("Count",       QuantityToPerform);
				
				NewDocument = Documents.ProductionOperation2_2.CreateDocument();
				NewDocument.Fill(FillingData);
				NewDocument.Write(DocumentWriteMode.Posting);
				
			EndIf;
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteLogEvent(
			NStr("vi = 'Quản lý trong phân xưởng. Tạo giao dịch sản xuất';
				|ru = 'Внутрицеховое управление. Создание производственных операций';
				|en = 'Shop management. Create routing operations'; fa = 'Shop management. Create routing operations';
				|it = 'Gestione interna. Creazione operazioni di produzione';
				|pl = 'Zarządzanie procesem produkcyjnym. Utworzenie operacji produkcyjnych';
				|tr = 'Üretim atölyesi yönetimi. Üretim işlemlerinin oluşturulması'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
		
		HasErrors = True;
		
	EndTry;
	
	Return Not HasErrors;
	
EndFunction

Function WarningTextUnavailabilityOfMarriageReflection() Export
	
	Return NStr("vi = 'Cho phép phản ánh hàng hỏng khi tính sản lượng trên cơ sở giao dịch sản xuất.';
				|ru = 'Отражение брака доступно при включенном оформлении выработки на основании производственных операций.';
				|en = 'To record nonconformities, enable output registration based on routing operations.'; fa = 'To record nonconformities, enable output registration based on routing operations.';
				|it = 'Отражение брака доступно при включенном оформлении выработки на основании производственных операций.';
				|pl = 'To record nonconformities, enable output registration based on routing operations.';
				|tr = 'Uygunsuzluğun yansıması, rota işlemleri temelinde çıktı düzenlenmesi etkinleştirildiğinde mevcuttur.'");
	
EndFunction

// Returns the settings for the "recalculate standards" switch
// 
// Parameters:
// ProductionOperation - DocumentRef.ProductionOperation2_2
// 
// Returns:
//  Structure - From:
//  * Visible - Boolean
//  * Title - String
Function RecalculateStandardsSwitchSettings(ProductionOperation) Export
	
	Visible = ValueIsFilled(ProductionOperation);
	Title = NStr("vi = 'Điền vật tư, sản phẩm, công lao động';
				|ru = 'Заполнить материалы, изделия, трудозатраты';
				|en = 'Fill materials, finished products, labor costs'; fa = 'Fill materials, finished products, labor costs';
				|it = 'Заполнить материалы, изделия, трудозатраты';
				|pl = 'Fill materials, finished products, labor costs';
				|tr = 'Malzemeleri, nihai ürünleri, iş gücü maliyetlerini doldur'");
	
	If Visible Then
		
		AttributesStructure1 = New Structure;
		AttributesStructure1.Insert("BasedOnMasterData",                        "BasedOnMasterData");
		AttributesStructure1.Insert("Operation",                              "Operation");
		AttributesStructure1.Insert("OperationOwner",                      "Operation.Owner");
		AttributesStructure1.Insert("UseMaterialsInOperations",       "Department.UseMaterialsInOperations");
		AttributesStructure1.Insert("UseFinishedProductsInOperations", "Department.UseFinishedProductsInOperations");
		
		AttributesValues = Common.ObjectAttributesValues(ProductionOperation, AttributesStructure1);
		
		ArrayOfResources = New Array;
		If AttributesValues.UseMaterialsInOperations Then
			ArrayOfResources.Add(NStr("vi = 'nguyên vật liệu';
										|ru = 'материалы';
										|en = 'materials'; fa = 'materials';
										|it = 'материалы';
										|pl = 'materials';
										|tr = 'malzemeler'"));
		EndIf;
		If AttributesValues.UseFinishedProductsInOperations Then
			ArrayOfResources.Add(NStr("vi = 'sản phẩm';
										|ru = 'изделия';
										|en = 'finished products'; fa = 'finished products';
										|it = 'изделия';
										|pl = 'finished products';
										|tr = 'nihai ürünler'"));
		EndIf;
		ArrayOfResources.Add(NStr("vi = 'công lao động';
									|ru = 'трудозатраты';
									|en = 'labor costs'; fa = 'labor costs';
									|it = 'трудозатраты';
									|pl = 'labor costs';
									|tr = 'iş gücü maliyetleri'"));
		
		If AttributesValues.BasedOnMasterData Then
			
			RouteDetails  = Catalogs.ManufacturingOperations.DetailsOfOperationRoute(AttributesValues.OperationOwner);
			
			Title = StrTemplate(
				NStr("vi = 'Điền %1 %2';
					|ru = 'Заполнить %1 %2';
					|en = 'Fill %1 %2'; fa = 'Fill %1 %2';
					|it = 'Заполнить %1 %2';
					|pl = 'Fill %1 %2';
					|tr = 'Doldur %1 %2'"),
				StrConcat(ArrayOfResources, ", "),
				ProductionAccountingClientServer.TextFillingOptionAccordingToStandard(RouteDetails.Route));
			
		Else
			
			Title = StrTemplate(
				NStr("vi = 'Tính lại %1';
					|ru = 'Пересчитать %1';
					|en = 'Recalculate %1'; fa = 'Recalculate %1';
					|it = 'Recalculate %1';
					|pl = 'Recalculate %1';
					|tr = '%1 yeniden hesapla'"),
				StrConcat(ArrayOfResources, ", "));
			
		EndIf;
		
	EndIf;
	
	Return New Structure("Visible, Title", Visible, Title);
	
EndFunction

#EndRegion

#Region Other

// Returns settings for using optional table parts in operations.
//
// Parameters:
//  Department - CatalogRef.BusinessStructure - the division of the document.
//  Route	- CatalogRef.RouteSheets - route map of the document.
//
// Returns:
//  Structure - customization.
//
Function AccountingSettings(Department, Route) Export
	
	DivisionParameters = ProductionServer.ProductionBusinessUnitDescription(Department);
	
	If ValueIsFilled(Route) And TypeOf(Route) = Type("CatalogRef.RouteSheets") Then
		AddlParameters = Common.ObjectAttributesValues(
			Route, "UseMaterials, UseFinishedProducts");
	Else
		AddlParameters = New Structure("UseMaterials, UseFinishedProducts", True, True);
	EndIf;
	
	Result = New Structure;
	
	Result.Insert("UseMaterials",
		DivisionParameters.UseMaterialsInOperations
		And AddlParameters.UseMaterials);
	
	Result.Insert("UseFinishedProducts",
		DivisionParameters.UseFinishedProductsInOperations
		And AddlParameters.UseFinishedProducts);
	
	Result.Insert("UseTeamWorkOrders",
		DivisionParameters.UseTeamWorkOrders);
	
	Result.Insert("UseShiftTasks",
		DivisionParameters.UseShiftTasks);
		
	Result.Insert("UseManufacturingExecutionSystem",
		DivisionParameters.UseManufacturingExecutionSystem);
		
	Result.Insert("UseAreas",
		DivisionParameters.UseAreas);
	
	Return Result;
	
EndFunction

Function CreateProductionOperationBasedOnBaseCheck(BasisObject) Export
	
	CheckResult = New Structure("ErrorText", Undefined);
	
	If TypeOf(BasisObject) = Type("DocumentRef.ProductionStage2_2") Then
		
		DivisionParameters = ProductionServer.ProductionBusinessUnitDescription(
			Common.ObjectAttributeValue(BasisObject, "Department"));
		
		If Not DivisionParameters.UseOperationManagement Then
			
			CheckResult.ErrorText = NStr("vi = 'Lệnh không thể được thực thi cho chứng từ này.';
										|ru = 'Команда не может быть выполнена для данного документа';
										|en = 'Unable to execute the command for this document'; fa = 'Unable to execute the command for this document';
										|it = 'Il comando non può essere eseguito per questo documento';
										|pl = 'Nie można wykonać polecenia dla danego dokumentu.';
										|tr = 'Mevcut belge için komut gerçekleştirilemez'");
			
		EndIf;
		
	Else
		
		CheckResult.ErrorText = NStr("vi = 'Lệnh không thể được thực thi cho chứng từ này.';
									|ru = 'Команда не может быть выполнена для данного документа';
									|en = 'Unable to execute the command for this document'; fa = 'Unable to execute the command for this document';
									|it = 'Il comando non può essere eseguito per questo documento';
									|pl = 'Nie można wykonać polecenia dla danego dokumentu.';
									|tr = 'Mevcut belge için komut gerçekleştirilemez'");
		
	EndIf;
	
	Return CheckResult;
	
EndFunction

Procedure CreateTTBatchesOfOperations(TempTablesManager, Stages) Export
	
	Query = New Query(
		"SELECT
		|	Table.Ref AS ProductionOperation,
		|	Table.Stage AS Stage,
		|	Table.Operation AS Operation,
		|	Table.OperationID AS OperationID,
		|	Table.LotNumber AS LotNumber,
		|	Table.Count - Table.CountCanceled AS Count,
		|	Table.Department AS Department,
		|	Table.WorkCenter AS WorkCenter,
		|	Table.Status AS Status,
		|	Table.RepetitionIsRequired AS RepetitionIsRequired
		|INTO TTBatchOperations
		|FROM
		|	Document.ProductionOperation2_2 AS Table
		|WHERE
		|	Table.Stage IN(&ReferencesArrray)
		|	AND Table.Posted");
	
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("ReferencesArrray", TMCommonUseClientServer.Array(Stages));
	Query.Execute();
	
EndProcedure

Function QueryTextTransactionList() Export
	
	Return
		"SELECT
		|	Operations.Ref AS Ref,
		|	Operations.Date AS Date,
		|	Operations.Number AS Number,
		|	Operations.Performer AS Performer,
		|	CASE
		|		WHEN Operations.WorkCenter REFS Catalog.WorkCenterTypes
		|			THEN Operations.WorkCenter
		|		ELSE
		|			Operations.WorkCenter.WorkCenterType
		|	END AS WorkCenterType,
		|	CASE
		|		WHEN Operations.WorkCenter REFS Catalog.WorkCenters
		|			THEN Operations.WorkCenter
		|		ELSE
		|			VALUE(Catalog.WorkCenters.EmptyRef)
		|	END AS WorkCenter,
		|	CASE
		|		WHEN Operations.Status = VALUE(Enum.ProductionOperationStatuses.Executed)
		|			THEN Operations.CountReal
		|				+ Operations.FollowUp
		|				+ Operations.QuantityUnderRevision
		|				+ Operations.DefectiveGoodsCount
		|		ELSE Operations.Count
		|				- Operations.CountCanceled
		|	END AS Count,
		|	Operations.Operation.UnitOfMeasure AS UnitOfMeasure,
		|	Operations.Status AS Status
		|FROM
		|	Document.ProductionOperation2_2 AS Operations
		|WHERE
		|	Operations.Ref IN(&TransactionList)
		|	AND Operations.Posted
		|
		|ORDER BY
		|	Ref";
	
EndFunction

Function TextOfOperationRouteDetailsField(Source = "")
	
	FieldText = "
	|	CASE
	|		WHEN Operations.Operation = VALUE(Catalog.ManufacturingOperations.EmptyRef)
	|			THEN Operations.Stage
	|		WHEN Operations.Operation.Owner REFS Catalog.ProductionStages
	|			THEN Operations.Operation.Owner.Owner
	|		ELSE Operations.Operation.Owner
	|	END                                                  AS Route,
	|	CASE
	|		WHEN Operations.Operation = VALUE(Catalog.ManufacturingOperations.EmptyRef)
	|			THEN &PresentationStage
	|		WHEN Operations.Operation.Owner REFS Catalog.ProductionStages
	|			THEN PRESENTATION(Operations.Operation.Owner.Owner)
	|		ELSE PRESENTATION(Operations.Operation.Owner)
	|	END                                                  AS RoutePresentation
	|";
	
	Documents.ProductionStage2_2.ReplacePresentationField(FieldText, "&PresentationStage", "Operations.Stage");
	
	If Source <> "" Then
		
		FieldText = StrReplace(FieldText, "Operations", Source);
		
	EndIf;
	
	Return FieldText;
	
EndFunction

// Returns:
// 	Structure - LongDesc:
// * Old_ - Map of KeyAndValue - Where:
// ** Key - String -
// ** Value - Array of ValueTableRow - 
// * New - Map of KeyAndValue - Where:
// ** Key - String -
// ** Value - Array of ValueTableRow -
Function NewStructureForRowsToDelete()
	Return New Structure("Old_, New", New Map, New Map);
EndFunction

// Types of work centers of operations.
// 
// Parameters:
//  Operations - Array of DocumentRef.ProductionOperation2_2
// 
// Returns:
//  Map of KeyAndValue - list of objects and the values of their Attributes:
//   * Key - DocumentRef.ProductionOperation2_2
//   * Value - CatalogRef.WorkCenterTypes:
Function WorkCentersTypesOfOperations(Operations)
	
	Result = New Map;
	
	QueryText = "
	|SELECT
	|	T.Ref                     AS Ref,
	|	CASE
	|		WHEN T.WorkCenter REFS Catalog.WorkCenterTypes
	|			THEN T.WorkCenter
	|		ELSE T.WorkCenter.WorkCenterType
	|	END                        AS WorkCenterType
	|FROM
	|	Document.ProductionOperation2_2 AS T
	|WHERE
	|	T.Ref IN (&Operations)
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Operations", Operations);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		Result.Insert(Selection.Ref, Selection.WorkCenterType);
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "Documents.ProductionOperation2_2.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.25.12";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("a2d3355b-dd58-8079-4b28-d80d9a6f8588");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.ProductionOperation2_2.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Điền mục tin ""Nguồn lực sản xuất"" và ""Tên định danh của giao dịch kiểm soát"".';
							|ru = 'Заполняет реквизиты ""Рабочий центр"" и ""Идентификатор контрольной операции"".';
							|en = 'Fills the ""Work center"" and ""Control operation ID"" attributes.'; fa = 'Fills the ""Work center"" and ""Control operation ID"" attributes.';
							|it = 'Fills the ""Work center"" and ""Control operation ID"" attributes.';
							|pl = 'Fills the ""Work center"" and ""Control operation ID"" attributes.';
							|tr = '""İş merkezi"" ve ""Kontrol işlemi tanımlayıcısı"" özniteliklerini doldurur.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.ProductionOperation2_2.FullName());
	ItemsToRead.Add(Metadata.InformationRegisters.DeleteQueueOfRoutingOperations.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.ProductionOperation2_2.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.ProductionOperation2_2.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// Registers data for processing when switching to a new version.
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.ProductionOperation2_2";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Ref");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	QueryText = "
	|SELECT DISTINCT
	|	NestedQuery.Ref AS Ref
	|FROM
	|
	|(SELECT
	|	Table.Ref AS Ref
	|FROM
	|	Document.ProductionOperation2_2 AS Table
	|WHERE
	|	NOT Table.DeletionMark
	|	AND Table.DeleteWorkCenterType <> VALUE(Catalog.WorkCenterTypes.EmptyRef)
	|	AND Table.WorkCenter IN (
	|				UNDEFINED,
	|				VALUE(Catalog.WorkCenterTypes.EmptyRef),
	|				VALUE(Catalog.WorkCenters.EmptyRef))
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS Ref
	|FROM
	|	Document.ProductionOperation2_2 AS Table
	|WHERE
	|	NOT Table.DeletionMark
	|	AND Table.BasedOnMasterData
	|	AND Table.OperationID <> 0
	|	AND Table.ControlOperationID = 0
	|	AND Table.Control IN (
	|		VALUE(Enum.ManufacturingOperationControlOptions.Required2),
	|		VALUE(Enum.ManufacturingOperationControlOptions.RequiredForSubsequentOperations))
	|	AND TRUE IN (
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.DeleteQueueOfRoutingOperations AS DeleteQueue
	|		WHERE
	|			DeleteQueue.Department = Table.Department
	|			AND DeleteQueue.Stage = Table.Stage
	|			AND DeleteQueue.Operation = Table.Operation
	|			AND DeleteQueue.OperationID = Table.OperationID
	|			AND DeleteQueue.ControlOperationID <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS Ref
	|FROM 
	|	Document.ProductionOperation2_2 AS Table
	|WHERE
	|	NOT Table.DeletionMark
	|	AND Table.BasedOnMasterData
	|	AND Table.TimePerPiece <> 0
	|	AND Table.SetupTime = 0
	|	AND Table.TimePerPieceUnitOfMeasure <> Table.ExecutionTimeUnitOfMeasure
	|	AND Table.SetupTimeUnitOfMeasure = Table.ExecutionTimeUnitOfMeasure
	|
	|) AS NestedQuery
	|";
	
	Query = New Query(QueryText);
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "Document.ProductionOperation2_2";
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	QueryText = "
	|SELECT
	|	UpdatedData.Ref AS Ref
	|INTO DocumentsTable
	|FROM
	|	&UpdatedData AS UpdatedData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsTable.Ref AS Ref,
	|	ISNULL(DeleteQueue.ControlOperationID, 0) AS ControlOperationID
	|FROM
	|	DocumentsTable AS DocumentsTable
	|		LEFT JOIN Document.ProductionOperation2_2 AS DocumentData
	|		ON DocumentsTable.Ref = DocumentData.Ref
	|		LEFT JOIN InformationRegister.DeleteQueueOfRoutingOperations AS DeleteQueue
	|		ON DocumentData.Department = DeleteQueue.Department
	|		AND DocumentData.Stage = DeleteQueue.Stage
	|		AND DocumentData.Operation = DeleteQueue.Operation
	|		AND DocumentData.OperationID = DeleteQueue.OperationID
	|WHERE
	|	DocumentData.Control = VALUE(Enum.ManufacturingOperationControlOptions.RequiredForSubsequentOperations)
	|	AND ISNULL(DeleteQueue.ControlOperationID, 0) <> 0";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("UpdatedData", UpdatedData);
	
	IDs = Query.Execute().Unload();
	IDs.Indexes.Add("Ref");
	
	For Each Item In UpdatedData Do
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Item.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			DocumentObject = Item.Ref.GetObject(); // DocumentObject.ProductionOperation2_2
			
			If DocumentObject = Undefined Then
				InfobaseUpdate.MarkProcessingCompletion(Item.Ref);
				CommitTransaction();
				Continue;
			EndIf;
			
			ObjectModified = False;
			
			If ValueIsFilled(DocumentObject.DeleteWorkCenterType)
				And Not ValueIsFilled(DocumentObject.WorkCenter) Then
				DocumentObject.WorkCenter = DocumentObject.DeleteWorkCenterType;
				DocumentObject.DeleteWorkCenterType = Undefined;
				ObjectModified = True;
			EndIf;
			
			If DocumentObject.BasedOnMasterData
					And DocumentObject.OperationID <> 0
					And DocumentObject.ControlOperationID = 0 Then
				If DocumentObject.Control = Enums.ManufacturingOperationControlOptions.Required2 Then
					DocumentObject.ControlOperationID = DocumentObject.OperationID;
					ObjectModified = True;
				ElsIf DocumentObject.Control = Enums.ManufacturingOperationControlOptions.RequiredForSubsequentOperations Then
					FoundRow = IDs.Find(Item.Ref, "Ref");
					If FoundRow <> Undefined Then
						DocumentObject.ControlOperationID = FoundRow.ControlOperationID;
						ObjectModified = True;
					EndIf;
				EndIf;
			EndIf;
			
			If DocumentObject.BasedOnMasterData
				And DocumentObject.TimePerPiece <> 0
				And DocumentObject.SetupTime = 0
				And DocumentObject.TimePerPieceUnitOfMeasure <> DocumentObject.ExecutionTimeUnitOfMeasure
				And DocumentObject.SetupTimeUnitOfMeasure = DocumentObject.ExecutionTimeUnitOfMeasure Then
				Documents.ProductionOperation2_2.RecalculateExecutionTime(DocumentObject);
				ObjectModified = True;
			EndIf;
			
			If ObjectModified Then
				InfobaseUpdate.WriteObject(DocumentObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Item.Ref);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Item.Ref);
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
