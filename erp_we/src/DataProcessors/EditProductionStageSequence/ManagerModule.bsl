
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region DataLock

Function BlockDocuments(Val DocumentsList, Val UUID, ErrorText = "") Export
	
	For Each Document In DocumentsList Do
		Try
			LockDataForEdit(Document.Ref, Document.DataVersion, UUID);
		Except
			BriefErrorDescription = BriefErrorDescription(ErrorInfo());
			ErrorText = NStr("vi = 'Không thể phong tỏa đối tượng %1, do nguyên nhân:
												|%2';
												|ru = 'Не удалось заблокировать объект %1, по причине:
												|%2';
												|en = 'Cannot lock the %1 object. Reason:
												|%2'; fa = 'Cannot lock the %1 object. Reason:
												|%2';
												|it = 'Non è stato possibile bloccare l''oggetto %1, a causa di:
												|%2';
												|pl = 'Nie udało się zablokować obiekt %1, z powodu:
												|%2';
												|tr = '%1 nesnesinin bloke edilememe nedeni:
												|%2'");
			ErrorText = StrTemplate(ErrorText, Document.Ref, BriefErrorDescription);
			Return False;
		EndTry;
	EndDo;
	Return True;
	
EndFunction

// Unlocks the documents.
//
// Parameters:
//  DocumentsList        - Array of Structure - Contains:
//                                       * Ref       - DocumentRef.ProductionStage2_2 - 
//                                       * DataVersion - String -
//  UUID - UUID -
//
Procedure UnlockDocuments(Val DocumentsList, Val UUID) Export
	
	For Each Document In DocumentsList Do
		UnlockDataForEdit(Document.Ref, UUID);
	EndDo;
	
EndProcedure

#EndRegion

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	Return "Stages,ProductionProcessType";
	
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
	
	#Region ManufacturedProducts
	ParametersForSpecifyingTSSeries = ProductsClientServer.SeriesSpecificationParameters();
	ParametersForSpecifyingTSSeries.FullObjectName = "DataProcessor.EditProductionStageSequence";
	
	ParametersForSpecifyingTSSeries.LinkFields.Add("Purpose");
	ParametersForSpecifyingTSSeries.LinkFields.Add("Recipient");
	ParametersForSpecifyingTSSeries.LinkFields.Add("Manufactured");
	ParametersForSpecifyingTSSeries.LinkFields.Add("ProductionDate");
	ParametersForSpecifyingTSSeries.LinkFields.Add("Canceled");
	ParametersForSpecifyingTSSeries.LinkFields.Add("Ref");
	ParametersForSpecifyingTSSeries.LinkFields.Add("Department");
	
	ParametersForSpecifyingTSSeries.WarehouseFieldName = "Recipient";
	ParametersForSpecifyingTSSeries.NameTSGoods = "ManufacturedProducts";
	ParametersForSpecifyingTSSeries.TSSeriesName = "BatchFinishedProducts";
	
	ParametersForSpecifyingTSSeries.UseCostAccountingByBatches =
		GetFunctionalOption("UseCostAccountingByBatchesWarehouse", New Structure())
		Or ProductionSettings.UseCostAccountingByBatches;
	
	ParametersForSpecifyingTSSeries.UseItemsBatch  =
		GetFunctionalOption("UseItemsBatchWarehouse", New Structure())
		Or ProductionSettings.UseItemsBatch;
	
	ParametersForSpecifyingTSSeries.SeriesWhenPlanningShipmentVHFSeriesAreIndicated = True;
	
	ParametersForSpecifyingTSSeries.WarehouseTransactions.Add(Enums.WarehouseTransactions.ProductReceivingFromManufacturing);
	
	ParametersForSpecifyingTSSeries.AdditionalFieldNames.Add("Manufactured");
	ParametersForSpecifyingTSSeries.AdditionalFieldNames.Add("Canceled");
	ParametersForSpecifyingTSSeries.AdditionalFieldNames.Add("ProductionByThirdParty");
	
	ParametersForSpecifyingTSSeries.NameOfValueSourceInObjectForm = "CurrentData";
	
	ParametersForSpecifyingTSSeries.ThisIsAnInvoice = True;
	
	ParametersForSpecifyingTSSeries.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	ParametersForSpecifyingTSSeries.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusSender");
	ParametersForSpecifyingTSSeries.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusRecipient");
	
	SeriesSpecificationParameters.Insert("ManufacturedProducts", ParametersForSpecifyingTSSeries);
	
	#EndRegion
	
	#Region SideAndIntermediateRelease
	ParametersForSpecifyingTSSeries = ProductsClientServer.SeriesSpecificationParameters();
	ParametersForSpecifyingTSSeries.FullObjectName = "DataProcessor.EditProductionStageSequence";
	
	ParametersForSpecifyingTSSeries.LinkFields.Add("Purpose");
	ParametersForSpecifyingTSSeries.LinkFields.Add("Recipient");
	ParametersForSpecifyingTSSeries.LinkFields.Add("Manufactured");
	ParametersForSpecifyingTSSeries.LinkFields.Add("ProductionDate");
	ParametersForSpecifyingTSSeries.LinkFields.Add("Canceled");
	ParametersForSpecifyingTSSeries.LinkFields.Add("Ref");
	ParametersForSpecifyingTSSeries.LinkFields.Add("Department");
	ParametersForSpecifyingTSSeries.LinkFields.Add("ProductOwner");
	
	ParametersForSpecifyingTSSeries.WarehouseFieldName = "Recipient";
	ParametersForSpecifyingTSSeries.NameTSGoods = "SideAndIntermediateRelease";
	ParametersForSpecifyingTSSeries.TSSeriesName = "BatchSideAndIntermediateRelease";
	
	ParametersForSpecifyingTSSeries.UseCostAccountingByBatches =
		GetFunctionalOption("UseCostAccountingByBatchesWarehouse", New Structure())
		Or ProductionSettings.UseCostAccountingByBatches;
	
	ParametersForSpecifyingTSSeries.UseItemsBatch  =
		GetFunctionalOption("UseItemsBatchWarehouse", New Structure())
		Or ProductionSettings.UseItemsBatch;
	
	ParametersForSpecifyingTSSeries.SeriesWhenPlanningShipmentVHFSeriesAreIndicated = True;
	
	ParametersForSpecifyingTSSeries.WarehouseTransactions.Add(Enums.WarehouseTransactions.ProductReceivingFromManufacturing);
	
	ParametersForSpecifyingTSSeries.AdditionalFieldNames.Add("Manufactured");
	ParametersForSpecifyingTSSeries.AdditionalFieldNames.Add("Canceled");
	ParametersForSpecifyingTSSeries.AdditionalFieldNames.Add("ProductionByThirdParty");
	ParametersForSpecifyingTSSeries.NameOfValueSourceInObjectForm = "CurrentData";
	
	ParametersForSpecifyingTSSeries.ThisIsAnInvoice = True;
	
	ParametersForSpecifyingTSSeries.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	ParametersForSpecifyingTSSeries.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusSender");
	ParametersForSpecifyingTSSeries.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusRecipient");
	
	SeriesSpecificationParameters.Insert("SideAndIntermediateRelease", ParametersForSpecifyingTSSeries);
	#EndRegion
	
	#Region MaterialsAndWorksConsumption
	ParametersForSpecifyingTSSeries = ProductsClientServer.SeriesSpecificationParameters();
	ParametersForSpecifyingTSSeries.FullObjectName = "DataProcessor.EditProductionStageSequence";
	
	ParametersForSpecifyingTSSeries.WarehouseFieldName = "Department";
	ParametersForSpecifyingTSSeries.NameTSGoods = "MaterialsAndWorksConsumption";
	ParametersForSpecifyingTSSeries.TSSeriesName  = "MaterialsAndWorksConsumption";
	
	ParametersForSpecifyingTSSeries.UseCostAccountingByBatches =
		ProductionSettings.UseCostAccountingByBatches;
	
	ParametersForSpecifyingTSSeries.UseItemsBatch =
		ProductionSettings.UseItemsBatch;
	
	ParametersForSpecifyingTSSeries.WarehouseTransactions.Add(Enums.WarehouseTransactions.ConsumptionDuringProduction);
	
	ParametersForSpecifyingTSSeries.NameOfValueSourceInObjectForm = "CurrentData";
	
	ParametersForSpecifyingTSSeries.ThisIsAnInvoice = True;
	ParametersForSpecifyingTSSeries.RegisterSeries = True;
	
	ParametersForSpecifyingTSSeries.ShipmentPlanning = False;
	ParametersForSpecifyingTSSeries.SelectionPlanning   = False;
	
	SeriesSpecificationParameters.Insert("MaterialsAndWorksConsumption", ParametersForSpecifyingTSSeries);
	#EndRegion
	
	#Region UnusedMaterials
	ParametersForSpecifyingTSSeries = ProductsClientServer.SeriesSpecificationParameters();
	ParametersForSpecifyingTSSeries.FullObjectName = "DataProcessor.EditProductionStageSequence";
	
	ParametersForSpecifyingTSSeries.LinkFields.Add("Recipient");
	ParametersForSpecifyingTSSeries.LinkFields.Add("DateOfTransaction");
	ParametersForSpecifyingTSSeries.LinkFields.Add("Purpose");
	ParametersForSpecifyingTSSeries.LinkFields.Add("Ref");
	ParametersForSpecifyingTSSeries.LinkFields.Add("Department");
	
	ParametersForSpecifyingTSSeries.NameTSGoods  = "UnusedMaterials";
	ParametersForSpecifyingTSSeries.TSSeriesName   = "SavingMaterialsBatch";
	ParametersForSpecifyingTSSeries.WarehouseFieldName = "Recipient";
	
	ParametersForSpecifyingTSSeries.UseCostAccountingByBatches =
		GetFunctionalOption("UseCostAccountingByBatchesWarehouse", New Structure())
		Or ProductionSettings.UseCostAccountingByBatches;
	
	ParametersForSpecifyingTSSeries.UseItemsBatch  =
		GetFunctionalOption("UseItemsBatchWarehouse", New Structure())
		Or ProductionSettings.UseItemsBatch;
	
	ParametersForSpecifyingTSSeries.WarehouseTransactions.Add(Enums.WarehouseTransactions.ReturnMaterialsFromProductionReceiving);
	
	ParametersForSpecifyingTSSeries.NameOfValueSourceInObjectForm = "CurrentData";
	
	ParametersForSpecifyingTSSeries.ThisIsAnInvoice = True;
	ParametersForSpecifyingTSSeries.RegisterSeries = True;
	
	ParametersForSpecifyingTSSeries.ShipmentPlanning = False;
	ParametersForSpecifyingTSSeries.SelectionPlanning   = False;
	
	ParametersForSpecifyingTSSeries.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	ParametersForSpecifyingTSSeries.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusSender");
	ParametersForSpecifyingTSSeries.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusRecipient");
	
	SeriesSpecificationParameters.Insert("UnusedMaterials", ParametersForSpecifyingTSSeries);
	#EndRegion

	#Region SupplyWithMaterialsAndWorks
	ParametersForSpecifyingTSSeries = ProductsClientServer.SeriesSpecificationParameters();
	
	ParametersForSpecifyingTSSeries.FullObjectName = "DataProcessor.EditProductionStageSequence";
	ParametersForSpecifyingTSSeries.NameTSGoods      = "SupplyWithMaterialsAndWorks";
	ParametersForSpecifyingTSSeries.TSSeriesName       = "SupplyWithMaterialsAndWorks";
	
	ParametersForSpecifyingTSSeries.UseCostAccountingByBatches =
		GetFunctionalOption("UseCostAccountingByBatchesWarehouse", New Structure())
		Or ProductionSettings.UseCostAccountingByBatches;
	
	ParametersForSpecifyingTSSeries.UseItemsBatch  =
		GetFunctionalOption("UseItemsBatchWarehouse", New Structure())
		Or ProductionSettings.UseItemsBatch;
	
	ParametersForSpecifyingTSSeries.WarehouseTransactions.Add(Enums.WarehouseTransactions.TransferToProductionShipment);
	
	If Object.Stages.FindRows(New Structure("ProductionByThirdParty", True)).Count() <> 0 Then
		ParametersForSpecifyingTSSeries.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentToCustomer);
	EndIf;
	
	ParametersForSpecifyingTSSeries.AdditionalFieldNames.Add("Warehouse");
	ParametersForSpecifyingTSSeries.AdditionalFieldNames.Add("Department");
	ParametersForSpecifyingTSSeries.AdditionalFieldNames.Add("ProductionByThirdParty");
	ParametersForSpecifyingTSSeries.AdditionalFieldNames.Add("Canceled");
	ParametersForSpecifyingTSSeries.AdditionalFieldNames.Add("UnderRepairBatch");
	ParametersForSpecifyingTSSeries.AdditionalFieldNames.Add("UnderRepairProduct");
	ParametersForSpecifyingTSSeries.AdditionalFieldNames.Add("UnderRepairBatchSpecificationStatus");
	ParametersForSpecifyingTSSeries.AdditionalFieldNames.Add("Status");
	
	ParametersForSpecifyingTSSeries.NameOfValueSourceInObjectForm = "CurrentData";
	
	ParametersForSpecifyingTSSeries.ThisIsOrder = True;
	ParametersForSpecifyingTSSeries.ShipmentPlanning = True;
	ParametersForSpecifyingTSSeries.RegisterSeries = False;
	
	ParametersForSpecifyingTSSeries.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	ParametersForSpecifyingTSSeries.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusSender");
	ParametersForSpecifyingTSSeries.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusRecipient");
	
	ParametersForSpecifyingTSSeries.MatchesSeriesFieldNameToStatusOfSeriesIndication.Insert("BatchesIndicationStatus",
																					"Series");
	
	If Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM Then
	
		ParametersForSpecifyingTSSeries.WarehouseTransactions.Add(Enums.WarehouseTransactions.ProductRM);
		
		ParametersForSpecifyingTSSeries.FieldNamesWithSuffix.Insert("Products",   "UnderRepairProduct");
		ParametersForSpecifyingTSSeries.FieldNamesWithSuffix.Insert("Characteristic", "UnderRepairVariant");
		ParametersForSpecifyingTSSeries.FieldNamesWithSuffix.Insert("Series",          "UnderRepairBatch");
		
		ParametersForSpecifyingTSSeries.FieldNamesStatusOfSeriesIndication.Add("UnderRepairBatchSpecificationStatus");
		ParametersForSpecifyingTSSeries.MatchesSeriesFieldNameToStatusOfSeriesIndication.Insert("UnderRepairBatchSpecificationStatus",
																						"UnderRepairBatch");
		
		ParametersForSpecifyingTSSeries.IndependentCalculationOfSeveralStatusesOfSeriesIndicationIsRequired = True;
		ParametersForSpecifyingTSSeries.SpecialCheckingOfSeriesIndicationStatuses = True; // See TextOfRequestToCheckSeriesFilling()
		
	EndIf;
	
	SeriesSpecificationParameters.Insert("SupplyWithMaterialsAndWorks", ParametersForSpecifyingTSSeries);
	#EndRegion
	
	#Region FinishedProductBeingRepaired
	
	ParametersForSpecifyingRIBatches = ProductsClientServer.SeriesSpecificationParameters();
	ParametersForSpecifyingRIBatches.FullObjectName = "DataProcessor.EditProductionStageSequence";
	ParametersForSpecifyingRIBatches.ProductInHeader = True;
	
	ParametersForSpecifyingRIBatches.UseItemsBatch = ProductionSettings.UseItemsBatch;
	
	ParametersForSpecifyingRIBatches.WarehouseFieldName = Undefined;
	ParametersForSpecifyingRIBatches.NameTSGoods = Undefined;
	ParametersForSpecifyingRIBatches.TSSeriesName = Undefined;

	ParametersForSpecifyingRIBatches.WarehouseTransactions.Add(Enums.WarehouseTransactions.ProductRM);

	ParametersForSpecifyingRIBatches.RegisterSeries = True; // the series registration form is always used (you can also choose from the leftovers in it)
	
	ParametersForSpecifyingRIBatches.FactOfSelection = False;
	
	SeriesSpecificationParameters.Insert("FinishedProductBeingRepaired", ParametersForSpecifyingRIBatches);
	
	#EndRegion
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	If SeriesSpecificationParameters.NameTSGoods = "ManufacturedProducts" 
		Or SeriesSpecificationParameters.NameTSGoods = "SideAndIntermediateRelease" Then
		QueryText = TextOfRequestToFillInStatusesForSpecifyingSerialNumberOfProduct();
	ElsIf SeriesSpecificationParameters.NameTSGoods = "SupplyWithMaterialsAndWorks" Then
		QueryText = TextOfRequestForFillingInStatusesForSpecifyingSeriesProvidingMaterialsAndWorks();
	ElsIf SeriesSpecificationParameters.NameTSGoods = "MaterialsAndWorksConsumption" Then
		QueryText = TextOfRequestForFillingInStatusesForSpecifyingSeriesOfMaterialsAndWorksConsumed();
	ElsIf SeriesSpecificationParameters.NameTSGoods = "UnusedMaterials" Then
		QueryText = TextOfRequestToFillInStatusesForSpecifyingSerialMaterials();
	ElsIf SeriesSpecificationParameters.ProductInHeader Then
		QueryText = QueryTextForFillingInStatusesIndicatingBatchesOfFinishedProductBeingRepaired();
	EndIf;
	
	Return QueryText;

