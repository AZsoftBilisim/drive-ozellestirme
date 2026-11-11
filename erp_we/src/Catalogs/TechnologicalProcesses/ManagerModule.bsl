#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Returns the names of attributes, which should not appear in the list of details of the processing Gruposeincentivos.
//
//	Returns:
//		Array of String - an array of the names of the details.
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	
	NotAttributesToEdit.Add("MaterialsAndServices.Operation");
	NotAttributesToEdit.Add("LaborCosts.Operation");
	
	Return NotAttributesToEdit;
	
EndFunction

// Checks the use of the object
//
// Parameters:
//  Parameters		- Structure - contains an object that you want to check for usage
//  StorageAddress	- String - address of the storage where the verification result will be placed.
//
Procedure CheckObjectUsage(Parameters, StorageAddress) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	TRUE AS ThereAreRefs
	|FROM
	|	Catalog.ManufacturingOperations AS SearchTable
	|WHERE
	|	SearchTable.ContainsTechnologicalProcess
	|	AND SearchTable.TechnologicalProcess = &Object
	|";
	
	Query.SetParameter("Object", Parameters.Object);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	ThereAreRefs = Not Result.IsEmpty();
	
	PutToTempStorage(ThereAreRefs, StorageAddress);

EndProcedure

// Function-constructor of the structure for selecting process data.
//
// Returns:
//  Structure - structure with process data sampling parameters:
//  * Products - CatalogRef.Products - Products
//  * Characteristic - CatalogRef.ItemsCharacteristics - Characteristic
//  * Department - CatalogRef.BusinessStructure - Department
//  * ProductionDispatcherBusinessUnit - CatalogRef.BusinessStructure - Department
//	* ReferenceOrder - DocumentRef - ReferenceOrder
//  * LineOfBusiness - CatalogRef.LinesOfBusiness - Direction of activity
//  * ProductionStart - Date - production start date
//  * BillOfMaterials - CatalogRef.BillsOfMaterials - BillOfMaterials
//  * BOMStage - CatalogRef.ProductionStages - specification stage
//  * Count - Number - number of products
Function ItemData_3() Export
	
	ItemData_3 = New Structure;
	
	ItemData_3.Insert("Products");
	ItemData_3.Insert("Characteristic");
	ItemData_3.Insert("Count", 0); // quantity of the main PC product
	
	ItemData_3.Insert("Department");
	ItemData_3.Insert("ProductionDispatcherBusinessUnit");
	ItemData_3.Insert("ReferenceOrder"); // production order
	ItemData_3.Insert("LineOfBusiness");
	ItemData_3.Insert("ProductionStart");
	
	ItemData_3.Insert("BillOfMaterials");
	ItemData_3.Insert("BOMStage");
	
	Return ItemData_3;
	
EndFunction

// Process data sampling parameters
// 
// Parameters:
//  ListOfData - String
//  TempTablesManager - TempTablesManager
// 
// Returns:
//  Structure - Data Sampling Parameters:
//		* ListOfData - Array of String
//		* TempTablesManager - Undefined - 
//		* UpdateCommunicationKeys - Boolean - 
//		* ShiftingFormulas - Number - 
//  	* PerformDirectiveSubstitutions - Boolean - if True, then directive substitutions will be performed
Function DataSamplingParameters(ListOfData = Undefined, TempTablesManager = Undefined) Export
	
	Result = New Structure;
	
	If ValueIsFilled(ListOfData) Then
		Result.Insert("ListOfData", StrSplit(ListOfData,","));
	Else
		Result.Insert("ListOfData", StrSplit("Operations,MaterialsAndServices,LaborCosts,PropertyMapping,SelectionByProperties",","));
	EndIf;
	
	Result.Insert("TempTablesManager", TempTablesManager);
	Result.Insert("UpdateCommunicationKeys", False);
	Result.Insert("ShiftingFormulas", 0);
	Result.Insert("PerformDirectiveSubstitutions", AlternativeMaterials.UseDirectiveSubstitutions());
	
	Return Result;
	
EndFunction

