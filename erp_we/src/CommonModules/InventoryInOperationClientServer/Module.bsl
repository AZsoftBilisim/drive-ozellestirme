////////////////////////////////////////////////////////////////////////////////
// Procedures of the subsystem "TMC in operation".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Parameters of the selection of goods in operation.
// 
// Parameters:
//  Date - Date - On what date are the goods and materials selected.
//  Organization - CatalogRef.Companies - Selection of goods and materials by organization.
//  Department - CatalogRef.BusinessStructure - Selection of goods and materials by division.
// 
// Returns:
//  Structure - Contains:
//		* Date - Date, Undefined - On what date are the goods and materials selected.
//		* Organization - CatalogRef.Companies, Undefined - Selection of goods and materials by organization.
//		* Department - CatalogRef.BusinessStructure, Undefined - Selection of goods and materials by division.
//		* Products - CatalogRef.Products, Undefined - Selection of goods and materials by nomenclature.
//		* Characteristic - CatalogRef.ItemsCharacteristics, Undefined - Selection of goods and materials by characteristics.
//		* Series - CatalogRef.ItemsBatches, Undefined - Selection of goods and materials by series.
//		* BatchesIndicationStatus - Number, Undefined - For the selection of goods and materials by series.
//		* Individual - CatalogRef.Persons, Undefined - Selection of goods and materials by physical face.
//		* MethodOfRepaymentOfCostOfAC - EnumRef.WaysToRepayCostOfInventory, Undefined - Selection of the method of repayment of the cost.
//		* AssetID - String, Undefined - Selection of goods and materials by inventory number.
//		* InventoryNumberContains - String, Undefined - Selection of goods and materials by the coincidence of the text in the inventory number.
//		* SelectFirstRecords - Number - Select the first entries.
//		* StocktakingRecord - Number, Undefined - The selection of goods and materials on the basis of inventory (0 - Any, 1 - Is not conducted, 2 - Is conducted).
//		* AssignedResource - String - (Worked out, not worked out).
//		* CurrentRegistrar - DocumentRef, Undefined - Filled in if you need to take into account the change in the balances of the document.
//		* StartDateOfOperationFrom - Date - Selection by the start date of operation.
//		* StartDateOfSoftwareOperation - Date - Selection by the start date of operation.
//		* ForDynamicList - Boolean - True if the selection is performed in din. the list.
//	
Function ParametersOfSelectionOfGoodsInOperation(Date = Undefined, Organization = Undefined, Department = Undefined) Export
	
	PickingParameters = New Structure;
	PickingParameters.Insert("Date", Date);
	PickingParameters.Insert("Organization", Organization);
	PickingParameters.Insert("Department", Department);
	PickingParameters.Insert("Products", Undefined);
	PickingParameters.Insert("Characteristic", Undefined);
	PickingParameters.Insert("Series", Undefined);
	PickingParameters.Insert("BatchesIndicationStatus", Undefined);
	PickingParameters.Insert("BatchesIndicationStatusSender", Undefined);
	PickingParameters.Insert("Individual", Undefined);
	PickingParameters.Insert("MethodOfRepaymentOfCostOfAC", Undefined);
	PickingParameters.Insert("CurrentRegistrar", Undefined);
	PickingParameters.Insert("AssetID", Undefined);
	PickingParameters.Insert("InventoryNumberContains", Undefined);
	PickingParameters.Insert("SelectFirstRecords", 0);	
	PickingParameters.Insert("AssignedResource", Undefined);	
	PickingParameters.Insert("StocktakingRecord", 0);
	PickingParameters.Insert("StartDateOfOperationFrom", '000101010000');	
	PickingParameters.Insert("StartDateOfSoftwareOperation", '000101010000');	
	PickingParameters.Insert("ForDynamicList", False);	
	
	Return PickingParameters;
	
EndFunction

// Parameters for filling in the operation category attributes.
// 
// Returns:
//  Structure - Parameters For Filling In The Operation Category Attributes:
//		* FillInExpenseItem - Boolean -
//		* FillInExpenseItemForGroupFA - Boolean -
//		* FillInServiceLife - Boolean -
Function ParametersForFillingInOperationCategoryAttributes() Export

	FillParameters = New Structure;
	FillParameters.Insert("FillInExpenseItem", True);
	FillParameters.Insert("FillInExpenseItemForGroupFA", True);
	FillParameters.Insert("FillInServiceLife", False);
	
	Return FillParameters;
	
EndFunction