EndFunction

// Returns the request text to check whether the series is filled in
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToCheckSeriesFilling(SeriesSpecificationParameters) Export
	
	QueryText =
	"SELECT
	|	TableOfSeries.LineNumber AS LineNumber,
	|	TableOfSeries.Products AS Products,
	|	TableOfSeries.Characteristic AS Characteristic,
	|	TableOfSeries.Count AS Count,
	|	TableOfSeries.Series AS Series,
	|	TableOfSeries.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfSeries.UnderRepairProduct AS UnderRepairProduct,
	|	TableOfSeries.UnderRepairVariant AS UnderRepairVariant,
	|	TableOfSeries.UnderRepairBatch AS UnderRepairBatch,
	|	TableOfSeries.UnderRepairBatchSpecificationStatus AS UnderRepairBatchSpecificationStatus
	|INTO SeriesPreparatoryTable
	|FROM
	|	&TableOfSeries_QueryNumber AS TableOfSeries
	|WHERE
	|	(TableOfSeries.BatchesIndicationStatus > 0
	|				AND NOT TableOfSeries.BatchesIndicationStatus IN (&SeriesStatusesYouCanSpecifySeries)
	|			OR TableOfSeries.UnderRepairBatchSpecificationStatus > 0
	|				AND NOT TableOfSeries.UnderRepairBatchSpecificationStatus IN (&SeriesStatusesYouCanSpecifySeries))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfSeries.LineNumber AS LineNumber,
	|	TableOfSeries.Products AS Products,
	|	TableOfSeries.Characteristic AS Characteristic,
	|	TableOfSeries.Series AS Series,
	|	""Series"" AS FieldNameSeries,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|	TableOfSeries.Count AS NumberOfPackages
	|INTO SeriesTableForQuery
	|FROM
	|	SeriesPreparatoryTable AS TableOfSeries
	|WHERE
	|	TableOfSeries.BatchesIndicationStatus > 0
	|	AND NOT TableOfSeries.BatchesIndicationStatus IN (&SeriesStatusesYouCanSpecifySeries)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfSeries.LineNumber,
	|	TableOfSeries.UnderRepairProduct,
	|	TableOfSeries.UnderRepairVariant,
	|	TableOfSeries.UnderRepairBatch,
	|	""UnderRepairBatch"",
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef),
	|	1
	|FROM
	|	SeriesPreparatoryTable AS TableOfSeries
	|WHERE
	|	TableOfSeries.UnderRepairBatchSpecificationStatus > 0
	|	AND NOT TableOfSeries.UnderRepairBatchSpecificationStatus IN (&SeriesStatusesYouCanSpecifySeries)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SeriesPreparatoryTable";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region QualityControl

// Document parameters for the Attribute filling mechanism to check the quality and data confirmation of the quality
// in the document.
// 
// Parameters:
//  Object - DataProcessorObject.EditProductionStageSequence - Object.
// 
// Returns:
//  Structure - structure with fields:
//   * FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   * Key - String - An identifier used when there are two or more data sources to fill in in the same object.
//
Function QualityControlActionParameters(Object) Export
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "");
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	
	ActionParameters.FullObjectName = "DataProcessor.EditProductionStageSequence";
	ActionParameters.ReadableFields = "Products,Recipient,ToExpenseAs,ProductionDate,Canceled,ProductionByThirdParty2_5,LeaveProductsAtSubcontractor,SubcontractOrder";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	
	ActionParameters.QueryOptions.Insert("QualityControlOneDateProduction", Object.ProductionInOneDay);
	ActionParameters.QueryOptions.Insert("QualityControlProductionDate",       Object.ProductionDate);
	
	ActionParameters.QueryTextDocumentData =
	"SELECT
	|	Table.IdOfTTRow AS IdOfTTRow,
	|	Table.Products AS Products,
	|	Table.Recipient AS Warehouse,
	|	ISNULL(OrderDetailsForProcessor.Contract, VALUE(Catalog.CounterpartyContracts.EmptyRef)) AS Contract,
	|	CASE
	|		WHEN &QualityControlOneDateProduction
	|			THEN &QualityControlProductionDate
	|		ELSE Table.ProductionDate
	|	END AS DateOfReceipt,
	|	FALSE AS Set,
	|	Table.Canceled
	|		OR Table.ToExpenseAs
	|		OR Table.LeaveProductsAtSubcontractor
	|		OR NOT Table.ProductionByThirdParty2_5 AS Reset
	|INTO DataOfDocumentToBeFilledInCheckQualityDateOfQualityConfirmation
	|FROM
	|	#DataSource AS Table
	|	
	|	LEFT JOIN Document.SubcontractOrder2_5 AS OrderDetailsForProcessor
	|	ON OrderDetailsForProcessor.Ref = Table.SubcontractOrder
	|
	|INDEX BY
	|	Products,
	|	Warehouse,
	|	Contract
	|";
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	Return Action_Parameters;
	
EndFunction

#EndRegion

#Region Other

// Returns parameters for selecting specifications for the items specified in the document.
//
// Parameters:
//   Object - Structure - the structure of the values of the details object required to populate the parameters of the choice specs.
//
// Returns:
//   Structure - A structure that overrides the defaults set in the management function of the Client Server's data items.Parameterselectionspecifications().
//
Function BOMSelectionParameters(Object) Export
	
	BOMSelectionParameters = New Structure;
	
	Attributes    = "DataPath, ChangeMode";
	ClearingMode = LinkedValueChangeMode.Clear;
	
	ProductionStart = ?(Object.DynamicStructure, Undefined, "Object.EarliestStartDate");
	
#Region ManufacturedProducts

	TSSpecificationSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	
	TSSpecificationSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.Disassembly);
	TSSpecificationSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
	
	ChoiceParameterLinks = New Structure(ProductDataManagementClientServer.ProductDataStructureFieldsForSelectingSpecifications());
	
	ChoiceParameterLinks.Products            = New Structure(Attributes, "Object.ManufacturedProducts.Products",   ClearingMode);
	ChoiceParameterLinks.Characteristic          = New Structure(Attributes, "Object.ManufacturedProducts.Characteristic", ClearingMode);
	ChoiceParameterLinks.ProductionStart      = ProductionStart;
	ChoiceParameterLinks.ProductionDispatcherBusinessUnit  = "Object.Department";
	ChoiceParameterLinks.LineOfBusiness = "Object.LineOfBusiness";
	
	TSSpecificationSelectionParameters.ChoiceParameterLinks.Insert("Object.ManufacturedProducts.BillOfMaterials", ChoiceParameterLinks);
	
	ChoiceParameterLinks = New Structure(ProductDataManagementClientServer.ProductDataStructureFieldsForSelectingSpecifications());
	
	ChoiceParameterLinks.Products            = New Structure(Attributes, "Object.SideAndIntermediateRelease.Products",   ClearingMode);
	ChoiceParameterLinks.Characteristic          = New Structure(Attributes, "Object.SideAndIntermediateRelease.Characteristic", ClearingMode);
	ChoiceParameterLinks.ProductionStart      = ProductionStart;
	ChoiceParameterLinks.ProductionDispatcherBusinessUnit  = "Object.Department";
	ChoiceParameterLinks.LineOfBusiness = "Object.LineOfBusiness";
	
	TSSpecificationSelectionParameters.ChoiceParameterLinks.Insert("Object.SideAndIntermediateRelease.BillOfMaterials", ChoiceParameterLinks);
	
	BOMSelectionParameters.Insert("ManufacturedProducts", TSSpecificationSelectionParameters);
	
#EndRegion
	
#Region SupplyWithMaterialsAndWorks

	TSSpecificationSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	
	If Object.ProductionProcessType = Enums.ProductionProcessTypes.Repair Then
		TSSpecificationSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.Assembly);
		TSSpecificationSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.Repair);
	ElsIf Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM Then
		TSSpecificationSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.Assembly);
	Else
		TSSpecificationSelectionParameters.AvailableTypes.Add(Object.ProductionProcessType);
	EndIf;
	
	TSSpecificationSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
	
	ChoiceParameterLinks = New Structure(ProductDataManagementClientServer.ProductDataStructureFieldsForSelectingSpecifications());
	
	ChoiceParameterLinks.Products            = New Structure(Attributes, "Object.SupplyWithMaterialsAndWorks.Products", ClearingMode);
	ChoiceParameterLinks.Characteristic          = "Object.SupplyWithMaterialsAndWorks.Characteristic";
	ChoiceParameterLinks.ProductionStart      = ProductionStart;
	ChoiceParameterLinks.ProductionDispatcherBusinessUnit  = "Object.Department";
	ChoiceParameterLinks.LineOfBusiness = "Object.LineOfBusiness";
	ChoiceParameterLinks.UnderRepairProduct   = "Object.SupplyWithMaterialsAndWorks.UnderRepairProduct";
	ChoiceParameterLinks.UnderRepairVariant = "Object.SupplyWithMaterialsAndWorks.UnderRepairVariant";
	
	TSSpecificationSelectionParameters.ChoiceParameterLinks.Insert("Object.SupplyWithMaterialsAndWorks.BillOfMaterials", ChoiceParameterLinks);
	TSSpecificationSelectionParameters.ChoiceParameterLinks.Insert("Items.SupplyWithMaterialsAndWorks.CurrentData.BillOfMaterials", ChoiceParameterLinks);
	
	BOMSelectionParameters.Insert("SupplyWithMaterialsAndWorks", TSSpecificationSelectionParameters);
	
	If Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM Then
		
		TSSpecificationSelectionParameters = Common.CopyRecursive(TSSpecificationSelectionParameters);
		
		TSSpecificationSelectionParameters.AvailableTypes.Clear();
		TSSpecificationSelectionParameters.AvailableTypes.Add(Object.ProductionProcessType);
		
		BOMSelectionParameters.Insert("SupplyOfMaterialsAndWorks_WorkPlanning", TSSpecificationSelectionParameters);
		
	EndIf;
	
#EndRegion
	
	Return BOMSelectionParameters;

EndFunction

// The names of the details, the values of which depend on the selection parameters spec
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSelectingSpecifications() Export
	
	AttributesNames = "ProductionProcessType,DynamicStructure";
	Return AttributesNames;
	
EndFunction

// Returns the parameters of the distribution of the costs of the output product.
//
// Parameters:
//  MethodOfAllocatingFinishedProductCosts	 - EnumRef.MethodsOfCostAllocatingOnProductCosts - method for allocating costs for output items.
// 
// Returns:
//  Structure - parameters specifying the specifics of the distribution of costs for output products.
//
Function CostAllocationParameters(MethodOfAllocatingFinishedProductCosts) Export
	
	CostAllocationParameters = ProductionClientServer.CostAllocationParametersForOutputProducts(
		"ManufacturedProducts",
		MethodOfAllocatingFinishedProductCosts);
	
	CostAllocationParameters.ThereIsFieldCanceled = True;
	
	CostAllocationParameters.CalculateShareCostPercentageField = True;
	CostAllocationParameters.ThisFlagIndicatesThatThereAreFillInErrors = True;
	CostAllocationParameters.CalculateShareOfCostAttributeRequired = True;
	
	CostAllocationParameters.LinkFields = "Products,Characteristic,Ref";

	Return CostAllocationParameters;
	
EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
// 
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	#Region SupplyWithMaterialsAndWorks
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "Object.SupplyWithMaterialsAndWorks.SupplyAssignment");
	DestinationPattern.TermsOfUse_     = "Object.BusinessOperation = VALUE(Enum.BusinessTransactions.OwnProduction)";
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	If Not Users.RolesAvailable("SelectArbitraryAssignmentsInProductionStage") Then
		DestinationPattern.Ref = "&RefsFilterInSelectionOfAssignmentsForm";
	EndIf;
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Own);
	
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "Object.SupplyWithMaterialsAndWorks.SupplyAssignment");
	DestinationPattern.TermsOfUse_     = "Object.BusinessOperation = VALUE(Enum.BusinessTransactions.TollManufacturing2_5)";
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.Partner                  = "Object.Partner";
	DestinationPattern.Contract                  = "Object.Contract";
	If Not Users.RolesAvailable("SelectArbitraryAssignmentsInProductionStage") Then
		DestinationPattern.Ref = "&RefsFilterInSelectionOfAssignmentsForm";
	EndIf;
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Giveaway2_5);
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.ProvidedMaterialsForStage22);
	
	// The remnants of the goods
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.SupplyWithMaterialsAndWorks.SupplyAssignment");
	DescriptionOfColumns.Columns.FindByValue("InStock").Check = True;
	DescriptionOfColumns.Columns.FindByValue("AvailableForReservation").Check = True;
	
	DescriptionOfColumns.DataPaths.Products     = "Object.SupplyWithMaterialsAndWorks.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.SupplyWithMaterialsAndWorks.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.SupplyWithMaterialsAndWorks.Warehouse";
	DescriptionOfColumns.DataPaths.Recorder      = "Object.SupplyWithMaterialsAndWorks.Ref";
	
	#EndRegion
	
	// template for output items at the calculated cost
	#Region ManufacturedProducts
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "Object.ManufacturedProducts.Purpose");
	DestinationPattern.TermsOfUse_     = "Object.BusinessOperation = VALUE(Enum.BusinessTransactions.OwnProduction)";
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Own);
	DestinationPattern.VisibleSelectionsOnForm.Insert("LineOfBusiness", NStr("vi = 'Chỉ đến ""%1""';
																			|ru = 'Только назначения направления деятельности ""%1""';
																			|en = 'The ""%1"" line of business assignments only'; fa = 'The ""%1"" line of business assignments only';
																			|it = 'Solo assegnazioni del settore di attività ""%1""';
																			|pl = 'Tylko przeznaczenia rodzaju działalności ""%1""';
																			|tr = 'Sadece ""%1"" iş kolunun atamaları'"));
	
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "Object.ManufacturedProducts.Purpose");
	DestinationPattern.TermsOfUse_     = "Object.BusinessOperation = VALUE(Enum.BusinessTransactions.TollManufacturing2_5)";
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.Partner                  = "Object.Partner";
	DestinationPattern.Contract                  = "Object.Contract";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Giveaway2_5);
	DestinationPattern.VisibleSelectionsOnForm.Insert("LineOfBusiness", NStr("vi = 'Chỉ đến ""%1""';
																			|ru = 'Только назначения направления деятельности ""%1""';
																			|en = 'The ""%1"" line of business assignments only'; fa = 'The ""%1"" line of business assignments only';
																			|it = 'Solo assegnazioni del settore di attività ""%1""';
																			|pl = 'Tylko przeznaczenia rodzaju działalności ""%1""';
																			|tr = 'Sadece ""%1"" iş kolunun atamaları'"));
	
	// The needs for manufactured products in the warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.ManufacturedProducts.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.ManufacturedProducts.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.ManufacturedProducts.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.ManufacturedProducts.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.ManufacturedProducts.Recipient";
	DescriptionOfColumns.DataPaths.Recorder      = "Object.ManufacturedProducts.Ref";
	DescriptionOfColumns.DataPaths.ReferenceOrder     = "Object.ReferenceOrder";
	
	// The needs for the work performed in the recipient unit.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "FulfillOrdersWithWorks", True, "Object.ManufacturedProducts.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.ManufacturedProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.ManufacturedProducts.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.ManufacturedProducts.Characteristic";
	DescriptionOfColumns.DataPaths.Department    = "Object.ManufacturedProducts.Recipient";
	DescriptionOfColumns.DataPaths.Recorder      = "Object.ManufacturedProducts.Ref";
	DescriptionOfColumns.DataPaths.ReferenceOrder     = "Object.ReferenceOrder";
	
	// Product needs in all warehouses.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "SecuringOrdersAllWarehouses", True, "Object.ManufacturedProducts.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.ManufacturedProducts.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.ManufacturedProducts.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.ManufacturedProducts.Characteristic";
	DescriptionOfColumns.DataPaths.Recorder      = "Object.ManufacturedProducts.Ref";
	DescriptionOfColumns.DataPaths.ReferenceOrder     = "Object.ReferenceOrder";
	
	#EndRegion
	
	// template for by-products at a fixed cost
	#Region SideAndIntermediateRelease
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "Object.SideAndIntermediateRelease.Purpose");
	DestinationPattern.TermsOfUse_     = "Object.BusinessOperation = VALUE(Enum.BusinessTransactions.OwnProduction)";
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.VisibleSelectionsOnForm.Insert("LineOfBusiness", NStr("vi = 'Chỉ đến ""%1""';
																			|ru = 'Только назначения направления деятельности ""%1""';
																			|en = 'The ""%1"" line of business assignments only'; fa = 'The ""%1"" line of business assignments only';
																			|it = 'Solo assegnazioni del settore di attività ""%1""';
																			|pl = 'Tylko przeznaczenia rodzaju działalności ""%1""';
																			|tr = 'Sadece ""%1"" iş kolunun atamaları'"));
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "Object.SideAndIntermediateRelease.Purpose");
	DestinationPattern.TermsOfUse_     = "Object.BusinessOperation IN (
												|				VALUE(Enum.BusinessTransactions.TollManufacturing2_5))";
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.VisibleSelectionsOnForm.Insert("LineOfBusiness", NStr("vi = 'Chỉ đến ""%1""';
																			|ru = 'Только назначения направления деятельности ""%1""';
																			|en = 'The ""%1"" line of business assignments only'; fa = 'The ""%1"" line of business assignments only';
																			|it = 'Solo assegnazioni del settore di attività ""%1""';
																			|pl = 'Tylko przeznaczenia rodzaju działalności ""%1""';
																			|tr = 'Sadece ""%1"" iş kolunun atamaları'"));
	
	// The needs for manufactured products in the warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.SideAndIntermediateRelease.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.SideAndIntermediateRelease.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.SideAndIntermediateRelease.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.SideAndIntermediateRelease.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.SideAndIntermediateRelease.Recipient";
	DescriptionOfColumns.DataPaths.Recorder      = "Object.SideAndIntermediateRelease.Ref";
	DescriptionOfColumns.DataPaths.ReferenceOrder     = "Object.ReferenceOrder";
	
	// The needs for the work performed in the recipient unit.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "FulfillOrdersWithWorks", True, "Object.SideAndIntermediateRelease.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.SideAndIntermediateRelease.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.SideAndIntermediateRelease.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.SideAndIntermediateRelease.Characteristic";
	DescriptionOfColumns.DataPaths.Department    = "Object.SideAndIntermediateRelease.Recipient";
	DescriptionOfColumns.DataPaths.Recorder      = "Object.SideAndIntermediateRelease.Ref";
	DescriptionOfColumns.DataPaths.ReferenceOrder     = "Object.ReferenceOrder";
	
	// Product needs in all warehouses.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "SecuringOrdersAllWarehouses", True, "Object.SideAndIntermediateRelease.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.SideAndIntermediateRelease.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.SideAndIntermediateRelease.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.SideAndIntermediateRelease.Characteristic";
	DescriptionOfColumns.DataPaths.Recorder      = "Object.SideAndIntermediateRelease.Ref";
	DescriptionOfColumns.DataPaths.ReferenceOrder     = "Object.ReferenceOrder";
	
	#EndRegion
	
	#Region UnusedMaterials
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "Object.UnusedMaterials.Purpose");
	DestinationPattern.TermsOfUse_     = "Object.BusinessOperation = VALUE(Enum.BusinessTransactions.OwnProduction)";
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Own);
	
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "Object.UnusedMaterials.Purpose");
	DestinationPattern.TermsOfUse_     = "Object.BusinessOperation = VALUE(Enum.BusinessTransactions.TollManufacturing2_5)";
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.Partner                  = "Object.Partner";
	DestinationPattern.Contract                  = "Object.Contract";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.ProvidedMaterialsForStage22);
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Giveaway2_5);
	
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "AllAssignments", False, "Object.UnusedMaterials.Purpose");
	
	#EndRegion
	
	Return FormTemplate;
	
EndFunction

