#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Print

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	SetPrivilegedMode(True);
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "BOMsTree") Then
		
		SpreadsheetDocument = FormPrintedFormsOfSpecificationTree(ObjectsArray, PrintObjects, PrintParameters);
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"BOMsTree",
			NStr("vi = 'Cây bảng kê chi tiết các nguồn lực sản xuất';
				|ru = 'Дерево спецификации';
				|en = 'BOM tree'; fa = 'درخت فهرست مواد';
				|it = 'Albero della specifica';
				|pl = 'Drzewo specyfikacji';
				|tr = 'Ürün ağacı'"),
			SpreadsheetDocument);
		
	EndIf;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

Function FormPrintedFormsOfSpecificationTree(ObjectsArray, PrintObjects, PrintParameters)
	
	TreeOfSpecificationsValue = GetFromTempStorage(PrintParameters.AddressInStorage);
	
	TabDocument = New SpreadsheetDocument;
	TabDocument.PrintParametersName = "PRINT_OPTIONS_BOMsTree";
	
	Template = DataProcessors.BillsOfMaterialsTree.GetTemplate("BOMsTree");
	
	TemplateArea = Template.GetArea("Title");
	TemplateArea.Parameters.TitleText = NStr("vi = 'Cây bảng kê chi tiết các nguồn lực sản xuất';
											|ru = 'Дерево спецификации';
											|en = 'BOM tree'; fa = 'درخت فهرست مواد';
											|it = 'Albero della specifica';
											|pl = 'Drzewo specyfikacji';
											|tr = 'Ürün ağacı'");
	TabDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("TableHeader");
	TabDocument.Put(TemplateArea);
	
	Level = 1;
	TabDocument.StartRowAutoGrouping();
	
	For Each String In TreeOfSpecificationsValue.Rows Do
		
		Count = String.Count;
		
		OutputStringOfSpecificationTree(TabDocument, Template, String, Level, Count);
		
	EndDo;
	
	TabDocument.EndRowAutoGrouping();
	
	TemplateArea = Template.GetArea("Footer");
	TabDocument.Put(TemplateArea);
	
	Return TabDocument;
	
EndFunction

Procedure OutputStringOfSpecificationTree(TabDocument, Template, TreeRow, Level, ProductsQuantity = 1)
	
	If TreeRow.LineKind = "MaterialsAndServices"
		Or TreeRow.LineKind = "ManufacturedProducts"
		Or TreeRow.LineKind = "LaborCosts" Then
		TemplateArea = Template.GetArea("Group");
		TemplateArea.Parameters.Products = TreeRow.Products;
	Else
		TemplateArea = Template.GetArea("String");
		TemplateArea.Parameters.Fill(TreeRow);
	EndIf;
	
	AreaRow = TabDocument.Put(TemplateArea, Level);
	TabDocument.Area(AreaRow.Top,1+1).Indent = Level - 1;
	
	If TreeRow.Rows.Count() > 0 Then
		
		Level = Level + 1;
		
		For Each String In TreeRow.Rows Do
			
			OutputStringOfSpecificationTree(TabDocument, Template, String, Level, String.Count);
			
		EndDo;
		
		Level = Level - 1;
		
	EndIf;
	
EndProcedure

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
	
	ChoiceParameterLinks = New Structure(ProductDataManagementClientServer.ProductDataStructureFieldsForSelectingSpecifications());
	ChoiceParameterLinks.Products            = "Object.BOMsTree.Products";
	ChoiceParameterLinks.Characteristic          = "Object.BOMsTree.Characteristic";
	ChoiceParameterLinks.ProductionStart      = "Object.TreeDate";
	ChoiceParameterLinks.ProductionDispatcherBusinessUnit  = "Object.AssignmentParameterDivisionManager";
	ChoiceParameterLinks.LineOfBusiness = "Object.DestinationParameterActivityDirection";
	
#Region ManufacturedProducts

	TSSpecificationSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	
	TSSpecificationSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.Disassembly);
	
	TSSpecificationSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
	
	TSSpecificationSelectionParameters.ChoiceParameterLinks.Insert("BOMsTree.BillOfMaterials", ChoiceParameterLinks);
	
	BOMSelectionParameters.Insert("ManufacturedProducts", TSSpecificationSelectionParameters);
	
#EndRegion
	
#Region MaterialsAndServices

	TSSpecificationSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	
	TSSpecificationSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.Assembly);
	TSSpecificationSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.PerformRM);
	TSSpecificationSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.Repair); // repair bills of materials are separated by the type of item
	
	TSSpecificationSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
	
	TSSpecificationSelectionParameters.ChoiceParameterLinks.Insert("BOMsTree.BillOfMaterials", ChoiceParameterLinks); 
	
	BOMSelectionParameters.Insert("MaterialsAndServices", TSSpecificationSelectionParameters);
	
#EndRegion

#Region MaterialsAndServices_KitRAndM

	TSSpecificationSelectionParameters = Common.CopyRecursive(TSSpecificationSelectionParameters);
	
	TSSpecificationSelectionParameters.AvailableTypes.Clear();
	TSSpecificationSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.Assembly);
	TSSpecificationSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.Repair); // repair bills of materials are separated by the type of item
	
	
	BOMSelectionParameters.Insert("MaterialsAndServices_KitRAndM", TSSpecificationSelectionParameters);
	
#EndRegion

#Region MaterialsAndServices_RepairWork

	TSSpecificationSelectionParameters = Common.CopyRecursive(TSSpecificationSelectionParameters);
	
	TSSpecificationSelectionParameters.AvailableTypes.Clear();
	TSSpecificationSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.PerformRM);
	
	BOMSelectionParameters.Insert("MaterialsAndServices_RepairWork", TSSpecificationSelectionParameters);
	
#EndRegion
	
	Return BOMSelectionParameters;
	
EndFunction

// The names of the details, the values of which depend on the selection parameters spec
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSelectingSpecifications() Export
	
	AttributesNames = "";
	Return AttributesNames;
	
EndFunction

#EndRegion

#EndRegion

#EndIf