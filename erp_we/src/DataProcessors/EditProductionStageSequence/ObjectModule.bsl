#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in processing data for production stages.
//
// Parameters:
//  FillingData - Structure - fill-in data
//
Procedure Read(FillingData) Export
	
	Clear();
	
	ProductionBatchData = Documents.ProductionStage2_2.ProductionBatchData(
		FillingData.ReferenceOrder,
		FillingData.AssignmentProducts,
		FillingData.ProductionLot);
	FillPropertyValues(ThisObject, ProductionBatchData);
	
	If ProductionLot.IsEmpty() Then
		
		If Not FillingData.Property("ProductionProcessType", ProductionProcessType) Then
			ProductionProcessType = Enums.ProductionProcessTypes.Assembly;
		EndIf;
		
		Return; // there are no stages
		
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("DeletionMark", False);
	Filter.Insert("ProductionLot", FillingData.ProductionLot);
	
	StageList = Documents.ProductionStage2_2.FindStages(Filter);
	
	QueryText = "
	|SELECT
	|	*,
	|	&TechProcessParameters
	|FROM
	|	Document.ProductionStage2_2 AS Table
	|
	|	LEFT JOIN InformationRegister.TechnologicalProcessesOfProductionStages AS TechnicalProcess
	|	ON Table.Ref = TechnicalProcess.Stage
	|
	|WHERE
	|	Table.Ref IN (&StageList)
	|	AND NOT Table.DeletionMark
	|
	|ORDER BY
	|	StageNumber,
	|	NextStageNo
	|";
	
	QueryText = StrReplace(QueryText,
		"&TechProcessParameters",
		ProductionProcessEditor.QueryTextParametersOfTechnicalProcessOfStage("Table"));
	
	Query = New Query(QueryText);
	Query.SetParameter("StageList", StageList);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	ListOfTS = ListOfNestedTableParts();
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		NewRow = Stages.Add();
		FillPropertyValues(NewRow, Selection);
		
		For Each TSName In ListOfTS Do
			
			ResultTS = Selection[TSName];// QueryResult - 
			NestedSelection = ResultTS.Select();
			
			While NestedSelection.Next() Do
				Table = ThisObject[TSName];// TabularSection - 
				NewRow = Table.Add();
				FillPropertyValues(NewRow, NestedSelection);
			EndDo;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Clears the data processing
//
Procedure Clear() Export
	
	Attributes = Metadata.DataProcessors.EditProductionStageSequence.Attributes;
	For Each Item In Attributes Do
		ThisObject[Item.Name] = Undefined;
	EndDo;
	
	TS = Metadata.DataProcessors.EditProductionStageSequence.TabularSections;
	For Each Item In TS Do
		ThisObject[Item.Name].Clear();
	EndDo;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	NotCheckedAttributeArray.Add("LineOfBusiness");
	NotCheckedAttributeArray.Add("Partner");
	NotCheckedAttributeArray.Add("Contract");
	
	// The details are checked in the processing form
	NotCheckedAttributeArray.Add("Stages.TechnologicalProcessFactor");
	NotCheckedAttributeArray.Add("Stages.NumberOfPackagesPlan");
	
	Documents.ProductionStage2_2.CheckUseOfBatchAccounting22(ThisObject, Cancel);
	
	TempTablesManager = Documents.ProductionStage2_2.TemporaryObjectDataTables(ThisObject);
	
	Documents.ProductionStage2_2.CheckObjectFilling(
		ThisObject,
		TempTablesManager,
		Cancel,
		CheckedAttributes);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, DataProcessors.EditProductionStageSequence);
	ProductsServer.CheckSeriesCompletion(ThisObject, SeriesSpecificationParameters.ManufacturedProducts, Cancel, NotCheckedAttributeArray);
	ProductsServer.CheckSeriesCompletion(ThisObject, SeriesSpecificationParameters.SideAndIntermediateRelease, Cancel, NotCheckedAttributeArray);
	ProductsServer.CheckSeriesCompletion(ThisObject, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks, Cancel, NotCheckedAttributeArray);
	ProductsServer.CheckSeriesCompletion(ThisObject, SeriesSpecificationParameters.MaterialsAndWorksConsumption, Cancel, NotCheckedAttributeArray);
	ProductsServer.CheckSeriesCompletion(ThisObject, SeriesSpecificationParameters.UnusedMaterials, Cancel, NotCheckedAttributeArray);
	
	ItemsAndDimensionsSelectionParameters = DataProcessors.EditProductionStageSequence.ItemsAndDimensionsSelectionParameters(ThisObject);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	RoundingParameters = Documents.ProductionStage2_2.TSParametersForRounding();
	ProductsServer.CheckQuantityRounding(ThisObject, Cancel, RoundingParameters["ManufacturedProducts"]);
	ProductsServer.CheckQuantityRounding(ThisObject, Cancel, RoundingParameters["SideAndIntermediateRelease"]);
	ProductsServer.CheckQuantityRounding(ThisObject, Cancel, RoundingParameters["SupplyWithMaterialsAndWorks"]);
	ProductsServer.CheckQuantityRounding(ThisObject, Cancel, RoundingParameters["UnusedMaterials"]);
	
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region Private

#Region StageList

Function DataOfProductionStages() Export
	
	DataOfProductionStages = ProductionManagement.DataStructureOfProductionStages();
	
	// Header
	For Each String In Stages Do
		NewRow = DataOfProductionStages.Attributes.Add();
		FillPropertyValues(NewRow, String);
	EndDo;
	// TS
	ListOfTS = New Array;
	ListOfTS.Add("ManufacturedProducts");
	ListOfTS.Add("SideAndIntermediateRelease");
	ListOfTS.Add("SupplyWithMaterialsAndWorks");
	ListOfTS.Add("MaterialsAndWorksConsumption");
	ListOfTS.Add("UnusedMaterials");
	ListOfTS.Add("LaborCosts");
	For Each TSName In ListOfTS Do
		If DataOfProductionStages.Property("CheckingTS" + TSName) Then
			DataOfProductionStages["CheckingTS" + TSName] = True;
			For Each String In ThisObject[TSName] Do
				Table = DataOfProductionStages[TSName];// ValueTable - 
				FillPropertyValues(Table.Add(), String);
			EndDo;
		EndIf;
	EndDo;
	
	Return DataOfProductionStages;
	
EndFunction

Function PathToDetailsOfEditingForm() Export
	
	Return "Object";
	
EndFunction

Function ListOfNestedTableParts()
	
	List = New Array;
	
	List.Add("ManufacturedProducts");
	List.Add("BatchFinishedProducts");
	List.Add("SideAndIntermediateRelease");
	List.Add("BatchSideAndIntermediateRelease");
	
	List.Add("SupplyWithMaterialsAndWorks");
	List.Add("MaterialsAndWorksConsumption");
	List.Add("UnusedMaterials");
	List.Add("SavingMaterialsBatch");
	List.Add("MaterialsAndWorksSets");
	
	List.Add("LaborCosts");
	
	Return List;
	
EndFunction

#EndRegion

#EndRegion

#EndIf

