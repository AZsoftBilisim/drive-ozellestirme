#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var MaxLevel_;

#EndRegion

#Region Public

// Performs report generation.
//
// Parameters:
//  SpreadsheetDocumentField	 - SpreadsheetDocument  - document for displaying the report.
// 
// Returns:
//  Boolean - True if the report is generated successfully. False otherwise.
//
Function GenerateReport(SpreadsheetDocumentField) Export
	
	Cancel = False;
	
	MaxLevel_ = 1000;
	
	ProcessSteps = Undefined; // See TableProcessSteps
	OperationsSheetList = New Array;
	AddProcessSteps(RouteSheet, ProcessSteps, 1, OperationsSheetList, -1, Cancel);
	
	If Cancel Then
		Return False;
	EndIf; 
	
	Template = GetTemplate("Template");
	
	// If there are more than 1 route maps, then we will color the operations
	ListOfColors = New Array;
	If OperationsSheetList.Count() > 1 Then
		Area_Colors = Template.GetArea("NestedMK_Colors");
		For Cnt = 1 To Area_Colors.TableHeight Do
			ListOfColors.Add(Area_Colors.Area(Cnt,1,Cnt,1).BackColor);
		EndDo;
	EndIf; 
	
	ProcessSteps.Columns.Add("Text1", New TypeDescription("String"));
	ProcessSteps.Columns.Add("Text2", New TypeDescription("String"));
	
	For Each StageString_ In ProcessSteps Do
		If StageString_.ContainsNestedRoute Then
			StageString_.Text1 = NStr("vi = 'Quy trình lồng nhau';
										|ru = 'Вложенный маршрут';
										|en = 'Nested route'; fa = 'مسیر تودرتو';
										|it = 'Ciclo di lavorazione inserito';
										|pl = 'Zagnieżdżona karta technologiczna';
										|tr = 'İç içe yol'");
		Else	
			StageString_.Text1 = NStr("vi = '%1';
										|ru = '%1';
										|en = '%1'; fa = '%1';
										|it = '%1';
										|pl = '%1';
										|tr = '%1'");
			StageString_.Text1 = StringFunctionsClientServer.SubstituteParametersToString(
											StageString_.Text1, 
											StageString_.DepartmentPresentation);
			
			StageString_.Text2 = StageString_.WorkCenterPresentation;
			StageString_.OutputParameters.Insert("TextPlacement2", SpreadsheetDocumentTextPlacementType.Wrap);
		EndIf;
		
		StageBackgroundColor = GetRouteMapColor(OperationsSheetList.Find(StageString_.Owner), ListOfColors);;
		StageString_.OutputParameters.Insert("StageBackgroundColor", StageBackgroundColor);
	EndDo;
	
	Result = UniversalDataProcessor.GenerateGraphicalPresentationOfProcess(ProcessSteps);
	
	SpreadsheetDocumentField.Clear();
	
	IndentArea = Template.GetArea("Indent");
	
	// Title
	HeaderArea_ = Template.GetArea("Title");
	HeaderArea_.Parameters.RouteSheet = RouteSheet;
	
	SpreadsheetDocumentField.Put(HeaderArea_);
	
	// List of nested march cards
	If OperationsSheetList.Count() > 1 Then
		SpreadsheetDocumentField.Put(IndentArea);
		SpreadsheetDocumentField.Put(Template.GetArea("NestedMK_Header"));
		SpreadsheetDocumentField.StartRowGroup(, False);
		
		NestedMKArea_String = Template.GetArea("NestedMK_String");
		For Each RouteMapOfScheme In OperationsSheetList Do
			NestedMKArea_String.Area(1,2,1,2).BackColor = GetRouteMapColor(OperationsSheetList.Find(RouteMapOfScheme), ListOfColors);
			NestedMKArea_String.Parameters.RouteSheet = RouteMapOfScheme;
			SpreadsheetDocumentField.Put(NestedMKArea_String);
		EndDo;
		SpreadsheetDocumentField.EndRowGroup();
	EndIf;
	
	// Schema
	SpreadsheetDocumentField.Put(Result.SpreadsheetDocument);
	
	Return True;
	
EndFunction

#EndRegion

#Region Private

// Constructor for the process stage table
//
// Returns:
// 	ValueTable - LongDesc:
// * Owner - CatalogRef.RouteSheets -
// * Details - CatalogRef.ManufacturingOperations -
// * Stage - CatalogRef.ManufacturingOperations -
// * NestedRoute - CatalogRef.RouteSheets -
// * PresentationStage - String -
// * OperationNumber - Number -
// * NextOperation - Number -
// * UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure -
// * ContainsNestedRoute - Boolean -
// * WorkCenterPresentation - String -
// * OutputParameters - Structure -
// * DurationOfDays - Number -
// * Parent  - ValueTable - 
// * SequenceNumber - Number -
// * StagesPredecessors - ValueTable -
// * Group - Number -
Function TableProcessSteps() Export
	
	Result = New ValueTable();
	
	Result.Columns.Add("Owner", New TypeDescription("CatalogRef.RouteSheets"));
	Result.Columns.Add("Stage", New TypeDescription("CatalogRef.ManufacturingOperations"));
	Result.Columns.Add("Details", New TypeDescription("CatalogRef.ManufacturingOperations"));
	Result.Columns.Add("NestedRoute", New TypeDescription("CatalogRef.RouteSheets"));
	Result.Columns.Add("PresentationStage", New TypeDescription("String"));
	Result.Columns.Add("OperationNumber", New TypeDescription("Number"));
	Result.Columns.Add("NextOperation", New TypeDescription("Number"));
	Result.Columns.Add("UnitOfMeasure", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Result.Columns.Add("ContainsNestedRoute", New TypeDescription("Boolean"));
	Result.Columns.Add("WorkCenterPresentation", New TypeDescription("String"));
	
	Result.Columns.Add("OutputParameters", New TypeDescription("Structure"));
	Result.Columns.Add("DurationOfDays", New TypeDescription("Number"));
	Result.Columns.Add("Parent");
	Result.Columns.Add("SequenceNumber", New TypeDescription("Number"));
	Result.Columns.Add("StagesPredecessors", New TypeDescription("ValueTable"));
	Result.Columns.Add("Group", New TypeDescription("Number"));
	
	Return Result;
	
EndFunction

// Gets the stages of the progenitor
// 
// Parameters:
// 	OperationNumber - Number - 
// 	Process_ - CatalogRef.RouteSheets - 
// 	Level - Number - 
// 	Group - Number - 
// 
// Returns:
// 	ValueTable - From:
// 		* ProcessStep - CatalogRef.ManufacturingOperations - 
// 		* Shop - CatalogRef.BusinessStructure - 
// 		* Group - Number - 
// 
Function GetStagesPredecessors(OperationNumber, Process_, Level, Group)
	
	Query = New Query;
	Query.Text = "SELECT
	               |	ManufacturingOperations.Ref AS ProcessStep,
	               |	CASE
	               |		WHEN ManufacturingOperations.WorkCenter REFS Catalog.WorkCenters
	               |			THEN ISNULL(CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenters).WorkCenterType.Department, """")
	               |		ELSE ISNULL(CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenterTypes).Department, """")
	               |	END AS Shop,
				   |	&Group AS Group
	               |FROM
	               |	Catalog.ManufacturingOperations AS ManufacturingOperations
	               |WHERE
	               |	ManufacturingOperations.Owner = &RouteSheet
	               |	AND NOT ManufacturingOperations.DeletionMark
	               |	AND ManufacturingOperations.NextOperation = &OperationNumber
	               |	AND (&Level = 1
	               |			OR &ShowOperationsOfNestedRoutes
	               |			OR ManufacturingOperations.ContainsNestedRoute)";

	Query.SetParameter("RouteSheet", Process_);
	Query.SetParameter("OperationNumber",   OperationNumber);
	Query.SetParameter("Level", Level);
	Query.SetParameter("Group", Group);
	Query.SetParameter("ShowOperationsOfNestedRoutes", ShowOperationsOfNestedRoutes);
		
 	Return Query.Execute().Unload();
	
EndFunction

Function AddProcessSteps(Process_, ProcessSteps, Level, OperationsSheetList, Group, Cancel)

	If Not Catalogs.RouteSheets.SequenceOfOperationsIsCorrect(RouteSheet, Cancel) Then
		Return Undefined;
	EndIf;
	
	Query = New Query;
	Query.Text = "SELECT
	               |	ManufacturingOperations.Owner AS Owner,
	               |	ManufacturingOperations.Ref AS Stage,
	               |	ManufacturingOperations.Presentation AS PresentationStage,
	               |	ManufacturingOperations.Ref AS Details,
	               |	ManufacturingOperations.OperationNumber AS OperationNumber,
	               |	ManufacturingOperations.NextOperation AS NextOperation,
	               |	ManufacturingOperations.UnitOfMeasure AS UnitOfMeasure,
	               |	ManufacturingOperations.ContainsNestedRoute AS ContainsNestedRoute,
	               |	ManufacturingOperations.NestedRoute AS NestedRoute,
	               |	ManufacturingOperations.WorkCenter.Presentation AS WorkCenterPresentation,
	               |	CASE
	               |		WHEN ManufacturingOperations.WorkCenter REFS Catalog.WorkCenters
	               |			THEN ISNULL(CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenters).WorkCenterType.Department, """")
	               |		ELSE ISNULL(CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenterTypes).Department, """")
	               |	END AS Department,
	               |	CASE
	               |		WHEN ManufacturingOperations.WorkCenter REFS Catalog.WorkCenters
	               |			THEN ISNULL(CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenters).WorkCenterType.Department.Presentation, """")
	               |		ELSE ISNULL(CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenterTypes).Department.Presentation, """")
	               |	END AS DepartmentPresentation
	               |FROM
	               |	Catalog.ManufacturingOperations AS ManufacturingOperations
	               |WHERE
	               |	ManufacturingOperations.Owner = &RouteSheet
	               |	AND NOT ManufacturingOperations.DeletionMark";
				   
	Query.SetParameter("RouteSheet", Process_);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	If ProcessSteps = Undefined Then
		ProcessSteps = QueryResult.CopyColumns();
		UniversalDataProcessor.AddRequiredColumnsToProcessSteps(ProcessSteps);
	EndIf;
	
	// We will leave only nested routes
	If Level > 1 And Not ShowOperationsOfNestedRoutes Then
		OperationArray = New Array;
		
		For Each Selection In QueryResult Do
			If Not Selection.ContainsNestedRoute Then
				OperationArray.Add(Selection.Stage);
			EndIf;
		EndDo; 
		
		// Delete operations
		For Each Stage In OperationArray Do
			DeletedStage = QueryResult.Find(Stage, "Stage");
			PreviousStages = QueryResult.FindRows(New Structure("NextOperation", DeletedStage.OperationNumber));
			For Each PreviousStage In PreviousStages Do
				PreviousStage.NextOperation = DeletedStage.NextOperation;
			EndDo;
			QueryResult.Delete(DeletedStage);
		EndDo; 
	EndIf; 
	
	If Level = 1 Or ShowOperationsOfNestedRoutes Then
		OperationsSheetList.Add(Process_);
	EndIf; 
	
	For Each Selection In QueryResult Do
		
		StageString_ = ProcessSteps.Add();
		FillPropertyValues(StageString_, Selection);
		StageString_.SequenceNumber = Format(MaxLevel_ - Level, "NG=0") + "_" + Format(Selection.OperationNumber, "NG=0");
		StageString_.Group = Group;
		
		StageString_.StagesPredecessors = GetStagesPredecessors(StageString_.OperationNumber, Process_, Level, Group);
		
		If Selection.ContainsNestedRoute Then
			
			NestedRouteStages = AddProcessSteps(
				Selection.NestedRoute,
				ProcessSteps,
				Level + 1,
				OperationsSheetList,
				ProcessSteps.IndexOf(StageString_),
				Cancel);
				
			For Each CollectionItem In NestedRouteStages Do
				NewRow = StageString_.StagesPredecessors.Add();
				FillPropertyValues(NewRow, CollectionItem);
				NewRow.Group = ProcessSteps.IndexOf(StageString_);
			EndDo;
			
			If Not ShowOperationsOfNestedRoutes Then
				StageString_.Owner = Selection.NestedRoute;
				OperationsSheetList.Add(Selection.NestedRoute);
			EndIf; 
			
		EndIf; 
		
	EndDo; 
	
	PredecessorsOfCurProcess = New ValueTable;
	PredecessorsOfCurProcess.Columns.Add("ProcessStep",  New TypeDescription("CatalogRef.ManufacturingOperations"));
	PredecessorsOfCurProcess.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	
	For Each Selection In QueryResult Do
		If Selection.NextOperation = 0 Then
			Stage = PredecessorsOfCurProcess.Add();
			Stage.ProcessStep  = Selection.Stage;
			Stage.Department = Selection.Department;
		EndIf; 
	EndDo; 
	
	Return PredecessorsOfCurProcess;
	
EndFunction

Function GetRouteMapColor(TemplateNumber, ListOfColors)

	If TemplateNumber < ListOfColors.UBound() Then
		Return ListOfColors.Get(TemplateNumber)
	Else
		Return New Color;
	EndIf; 

EndFunction

#EndRegion

#EndIf