// For the actions of the Inventory center in operation, it generates data describing readable and changeable fields.
// 
// Parameters:
//  CurrentRow - See BatchProcessingOfTablePartServer.ProcessTSString.CurrentRow
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//  AdditionalFillingParameters - Structure - Additional Filling Parameters
//  
// Returns:
// Array of Structure - Description of readable and modifiable fields:
//  * Name - String - The name of the action in the structure.
//  * ReadableFields - Structure - Readable Fields:
//  	** Key - String - Name of the field being read.
//  * EditableFields - Structure - fields that can be changed:
//  	** Key - String - Name of the field to change.
//
Function FieldsOfActionLine(CurrentRow, StructureOfActions, CachedValues, AdditionalFillingParameters) Export
	
	Actions = New Array();
	
	If StructureOfActions.Property("FillInCategoryAttributes") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("OperationCategory");
		
		EditableFields = New Structure();
		EditableFields.Insert("StocktakingRecord");
		EditableFields.Insert("AccountingForIndividuals");
		EditableFields.Insert("AccountAsGroupFA");
		EditableFields.Insert("MethodOfRepaymentOfCostOfAC");
		EditableFields.Insert("FACostCapitalizationArticle");
		EditableFields.Insert("ExpenseItem");
		EditableFields.Insert("ServiceLife");
		
		Actions.Add(New Structure("Name,ReadableFields,EditableFields",
			"FillInCategoryAttributes", ReadableFields, EditableFields));
		
	EndIf;
	
	If StructureOfActions.Property("FillInBatchOfTMTSV") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		ReadableFields.Insert("Individual");
		ReadableFields.Insert("NumberOfPackages");
		ReadableFields.Insert("Count");
		ReadableFields.Insert("Package");
		ReadableFields.Insert("OperationCategory");
		ReadableFields.Insert("AssetID");
		ReadableFields.Insert("Series");
		
		If CommonClientServer.HasAttributeOrObjectProperty(
			CurrentRow, "BatchesIndicationStatusSender") Then
				ReadableFields.Insert("BatchesIndicationStatusSender");
		Else
			ReadableFields.Insert("BatchesIndicationStatus");
		EndIf;
		
		EditableFields = New Structure();
		EditableFields.Insert("Lot");
		EditableFields.Insert("StocktakingRecord");
		EditableFields.Insert("AccountingForIndividuals");
		
		Actions.Add(New Structure("Name,ReadableFields,EditableFields",
			"FillInBatchOfTMTSV", ReadableFields, EditableFields));
		
	EndIf;
	
	Return Actions;
	
EndFunction

#EndRegion

#Region Private

#Region OBEntryInventoryInOperation

Function ValuesOfPropertiesOfDependentDetails_InputOfRemainingInventoryItemsInOperation(Object, AddlParameters, ChangedBankingDetails = "") Export
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;

	If StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
			
		PropertyValue = False;
		PropertyValue = 
			Object.Date <> '000101010000'
			And BegOfMonth(Object.Date) < BegOfMonth(LocalAccntingClientServer.BeginningOfApplicationFSBU5_2019());
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InventoryInOperation.InitialAmount", 
			"InventoryInOperationInitialAmount", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
		
		PropertyValue = Not AddlParameters.CostDebited;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InventoryInOperation.ExpenseItem", 
			"InventoryInOperationExpenseItem", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InventoryInOperation.DimensionOfExpenses", 
			"InventoryInOperationDimensionOfExpenses", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InventoryInOperation.Sum", 
			"InventoryInOperationSum", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InventoryInOperation.AmountTemporaryDifferences", 
			"InventoryInOperationAmountTemporaryDifferences", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InventoryInOperation.AmountPermanentDifferences", 
			"InventoryInOperationAmountPermanentDifferences", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	Return ItemDetailsParameters;
	
EndFunction

#EndRegion

#Region PhysicalCountOfInventoryInOperation

// Fill in the action based on the inventory.
// 
// Parameters:
//  RowData - LineOfATabularSection - this line:
//  	* Action - EnumRef.ActionsBasedOnPhysicalInventoryCount -
//  DataOfAccounting - Structure -
//  Organization - CatalogRef.Companies - Organization
//  Department - CatalogRef.BusinessStructure - Department
//  Individual - CatalogRef.Persons - FinanciallyLiablePerson
//	SetAction - Boolean - False if you need to leave the previously set action
Procedure FillInActionBasedOnInventory(RowData, DataOfAccounting, Organization, Department, Individual, SetAction = True) Export
	
	If DataOfAccounting <> Undefined Then
		OrganizationBasedOnAccountingData = DataOfAccounting.Organization;
		AccountingDataDivision = DataOfAccounting.Department;
		IndividualAccordingToAccountingData = DataOfAccounting.Individual;
	ElsIf TypeOf(RowData) = Type("FormDataCollectionItem") Then
		OrganizationBasedOnAccountingData = RowData.OrganizationBasedOnAccountingData;
		AccountingDataDivision = RowData.AccountingDataDivision;
		IndividualAccordingToAccountingData = RowData.IndividualAccordingToAccountingData;
	Else
		OrganizationBasedOnAccountingData = PredefinedValue("Catalog.Companies.EmptyRef");
		AccountingDataDivision = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
		IndividualAccordingToAccountingData = PredefinedValue("Catalog.Persons.EmptyRef");
	EndIf;
	
	If RowData.QuantityAccordingToAccountingData <> 0
		And (RowData.Quantity_Actual = 0
			Or RowData.QuantityAccordingToAccountingData > RowData.Quantity_Actual
				And OrganizationBasedOnAccountingData = Organization
				And AccountingDataDivision = Department
				And (IndividualAccordingToAccountingData = Individual
					Or Not ValueIsFilled(Individual)
						And IndividualAccordingToAccountingData = RowData.Individual)) Then
			
		RowData.Action = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff");
		
	ElsIf RowData.Quantity_Actual <> 0
		And (RowData.QuantityAccordingToAccountingData = 0
			Or RowData.QuantityAccordingToAccountingData < RowData.Quantity_Actual) Then
			
		If SetAction
			Or RowData.Action = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.EmptyRef")
			Or RowData.Action = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff")
			Or RowData.Action = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.PutOutOfOperation")
				And RowData.QuantityAccordingToAccountingData = 0 Then
			
			RowData.Action = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.RecordingAsReceived");
			
		EndIf;
		
	Else
	
		RowData.Action = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.EmptyRef");
		
	EndIf;

EndProcedure

// Fill in the inventory line based on accounting data.
// 
// Parameters:
//  Object - DocumentObject.PhysicalCountOfInventoryInOperation - 
//  RowData - FormDataStructure - 
//  DataOfAccounting - Structure - 
//  FillInServiceDetails - Boolean - 
//	SetAction - Boolean - False if you need to leave the previously set action
Procedure FillInInventoryLineBasedOnAccountingData(Object, RowData, DataOfAccounting, FillInServiceDetails = False, SetAction = True) Export
	
	If DataOfAccounting <> Undefined
		And DataOfAccounting.Organization = Object.Organization
		And DataOfAccounting.Department = Object.Department
		And (DataOfAccounting.Individual = Object.Individual
			Or Not ValueIsFilled(Object.Individual)
				And RowData.Individual = DataOfAccounting.Individual) Then

		RowData.QuantityAccordingToAccountingData = DataOfAccounting.QuantityAccordingToAccountingData;
	Else
		RowData.QuantityAccordingToAccountingData = 0;
	EndIf;
	
	If FillInServiceDetails Then
		If DataOfAccounting <> Undefined Then
			RowData.OrganizationBasedOnAccountingData = DataOfAccounting.Organization;
			RowData.AccountingDataDivision = DataOfAccounting.Department;
			RowData.IndividualAccordingToAccountingData = DataOfAccounting.Individual;
		Else
			RowData.OrganizationBasedOnAccountingData = Undefined;
			RowData.AccountingDataDivision = Undefined;
			RowData.IndividualAccordingToAccountingData = Undefined;
		EndIf;
	EndIf; 
	
	FillInActionBasedOnInventory(
		RowData,
		DataOfAccounting,
		Object.Organization, 
		Object.Department,
		Object.Individual,
		SetAction);
	
EndProcedure

#EndRegion

#Region OperationCategories