// The process data is "as is" (without parameterization calculation).
// 
// Parameters:
//  TechnologicalProcess - CatalogRef.TechnologicalProcesses
//  SelectionParameters - See DataSamplingParameters
// 
// Returns:
//  Structure - From:
//		* Operations - ValueTable - operation table:
//			** Operation - CatalogRef.ManufacturingOperations
//			** Description - String - name of operation
//		* MaterialsAndServices - ValueTable - table of materials:
//			** LineNumber - Number - the line number table
//			** ConnectionKey - UUID - the link key table
//		* LaborCosts - ValueTable - Table Of Labor Costs:
//			** LineNumber - Number - the line number table
//			** ConnectionKey - UUID - the link key table
Function ProcessData_(TechnologicalProcess, SelectionParameters) Export
	
	ListOfData             = SelectionParameters.ListOfData;
	QueryTexts              = New ValueList;
	RequestSeparatorInPacket_ = Common.QueryBatchSeparator();
	
	QueryText = QueryTextStructureOfProcessDetails();
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "Attributes");
	
	If ListOfData.Find("Operations") <> Undefined Then
		
		QueryText = "
		|SELECT
		|	T.Ref                 AS Operation,
		|	T.Id          AS OperationID,
		|	T.Description           AS Description,
		|	T.Presentation          AS OperationPresentation,
		|
		|	T.OperationKind            AS OperationKind,
		|	T.UnitOfMeasure       AS UnitOfMeasure,
		|	T.Load               AS Load,
		|	T.Continuous            AS Continuous,
		|	T.Repeatable         AS Repeatable,
		|	T.Skippable        AS Skippable,
		|	T.TransferLot     AS TransferLot,
		|	T.Control               AS Control,
		|
		|	T.OperationNumber          AS OperationNumber,
		|	T.NextOperation AS NextOperation,
		|	T.OperationNumber          AS OriginalOperationNumber,
		|	T.NextOperation AS SourceNumberOfNextOperation,
		|
		|	T.Count             AS Count,
		|
		|	T.SetupSettings         AS SetupSettings,
		|	T.ProductionArea                AS ProductionArea,
		|
		|	&TextDetailsOfTransactionExecutor,
		|	&TextDetailsForCalculatingOperationExecutionTime
		|FROM
		|	Catalog.ManufacturingOperations AS T
		|WHERE
		|	T.Owner = &TechnologicalProcess
		|	AND NOT T.DeletionMark
		|
		|ORDER BY
		|	T.OperationNumber,
		|	T.Description
		|";
		
		QueryText = StrReplace(
			QueryText,
			"&TextDetailsOfTransactionExecutor",
			Catalogs.ManufacturingOperations.QueryTextAttributesOfContractorOfOperation("T"));
		
		QueryText = StrReplace(
			QueryText,
			"&TextDetailsForCalculatingOperationExecutionTime",
			Catalogs.ManufacturingOperations.QueryTextAttributesForCalculatingTimeOfOperation("T"));
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "Operations");
		
	EndIf;
	
	If ListOfData.Find("MaterialsAndServices") <> Undefined Then
		
		QueryText = "
		|SELECT
		|	0                              AS Id,
		|	T.*,
		|	T.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces) AS PieceUnitOfMeasure,
		|	T.Products.ItemsType AS ItemsType,
		|	CASE
		|		WHEN T.Products.UseVariants IN (
		|					VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
		|					VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
		|					VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ItemVariantsAreUsed,
		|	CASE
		|		WHEN (T.MethodOfProductsAutoselection <> VALUE(Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData)
		|				OR T.MethodOfItemVariantAutoselection <> VALUE(Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData))
		|			THEN TRUE
		|		ELSE FALSE
		|	END                AS UseAutoselection,
		|	PRESENTATION("""")  AS AutoselectionDetails,
		|	PRESENTATION("""")  AS Formula,
		|	0                    AS Count,
		|	UNDEFINED         AS PackageData,
		|	&TextOfDirectiveReplacementField
		|
		|FROM
		|	Catalog.TechnologicalProcesses.MaterialsAndServices AS T
		|
		|		LEFT JOIN TT_SelectionByProperties AS TT_SelectionByProperties
		|		ON T.ConnectionKey = TT_SelectionByProperties.ConnectionKey
		|
		|WHERE
		|	T.Ref = &TechnologicalProcess
		|	AND ISNULL(TT_SelectionByProperties.Used, TRUE)
		|
		|ORDER BY
		|	T.LineNumber
		|";
		
		TextOfDirectiveReplacementField = ProductDataManagement.QueryTextOfDirectiveReplacementField(SelectionParameters, "T");
		QueryText = StrReplace(QueryText, "&TextOfDirectiveReplacementField" , TextOfDirectiveReplacementField);
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "MaterialsAndServices");
		
		#Region PackageData_
		
		TableDetails = ProductDataManagement.DescriptionOfQueryTextTablePackageData();
		TableDetails.TableName = "Catalog.TechnologicalProcesses.MaterialsAndServices";
		TableDetails.ConditionText = "T.Ref = &TechnologicalProcess";
		QueryText = ProductDataManagement.QueryTextPackageData_(CommonClientServer.ValueInArray(TableDetails));
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "PackageData_");
		
		#EndRegion
		
	EndIf;
	
	If ListOfData.Find("LaborCosts") <> Undefined Then
		
		QueryText = "
		|SELECT
		|	0                   AS Id,
		|	T.*,
		|	PRESENTATION("""") AS Formula
		|FROM
		|	Catalog.TechnologicalProcesses.LaborCosts AS T
		|
		|		LEFT JOIN TT_SelectionByProperties AS TT_SelectionByProperties
		|		ON T.ConnectionKey = TT_SelectionByProperties.ConnectionKey
		|
		|WHERE
		|	T.Ref = &TechnologicalProcess
		|	AND ISNULL(TT_SelectionByProperties.Used, TRUE)
		|
		|ORDER BY
		|	T.LineNumber
		|";
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "LaborCosts");
		
	EndIf;
	
	If ListOfData.Find("PropertyMapping") <> Undefined Then
	
		QueryText = "
		|SELECT
		|	T.*
		|FROM
		|	Catalog.TechnologicalProcesses.PropertyMapping AS T
		|WHERE
		|	T.Ref = &TechnologicalProcess
		|
		|ORDER BY
		|	T.LineNumber
		|";
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "PropertyMapping");
		
	EndIf;
	
	If ListOfData.Find("SelectionByProperties") <> Undefined Then
		
		QueryText = "
		|SELECT
		|	T.*
		|FROM
		|	Catalog.TechnologicalProcesses.SelectionByProperties AS T
		|WHERE
		|	T.Ref = &TechnologicalProcess
		|
		|ORDER BY
		|	T.LineNumber
		|";
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "SelectionByProperties");
		
	EndIf;
	
	TempTablesManager = SelectionParameters.TempTablesManager;
	If TempTablesManager = Undefined Then
		TempTablesManager = New TempTablesManager();
	EndIf;
	If TempTablesManager.Tables.Find("TT_SelectionByProperties") = Undefined Then
		ProductDataManagement.CreateTTSelectionBasedOnProperties(TechnologicalProcess, TempTablesManager);
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("TechnologicalProcess", TechnologicalProcess);
	
	SetPrivilegedMode(True);
	Tables = TMCommonUse.UploadResultsOfQuery(Query, QueryTexts);
	SetPrivilegedMode(False);
	
	If SelectionParameters.UpdateCommunicationKeys Then
		ProductDataManagement.UpdateObjectLinkKeys(Tables);
	EndIf;
	HandleShiftingFormulas(Tables, SelectionParameters.ShiftingFormulas);
	
	StructureOfData = StructureOfProcessDetails();
	
	If Tables.Attributes.Count() > 0 Then
		FillPropertyValues(StructureOfData, Tables.Attributes[0]);
	EndIf;
	
	For Each TableName In ListOfData Do
		
		Table = Tables[TableName];
		
		If TableName = "MaterialsAndServices" Then
			ProductDataManagement.FillInPackingDataInDataset(Table, Tables.PackageData_);
		EndIf;
		
		StructureOfData.Insert(TableName, Table);
		
	EndDo;
	
	Return StructureOfData;
	
EndFunction

// Process data calculated according to a specific nomenclature.
// 
// Parameters:
//  TechnologicalProcess - CatalogRef.TechnologicalProcesses
//  TechnologicalProcessFactor - Number - Coefficient of application of the technological process
//  ItemData_3 - See ItemData_3
//  SelectionParameters - See DataSamplingParameters
//  Filter - Structure,Undefined - Selection structure
// 
// Returns:
//  See ProcessData_
Function ProcessDataByNomenclature(TechnologicalProcess, TechnologicalProcessFactor, ItemData_3, SelectionParameters, Filter = Undefined) Export
	
	If SelectionParameters.TempTablesManager = Undefined Then
		SelectionParameters.TempTablesManager = New TempTablesManager();
	EndIf;
	
	ProductDataManagement.CreateTTSelectionBasedOnProperties(
		TechnologicalProcess, SelectionParameters.TempTablesManager, ItemData_3);
	
	ListOfTS = TabularPartsWithParameterization();
	TAData = ProcessData_(TechnologicalProcess, SelectionParameters);
	
	AutoSelectionParameters = ProductDataManagement.GetAutoSelectionParameters(TechnologicalProcess, ItemData_3);
	For Each LineOfListOfTS In ListOfTS Do
		If LineOfListOfTS.ThereIsAutoselection And TAData.Property(LineOfListOfTS.TSName) Then
			ProductDataManagement.ProcessSettingsForAutomaticSelectionOfProducts(TAData[LineOfListOfTS.TSName], AutoSelectionParameters);
		EndIf;
	EndDo;
	
	PerformDirectiveReplacementsOfMaterials(ItemData_3, TAData);
	
	DataForCalculation = DataForCalculationByFormulas(TechnologicalProcess, ItemData_3, TAData);
	
	For Each LineOfListOfTS In ListOfTS Do
		If Not TAData.Property(LineOfListOfTS.TSName) Then
			Continue;
		EndIf;
		If LineOfListOfTS.ThereIsCalculationAccordingToFormula Then
			ProductDataManagement.CalculateNumberInRows(
				TAData, LineOfListOfTS.TSName, LineOfListOfTS.ThereArePackages, DataForCalculation);
		EndIf;
		For Each String In TAData[LineOfListOfTS.TSName] Do
			If IsBlankString(String.QuantityCalculationAlgorithm) Then
				If LineOfListOfTS.ThereArePackages Then
					String.NumberOfPackages = String.NumberOfPackages * TechnologicalProcessFactor;
					If String.PackageData.Denominator <> 0 Then
						String.Count = String.NumberOfPackages * String.PackageData.Numerator / String.PackageData.Denominator;
					EndIf;
				Else
					String.Count = String.Count * TechnologicalProcessFactor;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
		
	If TAData.Property("Operations") Then
		Operations = Catalogs.ManufacturingOperations.OperationTableConstructor();
		For Each Operation In TAData.Operations Do
			NewRow = Operations.Add();
			FillPropertyValues(NewRow, Operation);
			NewRow.QuantityPerBatch = NewRow.Count * TechnologicalProcessFactor;
			ProductionAccountingClientServer.CalculateTotalOperationTime(NewRow, TechnologicalProcessFactor);
			NewRow.TechnologicalProcess = TechnologicalProcess;
			NewRow.TechnologicalProcessFactor = TechnologicalProcessFactor;
		EndDo;
		TAData.Operations = Operations;
	EndIf;
	
	UnpackCompositionOfSets(TAData, ItemData_3);
	
	ApplySelection(TAData, SelectionParameters, Filter);
	
	Return TAData;
	
EndFunction

// Checks the sequence of operations
//
// Parameters:
//  TechnologicalProcess		- CatalogRef.TechnologicalProcesses - the technological process whose operations need to be checked
//  Cancel				- Boolean - indicates whether the current action is canceled.
//
// Returns:
//   Boolean   - true if the sequence of operations is correct.
//
Function SequenceOfOperationsIsCorrect(TechnologicalProcess, Cancel = False) Export
	
	TheStructureOfTheMessages = ProductionProcessEditor.StructureOfOperationSequenceChecks();
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("NameOfOperationsCatalog",     "ManufacturingOperations");
	ParametersStructure.Insert("OperationNumberField",          "OperationNumber");
	ParametersStructure.Insert("NextOperationNumberField", "NextOperation");
	
	SequenceIsCorrect = ProductionProcessEditor.SequenceOfOperationsIsCorrect(
		TechnologicalProcess, ParametersStructure, TheStructureOfTheMessages, Cancel);
	
	Return SequenceIsCorrect;
	
EndFunction

// Fills in a technological process by another technological process
//
// Parameters:
//  Receiver - CatalogObject.TechnologicalProcesses, FormDataStructure - technological process
//		to which the operations will be copied.
//  Source - CatalogRef.TechnologicalProcesses - the technological process whose operations need to be copied.
//	ReceiverLink_ - CatalogRef.TechnologicalProcesses - a link to the technological process to be filled in.
//
// Returns:
//   Boolean   - true if the copy is successful.
//
Function FillInTheInformationOnTheTechnologicalProcess(Receiver, Source, ReceiverLink_) Export

	SourceObject_ = Source.GetObject();

	Receiver.MaterialsAndServices.Load(SourceObject_.MaterialsAndServices.Unload());
	Receiver.LaborCosts.Load(SourceObject_.LaborCosts.Unload());
	
	Query = New Query(
	"SELECT
	|	CatalogManufacturingOperations.Ref AS Ref
	|FROM
	|	Catalog.ManufacturingOperations AS CatalogManufacturingOperations
	|WHERE
	|	CatalogManufacturingOperations.Owner = &Source
	|	AND NOT CatalogManufacturingOperations.DeletionMark");
	Query.SetParameter("Source", Source);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		LinkToOperation = Catalogs.ManufacturingOperations.CopyProcessOperation(Selection.Ref, ReceiverLink_);
		If Not ValueIsFilled(LinkToOperation) Then
			Return False;
		EndIf;
		
		// Fill in the link with the operation
		FoundRows = Receiver.MaterialsAndServices.FindRows(New Structure("OperationEdit", Selection.Ref));
		For Each RowData In FoundRows Do
			RowData.OperationEdit = LinkToOperation;
		EndDo;
		FoundRows = Receiver.LaborCosts.FindRows(New Structure("OperationEdit", Selection.Ref));
		For Each RowData In FoundRows Do
			RowData.OperationEdit = LinkToOperation;
		EndDo;
		
	EndDo;

	Return True;
	
EndFunction

// Returns the coefficient of application of the technological process
//
// Parameters:
//  MainProductCount - Number - the quantity of the main product of the resource specification.
//  TechnologicalProcess - CatalogRef.TechnologicalProcesses - the technological process for calculating the coefficient.
// 
// Returns:
//  Number - the calculated coefficient.
//
Function ProcessRatioForSpecification(MainProductCount, TechnologicalProcess) Export
	
	SetPrivilegedMode(True);
	TAData = Common.ObjectAttributesValues(
			TechnologicalProcess, "CalculateFactor,NumeratorFactor,FactorDenominator");
	SetPrivilegedMode(False);
	
	If TAData.CalculateFactor = False Then
		
		Result = 1;
		
	ElsIf ValueIsFilled(TAData.FactorDenominator) Then
		
		Result = TAData.NumeratorFactor / TAData.FactorDenominator * MainProductCount;
		
	Else
		
		Result = 0;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Indicates that the process coefficient is being calculated.
// 
// Parameters:
//  TechnologicalProcess - CatalogRef.TechnologicalProcesses
// 
// Returns:
//  Boolean
Function CoefficientOfTechnologicalProcessIsCalculated(TechnologicalProcess) Export
	
	Result = False;
	
	If ValueIsFilled(TechnologicalProcess) Then
		SetPrivilegedMode(True);
		Result = Common.ObjectAttributeValue(TechnologicalProcess, "CalculateFactor");
		SetPrivilegedMode(False);
	EndIf;
	
	Return Result;
	
EndFunction

// Creates a copy of the technological process with all technological operations.
//
// Parameters:
//  Source - CatalogRef.TechnologicalProcesses - the technological process that needs to be copied.
// 
// Returns:
//  CatalogRef.TechnologicalProcesses - link to the created technological process.
//
Function CopyWorkflowWithOperations(Source) Export
	
	Ref = Undefined;
	
	BeginTransaction();
	
	Try
		
		Ref = Catalogs.TechnologicalProcesses.GetRef();
		
		Object = Source.Copy();
		Object.Description = Object.Description + " " + NStr("vi = '(bản sao)';
															|ru = '(копия)';
															|en = '(copy)'; fa = '(copy)';
															|it = '(copia)';
															|pl = '(copy)';
															|tr = '(kopya)'");
		
		If Not FillInTheInformationOnTheTechnologicalProcess(Object, Source, Ref) Then
			Raise NStr("vi = 'Không thể sao chép quy trình kỹ thuật.';
						|ru = 'Не удалось скопировать технологический процесс.';
						|en = 'Cannot copy technological process.'; fa = 'Cannot copy technological process.';
						|it = 'Non è stato possibile copiare il processo tecnologico.';
						|pl = 'Nie udało się skopiować procesu technologicznego.';
						|tr = 'Teknolojik süreç kopyalanamadı.'");
		EndIf;
		
		ProductDataManagement.UpdateObjectLinkKeys(Object);
		
		Object.SetNewObjectRef(Ref);
		Object.Write();
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
 		WriteLogEvent(
			NStr("vi = 'Sao chép quy trình công nghệ';
				|ru = 'Копирование технологического процесса';
				|en = 'Copying technological process'; fa = 'Copying technological process';
				|it = 'Copia del processo tecnologico';
				|pl = 'Kopiowanie procesu technologicznego';
				|tr = 'Teknolojik sürecin kopyalanması'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
		Raise;
		
	EndTry;
	
	Return Ref;
	
EndFunction

// Returns the values of the process details
// 
// Parameters:
// 	TechnologicalProcess - CatalogRef.TechnologicalProcesses
// Returns:
// 	See StructureOfProcessDetails
Function ValuesOfProcessDetails(TechnologicalProcess) Export
	
	Result = StructureOfProcessDetails();
	
	If ValueIsFilled(TechnologicalProcess) Then
		
		Query = New Query;
		Query.Text = QueryTextStructureOfProcessDetails();
		Query.SetParameter("TechnologicalProcess", TechnologicalProcess);
		
		SetPrivilegedMode(True);
		Selection = Query.Execute().Select();
		SetPrivilegedMode(False);
		
		If Selection.Next() Then
			FillPropertyValues(Result, Selection);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the structure of the process details
//
// Returns:
//  Structure - Contains:
//   * TechnologicalProcess - CatalogRef.TechnologicalProcesses
//   * Status - EnumRef.TechnologicalProcessStatuses
//   * Presentation - String
//   * ForFinishedProductsKind - CatalogRef.ItemKinds
//   * Department - CatalogRef.BusinessStructure
//   * CalculateFactor - Boolean
//   * NumeratorFactor - Number
//   * FactorDenominator - Number
//   * ContainsResourcesParametrization - Boolean
Function StructureOfProcessDetails() Export
	
	Result = New Structure;
	
	Result.Insert("TechnologicalProcess",     Catalogs.TechnologicalProcesses.EmptyRef());
	Result.Insert("Status",                     Enums.TechnologicalProcessStatuses.EmptyRef());
	Result.Insert("Presentation",              "");
	Result.Insert("ForFinishedProductsKind",             Catalogs.ItemKinds.EmptyRef());
	Result.Insert("Department",              Catalogs.BusinessStructure.EmptyRef());
	Result.Insert("CalculateFactor",    False);
	Result.Insert("NumeratorFactor",       0);
	Result.Insert("FactorDenominator",     0);
	Result.Insert("ContainsResourcesParametrization", False);
	
	Return Result;
	
EndFunction

#Region Commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Command = BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm,ListForm,ChoiceForm";
	EndIf;
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "TechnologicalProcess";
	PrintCommand.Presentation = NStr("vi = 'Quy trình công nghệ';
									|ru = 'Технологический процесс';
									|en = 'Technological process'; fa = 'فرایند فناورانه';
									|it = 'Processo tecnologico';
									|pl = 'Proces technologiczny';
									|tr = 'Teknolojik süreç'");
	PrintCommand.CheckPostingBeforePrint = True;
	
EndProcedure

#EndRegion

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

#EndIf

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Parameterization

Function TabularPartsWithParameterization()
	
	Result = ProductDataManagement.TablePartsWithParameterizationConstructor();
	
	NewRow = Result.Add();
	NewRow.TSName = "MaterialsAndServices";
	NewRow.ThereIsAutoselection        = True;
	NewRow.ThereIsSelectionByProperties = True;
	NewRow.ThereIsCalculationAccordingToFormula  = True;
	NewRow.ThereArePackages         = True;
	
	NewRow = Result.Add();
	NewRow.TSName = "LaborCosts";
	NewRow.ThereIsSelectionByProperties = True;
	NewRow.ThereIsCalculationAccordingToFormula  = True;
	
	Return Result;
	
EndFunction

#Region FormulasConstructor

Function UploadDataForFormulaConstructor(Object, TSName, RowData = Undefined) Export
	
	DescriptionOfSources = DescriptionOfOperandDataSources(Object);
	
	DescriptionOfSources["MainProduct"].SourceOfProductProperties = Object.ForFinishedProductsKind;
	
	ProductDataManagement.SupplementDescriptionOfSourcesWithCompositionOfOperands(
		DescriptionOfSources, Object, TSName, RowData);
	
	Return DescriptionOfSources;
	
EndFunction

#EndRegion

#Region DataSources

// Constructor of the source structure for calculation using formulas
// 
// Returns:
// 	Structure - From:
// * ItemData_3 - see the given nomenclatedextended
// * MaterialsAndServices - See ProductDataManagement.CreateTableOfDataSourcesForCalculationByFormulas
//
Function StructureOfSourcesForCalculationByFormulas() Export
	
	DataSources = New Structure;
	
	DataSources.Insert("ItemData_3"); // item data
	DataSources.Insert("MaterialsAndServices", ProductDataManagement.CreateTableOfDataSourcesForCalculationByFormulas());
	
	Return DataSources;
	
EndFunction

// Description of operand sources for formulas
// 
// Parameters:
// 	Object - FormDataStructure,Undefined - object data
// Returns:
// 	Structure - From:
// 		* MainProduct - See ProductDataManagement.CreateDescriptionsOfOperandDataSource
// 		* MaterialsAndServices - See ProductDataManagement.CreateDescriptionsOfOperandDataSource
// 		* Material - See ProductDataManagement.CreateDescriptionsOfOperandDataSource
// 		* Department - See ProductDataManagement.CreateDescriptionsOfOperandDataSource
// 		* ReferenceOrder - See ProductDataManagement.CreateDescriptionsOfOperandDataSource
// 		* LineOfBusiness - See ProductDataManagement.CreateDescriptionsOfOperandDataSource
// 		* BillOfMaterials - See ProductDataManagement.CreateDescriptionsOfOperandDataSource
//
Function DescriptionOfOperandDataSources(Object = Undefined) Export
	
	Result = New Structure;
	
	TypeDescriptionNumber = New TypeDescription("Number");
	
	// [MainProduct]
	SourcePresentation = NStr("vi = 'Sản phẩm chính';
								|ru = 'Основное изделие';
								|en = 'Main product'; fa = 'محصول اصلی';
								|it = 'Prodotto principale';
								|pl = 'Wyrób podstawowy';
								|tr = 'Nihai ana ürün'");
	LongDesc = ProductDataManagement.CreateDescriptionsOfOperandDataSource(
		"MainProduct", SourcePresentation);
	
	SourcePresentation = NStr("vi = 'Số lượng';
								|ru = 'Количество';
								|en = 'Quantity'; fa = 'مقدار';
								|it = 'Quantità';
								|pl = 'Ilość';
								|tr = 'Miktar'");
	NewAttribute = ProductDataManagement.CreateDescriptionsOfOperandDataSourceProps(
		"Count", TypeDescriptionNumber, SourcePresentation);
	LongDesc.Attributes.Add(NewAttribute);
	
	LongDesc.ContainsProductProperties = True;
	
	Result.Insert("MainProduct", LongDesc);
	
	// [Materials and services],[Material]
	LongDesc = ProductDataManagement.CreateDescriptionsOfOperandDataSource(
		"MaterialsAndServices", NStr("vi = 'Nguyên vật liệu phụ';
									|ru = 'Вспомогательные материалы';
									|en = 'Auxiliary materials'; fa = 'مواد کمکی';
									|it = 'Materiali ausiliari';
									|pl = 'Materiały pomocnicze';
									|tr = 'Yardımcı malzemeler'"));
	
	NewAttribute = ProductDataManagement.CreateDescriptionsOfOperandDataSourceProps(
		"Count", NStr("vi = 'Số lượng';
						|ru = 'Количество';
						|en = 'Quantity'; fa = 'مقدار';
						|it = 'Quantità';
						|pl = 'Ilość';
						|tr = 'Miktar'"));
	LongDesc.Attributes.Add(NewAttribute);
	
	LongDesc.ContainsProductProperties = True;
	LongDesc.Collection                    = True;
	
	Result.Insert("MaterialsAndServices", LongDesc);
	
	LongDesc = ProductDataManagement.CreateDescriptionsOfOperandDataSource(
		"Material", NStr("vi = 'Nguyên vật liệu (dòng hiện tại)';
						|ru = 'Материал (текущая строка)';
						|en = 'Material (current line)'; fa = 'Material (current line)';
						|it = 'Materiale (riga corrente)';
						|pl = 'Materiał (wiersz bieżący)';
						|tr = 'Malzeme (mevcut satır)'"));
	
	LongDesc.ContainsProductProperties = True;
	LongDesc.TSName = "MaterialsAndServices";
	
	Result.Insert("Material", LongDesc);
	
	// [Department]
	LongDesc = ProductDataManagement.CreateDescriptionsOfOperandDataSource(
		"Department", NStr("vi = 'Bộ phận';
							|ru = 'Подразделение';
							|en = 'Business unit'; fa = 'Business unit';
							|it = 'Reparto';
							|pl = 'Dział';
							|tr = 'Departman'"));
	
	LongDesc.ContainsProperties = True;
	LongDesc.PropertiesSet     = PropertyManager.PropertiesSetByName("Catalog_BusinessStructure");
	
	Result.Insert("Department", LongDesc);
	
	// [ReferenceOrder]
	LongDesc = ProductDataManagement.CreateDescriptionsOfOperandDataSource(
		"ReferenceOrder", NStr("vi = 'Đơn hàng sản xuất';
								|ru = 'Заказ на производство';
								|en = 'Production order'; fa = 'سفارش تولید';
								|it = 'Ordine di produzione';
								|pl = 'Zlecenie produkcyjne';
								|tr = 'Üretim emri'"));
	
	LongDesc.ContainsProperties = True;
	LongDesc.PropertiesSet     = PropertyManager.PropertiesSetByName("Document_ProductionOrder2_2");
	
	Result.Insert("ReferenceOrder", LongDesc);
	
	// [LineOfBusiness]
	If GetFunctionalOption("GenerateFinancialResult") Then
		
		LongDesc = ProductDataManagement.CreateDescriptionsOfOperandDataSource("LineOfBusiness", NStr("vi = 'Lĩnh vực hoạt động';
																										|ru = 'Направление деятельности';
																										|en = 'Line of business'; fa = 'خط کسب‌وکار';
																										|it = 'Settore di attività';
																										|pl = 'Rodzaj działalności';
																										|tr = 'İş kolu'"));
		
		LongDesc.ContainsProperties = True;
		LongDesc.PropertiesSet     = PropertyManager.PropertiesSetByName("Catalog_LinesOfBusiness");
		
		Result.Insert("LineOfBusiness", LongDesc);
		
	EndIf;
	
	// [BillOfMaterials]
	SourcePresentation = NStr("vi = 'Bảng kê chi tiết';
								|ru = 'Спецификация';
								|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
								|it = 'Specifica';
								|pl = 'Specafikacja';
								|tr = 'Ürün reçetesi'");
	LongDesc = ProductDataManagement.CreateDescriptionsOfOperandDataSource(
		"BillOfMaterials", SourcePresentation);
		
	LongDesc.ContainsProperties = True;
	LongDesc.PropertiesSet     = PropertyManager.PropertiesSetByName("Catalog_BillsOfMaterials");
	
	Result.Insert("BillOfMaterials", LongDesc);
	
	Return Result;
	
EndFunction

// Constructor of the data source for calculation using formulas
// 
// Parameters:
// 	DataPath - See ProductDataManagement.ParametersForCalculationByFormulas
// 	DataSources - See StructureOfSourcesForCalculationByFormulas
// Returns:
// 	See ProductDataManagement.CreateSourceDataStructureForCalculationUsingFormulas
//
Function DataSourceForFormulaCalculations(DataPath, DataSources) Export
	
	Source = Undefined;
	
	If DataPath.Key = "MainProduct" Then
		
		Source = ProductDataManagement.CreateSourceDataStructureForCalculationUsingFormulas();
		FillPropertyValues(Source, DataSources.ItemData_3);
		
	ElsIf DataPath.Key = "MaterialsAndServices" Then
		
		RowData = DataSources[DataPath.Key].Find(DataPath.LineNumber, "LineNumber");
		
		If RowData <> Undefined Then
			Source = ProductDataManagement.CreateSourceDataStructureForCalculationUsingFormulas();
			FillPropertyValues(Source, RowData);
		EndIf;
		
	ElsIf DataPath.Key = "Material" Then
		
		Source = ProductDataManagement.CreateSourceDataStructureForCalculationUsingFormulas();
		FillPropertyValues(Source, DataPath.RowData);
		
	Else
		
		Structure = New Structure(DataPath.Key);
		
		FillPropertyValues(Structure, DataSources.ItemData_3);
		
		Source = Structure[DataPath.Key];
		
	EndIf;
	
	Return Source;
	
EndFunction

#EndRegion

#Region CalculationByFormulas

Function DataForCalculationByFormulas(TechnologicalProcess, ItemData_3, TAData)
	
	DescriptionOfTS = TabularPartsWithParameterization();
	
	ArrayOfTables = New Array;
	For Each LineOfListOfTS In DescriptionOfTS Do
		If LineOfListOfTS.ThereIsCalculationAccordingToFormula Then
			ProductDataManagement.AddTableForCalculationByFormulas(ArrayOfTables, TAData, LineOfListOfTS.TSName);
		EndIf;
	EndDo;
	
	DescriptionOfSources  = DescriptionOfOperandDataSources();
	ParametersForCalculation = ProductDataManagement.ParametersForCalculationByFormulas(DescriptionOfSources, ArrayOfTables);
	
	If Not ValueIsFilled(ParametersForCalculation) Then
		Return Undefined;
	EndIf;
	
	DataSources = StructureOfSourcesForCalculationByFormulas();
	For Each KeyAndValue In DataSources Do
		If TAData.Property(KeyAndValue.Key) Then
			For Each String In TAData[KeyAndValue.Key] Do
				Source = DataSources[KeyAndValue.Key]; // ValueTable
				FillPropertyValues(Source.Add(), String);
			EndDo;
		EndIf;
	EndDo;
	DataSources.ItemData_3 = ItemData_3;
	
	SourcesOfParameterValues = ProductDataManagement.CreateTableOfSourcesOfParameterValuesForCalculationByFormulas();
	
	ProductDataManagement.SupplementTableOfSourcesOfParameterValuesForCalculationByFormulas(
		Catalogs.TechnologicalProcesses,
		SourcesOfParameterValues,
		DataSources,
		DescriptionOfSources,
		ParametersForCalculation);
		
	ProductDataManagement.FillInParameterValuesForCalculationByFormulas(SourcesOfParameterValues);
	
	DataForCalculation = ProductDataManagement.DataForCalculationByFormulas(
		Catalogs.TechnologicalProcesses,
		ParametersForCalculation,
		DescriptionOfSources,
		DataSources);
		
	Return DataForCalculation;
	
EndFunction

#EndRegion

#EndRegion

#Region Sets

Procedure UnpackCompositionOfSets(TAData, ItemData_3)
	
	DataSet = Undefined;
	If Not TAData.Property("MaterialsAndServices", DataSet) Then
		Return;
	EndIf;
	
	ParametersForObtainingComposition = ProductDataManagement.ParametersForObtainingCompositionOfSetInProduction();
	ParametersForObtainingComposition.AssigneeBusinessUnit = ItemData_3.Department;
	ParametersForObtainingComposition.ReferenceOrder             = ItemData_3.ReferenceOrder;
	ParametersForObtainingComposition.ProductionStart       = ItemData_3.ProductionStart;
	ParametersForObtainingComposition.ProductionDispatcherBusinessUnit   = ItemData_3.ProductionDispatcherBusinessUnit;
	ParametersForObtainingComposition.LineOfBusiness  = ItemData_3.LineOfBusiness;
	ParametersForObtainingComposition.Count               = ItemData_3.Count;
	ParametersForObtainingComposition.Product                  = ItemData_3.Products;
	ParametersForObtainingComposition.ItemVariantOfProduct    = ItemData_3.Characteristic;
	ParametersForObtainingComposition.ProductSpecification      = ItemData_3.BillOfMaterials;
	ParametersForObtainingComposition.ProductSpecificationStage  = ItemData_3.BOMStage;
	
	ProductDataManagement.UnpackCompositionOfProcessKits(DataSet, ParametersForObtainingComposition);
	
EndProcedure

#EndRegion

#Region ListOfTechnologicalProcesses

// Sets the conditional design of the list of technological processes
// 
// Parameters:
// 	ConditionalAppearance - DataCompositionConditionalAppearance - conditional list design
Procedure EstablishConditionalAppearanceOfListOfTechnologicalProcesses(ConditionalAppearance) Export
	
	// Design of the technological process in development
	Item = ConditionalAppearance.Items.Add();

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TechnologicalProcessStatuses.UnderDevelopment;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	
	// Design of a closed technological process
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TechnologicalProcessStatuses.Closed;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
	
EndProcedure

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
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "TechnologicalProcess") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"TechnologicalProcess",
			NStr("vi = 'Quy trình công nghệ';
				|ru = 'Технологический процесс';
				|en = 'Technological process'; fa = 'فرایند فناورانه';
				|it = 'Processo tecnologico';
				|pl = 'Proces technologiczny';
				|tr = 'Teknolojik süreç'"),
			ToFormPrintedFormOfTechnologicalProcess(ObjectsArray, PrintObjects));
		
	EndIf;
	
	PrintFormGeneration.FillInSendingParameters(
		OutputParameters.SendOptions,
		ObjectsArray,
		PrintFormsCollection);
	
EndProcedure

// Manufacturing operation

Function ToFormPrintedFormOfTechnologicalProcess(ObjectsArray, PrintObjects)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PageOrientation = PageOrientation.Portrait;
	
	Template = PrintManagement.PrintFormTemplate("Catalog.TechnologicalProcesses.PrintForm");
	FirstDocument = True;
	
	DataForPrint = DataForPrintingProcess(ObjectsArray);
	
	HeaderSelection = DataForPrint.HeaderSelection;
	
	While HeaderSelection.Next() Do
	
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// Title
		Area = Template.GetArea("Title");
	
		Area.Parameters.TitleText = StrTemplate(
			NStr("vi = 'Quy trình công nghệ %1';
				|ru = 'Технологический процесс %1';
				|en = '%1 technological process'; fa = '%1 technological process';
				|it = 'Технологический процесс %1';
				|pl = '%1 technological process';
				|tr = 'Teknolojik süreç %1'", Common.DefaultLanguageCode()),
			DataForPrint.HeaderSelection.Presentation);
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
		
		SpreadsheetDocument.Put(Area);
		
		// Operations
		PrintedFormOutputOperations(Template, SpreadsheetDocument, HeaderSelection, DataForPrint.OperationSelection_);
		
		// UsedMaterials
		PrintedFormAndMaterials(Template, SpreadsheetDocument, HeaderSelection, DataForPrint.SampleMaterials);
		
		// LaborCosts
		PrintedFormAndLaborCosts(Template, SpreadsheetDocument, HeaderSelection, DataForPrint.SamplingLaborCosts_);
		
		PrintManagement.SetDocumentPrintArea(
			SpreadsheetDocument,
			RowNumberStart,
			PrintObjects,
			HeaderSelection.Ref);
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

Function DataForPrintingProcess(References)
	
	QueryText =
		"SELECT
		|	Processes.Ref                          AS Ref,
		|	Processes.Department                   AS Department,
		|	Processes.Department.Presentation     AS DepartmentPresentation,
		|	Processes.Presentation                   AS Presentation,
		|	Processes.EmployeeResponsible                   AS EmployeeResponsible,
		|	Processes.EmployeeResponsible.Presentation     AS EmployeeResponsiblePresentation,
		|	Processes.ForFinishedProductsKind                  AS ForFinishedProductsKind,
		|	Processes.LongDesc                        AS LongDesc
		|FROM
		|	Catalog.TechnologicalProcesses AS Processes
		|WHERE
		|	Processes.Ref IN(&References)
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
		|	Catalog.TechnologicalProcesses.MaterialsAndServices AS UsedMaterials
		|WHERE
		|	UsedMaterials.Ref IN(&References)
		|	AND UsedMaterials.Products <> VALUE(Catalog.Products.EmptyRef) // Only the completed item is displayed
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
		|	Operations.Owner                                                     AS Ref,
		|	Operations.Description                                                 AS NameOfTheOperation,
		|	Operations.OperationNumber                                                AS OperationNumber,
		|	CASE
		|		WHEN Operations.WorkCenter REFS Catalog.WorkCenters
		|			THEN CAST(Operations.WorkCenter AS Catalog.WorkCenters).WorkCenterType
		|		ELSE Operations.WorkCenter
		|	END                                                                 AS WorkCenterType,
		|	&TextDetailsForCalculatingOperationExecutionTime
		|FROM
		|	Catalog.ManufacturingOperations AS Operations
		|
		|WHERE
		|	Operations.Owner IN(&References)
		|	AND NOT Operations.DeletionMark
		|
		|ORDER BY
		|	Ref,
		|	OperationNumber
		|TOTALS BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	LaborCosts.Ref                    AS Ref,
		|	LaborCosts.WorkKind                  AS WorkKind,
		|	LaborCosts.WorkKind.UnitOfMeasure AS TypeOfWorkEd,
		|	LaborCosts.Count                AS Count,
		|	LaborCosts.Operation                  AS Operation
		|FROM
		|	Catalog.TechnologicalProcesses.LaborCosts AS LaborCosts
		|WHERE
		|	LaborCosts.Ref IN(&References)
		|
		|ORDER BY
		|	Ref,
		|	LineNumber
		|TOTALS BY
		|	Ref
		|";
	
	TextEd = Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
		"Description", "UsedMaterials.Package", "UsedMaterials.Products");
	QueryText = StrReplace(QueryText, "&RequestTextUnitOfMeasurementMaterials", TextEd);
	
	QueryText = StrReplace(
		QueryText,
		"&TextDetailsForCalculatingOperationExecutionTime",
		Catalogs.ManufacturingOperations.QueryTextAttributesForCalculatingTimeOfOperation("Operations"));
	
	Query = New Query(QueryText);
	Query.SetParameter("References", References);
	
	SetPrivilegedMode(True);
	ResultsArray = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	DataForPrint = New Structure;
	DataForPrint.Insert("HeaderSelection",        ResultsArray[0].Select());
	DataForPrint.Insert("SampleMaterials",    ResultsArray[1].Select(QueryResultIteration.ByGroups));
	DataForPrint.Insert("OperationSelection_",     ResultsArray[2].Select(QueryResultIteration.ByGroups));
	DataForPrint.Insert("SamplingLaborCosts_", ResultsArray[3].Select(QueryResultIteration.ByGroups));
	
	Return DataForPrint;
	
EndFunction

// Parameters:
// 	Template - DataCompositionAppearanceTemplate, GeographicalSchema, DataCompositionSchema, GraphicalSchema, HTMLDocumentShell, BinaryData, SpreadsheetDocument, ActiveDocumentShell, TextDocument - LongDesc
// 	SpreadsheetDocument - SpreadsheetDocument - LongDesc
// 	HeaderSelection -  QueryResultSelection -
// 	SampleMaterials -  QueryResultSelection -
Procedure PrintedFormAndMaterials(Template, SpreadsheetDocument, HeaderSelection, SampleMaterials)
	
	If Not SampleMaterials.FindNext(New Structure("Ref", HeaderSelection.Ref)) Then
		Return;
	EndIf;
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
		
	SpreadsheetDocument.Put(Template.GetArea("TitleOfMaterialsTable"));
			
	If OutputCodes Then
	   	
		SectionHeader = Template.GetArea("HeaderOfMaterialsTableWithCode");
		SectionHeader.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
		AreaRow = Template.GetArea("RowOfMaterialsTableWithCode"); // See ProductionServer.ServiceStructureTabularDocument
			
	Else
				
		SectionHeader = Template.GetArea("HeaderOfMaterialsTable_NoCode");
		AreaRow = Template.GetArea("RowOfMaterialsTable_NoCode");  // See ProductionServer.ServiceStructureTabularDocument
		
	EndIf;
	
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
	
		AreaRow.Parameters.ProductPresentation = ProductsClientServer.PresentationOfProductsForPrinting(
			Selection.ProductFullName,
			Selection.CharacteristicFullName,
			,
			,
			AdditionalParametersProductPresentation);
		AreaRow.Parameters.LineNumber = LineNumber;
		LineNumber = LineNumber + 1;
		
		SpreadsheetDocument.Put(AreaRow);
		
	EndDo;
	
	SpreadsheetDocument.Put(Template.GetArea("BasementMaterials"));
	
EndProcedure

// Parameters:
// 	Template - DataCompositionAppearanceTemplate, GeographicalSchema, DataCompositionSchema, GraphicalSchema, HTMLDocumentShell, BinaryData, SpreadsheetDocument, ActiveDocumentShell, TextDocument - LongDesc
// 	SpreadsheetDocument - SpreadsheetDocument - LongDesc
// 	HeaderSelection -  QueryResultSelection -
// 	OperationSelection_ -  QueryResultSelection -
Procedure PrintedFormOutputOperations(Template, SpreadsheetDocument, HeaderSelection, OperationSelection_)
	
	If Not OperationSelection_.FindNext(New Structure("Ref", HeaderSelection.Ref)) Then
		Return;
	EndIf;
			
	SpreadsheetDocument.Put(Template.GetArea("OperationTableHeader"));
	
	SpreadsheetDocument.Put(Template.GetArea("HeaderOfOperationTable"));
	
	AreaRow = Template.GetArea("TableRowOperation");
	
	Selection = OperationSelection_.Select();
	While Selection.Next() Do
		
		AreaRow.Parameters.Fill(Selection);
			
		SpreadsheetDocument.Put(AreaRow);
		
	EndDo;
			
	SpreadsheetDocument.Put(Template.GetArea("BasementOperation"));
	
EndProcedure

// Parameters:
// 	Template - DataCompositionAppearanceTemplate, GeographicalSchema, DataCompositionSchema, GraphicalSchema, HTMLDocumentShell, BinaryData, SpreadsheetDocument, ActiveDocumentShell, TextDocument - LongDesc
// 	SpreadsheetDocument - SpreadsheetDocument - LongDesc
// 	HeaderSelection -  QueryResultSelection -
// 	SamplingLaborCosts_ -  QueryResultSelection -
Procedure PrintedFormAndLaborCosts(Template, SpreadsheetDocument, HeaderSelection, SamplingLaborCosts_)
	
	If Not SamplingLaborCosts_.FindNext(New Structure("Ref", HeaderSelection.Ref)) Then
		Return;
	EndIf;
			
	SpreadsheetDocument.Put(Template.GetArea("TableHeaderLaborCosts"));
	
	SpreadsheetDocument.Put(Template.GetArea("HeaderOfLaborTable"));
	
	AreaRow = Template.GetArea("TableRowLaborCosts");
	
	LineNumber = 1;
	Selection = SamplingLaborCosts_.Select();
	While Selection.Next() Do
		
		AreaRow.Parameters.Fill(Selection);
		
		AreaRow.Parameters.LineNumber = LineNumber;
		LineNumber = LineNumber + 1;
		
		SpreadsheetDocument.Put(AreaRow);
		
	EndDo;
			
	SpreadsheetDocument.Put(Template.GetArea("BasementLaborCosts"));
	
EndProcedure

#EndRegion

#Region Other

Function QueryTextStructureOfProcessDetails()
	
	QueryText = "
	|SELECT
	|	T.Ref                           AS TechnologicalProcess,
	|	T.Status                           AS Status,
	|	T.Presentation                    AS Presentation,
	|	T.ForFinishedProductsKind                   AS ForFinishedProductsKind,
	|	T.Department                    AS Department,
	|	T.CalculateFactor          AS CalculateFactor,
	|	T.NumeratorFactor             AS NumeratorFactor,
	|	T.FactorDenominator           AS FactorDenominator,
	|	T.ContainsResourcesParametrization       AS ContainsResourcesParametrization
	|FROM
	|	Catalog.TechnologicalProcesses AS T
	|WHERE
	|	T.Ref = &TechnologicalProcess
	|
	|";
	
	Return QueryText;
	
EndFunction

Procedure HandleShiftingFormulas(Tables, NumberOffset)
	
	If NumberOffset = 0 Then
		Return;
	EndIf;
	
	SourceOfOperands = "MaterialsAndServices";
	
	OperandAdjustmentTable = New ValueTable();
	OperandAdjustmentTable.Columns.Add("OperandOld");
	OperandAdjustmentTable.Columns.Add("NewNumber_");
	
	OperandSelection = New Structure("OperandOld");
	
	For Each TableName In StrSplit("MaterialsAndServices,LaborCosts", ",") Do
		
		Table = Undefined; // ValueTable
		If Not Tables.Property(TableName, Table) Then
			Return;
		EndIf;
		
		For IndexOf = 0 To Table.Count() - 1 Do
			
			String = Table[IndexOf];
			
			NumberOffset = NumberOffset + 1;
			
			LineNumberCur = String.LineNumber;
			NewLineNumber_   = NumberOffset;
			
			If TableName = SourceOfOperands Then
				NewRow = OperandAdjustmentTable.Add();
				NewRow.OperandOld = StrTemplate("%1[%2].", SourceOfOperands, Format(LineNumberCur,"NZ=; NG="));
				NewRow.NewNumber_    = Format(NewLineNumber_,"NZ=; NG=");
			EndIf;
			
			If Not IsBlankString(String.QuantityCalculationAlgorithm) Then
				
				Operands = New Array;
				
				OpeningMarker = StrFind(String.QuantityCalculationAlgorithm, SourceOfOperands,,1);
				While OpeningMarker > 0 Do
					ClosingMarker = StrFind(String.QuantityCalculationAlgorithm, "].",,OpeningMarker);
					If ClosingMarker > 0 Then
						Operand = Mid(String.QuantityCalculationAlgorithm, OpeningMarker, ClosingMarker-OpeningMarker+2);
						If Operands.Find(Operand) = Undefined Then
							Operands.Add(Operand);
						EndIf;
					EndIf;
					OpeningMarker = StrFind(String.QuantityCalculationAlgorithm, SourceOfOperands,,ClosingMarker);
				EndDo;
				
				For Each Operand In Operands Do
					OperandSelection.OperandOld = Operand;
					FoundRows = OperandAdjustmentTable.FindRows(OperandSelection);
					If FoundRows.UBound() <> -1 Then
						ReplacementNumber = FoundRows[0].NewNumber_;
					Else
						ReplacementNumber = "0";
					EndIf;
					String.QuantityCalculationAlgorithm = StrReplace(String.QuantityCalculationAlgorithm,
						Operand, StrTemplate("%1_[%2].", SourceOfOperands, ReplacementNumber));
				EndDo;
				
				String.QuantityCalculationAlgorithm = StrReplace(String.QuantityCalculationAlgorithm, SourceOfOperands+"_", SourceOfOperands);
				
			EndIf;
			
			String.LineNumber = NewLineNumber_;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Parameters:
// 	List - DynamicList - list of technological processes
// 	Products - CatalogRef.Products - Selection value
Procedure SetSelectionByProductInListOfTechnologicalProcesses(List, Products) Export
	
	QueryTexts = "";
	
	// Material
	If ValueIsFilled(Products) Then
		
		QueryTexts = "
		|SELECT
		|	T.Ref AS Ref
		|FROM
		|	Catalog.TechnologicalProcesses.MaterialsAndServices AS T
		|WHERE
		|	T.Products = &Products";
		
	EndIf;
	
	FilterList = New ValueList;
	Use = (QueryTexts <> "");
	
	If Use Then
		
		Query = New Query;
		Query.Text = QueryTexts;
		Query.SetParameter("Products",    Products);
		
		FilterList.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));
		
	EndIf;
		
	FilterRemainingGoodsByShelfLives = CommonClientServer.CreateFilterItemGroup(
		List.SettingsComposer.FixedSettings.Filter.Items,
		NStr("vi = 'Lọc theo mặt hàng';
			|ru = 'Отбор по номенклатуре';
			|en = 'Filter by items'; fa = 'فیلتر بر اساس اقلام';
			|it = 'La selezione in base all''elenco articoli';
			|pl = 'Filtr wg towaru';
			|tr = 'Öğeye göre filtre'"),
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.AddCompositionItem(
			FilterRemainingGoodsByShelfLives,
			"Ref",
			DataCompositionComparisonType.InList,
			FilterList,
			,
			Use);
	
EndProcedure

Procedure ApplySelection(ProcessData_, SelectionParameters, Filter)
	
	If TypeOf(Filter) = Type("Structure") Then
		For Each TableName In SelectionParameters.ListOfData Do
			ProcessData_.Insert(TableName, ProcessData_[TableName].Copy(Filter));
		EndDo;
	EndIf;
	
EndProcedure

Procedure PerformDirectiveReplacementsOfMaterials(ItemData_3, TAData)
	
	DataSet = Undefined;
	If Not TAData.Property("MaterialsAndServices", DataSet) Then
		Return;
	EndIf;
	
	If DataSet.Find(True, "SelectReplacement") = Undefined
		And DataSet.Find(True, "UseAutoselection") = Undefined Then
		Return;
	EndIf;
	
	ProductDataManagement.PerformDirectiveSubstitutionsInDataSet(DataSet, ItemData_3);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf