#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

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

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	// Product selection task
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "SelectionTask";
	PrintCommand.Presentation = NStr("vi = 'Nhiệm vụ lấy ra';
									|ru = 'Задание на отбор';
									|en = 'Picking job'; fa = 'کار برداشت';
									|it = 'Picking job';
									|pl = 'Picking job';
									|tr = 'Görev filtresi'");
	PrintCommand.CheckPostingBeforePrint = True;

EndProcedure

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
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "SelectionTask") Then
		
		SpreadsheetDocument = CreatePrintedFormForSelectionTask(
			ObjectsArray, PrintObjects, PrintParameters);
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"SelectionTask",
			NStr("vi = 'Nhiệm vụ lấy ra';
				|ru = 'Задание на отбор';
				|en = 'Picking job'; fa = 'کار برداشت';
				|it = 'Picking job';
				|pl = 'Picking job';
				|tr = 'Görev filtresi'"),
			SpreadsheetDocument);
		
	EndIf;
	
EndProcedure

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.GoodsQualityControlCertificate.AddGenerateCommand(GenerationCommands);
	
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

// Returns parameters for specifying series for products specified in the document
//
// Parameters:
//  Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  Structure - with keys:
//   *  PlanAndResearchResult - See ProductsClientServer.SeriesSpecificationParameters
//   *  Goods_Research - See ProductsClientServer.SeriesSpecificationParameters
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = New Structure;
	
	// PlanAndResearchResult
	ParametersForSpecifyingTSSeries = ProductsClientServer.SeriesSpecificationParameters();
	
	ParametersForSpecifyingTSSeries.FullObjectName = "Document.GoodsQualityResearch";
	ParametersForSpecifyingTSSeries.TSSeriesName = "PlanAndResearchResult";
	ParametersForSpecifyingTSSeries.NameTSGoods = "PlanAndResearchResult";
	ParametersForSpecifyingTSSeries.WarehouseTransactions.Add(Enums.WarehouseTransactions.EmptyRef());
	ParametersForSpecifyingTSSeries.UseCostAccountingByBatches = GetFunctionalOption("UseCostAccountingByBatchesWarehouse");
	ParametersForSpecifyingTSSeries.UseItemsBatch  = GetFunctionalOption("UseItemsBatchWarehouse");
	ParametersForSpecifyingTSSeries.AdditionalFieldNames.Add("Purpose");
	ParametersForSpecifyingTSSeries.ThisIsAnInvoice = False;
	
	SeriesSpecificationParameters.Insert("PlanAndResearchResult", ParametersForSpecifyingTSSeries);
	
	// Goods_Research
	ParametersForSpecifyingTSSeries = ProductsClientServer.SeriesSpecificationParameters();
	
	ParametersForSpecifyingTSSeries.FullObjectName = "Document.GoodsQualityResearch";
	ParametersForSpecifyingTSSeries.TSSeriesName = "Goods_Research";
	ParametersForSpecifyingTSSeries.NameTSGoods = "Goods_Research";
	ParametersForSpecifyingTSSeries.WarehouseTransactions.Add(Enums.WarehouseTransactions.EmptyRef());
	ParametersForSpecifyingTSSeries.UseCostAccountingByBatches = GetFunctionalOption("UseCostAccountingByBatchesWarehouse");
	ParametersForSpecifyingTSSeries.UseItemsBatch  = GetFunctionalOption("UseItemsBatchWarehouse");
	ParametersForSpecifyingTSSeries.ThisIsAnInvoice = False;
	
	SeriesSpecificationParameters.Insert("Goods_Research", ParametersForSpecifyingTSSeries);
	
	Return SeriesSpecificationParameters;
	
EndFunction

// The procedure fills in the Statuses of specifying the series in the TS lines
//
// Parameters:
//  SeriesSpecificationParameters - See ProductsClientServer.SeriesSpecificationParameters
//
// Returns:
//	String - The text of the request to fill in statuses.
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = "";
	If SeriesSpecificationParameters.NameTSGoods = "PlanAndResearchResult" Then
		
		QueryText = QueryTextForFillingInStatusesForSpecifyingSeriesPlan(SeriesSpecificationParameters);
		
	ElsIf SeriesSpecificationParameters.NameTSGoods = "Goods_Research" Then
		
		QueryText = QueryTextForFillingInStatusesIndicatingResearchBatches(SeriesSpecificationParameters);
		
	EndIf;
	
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
	
	DescriptionOfColumns.DataPaths.Products = "Object.PlanAndResearchResult.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.PlanAndResearchResult.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse = "Object.Warehouse";
	DescriptionOfColumns.DataPaths.ControlledLotReference = "Object.PlanAndResearchResult.ControlledLotReference";
	
	Return FormTemplate;
	
EndFunction

#EndRegion

#Region CreatingDocuments

// Returns the structure with the results of the formation of the document "Quality research of goods".
//
// Returns:
//   Structure of Array, ValueTable - It contains the results of the formation, including a table of values with item research maps, control requests and item quality research documents,
//               as well as an array of created objects and an array of messages.
//
Function ResultOfFormation() Export
	
	ResultOfFormation = New ValueTable;
	ResultOfFormation.Columns.Add("GoodsResearchSheet", New TypeDescription("CatalogRef.GoodsResearchSheets"));
	ResultOfFormation.Columns.Add("RequestForControl", New TypeDescription("DocumentRef.RequestForGoodsQualityControl"));
	ResultOfFormation.Columns.Add("GoodsQualityResearch", New TypeDescription("DocumentRef.GoodsQualityResearch"));
	
	CreatedObjects = New Array;
	
	Messages = New Array;
	
	Result = New Structure;
	Result.Insert("ResultOfFormation", ResultOfFormation);
	Result.Insert("CreatedObjects", CreatedObjects);
	Result.Insert("Messages", Messages);
	
	Return Result;
	
EndFunction