// 
// Parameters:
//  Object - CatalogObject.OperationCategories, FormDataStructure - 
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function ValuesOfPropertiesOfDependentDetails_CategoriesOfOperation(Object, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;

	If StructureOfChangedProps.Property("PropertyAccounting")
		Or UpdateAll Then
		
		PropertyValue = Not Object.PropertyAccounting;
										
		TMCommonUseClientServer.AddItemDetailsParameters(
			"StocktakingRecord", 
			"StocktakingRecord", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccountingForIndividuals", 
			"AccountingForIndividuals", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ServiceLife", 
			"ServiceLife", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccountAsGroupFA", 
			"AccountAsGroupFA", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"MethodOfRepaymentOfCostOfAC", 
			"MethodOfRepaymentOfCostOfAC", 
			"OnlyViewWithoutClearing", 
			PropertyValue, 
			ItemDetailsParameters);
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"SettingUpAccountingAccounts_GLAccount_InventoryInOperationOffBalance", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);

	EndIf;
	
	If StructureOfChangedProps.Property("PropertyAccounting")
		Or StructureOfChangedProps.Property("AccountAsGroupFA")
		Or UpdateAll Then
		
		PropertyValue = 
			Not Object.AccountAsGroupFA
			Or Not Object.PropertyAccounting;
										
		TMCommonUseClientServer.AddItemDetailsParameters(
			"OSGroup", 
			"OSGroup", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FACostCapitalizationArticle", 
			"FACostCapitalizationArticle", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
		
	If StructureOfChangedProps.Property("PropertyAccounting")
		Or StructureOfChangedProps.Property("MethodOfRepaymentOfCostOfAC")
		Or UpdateAll Then

		PropertyValue = 
			Object.MethodOfRepaymentOfCostOfAC = PredefinedValue("Enum.WaysToRepayCostOfInventory.OnCommissioning")
			Or Not Object.PropertyAccounting;
										
		TMCommonUseClientServer.AddItemDetailsParameters(
			"MethodOfRepaymentOfCostTA", 
			"MethodOfRepaymentOfCostTA", 
			"OnlyViewWithoutClearing", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	Return ItemDetailsParameters;

EndFunction

#EndRegion

#Region DefiningPropertiesOfDependentPropsOfObject

// 
// Parameters:
//  Object - DocumentObject.Decomissioning - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function PropertyValuesOfDependentAttributes_WriteOff(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;

	If StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		PropertyValue = AuxiliaryAttributes.UseTrackingOfTraceableItems;
										
		TMCommonUseClientServer.AddItemDetailsParameters(
			"Goods.CCDNumber", 
			"GoodsCCDNumber", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

		TMCommonUseClientServer.AddItemDetailsParameters(
			"Goods.QuantityByGBRN", 
			"GoodsQuantityByGBRN", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

	EndIf;
	
	Return ItemDetailsParameters;
		
EndFunction

#EndRegion

#Region Other

// Forms a new value for the selection of a batch of goods and materials.
// 
// Returns:
//  Structure - Contains:
// 		* Products - CatalogRef.Products -
// 		* Characteristic - CatalogRef.ItemsCharacteristics -
// 		* Series - CatalogRef.ItemsBatches -
// 		* Lot - CatalogRef.LotsOfInventoryInOperation -
// 		* Individual - CatalogRef.Persons -
// 		* LineOfBusiness - CatalogRef.LinesOfBusiness
// 		* AssetID - String -
// 		* Department - CatalogRef.BusinessStructure -
// 		* CCDNumber - CatalogRef.CCDNumbers -
// 		* StocktakingRecord - Boolean -
// 		* AccountingForIndividuals - Boolean -
// 		* EstimatedRunningTime - Number - 
// 		* CompletionDate_ - Date -
// 		* Count - Number -
// 		* NumberOfPackages - Number -
// 		* QuantityByGBRN - Number -
Function NewSelectionValue() Export
	
	SelectionValue = New Structure;
	
	SelectionValue.Insert("Products", PredefinedValue("Catalog.Products.EmptyRef"));
	SelectionValue.Insert("Characteristic", PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
	SelectionValue.Insert("Series", PredefinedValue("Catalog.ItemsBatches.EmptyRef"));
	SelectionValue.Insert("Lot", PredefinedValue("Catalog.LotsOfInventoryInOperation.EmptyRef"));
	SelectionValue.Insert("Individual", PredefinedValue("Catalog.Persons.EmptyRef"));
	SelectionValue.Insert("LineOfBusiness", PredefinedValue("Catalog.LinesOfBusiness.EmptyRef"));
	SelectionValue.Insert("AssetID", "");
	SelectionValue.Insert("Department", PredefinedValue("Catalog.BusinessStructure.EmptyRef"));
	SelectionValue.Insert("CCDNumber", PredefinedValue("Catalog.CCDNumbers.EmptyRef"));
	SelectionValue.Insert("StocktakingRecord", False);
	SelectionValue.Insert("AccountingForIndividuals", False);
	SelectionValue.Insert("EstimatedRunningTime", 0);
	SelectionValue.Insert("CompletionDate_", '000101010000');
	SelectionValue.Insert("Count", 0);
	SelectionValue.Insert("NumberOfPackages", 0);
	SelectionValue.Insert("QuantityByGBRN", 0);
	
	Return SelectionValue;
	
EndFunction

// Generates a description of the request for selecting a batch of goods and materials.
// 
// Parameters:
//  Parameters - See InventoryInOperationClientServer.ParametersOfSelectionOfGoodsInOperation.
// 
// Returns:
//  Structure - Description Of The Request To Select A Batch Of Goods And Materials:
// 		* QueryText - String - query text.
// 		* QueryOptions - Structure - request parameters.
Function DescriptionOfRequestToSelectBatchOfGoodsAndMaterials(Parameters) Export
	
	QueryText =
	"SELECT ALLOWED TOP 10
	|	InventoryInOperation.Organization AS Organization,
	|	InventoryInOperation.Department AS Department,
	|	InventoryInOperation.Individual AS Individual,
	|	InventoryInOperation.Products AS Products,
	|	InventoryInOperation.Characteristic AS Characteristic,
	|	InventoryInOperation.Series AS Series,
	|	InventoryInOperation.Lot AS Lot,
	|	InventoryInOperation.Lot.Description AS LotPresentation,
	|	InventoryInOperation.Lot.OperationCategory.StocktakingRecord AS StocktakingRecord,
	|	InventoryInOperation.Lot.OperationCategory.AccountingForIndividuals AS AccountingForIndividuals,
	|	InventoryInOperation.Lot.OperationCategory.MethodOfRepaymentOfCostOfAC AS MethodOfRepaymentOfCostOfAC,
	|	InventoryInOperation.Lot.OperationCategory.EstimatedRunningTime AS EstimatedRunningTime,
	|	InventoryInOperation.LineOfBusiness AS LineOfBusiness,
	|	InventoryInOperation.AssetID AS AssetID,
	|	InventoryInOperation.CCDNumber AS CCDNumber,
	|
	|	SUM(InventoryInOperation.Count) AS Count,
	|	SUM(InventoryInOperation.QuantityByGBRN) AS QuantityByGBRN
	|FROM
	|	(SELECT
	|		InventoryInOperationOverridable.Organization AS Organization,
	|		InventoryInOperationOverridable.Department AS Department,
	|		InventoryInOperationOverridable.Individual AS Individual,
	|		InventoryInOperationOverridable.Products AS Products,
	|		InventoryInOperationOverridable.Characteristic AS Characteristic,
	|		InventoryInOperationOverridable.Series AS Series,
	|		InventoryInOperationOverridable.Lot AS Lot,
	|		InventoryInOperationOverridable.LineOfBusiness AS LineOfBusiness,
	|		InventoryInOperationOverridable.AssetID AS AssetID,
	|		InventoryInOperationOverridable.CCDNumber AS CCDNumber,
	|		InventoryInOperationOverridable.CountBalance AS Count,
	|		InventoryInOperationOverridable.QuantityByGBRNBalance AS QuantityByGBRN
	|	FROM
	|		AccumulationRegister.InventoryInOperation.Balance(
	|			&FilterDate,
	|			(Organization = &FilterOrganization
	|					OR &FilterOrganization = VALUE(Catalog.Companies.EmptyRef))
	|
	|				AND (Department = &FilterDepartment
	|					OR &FilterDepartment = VALUE(Catalog.BusinessStructure.EmptyRef))
	|
	|				AND (&SelectionBasedOnLineData
	|					OR Individual = &FilterIndividual
	|					OR &FilterIndividual = VALUE(Catalog.Persons.EmptyRef))
	|
	|				AND (AssetID = &AssetID
	|					OR NOT &UseInventoryNumberSelection)
	|
	|				AND (AssetID LIKE &InventoryNumberContains
	|					OR &InventoryNumberContains = """")
	|
	|				AND (NOT &SelectionBasedOnLineData
	|					OR Products = &FilterProducts
	|							AND Characteristic = &FilterCharacteristic
	|							AND Series = &FilterSeries
	|							AND Individual = &FilterIndividual)) AS InventoryInOperationOverridable
	|
	|	UNION ALL
	|
	|	SELECT
	|		InventoryInOperationOverridable.Organization AS Organization,
	|		InventoryInOperationOverridable.Department AS Department,
	|		InventoryInOperationOverridable.Individual AS Individual,
	|		InventoryInOperationOverridable.Products AS Products,
	|		InventoryInOperationOverridable.Characteristic AS Characteristic,
	|		InventoryInOperationOverridable.Series AS Series,
	|		InventoryInOperationOverridable.Lot AS Lot,
	|		InventoryInOperationOverridable.LineOfBusiness AS LineOfBusiness,
	|		InventoryInOperationOverridable.AssetID AS AssetID,
	|		InventoryInOperationOverridable.CCDNumber AS CCDNumber,
	|		CASE
	|			WHEN InventoryInOperationOverridable.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -InventoryInOperationOverridable.Count
	|			ELSE InventoryInOperationOverridable.Count
	|		END AS Count,
	|		CASE
	|			WHEN InventoryInOperationOverridable.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -InventoryInOperationOverridable.QuantityByGBRN
	|			ELSE InventoryInOperationOverridable.QuantityByGBRN
	|		END AS QuantityByGBRN
	|	FROM
	|		AccumulationRegister.InventoryInOperation AS InventoryInOperationOverridable
	|	WHERE
	|		InventoryInOperationOverridable.Recorder = &CurrentRegistrar
	|		AND InventoryInOperationOverridable.Active
	|
	|		AND (InventoryInOperationOverridable.Period < &FilterDate
	|			OR &FilterDate = DATETIME(1,1,1))
	|
	|		AND (InventoryInOperationOverridable.Organization = &FilterOrganization
	|				OR &FilterOrganization = VALUE(Catalog.Companies.EmptyRef))
	|
	|		AND (InventoryInOperationOverridable.Department = &FilterDepartment
	|				OR &FilterDepartment = VALUE(Catalog.BusinessStructure.EmptyRef))
	|
	|		AND (&SelectionBasedOnLineData
	|				OR InventoryInOperationOverridable.Individual = &FilterIndividual
	|				OR &FilterIndividual = VALUE(Catalog.Persons.EmptyRef))
	|
	|		AND (InventoryInOperationOverridable.AssetID = &AssetID
	|				OR NOT &UseInventoryNumberSelection)
	|
	|		AND (InventoryInOperationOverridable.AssetID LIKE &InventoryNumberContains
	|				OR &InventoryNumberContains = """")
	|
	|		AND (NOT &SelectionBasedOnLineData
	|				OR InventoryInOperationOverridable.Products = &FilterProducts
	|					AND InventoryInOperationOverridable.Characteristic = &FilterCharacteristic
	|					AND InventoryInOperationOverridable.Series = &FilterSeries
	|					AND InventoryInOperationOverridable.Individual = &FilterIndividual)
	|
	|	) AS InventoryInOperation
	|
	|WHERE
	|	(&FilterAssignedResource = """"
	|		OR &FilterAssignedResource = ""Developed""
	|			AND InventoryInOperation.Lot.CompletionDate_ < &FilterDate
	|		OR &FilterAssignedResource = ""NotDeveloped""
	|			AND InventoryInOperation.Lot.CompletionDate_ >= &FilterDate)
	|
	|	AND (&FilterStocktakingRecord = 0
	|		OR &FilterStocktakingRecord = 1
	|				AND NOT InventoryInOperation.Lot.OperationCategory.StocktakingRecord
	|		OR &FilterStocktakingRecord = 2
	|				AND InventoryInOperation.Lot.OperationCategory.StocktakingRecord)
	|
	|	AND (&MethodOfRepaymentOfCostOfAC = VALUE(Enum.WaysToRepayCostOfInventory.EmptyRef)
	|		OR InventoryInOperation.Lot.OperationCategory.MethodOfRepaymentOfCostOfAC = &MethodOfRepaymentOfCostOfAC)
	|
	|	AND (&StartDateOfOperationFrom = DATETIME(1,1,1)
	|		OR InventoryInOperation.Lot.StartDateOfOperation >= &StartDateOfOperationFrom)
	|
	|	AND (&StartDateOfSoftwareOperation = DATETIME(1,1,1)
	|		OR InventoryInOperation.Lot.StartDateOfOperation <= &StartDateOfSoftwareOperation)
	|
	|GROUP BY
	|	InventoryInOperation.Organization,
	|	InventoryInOperation.Department,
	|	InventoryInOperation.Individual,
	|	InventoryInOperation.Products,
	|	InventoryInOperation.Characteristic,
	|	InventoryInOperation.Series,
	|	InventoryInOperation.Lot,
	|	InventoryInOperation.LineOfBusiness,
	|	InventoryInOperation.AssetID,
	|	InventoryInOperation.CCDNumber
	|
	|HAVING
	|	SUM(InventoryInOperation.Count) > 0";
	
	If Not Parameters.ForDynamicList Then
		
		QueryText = QueryText + "
		|
		|ORDER BY
		|	Organization,
		|	Department,
		|	Individual,
		|	Products,
		|	Characteristic,
		|	Series,
		|	LineOfBusiness,
		|	AssetID";
		
	EndIf;
	
	FilterDate = ?(
		Parameters.Date <> Undefined And Parameters.Date <> '000101010000', 
		EndOfDay(Parameters.Date) + 1, 
		'000101010000');
	
	FilterAssignedResource = ?(
		Parameters.AssignedResource <> Undefined, 
		Parameters.AssignedResource, 
		"");
	
	FilterOrganization = ?(
		Parameters.Organization <> Undefined, 
		Parameters.Organization, 
		PredefinedValue("Catalog.Companies.EmptyRef"));

	FilterDepartment = ?(
		Parameters.Department <> Undefined, 
		Parameters.Department, 
		PredefinedValue("Catalog.BusinessStructure.EmptyRef"));

	FilterProducts = ?(
		Parameters.Products <> Undefined, 
		Parameters.Products, 
		PredefinedValue("Catalog.Products.EmptyRef"));

	FilterCharacteristic = ?(
		Parameters.Characteristic <> Undefined, 
		Parameters.Characteristic, 
		PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));

	If Parameters.Series <> Undefined
		And (Parameters.BatchesIndicationStatusSender = 19
			Or Parameters.BatchesIndicationStatusSender = 20
			Or Parameters.BatchesIndicationStatusSender = Undefined
				And (Parameters.BatchesIndicationStatus = 19
					Or Parameters.BatchesIndicationStatus = 20)) Then
		FilterSeries = Parameters.Series;
	Else
		FilterSeries = PredefinedValue("Catalog.ItemsBatches.EmptyRef");
	EndIf;

	FilterIndividual = ?(
		Parameters.Individual <> Undefined, 
		Parameters.Individual, 
		PredefinedValue("Catalog.Persons.EmptyRef"));
	
	FilterMethodOfRepaymentOfCostOfAC = ?(
		Parameters.MethodOfRepaymentOfCostOfAC <> Undefined, 
		Parameters.MethodOfRepaymentOfCostOfAC, 
		PredefinedValue("Enum.WaysToRepayCostOfInventory.EmptyRef"));
	
	CurrentRegistrar = Parameters.CurrentRegistrar;
		
	AssetID = ?(
		Parameters.AssetID <> Undefined, 
		Parameters.AssetID, 
		"");
		
	UseInventoryNumberSelection = ValueIsFilled(Parameters.AssetID);
	
	InventoryNumberContains = ?(
		Parameters.InventoryNumberContains <> Undefined, 
		"%" + Parameters.InventoryNumberContains + "%", 
		"");
		
	FilterStocktakingRecord = ?(
		TypeOf(Parameters.StocktakingRecord) = Type("Boolean"),
		?(Parameters.StocktakingRecord, 2, 0),
		Parameters.StocktakingRecord);
		
	SelectionBasedOnLineData = 
		Parameters.Products <> Undefined
		Or Parameters.Characteristic <> Undefined
		Or Parameters.Series <> Undefined;
	
	If Parameters.ForDynamicList Then
		QueryText = StrReplace(QueryText, "ALLOWED TOP 10", "");
	EndIf;
	
	If Parameters.SelectFirstRecords > 0 Then
		QueryText = StrReplace(QueryText, "TOP 10", "FIRST" + " " + Format(Parameters.SelectFirstRecords, "NG=0;"));
	Else
		QueryText = StrReplace(QueryText, "TOP 10", "");
	EndIf;
	
	QueryOptions = New Structure;
	QueryOptions.Insert("FilterDate", FilterDate);
	QueryOptions.Insert("FilterAssignedResource", FilterAssignedResource);
	QueryOptions.Insert("FilterOrganization", FilterOrganization);
	QueryOptions.Insert("FilterDepartment", FilterDepartment);
	QueryOptions.Insert("FilterProducts", FilterProducts);
	QueryOptions.Insert("FilterCharacteristic", FilterCharacteristic);
	QueryOptions.Insert("FilterSeries", FilterSeries);
	QueryOptions.Insert("FilterIndividual", FilterIndividual);
	QueryOptions.Insert("MethodOfRepaymentOfCostOfAC", FilterMethodOfRepaymentOfCostOfAC);
	QueryOptions.Insert("SelectionBasedOnLineData", SelectionBasedOnLineData);
	QueryOptions.Insert("CurrentRegistrar", CurrentRegistrar);
	QueryOptions.Insert("AssetID", AssetID);
	QueryOptions.Insert("UseInventoryNumberSelection", UseInventoryNumberSelection);
	QueryOptions.Insert("InventoryNumberContains", InventoryNumberContains);
	QueryOptions.Insert("FilterStocktakingRecord", FilterStocktakingRecord);
	QueryOptions.Insert("StartDateOfOperationFrom", Parameters.StartDateOfOperationFrom);
	QueryOptions.Insert("StartDateOfSoftwareOperation",Parameters.StartDateOfSoftwareOperation);
	
	DescriptionOfSelectionRequest = New Structure("QueryText,QueryOptions", QueryText, QueryOptions);
	
	Return DescriptionOfSelectionRequest;
	
EndFunction

// Generates a description of the request for selecting a batch of goods and materials.
// 
// Parameters:
//  Parameters - See InventoryInOperationClientServer.ParametersOfSelectionOfGoodsInOperation.
// 
// Returns:
//  Structure - Description Of The Request To Select A Batch Of Goods And Materials:
// 		* QueryText - String - query text.
// 		* QueryOptions - Structure - request parameters.
Function DescriptionOfRequestToSelectBatchOfGoodsAndMaterials_UT(Parameters) Export
	
	QueryText =
	"SELECT ALLOWED
	|	LotsOfGoodsAndMaterials.Ref AS Ref
	|
	|INTO LotsOfGoodsAndMaterials
	|
	|FROM
	|	Catalog.LotsOfInventoryInOperation AS LotsOfGoodsAndMaterials
	|
	|WHERE
	|	LotsOfGoodsAndMaterials.CompletionDate_ >= &FilterDate
	|	AND NOT LotsOfGoodsAndMaterials.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED TOP 10
	|	InventoryInOperation.Organization AS Organization,
	|	InventoryInOperation.Department AS Department,
	|	InventoryInOperation.Individual AS Individual,
	|	InventoryInOperation.Products AS Products,
	|	InventoryInOperation.Characteristic AS Characteristic,
	|	FALSE AS StocktakingRecord,
	|	TRUE AS AccountingForIndividuals,
	|	InventoryInOperation.LineOfBusiness AS LineOfBusiness,
	|	InventoryInOperation.CompletionDate_ AS CompletionDate_,
	|
	|	SUM(InventoryInOperation.Count) AS Count
	|
	|FROM
	|	(SELECT
	|		GoodsTable.Ref.Organization AS Organization,
	|		GoodsTable.Ref.Department AS Department,
	|		GoodsTable.Individual AS Individual,
	|		GoodsTable.Products AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Ref.LineOfBusiness AS LineOfBusiness,
	|		GoodsTable.Lot.CompletionDate_ AS CompletionDate_,
	|		GoodsTable.Count AS Count
	|		
	|	FROM
	|		Document.InventoryConsumption.Goods AS GoodsTable
	|
	|	WHERE
	|		GoodsTable.Lot IN
	|			(SELECT
	|				LotsOfGoodsAndMaterials.Ref
	|			FROM
	|				LotsOfGoodsAndMaterials AS LotsOfGoodsAndMaterials)
	|		AND GoodsTable.Ref.Posted
	|
	|		AND (GoodsTable.Ref.Organization = &FilterOrganization
	|			OR &FilterOrganization = VALUE(Catalog.Companies.EmptyRef))
	|
	|		AND (GoodsTable.Ref.Department = &FilterDepartment
	|			OR &FilterDepartment = VALUE(Catalog.BusinessStructure.EmptyRef))
	|
	|		AND (&SelectionBasedOnLineData
	|			OR GoodsTable.Individual = &FilterIndividual
	|			OR &FilterIndividual = VALUE(Catalog.Persons.EmptyRef))
	|
	|		AND (NOT &SelectionBasedOnLineData
	|			OR GoodsTable.Products = &FilterProducts
	|				AND GoodsTable.Characteristic = &FilterCharacteristic
	|				AND GoodsTable.Individual = &FilterIndividual)
	|
	|	UNION ALL
	|
	|	SELECT
	|		GoodsTable.Ref.Organization AS Organization,
	|		GoodsTable.Ref.Department AS Department,
	|		GoodsTable.Individual AS Individual,
	|		GoodsTable.Products AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.LineOfBusiness AS LineOfBusiness,
	|		GoodsTable.Lot.CompletionDate_ AS CompletionDate_,
	|		GoodsTable.Count AS Count
	|	FROM
	|		Document.OBEntryInventoryInOperation.InventoryInOperation AS GoodsTable
	|
	|	WHERE
	|		GoodsTable.Lot IN
	|			(SELECT
	|				LotsOfGoodsAndMaterials.Ref
	|			FROM
	|				LotsOfGoodsAndMaterials AS LotsOfGoodsAndMaterials)
	|		AND GoodsTable.Ref.Posted
	|
	|		AND (GoodsTable.Ref.Organization = &FilterOrganization
	|			OR &FilterOrganization = VALUE(Catalog.Companies.EmptyRef))
	|
	|		AND (GoodsTable.Ref.Department = &FilterDepartment
	|			OR &FilterDepartment = VALUE(Catalog.BusinessStructure.EmptyRef))
	|
	|		AND (&SelectionBasedOnLineData
	|			OR GoodsTable.Individual = &FilterIndividual
	|			OR &FilterIndividual = VALUE(Catalog.Persons.EmptyRef))
	|
	|		AND (NOT &SelectionBasedOnLineData
	|			OR GoodsTable.Products = &FilterProducts
	|				AND GoodsTable.Characteristic = &FilterCharacteristic
	|				AND GoodsTable.Individual = &FilterIndividual)
	|
	|	UNION ALL
	|
	|	SELECT
	|		GoodsTable.Ref.Organization AS Organization,
	|		GoodsTable.Ref.Department AS Department,
	|		GoodsTable.Individual AS Individual,
	|		GoodsTable.Products AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Ref.LineOfBusiness AS LineOfBusiness,
	|		GoodsTable.Lot.CompletionDate_ AS CompletionDate_,
	|		GoodsTable.Count AS Count
	|	FROM
	|		Document.OBEntry.InventoryInOperation AS GoodsTable
	|
	|	WHERE
	|		GoodsTable.Lot IN
	|			(SELECT
	|				LotsOfGoodsAndMaterials.Ref
	|			FROM
	|				LotsOfGoodsAndMaterials AS LotsOfGoodsAndMaterials)
	|		AND GoodsTable.Ref.Posted
	|
	|		AND (GoodsTable.Ref.Organization = &FilterOrganization
	|			OR &FilterOrganization = VALUE(Catalog.Companies.EmptyRef))
	|
	|		AND (GoodsTable.Ref.Department = &FilterDepartment
	|			OR &FilterDepartment = VALUE(Catalog.BusinessStructure.EmptyRef))
	|
	|		AND (&SelectionBasedOnLineData
	|			OR GoodsTable.Individual = &FilterIndividual
	|			OR &FilterIndividual = VALUE(Catalog.Persons.EmptyRef))
	|
	|		AND (NOT &SelectionBasedOnLineData
	|			OR GoodsTable.Products = &FilterProducts
	|				AND GoodsTable.Characteristic = &FilterCharacteristic
	|				AND GoodsTable.Individual = &FilterIndividual)
	|
	|	UNION ALL
	|
	|	SELECT
	|		GoodsTable.Ref.Organization AS Organization,
	|		GoodsTable.Ref.Department AS Department,
	|		GoodsTable.Individual AS Individual,
	|		GoodsTable.Products AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.LineOfBusiness AS LineOfBusiness,
	|		GoodsTable.CompletionDate_ AS CompletionDate_,
	|		-GoodsTable.Count AS Count
	|		
	|	FROM
	|		Document.OtherGoodsRecordingAsReceived.Goods AS GoodsTable
	|
	|	WHERE
	|		GoodsTable.CompletionDate_ >= &FilterDate
	|		AND GoodsTable.Ref.Date <= &FilterDate
	|		AND GoodsTable.Ref.Posted
	|		AND GoodsTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.PutOutOfOperation)
	|
	|		AND (GoodsTable.Ref.Organization = &FilterOrganization
	|			OR &FilterOrganization = VALUE(Catalog.Companies.EmptyRef))
	|
	|		AND (GoodsTable.Ref.Department = &FilterDepartment
	|			OR &FilterDepartment = VALUE(Catalog.BusinessStructure.EmptyRef))
	|
	|		AND (&SelectionBasedOnLineData
	|			OR GoodsTable.Individual = &FilterIndividual
	|			OR &FilterIndividual = VALUE(Catalog.Persons.EmptyRef))
	|
	|		AND (NOT &SelectionBasedOnLineData
	|			OR GoodsTable.Products = &FilterProducts
	|				AND GoodsTable.Characteristic = &FilterCharacteristic
	|				AND GoodsTable.Individual = &FilterIndividual)
	|			
	|	) AS InventoryInOperation
	|
	|GROUP BY
	|	InventoryInOperation.Organization,
	|	InventoryInOperation.Department,
	|	InventoryInOperation.Individual,
	|	InventoryInOperation.Products,
	|	InventoryInOperation.Characteristic,
	|	InventoryInOperation.LineOfBusiness,
	|	InventoryInOperation.CompletionDate_
	|
	|HAVING
	|	SUM(InventoryInOperation.Count) > 0";
	
	If Not Parameters.ForDynamicList Then
		
		QueryText = QueryText + "
		|
		|ORDER BY
		|	Organization,
		|	Department,
		|	Individual,
		|	Products,
		|	Characteristic,
		|	LineOfBusiness";
		
	EndIf;
	
	FilterDate = ?(
		Parameters.Date <> Undefined And Parameters.Date <> '000101010000', 
		EndOfDay(Parameters.Date) + 1, 
		'000101010000');
	
	FilterOrganization = ?(
		Parameters.Organization <> Undefined, 
		Parameters.Organization, 
		PredefinedValue("Catalog.Companies.EmptyRef"));

	FilterDepartment = ?(
		Parameters.Department <> Undefined, 
		Parameters.Department, 
		PredefinedValue("Catalog.BusinessStructure.EmptyRef"));

	FilterProducts = ?(
		Parameters.Products <> Undefined, 
		Parameters.Products, 
		PredefinedValue("Catalog.Products.EmptyRef"));

	FilterCharacteristic = ?(
		Parameters.Characteristic <> Undefined, 
		Parameters.Characteristic, 
		PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));

	FilterIndividual = ?(
		Parameters.Individual <> Undefined, 
		Parameters.Individual, 
		PredefinedValue("Catalog.Persons.EmptyRef"));
	
	
	SelectionBasedOnLineData = 
		Parameters.Products <> Undefined
		Or Parameters.Characteristic <> Undefined;
	
	If Parameters.ForDynamicList Then
		QueryText = StrReplace(QueryText, "ALLOWED TOP 10", "");
	EndIf;
	
	If Parameters.SelectFirstRecords > 0 Then
		QueryText = StrReplace(QueryText, "TOP 10", "FIRST" + " " + Format(Parameters.SelectFirstRecords, "NG=0;"));
	Else
		QueryText = StrReplace(QueryText, "TOP 10", "");
	EndIf;
	
	QueryOptions = New Structure;
	QueryOptions.Insert("FilterDate", FilterDate);
	QueryOptions.Insert("FilterOrganization", FilterOrganization);
	QueryOptions.Insert("FilterDepartment", FilterDepartment);
	QueryOptions.Insert("FilterProducts", FilterProducts);
	QueryOptions.Insert("FilterCharacteristic", FilterCharacteristic);
	QueryOptions.Insert("FilterIndividual", FilterIndividual);
	QueryOptions.Insert("SelectionBasedOnLineData", SelectionBasedOnLineData);
	
	DescriptionOfSelectionRequest = New Structure("QueryText,QueryOptions", QueryText, QueryOptions);
	
	Return DescriptionOfSelectionRequest;
	
EndFunction

#EndRegion

#EndRegion
