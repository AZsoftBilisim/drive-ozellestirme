
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	For Each Parameter In Parameters.ExcludedAttributes Do
		FillPropertyValues(ExcludedAttributes.Add(), Parameter);
	EndDo;
	
	GenerateTreeOfSpecificationAssignmentParameters();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ExpandTreeRows();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ParameterTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = ParameterTree.FindByID(RowSelected);
	
	CompleteParameterSelection(CurrentData);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	CurrentData = Items.ParameterTree.CurrentData;
	
	If CurrentData <> Undefined Then
		CompleteParameterSelection(CurrentData);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateTreeOfSpecificationAssignmentParameters()
	
	TypesOfParameters = TypesOfBOMAssignmentParameters();
	
	Query = New Query;
	Query.SetParameter("AdditionalAttributeSets", TypesOfParameters.UnloadColumn("AdditionalAttributesSet"));
	Query.Text =
	"SELECT
	|	AdditionalAttributes.Ref             AS AdditionalAttributesSet,
	|	AdditionalAttributes.Property           AS Attribute
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS AdditionalAttributes
	|WHERE
	|	AdditionalAttributes.Ref IN(&AdditionalAttributeSets)
	|	AND NOT AdditionalAttributes.DeletionMark
	|
	|ORDER BY
	|	AdditionalAttributesSet,
	|	AdditionalAttributes.Property.Presentation";
	
	AdditionalAttributes = Query.Execute().Unload();
	
	Tree = FormAttributeToValue("ParameterTree");
	
	For IndexOf = 0 To TypesOfParameters.Count() - 1 Do
		
		String = TypesOfParameters[IndexOf];
		
		If ValueIsFilled(String.AdditionalAttributesSet) Then
			
			GroupString = AddRowToParameterTree(Tree, String.ParameterKind,, True);
			
			Attributes = AdditionalAttributes.FindRows(New Structure("AdditionalAttributesSet", String.AdditionalAttributesSet));
			For Each Attribute In Attributes Do
				
				AddRowToParameterTree(GroupString, GroupString.ParameterKind, Attribute.Attribute);
				
			EndDo;
			
			If GroupString.Rows.Count() = 0 Then
				Tree.Rows.Delete(GroupString);
			EndIf;
			
		Else
			
			AddRowToParameterTree(Tree, String.ParameterKind)
			
		EndIf;
		
	EndDo;
	
	ValueToFormAttribute(Tree, "ParameterTree");
	
EndProcedure

&AtServer
Function AddRowToParameterTree(Tree, ParameterKind, Attribute = Undefined, IsFolder = False)
	
	If Not IsFolder Then
	
		TheStructureOfTheSearch = New Structure("ParameterKind", ParameterKind);
		If ValueIsFilled(Attribute) Then
			TheStructureOfTheSearch.Insert("Attribute", Attribute);
		EndIf;
		
		If ExcludedAttributes.FindRows(TheStructureOfTheSearch).Count() > 0 Then
			Return Undefined;
		EndIf;
	
	EndIf;
	
	NewRow = Tree.Rows.Add();
	NewRow.ParameterKind          = ParameterKind;
	NewRow.Attribute              = Attribute;
	NewRow.IsFolder             = IsFolder;
	NewRow.Picture              = ?(IsFolder, 0, 3);
	
	If IsFolder Then
		NewRow.ParameterPresentation = String(ParameterKind);
	Else
		NewRow.ParameterPresentation = ProductDataManagement.PresentationOfDestinationParameter(ParameterKind, Attribute, False);
	EndIf;
	
	Return NewRow;
	
EndFunction

&AtServerNoContext
Function TypesOfBOMAssignmentParameters()
	
	Result = New ValueTable;
	Result.Columns.Add("ParameterKind", New TypeDescription("EnumRef.TypesOfBOMAssignmentParameters"));
	Result.Columns.Add("AdditionalAttributesSet", New TypeDescription("CatalogRef.AdditionalAttributesAndInfoSets"));
	Result.Columns.Add("Order", New TypeDescription("Number"));

	NewRow = Result.Add();
	NewRow.ParameterKind = Enums.TypesOfBOMAssignmentParameters.ProductionDispatcherBusinessUnit;
	NewRow.Order = 0;
	
	NewRow = Result.Add();
	NewRow.ParameterKind = Enums.TypesOfBOMAssignmentParameters.AdditionalAttributesOfBusinessUnit;
	NewRow.AdditionalAttributesSet = PropertyManager.PropertiesSetByName("Catalog_BusinessStructure");
	NewRow.Order = 2;
	
	If GetFunctionalOption("GenerateFinancialResult") Then
	
		NewRow = Result.Add();
		NewRow.ParameterKind = Enums.TypesOfBOMAssignmentParameters.LineOfBusiness;
		NewRow.Order = 1;
		
		NewRow = Result.Add();
		NewRow.ParameterKind = Enums.TypesOfBOMAssignmentParameters.AdditionalAttributesOfLineOfBusiness;
		NewRow.AdditionalAttributesSet = PropertyManager.PropertiesSetByName("Catalog_LinesOfBusiness");
		NewRow.Order = 3;
	
	EndIf;
	
	Result.Sort("Order");
	
	Return Result;
	
EndFunction

&AtClient
Procedure CompleteParameterSelection(CurrentData)
	
	If Not CurrentData.IsFolder Then
		
		Result = New Structure("ParameterKind, Attribute");
		FillPropertyValues(Result, CurrentData);
		
		NotifyChoice(Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpandTreeRows()
	
	For Each String In ParameterTree.GetItems() Do
		Items.ParameterTree.Expand(String.GetID());
	EndDo;
	
EndProcedure

#EndRegion