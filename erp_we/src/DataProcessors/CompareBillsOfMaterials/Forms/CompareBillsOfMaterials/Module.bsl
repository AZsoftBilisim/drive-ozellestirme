
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	ShowOnlyDifferences = True;
	Items.FormShowOnlyDifferences.Check = ShowOnlyDifferences;
	
	If Parameters.Property("ListOfSources") Then
		For Each CollectionItem In Parameters.ListOfSources Do
			BOMList.Add(CollectionItem);
		EndDo; 
		
		PerformComparisonOnServer();
	EndIf; 
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	ProductAndMaterialComparisonMode = Settings.Get("ProductAndMaterialComparisonMode");
	MarkCommandToChangeComparisonMode(Items, ProductAndMaterialComparisonMode);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PerformComparison(Command)
	
	PerformComparisonOnServer();
	
EndProcedure

&AtClient
Procedure ShowOnlyDifferences(Command)
	
	ShowOnlyDifferences = Not ShowOnlyDifferences;
	Items.FormShowOnlyDifferences.Check = ShowOnlyDifferences;
	
	DisplayReportOnServer();
	
EndProcedure

&AtClient
Procedure SetComparisonModeInStorageUnits(Command)
	
	ProductAndMaterialComparisonMode = 0;
	MarkCommandToChangeComparisonMode(Items, ProductAndMaterialComparisonMode);
	
	DisplayReportOnServer();
	
EndProcedure

&AtClient
Procedure SetComparisonModeInUnitsOfSpecifications(Command)
	
	ProductAndMaterialComparisonMode = 1;
	MarkCommandToChangeComparisonMode(Items, ProductAndMaterialComparisonMode);
	
	DisplayReportOnServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure DisplayReportOnServer(Val ComparisonDataStore = Undefined)

	ComparisonResult.Clear();
	
	If ComparisonDataStore = Undefined Then
		If Not IsTempStorageURL(ComparisonResultAddress) Then
			Return;
		EndIf;
		
		ComparisonDataStore = GetFromTempStorage(ComparisonResultAddress);
	EndIf; 
	
	ThereAreDifferences = DataProcessors.CompareBillsOfMaterials.OutputReport(
							ComparisonResult, 
							ComparisonDataStore.BOMList, 
							ShowOnlyDifferences, 
							ComparisonDataStore.ComparisonData_);
							
	DataProcessors.CompareBillsOfMaterials.CompleteReportOutput(ComparisonResult, ThereAreDifferences);

EndProcedure
 
&AtServer
Procedure PerformComparisonOnServer()
	
	AttributesValues = Common.ObjectsAttributesValues(BOMList.UnloadValues(), "IsFolder");

	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	BillsOfMaterials.Ref,
	|	BillsOfMaterials.Presentation
	|FROM
	|	Catalog.BillsOfMaterials AS BillsOfMaterials
	|WHERE
	|	BillsOfMaterials.Ref IN HIERARCHY(&BOMList)
	|	AND NOT BillsOfMaterials.IsFolder
	|
	|ORDER BY
	|	BillsOfMaterials.Description";
	
	Query.SetParameter("BOMList", BOMList);
	
	SpecificationTable_ = Query.Execute().Unload(); // See ProductionServer.ServiceStructureOfValueTable
	
	// You need to form a list in the right order
	ListOfSpecificationsForComparison = New ValueList;
	For Each SelectedSpecification In BOMList Do
		
		If Not ValueIsFilled(SelectedSpecification.Value) Then
			Continue;
		EndIf;
		
		For Each StringSpecification In SpecificationTable_ Do
			If AttributesValues[SelectedSpecification.Value].IsFolder Then
				If StringSpecification.Ref.BelongsToItem(SelectedSpecification.Value) Then
					ListOfSpecificationsForComparison.Add(StringSpecification.Ref, StringSpecification.Presentation);
				EndIf;
			Else
				If StringSpecification.Ref = SelectedSpecification.Value Then
					ListOfSpecificationsForComparison.Add(StringSpecification.Ref, StringSpecification.Presentation);
				EndIf;
			EndIf;
		EndDo; 
		
	EndDo;
	
	ComparisonData_ = DataProcessors.CompareBillsOfMaterials.PerformComparisonOfSpecifications(
						ListOfSpecificationsForComparison, ProductAndMaterialComparisonMode);
	
	ComparisonDataStore = New Structure;
	ComparisonDataStore.Insert("ComparisonData_", ComparisonData_);
	ComparisonDataStore.Insert("BOMList", ListOfSpecificationsForComparison);
	
	ComparisonResultAddress = PutToTempStorage(ComparisonDataStore, UUID);
	
	DisplayReportOnServer(ComparisonDataStore);
	
EndProcedure

&AtClientAtServerNoContext
Procedure MarkCommandToChangeComparisonMode(Items, ProductAndMaterialComparisonMode)
	
	ComparisonModeInStorageUnits = ProductAndMaterialComparisonMode = 0;
	Items.FormSetComparisonModeInStorageUnits.Check     = ComparisonModeInStorageUnits;
	Items.FormSetComparisonModeInUnitsOfSpecifications.Check = Not ComparisonModeInStorageUnits;
	
EndProcedure

#EndRegion
