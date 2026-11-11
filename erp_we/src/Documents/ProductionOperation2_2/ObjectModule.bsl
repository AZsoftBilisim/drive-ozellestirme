#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Sets the status for the document object
//
// Parameters:
//	NewStatus - String - Name of the status that will be set for orders
//	AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//
// Returns:
//	Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	Status = ProductionAccountingClientServer.StatusOfOperationLink(NewStatus);
	
	Documents.ProductionOperation2_2.FillInDetailsWhenSettingStatus(ThisObject);
	
	Return CheckFilling();
	
EndFunction

// Fills in the document according to the NSI data
//
// Parameters:
//	FillingData - Undefined, Structure - From:
//		* BOMStage - CatalogRef.ProductionStages
//		* SpecificationData - See Catalogs.BillsOfMaterials.DataSpecificationConstructor
//	SavePerformers - Boolean - determines the need to save the performers of labor costs
//	SaveBatches - Boolean - determines the need to save series in output products and materials
//
Procedure FillInTransactionStandards(FillingData = Undefined, SavePerformers = False, SaveBatches = False) Export
	
	If SavePerformers And Not ValueIsFilled(Performer) Then
		AdditionalProperties.Insert("LaborCosts", LaborCosts.Unload());
	EndIf;
	
	If SaveBatches Then
		AdditionalProperties.Insert("BatchFinishedProducts", BatchFinishedProducts.Unload());
		AdditionalProperties.Insert("ManufacturedProducts", ManufacturedProducts.Unload());
		AdditionalProperties.Insert("MaterialsAndWorks", MaterialsAndWorks.Unload());
	EndIf;
	
	ClearTableParts();
	
	TechProcessParameters = ProductionProcessEditorServerCall.ParametersOfTechnicalProcessOfStage(Stage);
	OwnerOfOperation = Common.ObjectAttributeValue(Operation, "Owner");
	
	If TypeOf(OwnerOfOperation) = Type("CatalogRef.TechnologicalProcesses")
			And (TechProcessParameters.TechnologicalProcessType = Enums.TechnologicalProcessTypesOfStage.AlternateType
				Or TechProcessParameters.TechnologicalProcessType = Enums.TechnologicalProcessTypesOfStage.Individual_)
			And (SpecificationData(FillingData) = Undefined
				Or SpecificationData(FillingData).Operations.FindRows(FilterOperations(FillingData)).Count() = 0) Then
		OperationData = DataOfOperationOfTechnologicalProcess(FillingData, TechProcessParameters);
	ElsIf TypeOf(OwnerOfOperation) = Type("CatalogRef.RouteSheets") Then
		OperationData = RouteMapOperationData();
	Else
		OperationData = OperationDataSpecifications(FillingData);
	EndIf;
	
	If OperationData = Undefined Then
		Raise NStr("vi = 'Lỗi tính toán tiêu chuẩn để điền giao dịch.';
					|ru = 'Ошибка расчета нормативов для заполнения операции.';
					|en = 'An error occurred when calculating standards for filling the operation.'; fa = 'An error occurred when calculating standards for filling the operation.';
					|it = 'Ошибка расчета нормативов для заполнения операции.';
					|pl = 'An error occurred when calculating standards for filling the operation.';
					|tr = 'İşlemin doldurulması için standartların hesaplanmasında hata.'");
	EndIf;
	
	AttributesList = "OperationKind,Repeatable,Skippable,Control,UnitOfMeasure,
	|Continuous,TransferLot,TimePerPiece,TimePerPieceUnitOfMeasure,SetupTime,SetupTimeUnitOfMeasure";
	FillPropertyValues(ThisObject, OperationData, AttributesList);
	
	For Each AttributeName In StrSplit("SetupSettings,Load", ",") Do
		If Not ValueIsFilled(ThisObject[AttributeName]) Then
			ThisObject[AttributeName] = OperationData[AttributeName];
		EndIf;
	EndDo;
	
	If WorkCenter.IsEmpty() Or TypeOf(WorkCenter) = Type("CatalogRef.WorkCenterTypes") Then
		OperationData.WorkTimeFactor = 1;
	Else
		OperationData.WorkTimeFactor = Common.ObjectAttributeValue(WorkCenter, "WorkTimeFactor");
	EndIf;
	
	Description = OperationData.OperationPresentation;
	CalculateExecutionTime(OperationData);
	
	Settings = Documents.ProductionOperation2_2.AccountingSettings(
		Department,
		OwnerOfOperation);
	
	If Settings.UseFinishedProducts Then
		For Each TSName In StrSplit("ManufacturedProducts,RecyclableWaste", ",") Do
			If OperationData.Property(TSName) Then
				For Each String In OperationData[TSName] Do
					FillPropertyValues(ManufacturedProducts.Add(), String);
				EndDo;
			EndIf;
		EndDo;
	EndIf;
	
	If Settings.UseMaterials Then
		
		FillInMaterialsOnStandards(OperationData.UsedMaterials);
		
	EndIf;
	
	For Each String In OperationData.LaborCosts Do
		FillPropertyValues(LaborCosts.Add(), String);
	EndDo;
	
	RestorePerformersOfLaborCosts();
	
	RestoreBatches();
	
	Documents.ProductionOperation2_2.FillInStatusesForSpecifyingSeries(ThisObject);
	
	If TechProcessParameters.TechnologicalProcessType = Enums.TechnologicalProcessTypesOfStage.Individual_ Then
		Repeatable = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		FillPropertyValues(ThisObject, FillingData);
		
		If FillingData.Property("Status")
			And Status <> Metadata.Documents.ProductionOperation2_2.Attributes.Status.FillValue Then
			
			Documents.ProductionOperation2_2.FillInDetailsWhenSettingStatus(ThisObject);
			
		EndIf;
		
		If FillingData.Property("WorkCenterType")
			And Not ValueIsFilled(WorkCenter) Then
			WorkCenter = FillingData.WorkCenterType;
		EndIf;
		
		If FillingData.Property("FillingMethod")
			And FillingData.FillingMethod = "FillInByOperation" Then
			
			If FillingData.Property("OperationKey") Then
				FillPropertyValues(ThisObject, FillingData.OperationKey); // See ProductionManagementClientServer.ProductionOperationKey
			Else
				FillPropertyValues(ThisObject, FillingData, "Stage,Operation,OperationID");
			EndIf;
			
			FillInTransactionStandards(FillingData);
			
			If FillingData.Property("ActivityKinds") Then
				Filter = New Structure("WorkKind");
				For Each StringOfActivitiesKinds In FillingData.ActivityKinds Do
					
					If Not ValueIsFilled(StringOfActivitiesKinds.Performer) Then
						Continue;
					EndIf;
					
					Filter.WorkKind = StringOfActivitiesKinds.WorkKind;
					
					LinesOfLaborCosts = LaborCosts.FindRows(Filter);
					
					For Each String In LinesOfLaborCosts Do
						String.Performer = StringOfActivitiesKinds.Performer;
					EndDo;
					
				EndDo;
			EndIf;
			
		EndIf;
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ProductionStage2_2") Then
		
		Stage = FillingData;
		
	EndIf;
	
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	
	OperationAsOutputReference = ProductionManagement.UseProductionOperationsAsReferencesForOutput(Date);
	
	If Not Stage.IsEmpty() Then
		
		Attributes = "Organization" + ?(Department.IsEmpty(), ",Department", "") + ",OperationAsOutputReference";
		
		FillPropertyValues(ThisObject,
			Common.ObjectAttributesValues(Stage, Attributes));
		
	EndIf;
	
	ProductionManagementClientServer.SetArtistType(
		Performer,
		ProductionServer.ProductionBusinessUnitDescription(Department).UseTeamWorkOrders,
		ProductionServer.AccountingOfLaborCostsInContextOfEmployeesIsUsed(Date));
	
	BasedOnMasterData = Not Operation.IsEmpty();
	
	If Not ValueIsFilled(EmployeeResponsible) Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	CheckHeaderDetails(Cancel, NotCheckedAttributeArray);
	
	If Status = Enums.ProductionOperationStatuses.NotExecuted
		Or Status = Enums.ProductionOperationStatuses.IsSkipped Then
		ExcludeAttributesOfTableParts(CheckedAttributes);
	Else
		CheckFillingInProducts(Cancel, NotCheckedAttributeArray);
		CheckWhetherCharacteristicsAreFilledIn(Cancel, NotCheckedAttributeArray);
		CheckSeriesCompletion(Cancel, NotCheckedAttributeArray);
		CheckQuantityFilling(Cancel, NotCheckedAttributeArray);
		CheckCompletionOfTeams(Cancel, NotCheckedAttributeArray);
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	SetKeyInRowsOfTableParts(Cancel);
	
	DataBeforeChange =  OperationDataBeforeChange();
	AdditionalProperties.Insert("DataBeforeChange", DataBeforeChange);
	
	// Checking the object
	If Not GroupProcessingMode() Then
		
		If Not Stage.IsEmpty() Then
			
			StageStatus = Common.ObjectAttributeValue(Stage, "Status");
			
			If StageStatus = Enums.StatusesOfProductionStages2_2.Completed Then
				
				Common.MessageToUser(
					NStr("vi = 'Không thể thay đổi giao dịch của công đoạn đã hoàn tất.';
						|ru = 'Изменение операции, принадлежащей завершенному этапу, невозможно.';
						|en = 'Cannot change the operation that belongs to a completed stage.'; fa = 'Cannot change the operation that belongs to a completed stage.';
						|it = 'Cannot change the operation that belongs to a completed stage.';
						|pl = 'Cannot change the operation that belongs to a completed stage.';
						|tr = 'Tamamlanmış bir aşamaya ait işlemin değiştirilmesi mümkün değildir.'"),
					ThisObject,
					"Stage",,
					Cancel);
					
			ElsIf WriteMode = DocumentWriteMode.Posting
				And StageStatus = Enums.StatusesOfProductionStages2_2.BeingGenerated
				And (CountReal > 0 Or DefectiveGoodsCount > 0 Or QuantityUnderRevision > 0 Or FollowUp > 0) Then
				
				Common.MessageToUser(
					StrTemplate(NStr("vi = 'Không thể phản ánh quá trình thực hiện giao dịch theo công đoạn trong trạng thái ""%1"".';
									|ru = 'Нельзя отражать ход выполнения операций по этапу в статусе ""%1"".';
									|en = 'Cannot display the progress of operations of the stage in the ""%1"" status.'; fa = 'Cannot display the progress of operations of the stage in the ""%1"" status.';
									|it = 'Cannot display the progress of operations of the stage in the ""%1"" status.';
									|pl = 'Cannot display the progress of operations of the stage in the ""%1"" status.';
									|tr = '""%1"" durumundaki aşama kapsamında işlemlerin ilerlemesi yansıtılamaz.'"), StageStatus),
					ThisObject,
					"Stage",,
					Cancel);
				
			EndIf;
			
		EndIf;
		
		If Not ShiftTask.IsEmpty() Then
		
			JobStatus = Common.ObjectAttributeValue(ShiftTask, "Status");
			
			If JobStatus = Enums.ShiftTaskStatuses.Closed Then
			
				Common.MessageToUser(
					NStr("vi = 'Không thể thay đổi giao dịch thuộc về ca làm việc đã đóng.';
						|ru = 'Изменение операции, принадлежащей закрытому сменному заданию, невозможно.';
						|en = 'Cannot edit the operation that belongs to a closed shift task.'; fa = 'Cannot edit the operation that belongs to a closed shift task.';
						|it = 'Cannot edit the operation that belongs to a closed shift task.';
						|pl = 'Cannot edit the operation that belongs to a closed shift task.';
						|tr = 'Kapalı vardiyalı göreve ait işlemin değiştirilmesi mümkün değildir.'"),
					ThisObject,
					"ShiftTask",,
					Cancel);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	// Filling in Bank details
	For Each KeyAndValue In ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ProductionOperation2_2) Do
		
		SeriesSpecificationParameters = KeyAndValue.Value; // ProductsClientServer.SeriesSpecificationParameters
		
		If SeriesSpecificationParameters.FactOfSelection Then
			ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
		EndIf;
		
	EndDo;
	
	If BasedOnMasterData
		And (Status = Enums.ProductionOperationStatuses.NotExecuted
			Or Status = Enums.ProductionOperationStatuses.IsSkipped) Then
		
		ClearTableParts();
		
	EndIf;
	
	If ValueIsFilled(Performer) Then
		For Each String In LaborCosts Do
			String.Performer = Performer;
		EndDo;
	EndIf;
	
	FillInNumber();
	FillInIdentifier(WriteMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	RecalculateQueueOfOperations(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	If Not GroupProcessingMode() Then
		AddTasksToProcessingStagesOfProduction();
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Number = "";
	StageOperationNumber = 0;
	
	If ProductionProcessEditorClientServer.ThisOperationIsIndividual(CopiedObject) Then
		
		Operation = Undefined;
		OperationID = 0;
	
	ElsIf Not CopiedObject.SplittingMode() Then
		
		Operation = Undefined;
		OperationID = 0;
		
		BasedOnPlanning = False;
		BasedOnMasterData = False;
		IncludedInTechnologicalProcess = False;
		
		LotNumber = 0;
		
	EndIf;
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region FillingInDocument_

Function RouteMapOperationData()
	
	Parameters = ParametersForReceivingOfOperationData();
	If Parameters = Undefined Then
		Return Undefined;
	EndIf;
	
	ItemData_3 = Catalogs.RouteSheets.ItemData_3();
	FillPropertyValues(ItemData_3, Parameters);
	
	Result = Catalogs.RouteSheets.RouteMapOperationData(
		Operation,
		Count,
		Parameters.TechnologicalProcessFactor,
		ItemData_3);
		
	DescriptionOfTables = DescriptionOfTablesForRecalculationOfStandards();
	
	For Each KeyAndValue In DescriptionOfTables Do
		
		TableDetails = KeyAndValue.Value;
		
		CurOperationCoefficient = (TableDetails.OperationsCount / Count);
		
		For Each String In Result[TableDetails.TSName] Do
			
			If TableDetails.ThereArePackages Then
				String.NumberOfPackages = String.NumberOfPackages * CurOperationCoefficient;
			EndIf;
			String.Count = String.Count * CurOperationCoefficient;
			
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function OperationDataSpecifications(FillingData = Undefined)
	
	Result          = New Structure;
	DescriptionOfTables     = DescriptionOfTablesForRecalculationOfStandards();
	SpecificationData = SpecificationData(FillingData);
	
	If Not ValueIsFilled(SpecificationData) Then
		Return Undefined;
	EndIf;
		
	For Each KeyAndValue In DescriptionOfTables Do
		Result.Insert(KeyAndValue.Value.TSName, SpecificationData[KeyAndValue.Key].CopyColumns());
	EndDo;
	
	FoundRows = SpecificationData.Operations.FindRows(FilterOperations());
	If ValueIsFilled(FoundRows) Then
		
		LineOperation = FoundRows[0];
		
		For Each Column In SpecificationData.Operations.Columns Do
			Result.Insert(Column.Name, LineOperation[Column.Name]);
		EndDo;
		
		For Each KeyAndValue In DescriptionOfTables Do
			
			TableDetails = KeyAndValue.Value;
			Table         = Result[TableDetails.TSName]; // ValueTable
			
			For Each NSIString In SpecificationData[KeyAndValue.Key] Do
				
				If NSIString.Stage <> LineOperation.Stage Then
					Continue;
				EndIf;
				
				If Catalogs.BillsOfMaterials.DataLineOfBillOfMaterialsBelongsToOperation(LineOperation, NSIString, TableDetails.Product) Then
					
					NewRow = Table.Add();
					FillPropertyValues(NewRow, NSIString);
					
					CurOperationCoefficient = (TableDetails.OperationsCount / LineOperation.QuantityPerBatch);
					If TableDetails.ThereArePackages Then
						NewRow.NumberOfPackages = NewRow.NumberOfPackages * CurOperationCoefficient;
					EndIf;
					NewRow.Count = NewRow.Count * CurOperationCoefficient;
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
	Else
		
		For Each Column In SpecificationData.Operations.Columns Do
			Result.Insert(Column.Name, Column.ValueType.AdjustValue(0));
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function DataOfOperationOfTechnologicalProcess(FillingData, TechProcessParameters)
	
	Result = New Structure;
	FilterOperation = New Structure("Operation", Operation);
	DescriptionOfTables = DescriptionOfTablesForRecalculationOfStandards();
	
	Parameters = ParametersForReceivingOfOperationData();
	If Parameters = Undefined Then
		Return Undefined;
	EndIf;
	
	ItemData_3 = Catalogs.TechnologicalProcesses.ItemData_3();
	FillPropertyValues(ItemData_3, Parameters);
	
	TAData = Catalogs.TechnologicalProcesses.ProcessDataByNomenclature(
		Parameters.TechnologicalProcess,
		Parameters.TechnologicalProcessFactor,
		ItemData_3,
		Catalogs.TechnologicalProcesses.DataSamplingParameters("Operations,MaterialsAndServices,LaborCosts"));
	
	For Each Column In TAData.Operations.Columns Do
		Result.Insert(Column.Name, Column.ValueType.AdjustValue(0));
	EndDo;
	
	FoundRows = TAData.Operations.FindRows(FilterOperation);
	If ValueIsFilled(FoundRows) Then
		
		FillPropertyValues(Result, FoundRows[0]);
		
		If TechProcessParameters.TechnologicalProcessType = Enums.TechnologicalProcessTypesOfStage.AlternateType Then
			ProductionProcessEditor.AddResourcesBillOfMaterials(
				TAData,
				SpecificationData(FillingData),
				ProductionProcessEditor.ListOfDataWhenAddingResourcesBillOfMaterials(Result),
				Operation);
		EndIf;
		
		For Each KeyAndValue In DescriptionOfTables Do
			
			TableDetails = KeyAndValue.Value;
			If Not TAData.Property(KeyAndValue.Key) Then
				Continue;
			EndIf;
			
			Result.Insert(TableDetails.TSName, TAData[KeyAndValue.Key].Copy(FilterOperation));
			
			CurOperationCoefficient = (TableDetails.OperationsCount / Result.QuantityPerBatch);
			
			For Each String In Result[TableDetails.TSName] Do
				
				If TableDetails.ThereArePackages Then
					String.NumberOfPackages = String.NumberOfPackages * CurOperationCoefficient;
				EndIf;
				String.Count = String.Count * CurOperationCoefficient;
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure FillInMaterialsOnStandards(UsedMaterials) 
	
	For Each String In UsedMaterials Do
		FillPropertyValues(MaterialsAndWorks.Add(), String);
	EndDo;
	
	StageMaterials = Documents.ProductionStage2_2.ResiduesOfProvidedMaterials(Stage, "Characteristic");
	StageMaterials.Indexes.Add("Products, Characteristic");
	
	TheStructureOfTheSearch = New Structure("Products, Characteristic");
	CachedValues = Undefined;
	
	For IndexOf = 0 To MaterialsAndWorks.Count()-1 Do
		
		String = MaterialsAndWorks[IndexOf];
		
		FillPropertyValues(TheStructureOfTheSearch, String);
		FoundRows = StageMaterials.FindRows(TheStructureOfTheSearch);
		
		If FoundRows.Count() = 0 Then
			
			NoteMaterialLineIsMissingFromStage(String);
			
		Else
			
			StringStageMaterial = FoundRows[0];
			
			If StringStageMaterial.Count = String.Count Then
				
				StageMaterials.Delete(StringStageMaterial);
				
			ElsIf StringStageMaterial.Count > String.Count Then
				
				StringStageMaterial.Count = StringStageMaterial.Count - String.Count;
				
			Else
				
				QuantityShortage_ = String.Count - StringStageMaterial.Count;
				
				String.Count = StringStageMaterial.Count;
				RecalculateNumberOfPackages(String, CachedValues);
				
				NewRow = MaterialsAndWorks.Add();
				FillPropertyValues(NewRow, String);
				NewRow.Count = QuantityShortage_;
				RecalculateNumberOfPackages(NewRow, CachedValues);
				NoteMaterialLineIsMissingFromStage(NewRow);
				
				StageMaterials.Delete(StringStageMaterial);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CalculateExecutionTime(OperationData)
	
	CalculationStructure = ProductionAccountingClientServer.StructureOfCalculationOfTotalExecutionTime();
	FillPropertyValues(CalculationStructure, OperationData);
	
	ConversionFactor_ = Catalogs.ManufacturingOperations.CalculateConversionFactorOfStandards(
		Operation,
		?(Status = Enums.ProductionOperationStatuses.Executed,
			CountReal + DefectiveGoodsCount + QuantityUnderRevision + FollowUp,
			Count - CountCanceled));
	
	ProductionAccountingClientServer.CalculateTotalOperationTime(
		CalculationStructure,
		ConversionFactor_);
	
	FillPropertyValues(ThisObject, CalculationStructure, "RunTime, ExecutionTimeUnitOfMeasure");
	
EndProcedure

Procedure NoteMaterialLineIsMissingFromStage(String)
	
	String.RouteSheetItems = String.Products;
	String.Products = Catalogs.Products.EmptyRef();
	
	String.ItemVariantOfRouteSheet = String.Characteristic;
	String.Characteristic = Catalogs.ItemsCharacteristics.EmptyRef();
	
	String.RouteSheetPackage = String.Package;
	String.Package = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
	
EndProcedure

Procedure RecalculateNumberOfPackages(LineOfATabularSection, CachedValues)
	
	StructureOfActions = New Structure("RecalculateNumberOfPackages");
	
	BatchProcessingOfTablePartServer.ProcessTSString(LineOfATabularSection, StructureOfActions, CachedValues);
	
EndProcedure

Procedure ClearTableParts()
	
	For Each TSName In TabularSections() Do
		ThisObject[TSName].Clear();
	EndDo;
	
EndProcedure

Function TabularSections()
	
	Result = New Array;
	
	Result.Add("MaterialsAndWorks");
	Result.Add("LaborCosts");
	Result.Add("ManufacturedProducts");
	Result.Add("BatchFinishedProducts");
	
	Return Result;
	
EndFunction

Function SpecificationData(FillingData = Undefined)
	
	SpecificationData = Undefined;
	
	If Not AdditionalProperties.Property("SpecificationData", SpecificationData) Then
		
		If ValueIsFilled(FillingData) And FillingData.Property("SpecificationData", SpecificationData) Then
			
			If Not SpecificationData.Property("Stages") Or SpecificationData.Stages.Count() > 1 Then
			
				SpecificationData = Common.CopyRecursive(SpecificationData);
				
				Catalogs.BillsOfMaterials.ApplySelectionBasedOnSpecificationData(
						SpecificationData,
						New Structure("Stage", Common.ObjectAttributeValue(Stage, "Stage")));
					
			EndIf;
			
		Else
			
			AttributesValues = Common.ObjectAttributesValues(
				Stage,
				"Stage,ReferenceOrder,AssignmentProducts,ProductionLot,NumberOfPackagesPlan,PackagePlan");
			
			ProductionBatchData = New Structure(
					Documents.ProductionStage2_2.ProductionBatchData(
						AttributesValues.ReferenceOrder,
						AttributesValues.AssignmentProducts,
						AttributesValues.ProductionLot));
			// we change the quantity to the planned quantity from the current stage
			ProductionBatchData.Count = AttributesValues.NumberOfPackagesPlan
				* Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(AttributesValues.PackagePlan, ProductionBatchData.Products);
			
			SpecificationData = Documents.ProductionStage2_2.GetStandardsForSpecifications(
				ProductionBatchData,
				False,
				"ManufacturedProducts,RecyclableWaste,MaterialsAndServices,LaborCosts,Operations",
				New Structure("Stage", AttributesValues.Stage));
			
		EndIf;
		
		AdditionalProperties.Insert("SpecificationData", SpecificationData);
		
	EndIf;
	
	Return SpecificationData;
	
EndFunction

Function ParametersForReceivingOfOperationData()
	
	QueriesTexts = New Array;
	
	QueryText = "
	|SELECT
	|	Stages.Ref             AS Stage,
	|	Stages.Stage               AS BOMStage,
	|	Stages.Department      AS Department,
	|	Stages.ProductionLot AS ProductionLot
	|INTO Data_Stage
	|FROM
	|	Document.ProductionStage2_2 AS Stages
	|WHERE
	|	Stages.Ref = &Stage";
	QueriesTexts.Add(QueryText);
	
	QueriesTexts.Add(Documents.ProductionStage2_2.QueryTextDataOfMainProductOfProductionBatches("MainProductData"));
	
	QueryText = "
	|SELECT
	|	Data_Stage.Department                                                                                                AS Department,
	|	Data_Stage.ProductionLot                                                                                           AS ProductionLot,
	|	Queue.TechnologicalProcess                                                                                           AS TechnologicalProcess,
	|	Queue.TechnologicalProcessFactor                                                                              AS TechnologicalProcessFactor,
	|	MainProductData.Products                                                                                      AS Products,
	|	MainProductData.Characteristic                                                                                    AS Characteristic,
	|	MainProductData.ProductionLot.BillOfMaterials                                                                   AS BillOfMaterials,
	|	Data_Stage.BOMStage                                                                                             AS BOMStage,
	|	CAST(MainProductData.ProductionLot.Document AS Document.ProductionOrder2_2)                         AS ReferenceOrder,
	|	CAST(MainProductData.ProductionLot.Document AS Document.ProductionOrder2_2).Department           AS ProductionDispatcherBusinessUnit,
	|	CAST(MainProductData.ProductionLot.Document AS Document.ProductionOrder2_2).LineOfBusiness AS LineOfBusiness,
	|	CAST(MainProductData.ProductionLot.Document AS Document.ProductionOrder2_2).EarliestStartDate           AS ProductionStart,
	|	CASE
	|		WHEN MainProductData.NumberOfTS <> 0
	|			THEN MainProductData.NumberOfTS
	|		ELSE MainProductData.NumberOfCaps
	|	END                                                                                                                    AS Count
	|
	|FROM
	|	Data_Stage AS Data_Stage
	|
	|	INNER JOIN MainProductData AS MainProductData
	|	ON Data_Stage.ProductionLot = MainProductData.ProductionLot
	|
	|	INNER JOIN InformationRegister.QueueOfProductionOperations AS Queue
	|	ON Data_Stage.Stage = Queue.Stage
	|	AND Queue.OperationID = &OperationID
	|
	|";
	QueriesTexts.Add(QueryText);
	
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	QueryText = StrReplace(QueryText, "&ProductionLots", "SELECT T.ProductionLot FROM Data_Stage AS T");
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Stage", Stage);
	Query.SetParameter("OperationID", OperationID);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Recalculates the resources of an individual Operation
// 
// Parameters:
//  ResultsBeforeChange - See ProductionAccountingClientServer.StructureOfResultsConstructor
//
Procedure RecalculateResourcesOfIndividualOperation(ResultsBeforeChange) Export
	
	CurrentResults = ProductionAccountingClientServer.StructureOfResultsConstructor(ThisObject);
	
	DeltaNonconformity     = CurrentResults.DefectiveGoodsCount - ResultsBeforeChange.DefectiveGoodsCount;
	DeltaCanceled = CurrentResults.CountCanceled - ResultsBeforeChange.CountCanceled;
	
	If DeltaNonconformity <> 0 Or DeltaCanceled <> 0 Then
		
		For Each TSName In StrSplit("ManufacturedProducts,MaterialsAndWorks,LaborCosts", ",") Do
			
			Product = TSName = "ManufacturedProducts";
			
			DeltaTo    = ?(Product, ResultsBeforeChange.CountCanceled + ResultsBeforeChange.DefectiveGoodsCount, ResultsBeforeChange.CountCanceled);
			DeltaAfter = ?(Product, CurrentResults.CountCanceled + CurrentResults.DefectiveGoodsCount, CurrentResults.CountCanceled);
			
			For Each String In ThisObject[TSName] Do
				
				For Each Factor In StrSplit("Count"+?(TSName <> "LaborCosts", ",NumberOfPackages", ""), ",") Do
					
					IndicatorIsInitial = String[Factor] * ResultsBeforeChange.Count / (ResultsBeforeChange.Count - DeltaTo);
					String[Factor] = IndicatorIsInitial * (CurrentResults.Count - DeltaAfter) / CurrentResults.Count;
					
				EndDo;
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FillChecking

Procedure CheckHeaderDetails(Cancel, NotCheckedAttributeArray)
	
	If Not (Status = Enums.ProductionOperationStatuses.Running
		Or Status = Enums.ProductionOperationStatuses.Executed) Then
		
		NotCheckedAttributeArray.Add("ExecutionStarted");
		
	EndIf;
	
	If Status <> Enums.ProductionOperationStatuses.Executed Then
		
		NotCheckedAttributeArray.Add("ExecutionEnd");
		
	EndIf;
	
	If ValueIsFilled(WorkCenter) Then
		
		SetupSettingsAreUsed = Common.ObjectAttributeValue(
			WorkCenter,
			?(TypeOf(WorkCenter) = Type("CatalogRef.WorkCenters"),
				"WorkCenterType.SetupSettingsAreUsed",
				"SetupSettingsAreUsed"));
			
	Else
			
		SetupSettingsAreUsed = False;
		
	EndIf;
	
	If Not SetupSettingsAreUsed Then
		
		NotCheckedAttributeArray.Add("SetupSettings");
		
	EndIf;
	
	If Not BasedOnMasterData Then
		
		NotCheckedAttributeArray.Add("Operation");
		
	Else
		
		NotCheckedAttributeArray.Add("Count");
		
	EndIf;
	
	Settings = Documents.ProductionOperation2_2.AccountingSettings(Department, Undefined);
	
	If Not Settings.UseShiftTasks
		Or Status = Enums.ProductionOperationStatuses.BeingGenerated Then
		
		NotCheckedAttributeArray.Add("ShiftTask");
		
	EndIf;
	
	If Not Settings.UseAreas
		Or Status = Enums.ProductionOperationStatuses.BeingGenerated
		Or Status = Enums.ProductionOperationStatuses.IsSkipped Then
		
		NotCheckedAttributeArray.Add("ProductionArea");
		
	EndIf;
	
	If Not Skippable
		And Status = Enums.ProductionOperationStatuses.IsSkipped Then
		
		Common.MessageToUser(
			NStr("vi = 'Hoạt động không thể được bỏ qua';
				|ru = 'Операция не может быть пропущена';
				|en = 'Operation cannot be skipped'; fa = 'Operation cannot be skipped';
				|it = 'L''operazione non può essere ignorata';
				|pl = 'Operacja nie może być pominięta';
				|tr = 'İşlem atlanamaz'"),
			TMCommonUse.DataKeyForMessageToUser(ThisObject),
			"Status",
			"Object",
			Cancel);
		
	EndIf;
	
EndProcedure

Procedure CheckFillingInProducts(Cancel, NotCheckedAttributeArray)
	
	If Status = Enums.ProductionOperationStatuses.Executed Then
		Return; // Standard verification of banking details
	EndIf;
	
	NotCheckedAttributeArray.Add("MaterialsAndWorks.Products");
	
	DataKey  = TMCommonUse.DataKeyForMessageToUser(ThisObject);
	DataPath = "Object";
	
	TemplateError = NStr("vi = 'Cột ""Mặt hàng"" không được điền vào dòng %LineNumber% của danh sách ""Nguyên vật liệu và nhân công""';
						|ru = 'Не заполнена колонка ""Номенклатура"" в строке %LineNumber% списка ""Материалы и работы""';
						|en = 'Column ""Items"" in line %LineNumber% of the ""Materials and works"" list is not filled in'; fa = 'Column ""Items"" in line %LineNumber% of the ""Materials and works"" list is not filled in';
						|it = 'Non è compilata la colonna ""Nomenclatura"" nella riga %LineNumber% dell''elenco ""Materiali e lavori""';
						|pl = 'Nie jest wypełniona kolumna ""Wykaz towarów"" w wierszu %LineNumber% na liście ""Materiały i prace""';
						|tr = '""Malzemeler ve İşler"" listesinin %LineNumber% satırında ""Öğe"" sütunu doldurulmadı'");
	
	For Each String In MaterialsAndWorks Do
		
		If Not ValueIsFilled(String.Products)
			And Not ValueIsFilled(String.RouteSheetItems) Then
			
			MessageText = StrReplace(TemplateError, "%LineNumber%", String(String.LineNumber));
			Field = CommonClientServer.PathToTabularSection("MaterialsAndWorks", String.LineNumber, "Products");
			
			Common.MessageToUser(MessageText, DataKey, Field, DataPath, Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CheckWhetherCharacteristicsAreFilledIn(Cancel, NotCheckedAttributeArray)
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.TSName = "MaterialsAndWorks";
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(
		ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.TSName = "ManufacturedProducts";
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(
		ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	
EndProcedure

Procedure CheckSeriesCompletion(Cancel, NotCheckedAttributeArray)
	
	DisableVerification = "FillCheckDisableSeriesControl";
	
	For Each KeyAndValue In ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ProductionOperation2_2) Do
		
		SeriesSpecificationParameters = KeyAndValue.Value; // ProductsClientServer.SeriesSpecificationParameters
		
		If Not SeriesSpecificationParameters.FactOfSelection Then
			AdditionalProperties.Insert(DisableVerification);
		ElsIf AdditionalProperties.Property(DisableVerification) Then
			AdditionalProperties.Delete(DisableVerification);
		EndIf;
		
		ProductsServer.CheckSeriesCompletion(ThisObject,
			SeriesSpecificationParameters,
			Cancel,
			NotCheckedAttributeArray);
		
	EndDo;
	
EndProcedure

Procedure CheckQuantityFilling(Cancel, NotCheckedAttributeArray)
	
	ProductionManagement.CheckFillingOfNumberOfWH(
		ThisObject, "MaterialsAndWorks", NotCheckedAttributeArray, Cancel);
	
	ProductionManagement.CheckFillingOfNumberOfWH(
		ThisObject, "ManufacturedProducts", NotCheckedAttributeArray, Cancel);
	
EndProcedure

Procedure CheckCompletionOfTeams(Cancel, NotCheckedAttributeArray)
	
	If Status <> Enums.ProductionOperationStatuses.Executed
		Or ValueIsFilled(Performer) Then
		
		NotCheckedAttributeArray.Add("LaborCosts.Performer");
		
	EndIf;
	
EndProcedure


Procedure ExcludeAttributesOfTableParts(CheckedAttributes)
	
	NamesOfTS = TabularSections();
	
	For IndexOf = -CheckedAttributes.UBound() To 0 Do
		PathParts = StrSplit(CheckedAttributes[-IndexOf], ".");
		If NamesOfTS.Find(PathParts[0]) <> Undefined Then
			CheckedAttributes.Delete(-IndexOf);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region UpdatingRelatedData

Function OperationDataBeforeChange()
	
	AttributeSet = 
		"Status,
		|Stage,
		|Posted,
		|DeletionMark,
		|WorkCenter,
		|ShiftTask,
		|Performer,
		|RunTime,
		|ExecutionTimeUnitOfMeasure,
		|Count,
		|FollowUp,
		|QuantityUnderRevision,
		|DefectiveGoodsCount,
		|CountCanceled,
		|CountReal,
		|RepetitionIsRequired,
		|OperationNumber,
		|NextOperation,
		|Protocol,
		|OperationID";
	
	If Not IsNew() Then
		DataBeforeChange = Common.ObjectAttributesValues(Ref, AttributeSet);
	Else
		DataBeforeChange = New Structure(AttributeSet);
		FillPropertyValues(DataBeforeChange, ThisObject);
	EndIf;
	
	Return DataBeforeChange;
	
EndFunction

Procedure AddTasksToProcessingStagesOfProduction()
	
	Stage_Changed = ChangedDocumentData("Stage", False);
	HasBeenConductedAndCompleted = AdditionalProperties.DataBeforeChange.Posted
		And AdditionalProperties.DataBeforeChange.Status = Enums.ProductionOperationStatuses.Executed;
	
	If Stage_Changed
		And Not AdditionalProperties.DataBeforeChange.Stage.IsEmpty() Then
		
		Actions = InformationRegisters.JobsForProcessingProductionStages.StructureOfActions();
		Actions.RefreshStatus = True;
		If HasBeenConductedAndCompleted Then
			Actions.FillInAccordingToOperations = Not ProductionProcessEditorMode();
		EndIf;
		
		InformationRegisters.JobsForProcessingProductionStages.AddJob(
			AdditionalProperties.DataBeforeChange.Stage,
			Actions);
		
	EndIf;
	
	If Not Stage.IsEmpty() Then
		
		Actions = InformationRegisters.JobsForProcessingProductionStages.StructureOfActions();
		Actions.RefreshStatus = ChangedDocumentData(ListOfAttributesToUpdateStateOfStage());
		If (DocumentsPosting.DocumentProperties(ThisObject).WriteMode = DocumentWriteMode.Posting
				And Status = Enums.ProductionOperationStatuses.Executed)
			Or (HasBeenConductedAndCompleted And Not Stage_Changed) Then
			
			Actions.FillInAccordingToOperations = Not ProductionProcessEditorMode();
			
		EndIf;
		
		InformationRegisters.JobsForProcessingProductionStages.AddJob(Stage, Actions);
		
	EndIf;
	
EndProcedure

Function ChangedDocumentData(AttributesList = "", ToCheckState = True)
	
	DataBeforeChange = AdditionalProperties.DataBeforeChange;
	DocumentProperties = DocumentsPosting.DocumentProperties(ThisObject);
	
	If ToCheckState Then
		If (DataBeforeChange.Posted
				And DocumentProperties.WriteMode = DocumentWriteMode.UndoPosting)
			Or (Not DataBeforeChange.Posted
				And DocumentProperties.WriteMode = DocumentWriteMode.Posting)
			Or IsNew() Then
			Return True;
		EndIf;
	EndIf;
	
	If Not IsBlankString(AttributesList) Then
		AttributesArray = StrSplit(AttributesList, ",");
		For Each AttributeName In AttributesArray Do
			If ThisObject[AttributeName] <> DataBeforeChange[AttributeName] Then
				Return True;
			EndIf;
		EndDo;
	EndIf;
	
	Return False;
	
EndFunction

Function ListOfAttributesToUpdateStateOfStage()
	
	Result = "Stage,Status,Count,CountReal,DefectiveGoodsCount";
	Return Result;
	
EndFunction

Function ListOfAttributesToRecalculateQueueOfOperations()
	
	Result = "Status,Count,RepetitionIsRequired,RunTime,ExecutionTimeUnitOfMeasure,
	|FollowUp,QuantityUnderRevision,DefectiveGoodsCount,CountCanceled,CountReal,
	|OperationNumber,NextOperation,WorkCenter,Performer,ShiftTask,
	|OperationID";
	Return StrReplace(Result, Chars.LF, "");
	
EndFunction

Function ListOfAttributesToFillInQueueFields()
	
	Result = "Stage,Department,Operation,OperationID,OperationNumber,NextOperation,
	|ShiftTask,WorkCenter,Performer";
	Return StrReplace(Result, Chars.LF, "");
	
EndFunction

Procedure RecalculateQueueOfOperations(Cancel)

	If Cancel
		Or Not ChangedDocumentData(ListOfAttributesToRecalculateQueueOfOperations()) Then
		Return;
	EndIf;
	
	If Not BasedOnMasterData Then
		
		Set = InformationRegisters.QueueOfProductionOperations.CreateRecordSet();
		Set.Filter.ProductionOperation.Set(Ref);
		
		If Posted
			And IncludedInTechnologicalProcess > 0
			And Not ProductionProcessEditorMode() Then
			
			TechProcessParameters = ProductionProcessEditorServerCall.ParametersOfTechnicalProcessOfStage(Stage);
			If TechProcessParameters.TechnologicalProcessType <> Enums.TechnologicalProcessTypesOfStage.Individual_ Then
				Common.MessageToUser(
					ProductionProcessEditorClientServer.TextSwitchProcessTechnologyToIndividualMode(),,,,Cancel);
				Return;
			EndIf;
			
			Record = Set.Add();
			
			Record.ProductionOperation = Ref;
			Record.ReferenceOrder = Common.ObjectAttributeValue(Stage, "ReferenceOrder");
			FillPropertyValues(Record, ThisObject, ListOfAttributesToFillInQueueFields());
			Record.Required2 = Count - CountCanceled;
			
			AttributesList = New Structure;
			AttributesList.Insert("Status", "Status");
			AttributesList.Insert("Posted", "Posted");
			AttributesList.Insert("UseManufacturingExecutionSystem", "Department.UseManufacturingExecutionSystem");
			AttributesList.Insert("UseShiftTasks", "Department.UseShiftTasks");
			AttributesValues = Common.ObjectAttributesValues(Stage, AttributesList);
			
			Record.InArchive = Documents.ProductionStage2_2.ArchiveQueueAttributes(AttributesValues);
			Record.TechnologicalProcessFactor = TechProcessParameters.TechnologicalProcessFactor;
			
		EndIf;
		
		Set.Write();
		
	EndIf;
	
	If GroupProcessingMode() Then
		Return;
	EndIf;
	
	QueueCalculationParameters = InformationRegisters.QueueOfProductionOperations.QueueCalculationParameters();
	
	If BasedOnMasterData Then
		
		OperationKey = ProductionManagementClientServer.ProductionOperationKey();
		FillPropertyValues(OperationKey, ThisObject);
		
		QueueCalculationParameters.CalculateAllSubsequentOperations = ChangedDocumentData("DefectiveGoodsCount", False)
			Or ChangedDocumentData() And DefectiveGoodsCount > 0;
		
		InformationRegisters.QueueOfProductionOperations.RecalculateQueue(OperationKey, QueueCalculationParameters, Cancel);
		
		If BasedOnPlanning Then
			InformationRegisters.PostOperativeSchedule2_2.RecalculateQuantitativeResourcesByKey(OperationKey, LotNumber, Cancel);
		EndIf;
		
	ElsIf IncludedInTechnologicalProcess > 0 Then
		
		Data_Stage = Documents.ProductionStage2_2.DataForCalculatingOperationQueue(Stage, True)[Stage];
		InformationRegisters.QueueOfProductionOperations.CalculateQueueBasedOnStageData(Stage, Data_Stage, QueueCalculationParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

Procedure FillInNumber()
	
	If Not ValueIsFilled(Stage)
		Or (ValueIsFilled(Number) And AdditionalProperties.DataBeforeChange.Stage = Stage) Then
		Return;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	MAX(ProductionOperation2_2.StageOperationNumber) AS StageOperationNumber
	|INTO TTStageOperationNumber
	|FROM
	|	Document.ProductionOperation2_2 AS ProductionOperation2_2
	|WHERE
	|	ProductionOperation2_2.Stage = &Stage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductionStage2_2.Number AS StageNumber,
	|	ISNULL(TTStageOperationNumber.StageOperationNumber, 0) AS StageOperationNumber
	|FROM
	|	Document.ProductionStage2_2 AS ProductionStage2_2
	|		LEFT JOIN TTStageOperationNumber AS TTStageOperationNumber
	|		ON (TRUE)
	|WHERE
	|	ProductionStage2_2.Ref = &Stage");
	
	Query.SetParameter("Stage", Stage);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	StageOperationNumber = Selection.StageOperationNumber + 1;
	Number = "" + Selection.StageNumber + "." + Format(StageOperationNumber, "NG=0");
	
EndProcedure

Procedure FillInIdentifier(WriteMode)
	
	If BasedOnMasterData
			Or Not IncludedInTechnologicalProcess Then
		Return;
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting
		And OperationID = 0 Then
		
		Query = New Query("
		|SELECT TOP 1
		|	NestedQuery.OperationID
		|FROM
		|	(SELECT
		|		0 AS OperationID
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		T.OperationID
		|	FROM
		|		Document.ProductionOperation2_2 AS T
		|	WHERE
		|		T.Stage = &Stage
		|		AND T.Posted
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		T.OperationID
		|	FROM
		|		InformationRegister.QueueOfProductionOperations AS T
		|	WHERE
		|		T.Stage = &Stage) AS NestedQuery
		|	
		|ORDER BY
		|	OperationID DESC
		|");
		
		Query.SetParameter("Stage", Stage);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			OperationID = Selection.OperationID + 1;
		EndIf;
		
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		
		OperationID = 0;
		
	EndIf;
	
EndProcedure

Procedure SetGroupProcessingMode() Export
	
	AdditionalProperties.Insert("KeyGroupProcessingMode");
	
EndProcedure

// The Operation is in group processing mode
// 
// Returns:
//  Boolean
Function GroupProcessingMode() Export

	Return AdditionalProperties.Property("KeyGroupProcessingMode");
	
EndFunction

Function FilterOperations(FillingData = Undefined)
	
	Result = New Structure("Operation,OperationID", Operation, OperationID);
	
	If FillingData <> Undefined Then
		
		If FillingData.Property("OperationKey") Then
			FillPropertyValues(Result, FillingData.OperationKey);
		Else
			FillPropertyValues(Result, FillingData);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure SetSplitMode() Export
	
	AdditionalProperties.Insert("Partitioning");
	
EndProcedure

// The Operation is in partitioning mode
// 
// Returns:
//  Boolean
Function SplittingMode() Export
	
	Return AdditionalProperties.Property("Partitioning");
	 
EndFunction

Procedure SetProductionProcessEditorMode() Export
	
	AdditionalProperties.Insert("KeyProductionProcessEditorMode");
	
EndProcedure

// The Operation is in the recording mode from the production process editor
// 
// Returns:
//  Boolean
Function ProductionProcessEditorMode() Export
	
	Return AdditionalProperties.Property("KeyProductionProcessEditorMode");
	
EndFunction

Procedure SetKeyInRowsOfTableParts(Cancel)
	
	OrdersServer.SetKeyInRowsOfTablePart(
		ThisObject, "LaborCosts", "MaximumRowCodeLaborCosts");
	
EndProcedure

Procedure RestorePerformersOfLaborCosts()
	
	LaborCostsBeforeRecalculation = Undefined; // ValueTable
	
	If Not AdditionalProperties.Property("LaborCosts", LaborCostsBeforeRecalculation) Then
		Return;
	EndIf;
	
	LaborCostsResult = LaborCosts.UnloadColumns();
	
	LaborCostsBeforeRecalculation.GroupBy("WorkKind,Performer,WorkAssignment", "Count");
	LaborCostsBeforeRecalculation.Indexes.Add("WorkKind");
	
	TheStructureOfTheSearch = New Structure("WorkKind");
	
	While LaborCosts.Count() > 0 Do
		
		RowData = LaborCosts[0];
		If RowData.Count = 0 Then
			LaborCosts.Delete(0);
			Continue;
		EndIf;
		
		NewRow = LaborCostsResult.Add();
		FillPropertyValues(NewRow, RowData);
		
		TheStructureOfTheSearch.WorkKind = RowData.WorkKind;
		
		For Each FoundRow In LaborCostsBeforeRecalculation.FindRows(TheStructureOfTheSearch) Do
			If FoundRow.Count > 0 
				And (ValueIsFilled(FoundRow.Performer)
					Or ValueIsFilled(FoundRow.WorkAssignment)) Then
				
				ToSetOff = Min(RowData.Count, FoundRow.Count);
				
				NewRow.Count      = ToSetOff;
				NewRow.Performer     = FoundRow.Performer;
				NewRow.WorkAssignment = FoundRow.WorkAssignment;
				
				FoundRow.Count  = FoundRow.Count - ToSetOff;
				
				Break;
			EndIf;
		EndDo;
		
		RowData.Count = RowData.Count - NewRow.Count;
		
	EndDo;
	
	LaborCosts.Load(LaborCostsResult);
	
EndProcedure

Procedure RestoreBatches()
	
	TableBeforeRecalculation = Undefined; // ValueTable
	
	For Each TSName In StrSplit("ManufacturedProducts,MaterialsAndWorks", ",") Do
		
		If Not AdditionalProperties.Property(TSName, TableBeforeRecalculation) Then
			Continue;
		EndIf;
		
		TableBeforeRecalculation.GroupBy("Products,Characteristic,Series,Package", "Count,NumberOfPackages");
		
		RestoreBatchesInTable(ThisObject[TSName], TableBeforeRecalculation);
		
	EndDo;
	
	If AdditionalProperties.Property("BatchFinishedProducts", TableBeforeRecalculation)
		And TableBeforeRecalculation.Count() > 0 Then
		
		BatchFinishedProducts.Load(ManufacturedProducts.Unload());
		BatchFinishedProducts.GroupBy("Products,Characteristic,Count");
		
		RestoreBatchesInTable(BatchFinishedProducts, TableBeforeRecalculation, False, False);
		
	EndIf;
	
EndProcedure

Procedure RestoreBatchesInTable(TableIsCurrent, TableBeforeRecalculation, ThereArePackages = True, LeaveLinesWithoutBatch = True)
	
	PackingDetails = "Products,Package";
	SearchAttributes   = "Products,Characteristic";
	TheStructureOfTheSearch   = New Structure(SearchAttributes);
	
	TableBeforeRecalculation.Indexes.Add(SearchAttributes);
	ResultTable1 = TableIsCurrent.UnloadColumns(); // ValueTable
	
	If ThereArePackages Then
		ProductsPackage = ResultTable1.CopyColumns(PackingDetails);
		TMCommonUse.AddRowsToTable(ProductsPackage, TableIsCurrent);
		TMCommonUse.AddRowsToTable(ProductsPackage, TableBeforeRecalculation);
		PackingFactors = Catalogs.PackagesAndUnitsOfMeasure.PackingFactors(ProductsPackage);
	EndIf;
	
	While TableIsCurrent.Count() > 0 Do
		
		RowData = TableIsCurrent[0];
		If RowData.Count = 0 Then
			TableIsCurrent.Delete(0);
			Continue;
		EndIf;
		
		NewRow = ResultTable1.Add();
		FillPropertyValues(NewRow, RowData);
		FillPropertyValues(TheStructureOfTheSearch, RowData, SearchAttributes);
		
		For Each FoundRow In TableBeforeRecalculation.FindRows(TheStructureOfTheSearch) Do
			If FoundRow.Count > 0
				And ValueIsFilled(FoundRow.Series) Then
				
				ToSetOff = Min(RowData.Count, FoundRow.Count);
				
				NewRow.Count     = ToSetOff;
				NewRow.Series          = FoundRow.Series;
				FoundRow.Count = FoundRow.Count - ToSetOff;
				
				If ThereArePackages Then
					ZoomRatio = PackingFactors[FoundRow.Products][FoundRow.Package];
					NewRow.NumberOfPackages = ToSetOff / ?(ValueIsFilled(ZoomRatio), ZoomRatio, 1);
					NewRow.Package           = FoundRow.Package;
				EndIf;
				
				Break;
			EndIf;
		EndDo;
		
		RowData.Count = RowData.Count - NewRow.Count;
		
		If ThereArePackages Then
			ZoomRatio = PackingFactors[RowData.Products][RowData.Package];
			RowData.NumberOfPackages = RowData.NumberOfPackages - NewRow.Count / ?(ValueIsFilled(ZoomRatio), ZoomRatio, 1);
		EndIf;
		
	EndDo;
	
	TableIsCurrent.Clear();
	For IndexOf = 0 To ResultTable1.Count() - 1 Do
		RowData = ResultTable1[IndexOf];
		If LeaveLinesWithoutBatch
			Or ValueIsFilled(RowData.Series) Then
			FillPropertyValues(TableIsCurrent.Add(), RowData);
		EndIf;
	EndDo;
	
EndProcedure

Function DescriptionOfTablesForRecalculationOfStandards()
	
	NumberOfProductOperations = ?(Status = Enums.ProductionOperationStatuses.Executed,
								CountReal + QuantityUnderRevision + FollowUp,
								Count - DefectiveGoodsCount - CountCanceled);
	OperationsCount        = ?(Status = Enums.ProductionOperationStatuses.Executed,
								CountReal + DefectiveGoodsCount + QuantityUnderRevision + FollowUp,
								Count - CountCanceled);
								
	AttributesList      = "TSName,Product,ThereArePackages,OperationsCount";
	
	DescriptionOfTables = New Structure;
	DescriptionOfTables.Insert("ManufacturedProducts",  New Structure(AttributesList, "ManufacturedProducts",  True, True, NumberOfProductOperations));
	DescriptionOfTables.Insert("RecyclableWaste", New Structure(AttributesList, "RecyclableWaste", True, True, OperationsCount));
	DescriptionOfTables.Insert("MaterialsAndServices", New Structure(AttributesList, "UsedMaterials",        False,   True, OperationsCount));
	DescriptionOfTables.Insert("LaborCosts",     New Structure(AttributesList, "LaborCosts",     False,   False,   OperationsCount));
	
	Return DescriptionOfTables;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