// Parameters:
//  Parameters - Structure - From:
//  *Goods - ValueTable
//  *RequestForControl - DocumentRef.RequestForGoodsQualityControl
//  *SeveralItemsInStudy - Boolean
//  StorageAddress - String
Procedure CreateDocumentsDeferred(Parameters, StorageAddress) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Document.GoodsQualityResearch.ManagerModule.CreateDocumentsDeferred");
	
	DataVolume = CreateDocumentsDeferredInsideTimeMeasurement(Parameters, StorageAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
	
EndProcedure

// Parameters:
//  Parameters  - Structure - From:
//  *References - Array of DocumentRef.GoodsQualityResearch
//  StorageAddress  - String
Procedure DeleteObjectsOnHold(Parameters, StorageAddress) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Document.GoodsQualityResearch.ManagerModule.DeleteObjectsOnHold");
	
	DeleteObjectsDeferredInsideTimeMeasurement(Parameters, StorageAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, Parameters.References.Count());
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region SetOfSeries

Function QueryTextForFillingInStatusesForSpecifyingSeriesPlan(SeriesSpecificationParameters)

	QueryText =
	"SELECT
	|	Goods.LineNumber AS LineNumber,
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
	|	Goods.Products AS Products,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind,
	|	Goods.Series AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|INDEX BY
	|	ProductKind
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
	|		ON Goods.ProductKind = BatchAccountingPolicies.Ref
	|			AND BatchAccountingPolicies.Warehouse = &Warehouse
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

Function QueryTextForFillingInStatusesIndicatingResearchBatches(SeriesSpecificationParameters)
	
	QueryText =
		"SELECT
		|	Goods.LineNumber AS LineNumber,
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
		|	Goods.Products AS Products,
		|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind,
		|	Goods.Series AS Series,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus
		|INTO ProductsToRequest
		|FROM
		|	Goods AS Goods
		|INDEX BY
		|	ProductKind
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.LineNumber AS LineNumber,
		|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
		|	CASE
		|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
		|			THEN 0
		|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.PolicyType = VALUE(Enum.TypesOfBatchSpecificationPolicies.ReferenceBatchSpecification)
		|			THEN
		|				CASE
		|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|						THEN 2
		|					ELSE 21
		|				END
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
		|INTO Statuses
		|FROM
		|	ProductsToRequest AS Goods
		|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
		|		ON Goods.ProductKind = BatchAccountingPolicies.Ref
		|			AND BatchAccountingPolicies.Warehouse = &Warehouse
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
		|ORDER BY
		|	Statuses.LineNumber";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Other
// Creates documents deferred inside the time measurement.
//
// Parameters:
//   Parameters - Structure - Parameters for creating documents
//   StorageAddress - String - Storage address for processing
//
// Returns:
//   Number - Number of generated data
Function CreateDocumentsDeferredInsideTimeMeasurement(Parameters, StorageAddress)
	
	ResultOfFormation = ResultOfFormation();
	GenerateResearch(
		Parameters.Goods, Parameters.RequestForControl, Parameters.SeveralItemsInStudy, ResultOfFormation, StorageAddress);
		
	DataVolume = 0;
	Result = GetFromTempStorage(StorageAddress);
	If TypeOf(Result) = Type("Structure") Then
		DataVolume = Result.ResultOfFormation.Count();
	EndIf;
	
	Return DataVolume;
	
EndFunction

// Generate item research documents.
// 
// Parameters:
//  Goods - ValueTable
//  RequestForControl - DocumentRef.RequestForGoodsQualityControl
//  SeveralItemsInStudy - Boolean
//  Result - Structure
//  StorageAddress - String
//
Procedure GenerateResearch(Goods, RequestForControl, SeveralItemsInStudy, Result, StorageAddress)

	ResultOfFormation = Result.ResultOfFormation;
	CreatedObjects = Result.CreatedObjects;
	Messages = Result.Messages;

	If Not SeveralItemsInStudy Then
		
	// Creating research
		SetPrivilegedMode(True);
		For Each SpecificationRow In Goods Do

			While True Do

				Try

					HeaderAttributes = New Structure;

					HeaderAttributes.Insert("RequestForControl", RequestForControl);
					HeaderAttributes.Insert("GoodsResearchSheet", SpecificationRow.GoodsResearchSheet);
					HeaderAttributes.Insert("Control", SpecificationRow.Control);
					HeaderAttributes.Insert("Warehouse", SpecificationRow.Warehouse);
					HeaderAttributes.Insert("EmployeeResponsible", SpecificationRow.Performer);
					HeaderAttributes.Insert("Completed", False);

					HeaderAttributes.Insert("InstancesCheckMethod",
						Enums.CheckOptionsOfResearchCopies.CopyByCopy);

					HeaderAttributes.Insert("Date", CurrentSessionDate());
					HeaderAttributes.Insert("Comment", NStr(
						"vi = 'Được tạo tự động (chỉ định nghiên cứu)';
						|ru = 'Сформирован автоматически (назначение исследований)';
						|en = 'Generated automatically (research assignment)'; fa = 'Generated automatically (research assignment)';
						|it = 'Generated automatically (research assignment)';
						|pl = 'Generated automatically (research assignment)';
						|tr = 'Otomatik oluşturuldu (inceleme atama)'"));

					ItemsForResearch = Goods.CopyColumns();
					NewRow = ItemsForResearch.Add();
					FillPropertyValues(NewRow, SpecificationRow);

					FillingData = New Structure;
					FillingData.Insert("HeaderAttributes", HeaderAttributes);
					FillingData.Insert("Goods", ItemsForResearch);

					ResearchProject = Documents.GoodsQualityResearch.CreateDocument();
					ResearchProject.Fill(FillingData);
				
					// Refusal to check filling in additional Attributes
					SessionParameters.PropertiesFillingInteractiveCheck = True;

					If ResearchProject.CheckFilling() Then

						ResearchProject.Write(DocumentWriteMode.Posting);

						NewRow = ResultOfFormation.Add();
						NewRow.GoodsResearchSheet = SpecificationRow.GoodsResearchSheet;
						NewRow.RequestForControl = RequestForControl;
						NewRow.GoodsQualityResearch = ResearchProject.Ref;

						CreatedObjects.Add(ResearchProject.Ref);

					EndIf;

				Except

					Event = NStr("vi = 'Kiểm nghiệm hàng hóa';
								|ru = 'Исследование товаров';
								|en = 'Goods research'; fa = 'تحلیل کالاها';
								|it = 'Goods research';
								|pl = 'Goods research';
								|tr = 'Ürün incelemesi'", Common.DefaultLanguageCode()) + "." + NStr(
						"vi = 'Tạo các kiểm nghiệm';
						|ru = 'Формирование исследований';
						|en = 'Generate research'; fa = 'Generate research';
						|it = 'Generate research';
						|pl = 'Generate research';
						|tr = 'İncelemelerin oluşturulması'", Common.DefaultLanguageCode());

					WriteLogEvent(Event, EventLogLevel.Error, , ,
						ErrorProcessing.DetailErrorDescription(ErrorInfo()));

				EndTry;

				For Each Message In GetUserMessages(True) Do
					Message.DataKey = ResearchProject.Ref;
					Messages.Add(Message);
				EndDo;

				Break;

			EndDo;

		EndDo;
		SetPrivilegedMode(False);

	Else

		GoodsResearchMapSearchStructure = New Structure;
		GoodsResearchMapSearchStructure.Insert("GoodsResearchSheet",
			Catalogs.GoodsResearchSheets.EmptyRef());
		GoodsResearchMapSearchStructure.Insert("Performer", Catalogs.Users.EmptyRef());
		GoodsResearchMapSearchStructure.Insert("Warehouse", Catalogs.Warehouses.EmptyRef());

		GoodsResearchMaps = Goods.Copy( , "GoodsResearchSheet, Performer, Warehouse");
		GoodsResearchMaps.GroupBy("GoodsResearchSheet, Performer, Warehouse");
	
		// Creating research
		SetPrivilegedMode(True);
		For Each SpecificationRow In GoodsResearchMaps Do

			While True Do

				Try

					FillPropertyValues(GoodsResearchMapSearchStructure, SpecificationRow);
					ItemsToBePlacedInStudy = Goods.Copy(GoodsResearchMapSearchStructure);

					HeaderAttributes = New Structure;

					If ItemsToBePlacedInStudy.Count() <> 0 Then

						RowOfGoods = ItemsToBePlacedInStudy[0];
						HeaderAttributes.Insert("RequestForControl", RequestForControl);
						HeaderAttributes.Insert("GoodsResearchSheet", RowOfGoods.GoodsResearchSheet);
						HeaderAttributes.Insert("Control", RowOfGoods.Control);
						HeaderAttributes.Insert("Warehouse", RowOfGoods.Warehouse);
						HeaderAttributes.Insert("EmployeeResponsible", RowOfGoods.Performer);
						HeaderAttributes.Insert("Completed", False);

						HeaderAttributes.Insert("InstancesCheckMethod",
							Enums.CheckOptionsOfResearchCopies.CopyByCopy);

						HeaderAttributes.Insert("Date", CurrentSessionDate());
						HeaderAttributes.Insert("Comment", NStr(
						"vi = 'Được tạo tự động (chỉ định nghiên cứu)';
						|ru = 'Сформирован автоматически (назначение исследований)';
						|en = 'Generated automatically (research assignment)'; fa = 'Generated automatically (research assignment)';
						|it = 'Generated automatically (research assignment)';
						|pl = 'Generated automatically (research assignment)';
						|tr = 'Otomatik oluşturuldu (inceleme atama)'"));

					EndIf;

					FillingData = New Structure;
					FillingData.Insert("HeaderAttributes", HeaderAttributes);
					FillingData.Insert("Goods", ItemsToBePlacedInStudy);

					ResearchProject = Documents.GoodsQualityResearch.CreateDocument();
					ResearchProject.Fill(FillingData);
				
					// Refusal to check filling in additional Attributes
					SessionParameters.PropertiesFillingInteractiveCheck = True;

					If ResearchProject.CheckFilling() Then
						ResearchProject.Write(DocumentWriteMode.Posting);

						NewRow = ResultOfFormation.Add();
						If ItemsToBePlacedInStudy.Count() <> 0 Then
							NewRow.GoodsResearchSheet = RowOfGoods.GoodsResearchSheet;
						EndIf;
						NewRow.RequestForControl = RequestForControl;
						NewRow.GoodsQualityResearch = ResearchProject.Ref;

						CreatedObjects.Add(ResearchProject.Ref);

					EndIf;

				Except

					Event = NStr("vi = 'Kiểm nghiệm hàng hóa';
								|ru = 'Исследование товаров';
								|en = 'Goods research'; fa = 'تحلیل کالاها';
								|it = 'Goods research';
								|pl = 'Goods research';
								|tr = 'Ürün incelemesi'", Common.DefaultLanguageCode()) + "." + NStr(
						"vi = 'Tạo các kiểm nghiệm';
						|ru = 'Формирование исследований';
						|en = 'Generate research'; fa = 'Generate research';
						|it = 'Generate research';
						|pl = 'Generate research';
						|tr = 'İncelemelerin oluşturulması'", Common.DefaultLanguageCode());

					WriteLogEvent(Event, EventLogLevel.Error, , ,
						ErrorProcessing.DetailErrorDescription(ErrorInfo()));

				EndTry;

				For Each Message In GetUserMessages(True) Do
					Message.DataKey = ResearchProject.Ref;
					Messages.Add(Message);
				EndDo;

				Break;

			EndDo;

		EndDo;
		SetPrivilegedMode(False);

	EndIf;
	
	// Clearing the message stack
	For Each Message In GetUserMessages(True) Do
		Messages.Add(Message);
	EndDo;
	
	// Fixing the result
	PutToTempStorage(Result, StorageAddress);

EndProcedure

// Returns the Query Text for a dynamic list of item research.
//
// Returns:
//   String - Query Text for a dynamic list of item research
Function QueryTextOfDynamicGoodsResearchList() Export
	
	QueryText = "SELECT
	|	GoodsQualityResearchOverridable.Ref,
	|	GoodsQualityResearchOverridable.Number,
	|	GoodsQualityResearchOverridable.Date,
	|	GoodsQualityResearchOverridable.GoodsResearchSheet,
	|	GoodsQualityResearchOverridable.Control,
	|	GoodsQualityResearchOverridable.EmployeeResponsible
	|FROM
	|	Document.GoodsQualityResearch AS GoodsQualityResearchOverridable
	|WHERE
	|	GoodsQualityResearchOverridable.Ref IN (&References)";
	
	Return QueryText;
	
EndFunction

Procedure DeleteObjectsDeferredInsideTimeMeasurement(Parameters, StorageAddress)

	For Each Ref In Parameters.References Do

		Object = Ref.GetObject();

		If Object = Undefined Or Object.DeletionMark Then
			Continue;
		EndIf;

		Object.Lock();

		SetPrivilegedMode(True);
		Object.SetDeletionMark(True);
		SetPrivilegedMode(False);

	EndDo;

EndProcedure

#EndRegion

#Region Print

#Region SelectionTask

Function CreatePrintedFormForSelectionTask(ObjectsArray, PrintObjects, PrintParameters)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PageOrientation = PageOrientation.Landscape;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_GoodsQualityResearch_SelectionTask";
	
	Template = PrintManagement.PrintFormTemplate("Document.GoodsQualityResearch.PF_MXL_SelectionTask");
	FirstDocument = True;
	
	DataForPrint = GetDataForPrintedFormSelectionTask(ObjectsArray, PrintParameters);
	SampleDocument = DataForPrint.SampleDocument;
	
	While SampleDocument.Next() Do
	
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		SelectionTaskDisplayTitle(SpreadsheetDocument, Template, SampleDocument);
		
		SelectionTaskDisplayHeader(SpreadsheetDocument, Template, SampleDocument);
		
		SelectionTaskDisplayGoods(
			PrintParameters, SpreadsheetDocument, Template, SampleDocument, DataForPrint);
		
		PrintManagement.SetDocumentPrintArea(
			SpreadsheetDocument,
			RowNumberStart,
			PrintObjects,
			SampleDocument.Ref);
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

Function GetDataForPrintedFormSelectionTask(ObjectsArray, PrintParameters)
	
	BatchQueryText = New Array;
	IndexesOfResults = New Map;
	IndexOf = 0;
	
	#Region QueryTextHeader
	
	QueryText =
	"SELECT
	|	DocumentData.Ref            AS Ref,
	|	DocumentData.Number             AS Number,
	|	DocumentData.Presentation     AS PresentationOfOrder,
	|
	|	DocumentData.Date              AS CompletionDatePlan,
	|	DocumentData.EmployeeResponsible.Presentation AS ArtistPresentation
	|FROM
	|	Document.GoodsQualityResearch AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref";
	
	BatchQueryText.Add(QueryText);
	IndexesOfResults.Insert("SampleDocument", IndexOf);
	IndexOf = IndexOf + 1;
	
	#EndRegion
	
	#Region QueryTextGoods
	
	QueryText = "SELECT
	|	Goods.Ref AS Ref,
	|	Goods.Products AS Products,
	|	Goods.Products.Code AS Code,
	|	Goods.Products.SKU AS SKU,
	|	Goods.Products.DescriptionFull AS ProductFullName,
	|	Goods.Characteristic.DescriptionFull AS CharacteristicFullName,
	|	Goods.Series,
	|	Goods.Ref.Warehouse AS Warehouse,
	|	Goods.Purpose,
	|	Goods.ControlledLotReference,
	|	Goods.Ref.Warehouse.Presentation AS WarehousePresentation_,
	|	Goods.Products.UnitOfMeasure AS UnitOfMeasurePresentation,
	|	Goods.Count AS Count
	|FROM
	|	Document.GoodsQualityResearch.PlanAndResearchResult AS Goods
	|WHERE
	|	Goods.Ref IN (&ObjectsArray)
	|
	|ORDER BY
	|	Ref,
	|	Goods.LineNumber
	|TOTALS
	|BY
	|	Ref";
		
	BatchQueryText.Add(QueryText);
	IndexesOfResults.Insert("SampleProducts_", IndexOf);
	IndexOf = IndexOf + 1;
	
	#EndRegion
	
	#Region AssemblingText
	
	Separator =
	"
	|;
	|/////////////////////////////////////////////////////////////
	|";
	
	QueryText = StrConcat(BatchQueryText, Separator);
	
	#EndRegion
	
	#Region RequestExecution
	
	Query = New Query(QueryText);
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.TempTablesManager = New TempTablesManager;
	
	SetPrivilegedMode(True);
	
	ResultsArray = Query.ExecuteBatch();
	
	SetPrivilegedMode(False);
	
	DataForPrint = New Structure;
	
	For Each Result In IndexesOfResults Do
		
		QueryResult = ResultsArray[Result.Value]; // QueryResult
		Selection = QueryResult.Select(
			?(Result.Key = "SampleDocument",
				QueryResultIteration.Linear,
				QueryResultIteration.ByGroups));
		DataForPrint.Insert(Result.Key, Selection);
		
	EndDo;
	
	#EndRegion
	
	Return DataForPrint;
	
EndFunction

// Displays the title
//
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument
//  Template - SpreadsheetDocument, DataCompositionAppearanceTemplate, ActiveDocumentShell, GeographicalSchema, TextDocument, HTMLDocumentShell, BinaryData, GraphicalSchema, DataCompositionSchema -
//  SampleDocument - QueryResultSelection - Contains:
//                     * Ref - DocumentRef - 
//
Procedure SelectionTaskDisplayTitle(SpreadsheetDocument, Template, SampleDocument)
	
	Area = Template.GetArea("Title");
	
	Area.Parameters.Fill(SampleDocument);
	
	BarcodingOfPrintForms.OutputBarcodeToTabularDocument(
		SpreadsheetDocument,
		Template,
		Area,
		SampleDocument.Ref);
	
	SpreadsheetDocument.Put(Area);
	
EndProcedure

Procedure SelectionTaskDisplayHeader(SpreadsheetDocument, Template, SampleDocument)
	
	Area = Template.GetArea("Header");
	
	Area.Parameters.Fill(SampleDocument);
	If ValueIsFilled(SampleDocument.ArtistPresentation) Then
		Area.Parameters.ArtistPresentation = PersonsClientServer.InitialsAndLastName(SampleDocument.ArtistPresentation);
	EndIf;
	
	SpreadsheetDocument.Put(Area);
	
EndProcedure

// Displays Goods
//
// Parameters:
//  PrintParameters - Structure
//  SpreadsheetDocument - SpreadsheetDocument
//  Template - SpreadsheetDocument, DataCompositionAppearanceTemplate, ActiveDocumentShell, GeographicalSchema, TextDocument, HTMLDocumentShell, BinaryData, GraphicalSchema, DataCompositionSchema -
//  SampleDocument - QueryResultSelection - Contains:
// * Ref - DocumentRef -
//  DataForPrint - Structure - Contains:
// * SampleProducts_ - QueryResultSelection
Procedure SelectionTaskDisplayGoods(PrintParameters, SpreadsheetDocument, Template, SampleDocument, DataForPrint)
	
	SampleProducts_ = DataForPrint.SampleProducts_;
		
	TheStructureOfTheSearch = New Structure("Ref", SampleDocument.Ref);
	If Not SampleProducts_.FindNext(TheStructureOfTheSearch) Then
		Return;
	EndIf;
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	If OutputCodes Then
		
		SectionHeader = Template.GetArea("HeaderOfGoods_TableWithCode");
		SectionHeader.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
		
		AreaNameString = "TableRowItems_WithCode";
		AreaRow = Template.GetArea(AreaNameString);
		
	Else
		
		SectionHeader = Template.GetArea("GoodsTableHeader_WithoutCode");
		
		AreaNameString = "TableRowItems_WithoutCode";
		AreaRow = Template.GetArea(AreaNameString);
		
	EndIf;
	
	SpreadsheetDocument.Put(SectionHeader);
		
	LineNumber = 0;
	Selection = SampleProducts_.Select();
	While Selection.Next() Do
		
		AreaRow.Parameters.Fill(Selection);
		
		LineNumber = LineNumber + 1;
		AreaRow.Parameters.LineNumber = LineNumber;
		
		If OutputCodes Then
			AreaRow.Parameters.SKU = Selection[NameOfCodeColumn];
		EndIf;
		
		AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
		AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
		
		ProductPresentation = ProductsClientServer.PresentationOfProductsForPrinting(
				Selection.ProductFullName,
				Selection.CharacteristicFullName,
				,
				Selection.Series,
				AdditionalParametersProductPresentation);
		AreaRow.Parameters.ProductPresentation = ProductPresentation;
		AreaRow.Parameters.PresentationPurpose = String(Selection.Purpose);
		
		SpreadsheetDocument.Put(AreaRow);
		
	EndDo;
	
	BasementArea = Template.GetArea("BasementTableGoods");
	SpreadsheetDocument.Put(BasementArea);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#EndIf