// Forms the structure of the document parameters for embedding the document in the software algorithms.
//
// Returns:
//  See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions
//
Function AvailableRemainingEmbeddingOptions() Export
	
	EmbeddingParameters = ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions();
	EmbeddingParameters.AttributesToBeCleared = "RowCode";
	
	// Updating the "Available" column.
	EmbeddingParameters.FormTableName = "SupplyWithMaterialsAndWorks";
	
	// Conditional registration.
	FormItems = EmbeddingParameters.ConditionalAppearance.FormItems;
	FormItems.SupplyOption = "SupplyWithMaterialsAndWorksSupplyOption";
	FormItems.Available           = "SupplyWithMaterialsAndWorksAvailable";
	FormItems.Series              = "SupplyWithMaterialsAndWorksSeries";
	FormItems.WithAssignment        = "SupplyWithMaterialsAndWorksWithAssignment";
	FormItems.Warehouse              = "SupplyWithMaterialsAndWorksWarehouse";
	
	DataPaths = EmbeddingParameters.ConditionalAppearance.DataPaths;
	DataPaths.ReallocateInventory = "Object.SupplyWithMaterialsAndWorks.ReallocateInventory";
	DataPaths.NoEditingAllowed = "Object.SupplyWithMaterialsAndWorks.Canceled";
	DataPaths.ItemsType = "Object.SupplyWithMaterialsAndWorks.ItemsType";
	
	// The choice of the security option.
	Links = EmbeddingParameters.ConnectionsOfSoftwareOptionSelectionParameters;
	Links.Available              = "Items.SupplyWithMaterialsAndWorks.CurrentData.Available";
	Links.NumberOfPackages    = "Items.SupplyWithMaterialsAndWorks.CurrentData.NumberOfPackages";
	Links.Count            = "Items.SupplyWithMaterialsAndWorks.CurrentData.Count";
	Links.ShipIfAvailable = "Items.SupplyWithMaterialsAndWorks.CurrentData.ShipIfAvailable";
	Links.WithAssignment           = "Items.SupplyWithMaterialsAndWorks.CurrentData.WithAssignment";
	Links.ItemsType       = "Items.SupplyWithMaterialsAndWorks.CurrentData.ItemsType";
	Links.Package              = "Items.SupplyWithMaterialsAndWorks.CurrentData.Package";
	Links.Products          = "Items.SupplyWithMaterialsAndWorks.CurrentData.Products";
	Links.SupplyOption    = "Items.SupplyWithMaterialsAndWorks.CurrentData.SupplyOption";
	Links.Warehouse                 = "Items.SupplyWithMaterialsAndWorks.CurrentData.Warehouse";
	Links.MultipleWarehouses      = True;
	
	// The name of the shipment registration register.
	EmbeddingParameters.NameOfShipmentRegistrationRegister = "OrdersOfMaterialsForProduction";
	
	// Temporary document data table.
	EmbeddingParameters.ObjectName = "Form";
	EmbeddingParameters.TableName = "Form.Object.SupplyWithMaterialsAndWorks";
	
	EmbeddingParameters.DescriptionOfGettingDocumentData =
		"SELECT
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Department AS Department,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	ISNULL(Attributes.Ref, UNDEFINED) AS ShipmentOrder,
		|	TabPart.SupplyOption AS SupplyOption,
		|	TabPart.WithAssignment AS WithAssignment,
		|	TabPart.Count AS Count,
		|	TabPart.NumberOfPackages AS NumberOfPackages,
		|	TabPart.Package AS Package,
		|	Attributes.Status <> VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated) AS ReadyForSupply,
		|	Attributes.Status <> VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated) AS ReadyToShip,
		|	CASE WHEN Attributes.NotShipInInstallments THEN
		|				Attributes.DateOfShipment
		|			ELSE
		|				TabPart.DateOfShipment
		|		END AS RequestShipmentOn,
		|	TabPart.Series AS Series,
		|	TabPart.Canceled AS Canceled,
		|	TabPart.RowCode AS RowCode,
		|	TabPart.LineNumber AS LineNumber,
		|	Attributes.Ref AS Recorder,
		|	Attributes.Date AS DocumentDate,
		|	UNDEFINED AS GroupOfWarehouses,
		|	Attributes.Ref.ReferenceOrder.Priority AS Priority,
		|	CASE WHEN Attributes.NotShipInInstallments THEN
		|				Attributes.DateOfShipment
		|			ELSE
		|				UNDEFINED
		|		END AS TheShipmentDateOfAllLinesIsASingleDate
		|INTO TemporaryDocumentDataTable
		|FROM
		|	Form.Object.SupplyWithMaterialsAndWorks AS TabPart
		|		
		|		LEFT JOIN Form.Object.Stages AS Attributes
		|		ON Attributes.Ref = TabPart.Ref";
	
	// Template for serialization of form data.
	SupplyWithMaterialsAndWorks = New Structure();
	SupplyWithMaterialsAndWorks.Insert("LineNumber",           New TypeDescription("Number"));
	SupplyWithMaterialsAndWorks.Insert("Products",          New TypeDescription("CatalogRef.Products"));
	SupplyWithMaterialsAndWorks.Insert("Characteristic",        New TypeDescription("CatalogRef.ItemsCharacteristics"));
	SupplyWithMaterialsAndWorks.Insert("Warehouse",                 New TypeDescription("CatalogRef.Warehouses"));
	SupplyWithMaterialsAndWorks.Insert("Department",         New TypeDescription("CatalogRef.BusinessStructure"));
	SupplyWithMaterialsAndWorks.Insert("Purpose",            New TypeDescription("CatalogRef.Assignments"));
	SupplyWithMaterialsAndWorks.Insert("SupplyOption",    New TypeDescription("EnumRef.SupplyOptions"));
	SupplyWithMaterialsAndWorks.Insert("WithAssignment",           New TypeDescription("Boolean"));
	SupplyWithMaterialsAndWorks.Insert("Produced",          New TypeDescription("Boolean"));
	SupplyWithMaterialsAndWorks.Insert("Count",            New TypeDescription("Number"));
	SupplyWithMaterialsAndWorks.Insert("NumberOfPackages",    New TypeDescription("Number"));
	SupplyWithMaterialsAndWorks.Insert("Package",              New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	SupplyWithMaterialsAndWorks.Insert("DateOfShipment",          New TypeDescription("Date"));
	SupplyWithMaterialsAndWorks.Insert("Series",                 New TypeDescription("CatalogRef.ItemsBatches"));
	SupplyWithMaterialsAndWorks.Insert("RowCode",             New TypeDescription("Number"));
	SupplyWithMaterialsAndWorks.Insert("Ref",                New TypeDescription("DocumentRef.ProductionStage2_2"));
	SupplyWithMaterialsAndWorks.Insert("Canceled",              New TypeDescription("Boolean"));
	
	Stages = New Structure();
	Stages.Insert("Ref",                  New TypeDescription("DocumentRef.ProductionStage2_2"));
	Stages.Insert("Status",                  New TypeDescription("EnumRef.StatusesOfProductionStages2_2"));
	Stages.Insert("NotShipInInstallments",      New TypeDescription("Boolean"));
	Stages.Insert("DateOfShipment",            New TypeDescription("Date"));
	Stages.Insert("Date",                    New TypeDescription("Date"));
	Stages.Insert(
		"SubcontractOrder",
		New TypeDescription("DocumentRef.SubcontractOrder2_5"));
	
	Object = New Structure();
	Object.Insert("SupplyWithMaterialsAndWorks", SupplyWithMaterialsAndWorks);
	Object.Insert("Stages",                           Stages);
	
	EmbeddingParameters.FormDataSerializationPattern.Insert("Object", Object);
	EmbeddingParameters.RelationshipFieldsOfTableParts.Insert("Stages", New Structure("Ref", "Ref"));
	
	Return EmbeddingParameters;
	
EndFunction

// Returns parameters for selecting articles in the document.
// 
// Returns:
//  Array, Structure - See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters(Object) Export
	
	ItemsAndDimensionsSelectionParameters = New Array;
	
#Region ManufacturedProducts
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.DataPath         = "Object.ManufacturedProducts";
	ChoiceParameters.AssetRef              = "ExpenseItem";
	ChoiceParameters.ArticleType           = "ArticleType";
	ChoiceParameters.DefaultValue = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
	
	ChoiceParameters.AvailabilityByOperation =
		Not Object.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
		And True;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses   = "DimensionOfExpenses";
	ProductionManagement.CompleteSelectionOfExpenditureItems(ChoiceParameters.SelectionOfExpenditureItems);
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension   = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("ManufacturedProductsExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ManufacturedProductsDimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("ManufacturedProductsAssetsLiabilitiesDimension");
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("ToExpenseAs", True);
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("Canceled", False);
	
	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	
#EndRegion
	
#Region SideAndIntermediateRelease
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.DataPath         = "Object.SideAndIntermediateRelease";
	ChoiceParameters.AssetRef              = "ExpenseItem";
	ChoiceParameters.ArticleType           = "ArticleType";
	ChoiceParameters.DefaultValue = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
	
	ChoiceParameters.AvailabilityByOperation =
		Not Object.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
		And True;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses   = "DimensionOfExpenses";
	ProductionManagement.CompleteSelectionOfExpenditureItems(ChoiceParameters.SelectionOfExpenditureItems);
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension   = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("SideAndIntermediateReleaseExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("SideAndIntermediateReleaseDimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("SideAndIntermediateReleaseAssetsLiabilitiesDimension");
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("ToExpenseAs", True);
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("Canceled", False);
	
	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	
#EndRegion
	
#Region UnusedMaterials
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.DataPath         = "Object.UnusedMaterials";
	ChoiceParameters.AssetRef              = "ExpenseItem";
	ChoiceParameters.ArticleType           = "ArticleType";
	ChoiceParameters.DefaultValue = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
	
	ChoiceParameters.AvailabilityByOperation =
		Not Object.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
		And True;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses   = "DimensionOfExpenses";
	ProductionManagement.CompleteSelectionOfExpenditureItems(ChoiceParameters.SelectionOfExpenditureItems);
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension   = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("UnusedMaterialsExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("UnusedMaterialsDimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("UnusedMaterialsAssetsLiabilitiesDimension");
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("ToExpenseAs", True);
	
	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	
#EndRegion
	
	Return ItemsAndDimensionsSelectionParameters;
	
EndFunction

// Returns parameters for setting up accounting accounts in the document.
//  
// Returns:
//  Array - Accounting account settings (See GLAccountSettingsServer.SetupParameters)
//           .
//
Function AccountingAccountSettings_() Export
	
	SettingsParameters = New Array;
	
#Region ManufacturedProducts

	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.AvailabilityByOperation	= True;
	SetupParameters.DataPath				= "Object.ManufacturedProducts";
	SetupParameters.ArticleType				= "ArticleType";
	
	SetupParameters.FormItems.Add("ManufacturedProductsTransactionRecordingPresentation");
	
	SettingsParameters.Add(SetupParameters);
	
#EndRegion
	
#Region SideAndIntermediateRelease

	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.AvailabilityByOperation	= True;
	SetupParameters.DataPath				= "Object.SideAndIntermediateRelease";
	SetupParameters.ArticleType				= "ArticleType";
	
	SetupParameters.FormItems.Add("SideAndIntermediateReleaseTransactionRecordingPresentation");
	
	SettingsParameters.Add(SetupParameters);
	
#EndRegion
	
#Region UnusedMaterials

	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.AvailabilityByOperation	= True;
	SetupParameters.DataPath				= "Object.UnusedMaterials";
	SetupParameters.ArticleType				= "ArticleType";
	
	SetupParameters.FormItems.Add("UnusedMaterialsTransactionRecordingPresentation");
	
	SettingsParameters.Add(SetupParameters);
	
#EndRegion
	
	Return SettingsParameters;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region FillType

// Fills in an expense based on security data
//
// Parameters:
//  Object - FormDataStructure -
//  StageList - Undefined, Array - 
//  Mode - See Documents.ProductionStage2_2.FillInConsumptionOfMaterialsAndWorksAccordingToProvisionData.Mode
//
Procedure FillInConsumptionOfMaterialsAndWorksAccordingToProvisionData(Object, StageList = Undefined, Mode = 0) Export
	
	DateOfTransaction = BegOfDay(CurrentSessionDate());
	TempTablesManager = New TempTablesManager;
	
	Query = New Query(
	"SELECT
	|	TabularSection.Ref              AS Ref,
	|	TabularSection.DateOfShipment        AS DateOfTransaction,
	|	TabularSection.Department       AS Department,
	|	TabularSection.LineNumber         AS LineNumber,
	|	TabularSection.Products        AS Products,
	|	TabularSection.Characteristic      AS Characteristic,
	|	TabularSection.Warehouse               AS Warehouse,
	|	TabularSection.Series               AS Series,
	|	TabularSection.ProductCostElement   AS ProductCostElement,
	|	TabularSection.Package            AS Package,
	|	TabularSection.Count          AS Count,
	|	TabularSection.NumberOfPackages  AS NumberOfPackages
	|INTO Supply
	|FROM
	|	&SupplyWithMaterialsAndWorks AS TabularSection
	|WHERE
	|	TabularSection.Products <> VALUE(Catalog.Products.EmptyRef)
	|	AND TabularSection.Count <> 0
	|	AND TabularSection.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND (NOT &ThereIsSelectionByStages OR TabularSection.Ref IN (&StageList))
	|	AND NOT TabularSection.Canceled
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.Ref              AS Ref,
	|	TabularSection.Department       AS Department,
	|	TabularSection.LineNumber         AS LineNumber,
	|	TabularSection.RowID AS RowID,
	|	TabularSection.Products        AS Products,
	|	TabularSection.Characteristic      AS Characteristic,
	|	TabularSection.Series               AS Series,
	|	TabularSection.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TabularSection.ProductCostElement   AS ProductCostElement,
	|	TabularSection.Package            AS Package,
	|	TabularSection.DateOfMaterialWorkConsumption         AS DateOfMaterialWorkConsumption,
	|	TabularSection.Count          AS Count,
	|	TabularSection.NumberOfPackages  AS NumberOfPackages
	|INTO ConsumptionFilledSeries
	|FROM
	|	&MaterialsAndWorksConsumption AS TabularSection
	|WHERE
	|	TabularSection.Products <> VALUE(Catalog.Products.EmptyRef)
	|	AND TabularSection.Count <> 0
	|	AND (NOT &ThereIsSelectionByStages OR TabularSection.Ref IN (&StageList))
	// We select only correctly filled series
	|	AND TabularSection.BatchesIndicationStatus IN (0, 2, 14)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.Ref         AS Ref,
	|	TabularSection.DateOfTransaction   AS DateOfTransaction,
	|	TabularSection.Department  AS Department,
	|	TabularSection.Products   AS Products,
	|	TabularSection.Characteristic AS Characteristic,
	|	TabularSection.Series          AS Series,
	|	TabularSection.Count     AS Count
	|INTO Savings
	|FROM
	|	&UnusedMaterials AS TabularSection
	|WHERE
	|	TabularSection.Products <> VALUE(Catalog.Products.EmptyRef)
	|	AND TabularSection.Count <> 0
	|	AND (NOT &ThereIsSelectionByStages OR TabularSection.Ref IN (&StageList))
	|");
	Query.SetParameter("ThereIsSelectionByStages"               , StageList <> Undefined);
	Query.SetParameter("StageList"                    , StageList);
	Query.SetParameter("SupplyWithMaterialsAndWorks" , Object.SupplyWithMaterialsAndWorks.Unload());
	Query.SetParameter("MaterialsAndWorksConsumption"          , 
		Object.MaterialsAndWorksConsumption.Unload(?(Mode = 0, New Array, Undefined)));
	Query.SetParameter("UnusedMaterials"              , Object.UnusedMaterials.Unload());
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
	SeriesSpecificationParameters = SeriesSpecificationParameters(Object).MaterialsAndWorksConsumption;
	
	Result = Documents.ProductionStage2_2.CalculateMaterialConsumption(TempTablesManager, DateOfTransaction, Mode = 2);
	
	Object.MaterialsAndWorksConsumption.Load(Result);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	ProductsServer.ClearUnusedSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

Procedure FillInUnspentMaterials(Object, StageList = Undefined) Export
	
	DateOfTransaction = BegOfDay(CurrentSessionDate());
	TempTablesManager = New TempTablesManager;
	
	Query = New Query(
	"SELECT
	|	TabularSection.Ref              AS Ref,
	|	TabularSection.Department       AS Department,
	|	TabularSection.LineNumber         AS LineNumber,
	|	TabularSection.Products        AS Products,
	|	TabularSection.Characteristic      AS Characteristic,
	|	TabularSection.Warehouse               AS Warehouse,
	|	TabularSection.Series               AS Series,
	|	TabularSection.SupplyOption  AS SupplyOption,
	|	TabularSection.Purpose          AS Purpose,
	|	TabularSection.ProductCostElement   AS ProductCostElement,
	|	TabularSection.Package            AS Package,
	|	TabularSection.Count          AS Count,
	|	TabularSection.NumberOfPackages  AS NumberOfPackages,
	|	TabularSection.Canceled            AS Canceled
	|	
	|INTO Supply
	|FROM
	|	&SupplyWithMaterialsAndWorks AS TabularSection
	|WHERE
	|	(NOT &ThereIsSelectionByStages OR TabularSection.Ref IN (&StageList))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.Ref         AS Ref,
	|	TabularSection.Department  AS Department,
	|	TabularSection.LineNumber    AS LineNumber,
	|	TabularSection.Products   AS Products,
	|	TabularSection.Characteristic AS Characteristic,
	|	TabularSection.Count     AS Count
	|	
	|INTO Expense
	|FROM
	|	&MaterialsAndWorksConsumption AS TabularSection
	|WHERE
	|	(NOT &ThereIsSelectionByStages OR TabularSection.Ref IN (&StageList))
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	*
	|INTO UnusedMaterials
	|FROM
	|	&UnusedMaterials AS TabularSection
	|");
	Query.SetParameter("ThereIsSelectionByStages", StageList <> Undefined);
	Query.SetParameter("StageList", StageList);
	Query.SetParameter("SupplyWithMaterialsAndWorks", Object.SupplyWithMaterialsAndWorks.Unload());
	Query.SetParameter("MaterialsAndWorksConsumption", Object.MaterialsAndWorksConsumption.Unload());
	Query.SetParameter("UnusedMaterials", Object.UnusedMaterials.Unload());
	
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
	Result = Documents.ProductionStage2_2.CalculateMaterialSavings(TempTablesManager, DateOfTransaction);
	Object.UnusedMaterials.Load(Result);
	
EndProcedure

#EndRegion

#Region SetOfSeries

Function TextOfRequestToFillInStatusesForSpecifyingSerialNumberOfProduct()
	
	QueryText = 
	"SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose AS Purpose,
	|	Goods.Series AS Series,
	|	Goods.Recipient AS Recipient,
	|	Goods.Manufactured AS Manufactured,
	|	Goods.ProductionDate AS ProductionDate,
	|	Goods.Count AS Count,
	|	Goods.Canceled AS Canceled,
	|	Goods.Department AS Department,
	|	Goods.ProductionByThirdParty AS ProductionByThirdParty,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.BatchesIndicationStatusSender AS BatchesIndicationStatusSender,
	|	Goods.BatchesIndicationStatusRecipient AS BatchesIndicationStatusRecipient,
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Ref AS Ref
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose AS Purpose,
	|	Goods.Series AS Series,
	|	Goods.Recipient AS Recipient,
	|	Goods.Manufactured AS Manufactured,
	|	Goods.ProductionDate AS ProductionDate,
	|	Goods.Department AS Department,
	|	Goods.Ref AS Ref,
	|	SUM(Goods.Count) AS Count
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|WHERE
	|	NOT Goods.Canceled
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Series,
	|	Goods.Recipient,
	|	Goods.Manufactured,
	|	Goods.ProductionDate,
	|	Goods.Department,
	|	Goods.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.Purpose AS Purpose,
	|	SetOfSeries.Recipient AS Recipient,
	|	SetOfSeries.Manufactured AS Manufactured,
	|	SetOfSeries.ProductionDate AS ProductionDate,
	|	SetOfSeries.Department AS Department,
	|	SetOfSeries.Ref AS Ref,
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
	|	SetOfSeries.Purpose AS Purpose,
	|	SetOfSeries.Recipient AS Recipient,
	|	SetOfSeries.Manufactured AS Manufactured,
	|	SetOfSeries.ProductionDate AS ProductionDate,
	|	SetOfSeries.Department AS Department,
	|	SetOfSeries.Ref AS Ref,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.Recipient,
	|	SetOfSeries.Manufactured,
	|	SetOfSeries.ProductionDate,
	|	SetOfSeries.Department,
	|	SetOfSeries.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	CASE
	|		WHEN Goods.Canceled
	|				OR Goods.ProductionByThirdParty
	|				OR ItemKinds.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN ItemKinds.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					WHEN NOT Goods.Manufactured
	|						THEN 15
	|					ELSE 13
	|				END
	|		WHEN ItemKinds.BatchAccountingPolicy.SpecifyDuringProduction
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|							AND ProductsToRequest.Count > 0
	|						THEN 2
	|					WHEN NOT ProductsToRequest.Manufactured
	|							AND ISNULL(SeriesToRequest.Count, 0) = 0
	|						THEN 21
	|					ELSE 1
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO SenderStatuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|			AND Goods.Recipient = ProductsToRequest.Recipient
	|			AND Goods.Manufactured = ProductsToRequest.Manufactured
	|			AND Goods.ProductionDate = ProductsToRequest.ProductionDate
	|			AND Goods.Department = ProductsToRequest.Department
	|			AND Goods.Ref = ProductsToRequest.Ref
	|		LEFT JOIN SeriesToRequest AS SeriesToRequest
	|		ON Goods.Products = SeriesToRequest.Products
	|			AND Goods.Characteristic = SeriesToRequest.Characteristic
	|			AND Goods.Purpose = SeriesToRequest.Purpose
	|			AND Goods.Recipient = SeriesToRequest.Recipient
	|			AND Goods.Manufactured = SeriesToRequest.Manufactured
	|			AND Goods.ProductionDate = SeriesToRequest.ProductionDate
	|			AND Goods.Department = SeriesToRequest.Department
	|			AND Goods.Ref = SeriesToRequest.Ref
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON Goods.Products = CatalogProducts.Ref
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON (CatalogProducts.ProductKind = ItemKinds.Ref)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	CASE
	|		WHEN Goods.Canceled
	|				OR Goods.ProductionByThirdParty
	|				OR BatchAccountingPolicies.BatchAccountingPolicy IS NULL
	|				OR NOT Warehouses.ShopFloorStockroom
	|				OR Warehouses.Department <> Goods.Department
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					WHEN NOT Goods.Manufactured
	|						THEN 15
	|					ELSE 13
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|							AND ProductsToRequest.Count > 0
	|						THEN 10
	|					WHEN NOT ProductsToRequest.Manufactured
	|							AND ISNULL(SeriesToRequest.Count, 0) = 0
	|						THEN 11
	|					ELSE 9
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|							AND ProductsToRequest.Count > 0
	|						THEN 8
	|					WHEN NOT ProductsToRequest.Manufactured
	|							AND ISNULL(SeriesToRequest.Count, 0) = 0
	|						THEN 27
	|					ELSE 7
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceiving
	|				AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenReceivingProductsFromManufacturing
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 4
	|								WHEN NOT ProductsToRequest.Manufactured
	|										AND ISNULL(SeriesToRequest.Count, 0) = 0
	|									THEN 23
	|								ELSE 3
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 2
	|							WHEN NOT ProductsToRequest.Manufactured
	|									AND ISNULL(SeriesToRequest.Count, 0) = 0
	|								THEN 21
	|							ELSE 1
	|						END
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO RecipientStatuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|			AND Goods.Recipient = ProductsToRequest.Recipient
	|			AND Goods.Manufactured = ProductsToRequest.Manufactured
	|			AND Goods.ProductionDate = ProductsToRequest.ProductionDate
	|			AND Goods.Department = ProductsToRequest.Department
	|			AND Goods.Ref = ProductsToRequest.Ref
	|		LEFT JOIN SeriesToRequest AS SeriesToRequest
	|		ON Goods.Products = SeriesToRequest.Products
	|			AND Goods.Characteristic = SeriesToRequest.Characteristic
	|			AND Goods.Purpose = SeriesToRequest.Purpose
	|			AND Goods.Recipient = SeriesToRequest.Recipient
	|			AND Goods.Manufactured = SeriesToRequest.Manufactured
	|			AND Goods.ProductionDate = SeriesToRequest.ProductionDate
	|			AND Goods.Department = SeriesToRequest.Department
	|			AND Goods.Ref = SeriesToRequest.Ref
	|		LEFT JOIN Catalog.Warehouses AS Warehouses
	|		ON Goods.Recipient = Warehouses.Ref
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON Goods.Products = CatalogProducts.Ref
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		ON Goods.Recipient = BatchAccountingPolicies.Warehouse
	|			AND (CatalogProducts.ProductKind = BatchAccountingPolicies.Ref)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	SenderStatuses.BatchesIndicationStatus AS BatchesIndicationStatusSender,
	|	RecipientStatuses.BatchesIndicationStatus AS BatchesIndicationStatusRecipient,
	|	CASE
	|		WHEN SenderStatuses.BatchesIndicationStatus IN (13, 14, 15)
	|			THEN SenderStatuses.BatchesIndicationStatus
	|		WHEN RecipientStatuses.BatchesIndicationStatus <> 0
	|			THEN RecipientStatuses.BatchesIndicationStatus
	|		ELSE SenderStatuses.BatchesIndicationStatus
	|	END AS BatchesIndicationStatus
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN SenderStatuses AS SenderStatuses
	|		ON Goods.LineNumber = SenderStatuses.LineNumber
	|		LEFT JOIN RecipientStatuses AS RecipientStatuses
	|		ON Goods.LineNumber = RecipientStatuses.LineNumber
	|WHERE
	|	(SenderStatuses.BatchesIndicationStatus <> Goods.BatchesIndicationStatusSender
	|			OR RecipientStatuses.BatchesIndicationStatus <> Goods.BatchesIndicationStatusRecipient
	|			OR CASE
	|				WHEN SenderStatuses.BatchesIndicationStatus IN (13, 14, 15)
	|					THEN SenderStatuses.BatchesIndicationStatus
	|				WHEN RecipientStatuses.BatchesIndicationStatus <> 0
	|					THEN RecipientStatuses.BatchesIndicationStatus
	|				ELSE SenderStatuses.BatchesIndicationStatus
	|			END <> Goods.BatchesIndicationStatus)
	|
	|ORDER BY
	|	Goods.LineNumber";

	Return QueryText;
	
EndFunction

Function TextOfRequestForFillingInStatusesForSpecifyingSeriesProvidingMaterialsAndWorks()
	
	QueryText = 
	"SELECT
	|	Goods.Series AS Series,
	|	Goods.Products AS Products,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.BatchesIndicationStatusSender AS BatchesIndicationStatusSender,
	|	Goods.BatchesIndicationStatusRecipient AS BatchesIndicationStatusRecipient,
	|	Goods.Department AS Department,
	|	Goods.Warehouse AS Warehouse,
	|	Goods.SupplyOption AS SupplyOption,
	|	Goods.Canceled AS Canceled,
	|	Goods.ProductionByThirdParty AS ProductionByThirdParty,
	|	Goods.UnderRepairBatch AS UnderRepairBatch,
	|	Goods.UnderRepairProduct AS UnderRepairProduct,
	|	Goods.UnderRepairBatchSpecificationStatus AS UnderRepairBatchSpecificationStatus,
	|	Goods.Status AS Status,
	|	Goods.LineNumber AS LineNumber
	|INTO GoodsPreliminary
	|FROM
	|	&Goods AS Goods
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Series AS Series,
	|	Goods.Products AS Products,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.BatchesIndicationStatusSender AS BatchesIndicationStatusSender,
	|	Goods.BatchesIndicationStatusRecipient AS BatchesIndicationStatusRecipient,
	|	Goods.Department AS Department,
	|	Goods.Warehouse AS Warehouse,
	|	Goods.SupplyOption AS SupplyOption,
	|	Goods.Canceled AS Canceled,
	|	Goods.ProductionByThirdParty AS ProductionByThirdParty,
	|	Goods.UnderRepairBatch AS UnderRepairBatch,
	|	Goods.UnderRepairProduct AS UnderRepairProduct,
	|	CAST(Goods.UnderRepairProduct AS Catalog.Products).ProductKind AS ItemKindOfProductUnderRM,
	|	Goods.UnderRepairBatchSpecificationStatus AS UnderRepairBatchSpecificationStatus,
	|	Goods.Status AS Status,
	|	Goods.LineNumber AS LineNumber
	|INTO Goods
	|FROM
	|	GoodsPreliminary AS Goods
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
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
	// When shipping from our pantry
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|				AND Goods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|				AND CAST(Goods.Warehouse AS Catalog.Warehouses).ShopFloorStockroom
	|				AND CAST(Goods.Warehouse AS Catalog.Warehouses).Department = Goods.Department
	|				AND NOT Goods.ProductionByThirdParty
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO
	|						THEN CASE
	|								WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|									THEN 6
	|								ELSE 5
	|							END
	|					ELSE CASE
	|							WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 8
	|							ELSE 7
	|						END
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult
	|				AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnShipmentForInternalNeeds
	|				AND Goods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|				AND CAST(Goods.Warehouse AS Catalog.Warehouses).ShopFloorStockroom
	|				AND CAST(Goods.Warehouse AS Catalog.Warehouses).Department = Goods.Department
	|				AND NOT Goods.ProductionByThirdParty
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|						THEN CASE
	|								WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|									THEN 4
	|								ELSE 3
	|							END
	|					ELSE CASE
	|							WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 2
	|							ELSE 1
	|						END
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO SenderStatuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		ON Goods.Warehouse = BatchAccountingPolicies.Warehouse
	|			AND Goods.ProductKind = BatchAccountingPolicies.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	CASE
	|		WHEN Goods.Canceled
	|				OR ItemKinds.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN ItemKinds.BatchAccountingPolicy.UseCostAccountingByBatches
	|				AND Goods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|				AND CAST(Goods.Warehouse AS Catalog.Warehouses).ShopFloorStockroom
	|				AND CAST(Goods.Warehouse AS Catalog.Warehouses).Department = Goods.Department
	|				AND NOT Goods.ProductionByThirdParty
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO RecipientStatuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON Goods.ProductKind = ItemKinds.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	CASE
	|		WHEN ItemKinds.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN ItemKinds.BatchAccountingPolicy.SpecifyWhenRepairingProducts
	|			THEN CASE
	|					WHEN Goods.UnderRepairBatch <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 2
	|					WHEN NOT Goods.Status IN (
	|								VALUE(Enum.StatusesOfProductionStages2_2.Initiated),
	|								VALUE(Enum.StatusesOfProductionStages2_2.Completed))
	|							OR Goods.Canceled
	|						THEN 21
	|					ELSE 1
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO FinishedProductUnderRepairStatus
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON Goods.ItemKindOfProductUnderRM = ItemKinds.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	SenderStatuses.BatchesIndicationStatus AS BatchesIndicationStatusSender,
	|	RecipientStatuses.BatchesIndicationStatus AS BatchesIndicationStatusRecipient,
	|	CASE
	|		WHEN RecipientStatuses.BatchesIndicationStatus <> 0 THEN 
	|			RecipientStatuses.BatchesIndicationStatus
	|		ELSE
	|			SenderStatuses.BatchesIndicationStatus
	|	END AS BatchesIndicationStatus,
	|	FinishedProductUnderRepairStatus.BatchesIndicationStatus AS UnderRepairBatchSpecificationStatus
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN SenderStatuses AS SenderStatuses
	|		ON Goods.LineNumber = SenderStatuses.LineNumber
	|		LEFT JOIN RecipientStatuses AS RecipientStatuses
	|		ON Goods.LineNumber = RecipientStatuses.LineNumber
	|		LEFT JOIN FinishedProductUnderRepairStatus AS FinishedProductUnderRepairStatus
	|		ON Goods.LineNumber = FinishedProductUnderRepairStatus.LineNumber
	|WHERE
	|	(SenderStatuses.BatchesIndicationStatus <> Goods.BatchesIndicationStatusSender
	|			OR RecipientStatuses.BatchesIndicationStatus <> Goods.BatchesIndicationStatusRecipient
	|			OR CASE WHEN RecipientStatuses.BatchesIndicationStatus <> 0
	|					THEN RecipientStatuses.BatchesIndicationStatus
	|					ELSE SenderStatuses.BatchesIndicationStatus
	|				END <> Goods.BatchesIndicationStatus
	|			OR Goods.UnderRepairBatchSpecificationStatus <> FinishedProductUnderRepairStatus.BatchesIndicationStatus)
	|
	|ORDER BY
	|	Goods.LineNumber";
	
	Return QueryText;
	
EndFunction

Function TextOfRequestForFillingInStatusesForSpecifyingSeriesOfMaterialsAndWorksConsumed()

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
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN ItemKinds.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN ItemKinds.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN ItemKinds.BatchAccountingPolicy.SpecifyOnMaterialConsumption
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 2
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
	|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;

EndFunction

Function TextOfRequestToFillInStatusesForSpecifyingSerialMaterials()
	
	QueryText = 
	"SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series,
	|	Goods.Recipient AS Warehouse,
	|	Goods.Purpose AS Purpose,
	|	Goods.DateOfTransaction AS DateOfTransaction,
	|	Goods.Count AS Count,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.BatchesIndicationStatusSender AS BatchesIndicationStatusSender,
	|	Goods.BatchesIndicationStatusRecipient AS BatchesIndicationStatusRecipient,
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Department AS Department,
	|	Goods.Ref AS Ref
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
	|	Goods.Warehouse AS Warehouse,
	|	Goods.Purpose AS Purpose,
	|	Goods.DateOfTransaction AS DateOfTransaction,
	|	Goods.Department AS Department,
	|	Goods.Ref AS Ref,
	|	SUM(Goods.Count) AS Count
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Series,
	|	Goods.Warehouse,
	|	Goods.Purpose,
	|	Goods.DateOfTransaction,
	|	Goods.Department,
	|	Goods.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.Recipient AS Warehouse,
	|	SetOfSeries.Purpose AS Purpose,
	|	SetOfSeries.DateOfTransaction AS DateOfTransaction,
	|	SetOfSeries.Department AS Department,
	|	SetOfSeries.Ref AS Ref,
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
	|	SetOfSeries.Warehouse AS Warehouse,
	|	SetOfSeries.Purpose AS Purpose,
	|	SetOfSeries.DateOfTransaction AS DateOfTransaction,
	|	SetOfSeries.Department AS Department,
	|	SetOfSeries.Ref AS Ref,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Warehouse,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.DateOfTransaction,
	|	SetOfSeries.Department,
	|	SetOfSeries.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	CASE
	|		WHEN ItemKinds.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN ItemKinds.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO SenderStatuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Warehouse = ProductsToRequest.Warehouse
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|			AND Goods.DateOfTransaction = ProductsToRequest.DateOfTransaction
	|			AND Goods.Department = ProductsToRequest.Department
	|			AND Goods.Ref = ProductsToRequest.Ref
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON Goods.Products = CatalogProducts.Ref
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON (CatalogProducts.ProductKind = ItemKinds.Ref)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL
	|				OR NOT Warehouses.ShopFloorStockroom
	|				OR Warehouses.Department <> Goods.Department
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|							AND ProductsToRequest.Count > 0
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|							AND ProductsToRequest.Count > 0
	|						THEN 8
	|					ELSE 7
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceiving
	|				AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceivingByOtherRecordingAsReceived
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 4
	|								ELSE 3
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 2
	|							ELSE 1
	|						END
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO RecipientStatuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Warehouse = ProductsToRequest.Warehouse
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|			AND Goods.DateOfTransaction = ProductsToRequest.DateOfTransaction
	|			AND Goods.Department = ProductsToRequest.Department
	|			AND Goods.Ref = ProductsToRequest.Ref
	|		LEFT JOIN SeriesToRequest AS SeriesToRequest
	|		ON Goods.Products = SeriesToRequest.Products
	|			AND Goods.Characteristic = SeriesToRequest.Characteristic
	|			AND Goods.Warehouse = SeriesToRequest.Warehouse
	|			AND Goods.Purpose = SeriesToRequest.Purpose
	|			AND Goods.DateOfTransaction = SeriesToRequest.DateOfTransaction
	|			AND Goods.Department = SeriesToRequest.Department
	|			AND Goods.Ref = SeriesToRequest.Ref
	|		LEFT JOIN Catalog.Warehouses AS Warehouses
	|		ON Goods.Warehouse = Warehouses.Ref
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON Goods.Products = CatalogProducts.Ref
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		ON Goods.Warehouse = BatchAccountingPolicies.Warehouse
	|			AND (CatalogProducts.ProductKind = BatchAccountingPolicies.Ref)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	SenderStatuses.BatchesIndicationStatus AS BatchesIndicationStatusSender,
	|	RecipientStatuses.BatchesIndicationStatus AS BatchesIndicationStatusRecipient,
	|	CASE
	|		WHEN SenderStatuses.BatchesIndicationStatus <> 0
	|			THEN SenderStatuses.BatchesIndicationStatus
	|		ELSE RecipientStatuses.BatchesIndicationStatus
	|	END AS BatchesIndicationStatus
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN SenderStatuses AS SenderStatuses
	|		ON Goods.LineNumber = SenderStatuses.LineNumber
	|		LEFT JOIN RecipientStatuses AS RecipientStatuses
	|		ON Goods.LineNumber = RecipientStatuses.LineNumber
	|WHERE
	|	(SenderStatuses.BatchesIndicationStatus <> Goods.BatchesIndicationStatusSender
	|			OR RecipientStatuses.BatchesIndicationStatus <> Goods.BatchesIndicationStatusRecipient
	|			OR CASE
	|				WHEN SenderStatuses.BatchesIndicationStatus <> 0
	|					THEN SenderStatuses.BatchesIndicationStatus
	|				ELSE RecipientStatuses.BatchesIndicationStatus
	|			END <> Goods.BatchesIndicationStatus)
	|
	|ORDER BY
	|	Goods.LineNumber";
	
	Return QueryText;
	
EndFunction

Function QueryTextForFillingInStatusesIndicatingBatchesOfFinishedProductBeingRepaired()
	
	QueryText = 
	"SELECT
	|	Goods.Series AS Series,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
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
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN ItemKinds.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN ItemKinds.BatchAccountingPolicy.SpecifyWhenRepairingProducts
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
	|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

#EndRegion

Function StageEditingParameters() Export

	StageEditingParameters = ProductionManagement.StageEditingParameters("DataProcessor");
	Return StageEditingParameters;

EndFunction

#EndRegion

#EndIf
