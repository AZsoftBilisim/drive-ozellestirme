///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DefineSettings();
	
	If ValueIsFilled(Parameters.FilterObject) Then
		MainObject = Parameters.FilterObject;
	EndIf;
	
	InitialObject = MainObject;
	
	If ValueIsFilled(MainObject) Then
		UpdateHierarchicalTree();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SearchStringTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	FindAndSelectString(Text);
EndProcedure

&AtClient
Procedure ReportTableOnActivate(Item)
	
	RowsSelected = New Array;
	
	SelectedAreas = Items.ReportTable.GetSelectedAreas();
	
	For Each SelectedArea1 In SelectedAreas Do 
		
		If TypeOf(SelectedArea1) <> Type("SpreadsheetDocumentRange") Then
			Continue;
		EndIf;
		
		NewArea = ReportTable.Area(SelectedArea1.Top, ,SelectedArea1.Bottom);
		RowsSelected.Add(NewArea);
	EndDo;
	
	If RowsSelected.Count() = 0 Then
		Return;
	EndIf;
	
	RowsSelected = CommonClientServer.CollapseArray(RowsSelected);
	
	Items.ReportTable.SetSelectedAreas(RowsSelected);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	OutputHierarchy();
	
EndProcedure

&AtClient
Procedure OutputForCurrentDocument(Command)
	
	CurrentArea = Items.ReportTable.CurrentArea;
	
	If CurrentArea = Undefined Then
		Return;
	EndIf;
	
	CurrentObject = FirstRowFieldDrilldown(CurrentArea.Top);
	
	If Not ValueIsFilled(CurrentObject) Then
		Return;
	EndIf;
	
	MainObject = CurrentObject;
	
	OutputHierarchy();
	
EndProcedure

&AtClient
Procedure ChangeDeletionMark(Command)
	
	ClearMessages();
	
	SelectedItems = SelectedItems();
	
	If SelectedItems.Count() = 0 Then
		Return;
	EndIf;
	
	Statistics = StatisticsBySelectedItems(SelectedItems);
	
	Scenario = DeletionMarkEditScenario(SelectedItems, Statistics);
	Scenario.Insert("SelectedItems", SelectedItems);
	SelectedItemsPresentations = ?(Scenario.Check, Statistics.NoDeletionMark, Statistics.WithDeletionMark);
	Scenario.Insert("SelectedItemsPresentations", SelectedItemsPresentations);
	
	Handler = New CallbackDescription("ExecuteDeletionMarkChangeScenario", ThisObject, Scenario);
	ShowQueryBox(Handler, Scenario.DoQueryBox, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure Post(Command)
	
	ChangeDocumentsPosting(DocumentWriteMode.Posting);
	
EndProcedure

&AtClient
Procedure CancelPosting(Command)
	
	ChangeDocumentsPosting(DocumentWriteMode.UndoPosting);
	
EndProcedure

&AtClient
Procedure FindNextLine(Command)
	SearchStart = Undefined;
	SelectedAreas = Items.ReportTable.GetSelectedAreas();
	For Each SelectedArea1 In SelectedAreas Do 
		If TypeOf(SelectedArea1) = Type("SpreadsheetDocumentRange") Then
			NextStringUp = SelectedArea1.Top + 1;
			NextStringDown = SelectedArea1.Bottom + 1;
			SearchStart = ReportTable.Area(NextStringUp, 1,NextStringDown, 1);
			Break;
		EndIf;
	EndDo;
	SearchStart = ?(SearchStart <> Undefined, SearchStart, Undefined);
	
	FindAndSelectString(SearchString, SearchStart);
EndProcedure

#EndRegion

#Region Private

#Region ProceduresForOutputToSpreadsheet

&AtServer
Procedure OutputSpreadsheetDocument()

	ReportTable.Clear();
	
	Template = GetCommonTemplate("SubordinationStructure");
	
	OutputParentTreeItems(TreeParentObjects.GetItems(), Template);
	OutputCurrentObject(Template);
	OutputSubordinateTreeItems(TreeSubordinateObjects.GetItems(), Template);
	
EndProcedure

// Parameters:
//  TreeRows - FormDataTreeItemCollection
//  Template - SpreadsheetDocument
//  RecursionLevels - Number
//
&AtServer
Procedure OutputParentTreeItems(TreeRows, Template, RecursionLevels = 1)
	
	Counter =  TreeRows.Count();
	While Counter > 0 Do
		
		CurrentTreeRow = TreeRows.Get(Counter - 1);
		
		SubordinateTreeRowItems = CurrentTreeRow.GetItems();
		OutputParentTreeItems(SubordinateTreeRowItems, Template, RecursionLevels + 1);
		
		For Level = 1 To RecursionLevels Do
			
			If Level = RecursionLevels Then
				
				If TreeRows.IndexOf(CurrentTreeRow) < (TreeRows.Count() - 1) Then
					Area = Template.GetArea("ConnectorTopRightBottom");
				Else
					Area = Template.GetArea("ConnectorRightBottom");
				EndIf;
				
			Else
				
				If OutputVerticalConnector(RecursionLevels - Level + 1, CurrentTreeRow, False) Then
					Area = Template.GetArea("ConnectorTopBottom");
				Else
					Area = Template.GetArea("Indent");
				EndIf;
				
			EndIf;
			
			If Level = 1 Then
				ReportTable.Put(Area);
			Else
				ReportTable.Join(Area);
			EndIf;
			
		EndDo;
		
		OutputPresentationAndPicture(CurrentTreeRow, Template, False, False);		
		Counter = Counter - 1;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure OutputPresentationAndPicture(TreeRow, Template, IsCurrentObject = False, IsSubordinateDocument = Undefined)
	
	ObjectMetadata = TreeRow.Ref.Metadata();
	IsDocument       = Common.IsDocument(ObjectMetadata);
	
	HasParentsCumulative = TreeParentObjects.GetItems().Count() > 0;
	HasSubordinateItemsCumulative = TreeSubordinateObjects.GetItems().Count() > 0;
	HasSubordinateItems = TypeOf(TreeRow) = Type("FormDataTreeItem")
		And TreeRow.GetItems().Count() > 0;
	
	// Output picture.
	If TreeRow.Posted Then
		If IsCurrentObject Then
			If HasSubordinateItemsCumulative And HasParentsCumulative Then
				PictureArea = Template.GetArea("DocumentPostedConnectorTopBottom");
			ElsIf HasSubordinateItemsCumulative Then
				PictureArea = Template.GetArea("DocumentPostedConnectorBottom");
			Else
				PictureArea = Template.GetArea("DocumentPostedConnectorTop");
			EndIf;
		ElsIf IsSubordinateDocument = True Then
			If HasSubordinateItems Then
				PictureArea = Template.GetArea("DocumentPostedConnectorLeftBottom");
			Else
				PictureArea = Template.GetArea("DocumentPosted");
			EndIf;
		Else
			If HasSubordinateItems Then
				PictureArea = Template.GetArea("DocumentPostedConnectorLeftTop");
			Else
				PictureArea = Template.GetArea("DocumentPosted");
			EndIf;
		EndIf;
	ElsIf TreeRow.DeletionMark Then
		If IsCurrentObject Then
			If HasSubordinateItemsCumulative And HasParentsCumulative  Then
				AreaName = ?(IsDocument, "DocumentMarkedForDeletionConnectorTopBottom", "CatalogCCTMarkedForDeletionConnectorTopBottom");
				PictureArea = Template.GetArea(AreaName);
			ElsIf HasSubordinateItemsCumulative Then
				AreaName = ?(IsDocument, "DocumentMarkedForDeletionConnectorBottom", "CatalogCCTMarkedForDeletionConnectorBottom");
				PictureArea = Template.GetArea(AreaName);
			Else
				AreaName = ?(IsDocument, "DocumentMarkedForDeletionConnectorTop", "CatalogCCTMarkedForDeletionConnectorTop");
				PictureArea = Template.GetArea(AreaName);
			EndIf;
		ElsIf IsSubordinateDocument = True Then
			If HasSubordinateItems Then
				AreaName = ?(IsDocument, "DocumentMarkedForDeletionConnectorLeftBottom", "CatalogCCTMarkedForDeletionConnectorLeftBottom");
				PictureArea = Template.GetArea(AreaName);
			Else
				AreaName = ?(IsDocument, "DocumentMarkedForDeletion_", "CatalogCCTMarkedForDeletionConnectorLeft");
				PictureArea = Template.GetArea(AreaName);
			EndIf;
		Else
			If HasSubordinateItems Then
				AreaName = ?(IsDocument, "DocumentMarkedForDeletionConnectorLeftTop", "CatalogCCTMarkedForDeletionConnectorLeftTop");
				PictureArea = Template.GetArea(AreaName);
			Else
				AreaName = ?(IsDocument, "DocumentMarkedForDeletion_", "CatalogCCTMarkedForDeletionConnectorLeft");
				PictureArea = Template.GetArea(AreaName);
			EndIf;
		EndIf;
	Else
		If IsCurrentObject Then
			If HasSubordinateItemsCumulative And HasParentsCumulative Then
				AreaName = ?(IsDocument, "DocumentWrittenConnectorTopBottom", "CatalogCCTConnectorTopBottom");
				PictureArea = Template.GetArea(AreaName);
			ElsIf HasSubordinateItemsCumulative Then
				AreaName = ?(IsDocument, "DocumentWrittenConnectorDown", "CatalogCCTConnectorBottom");
				PictureArea = Template.GetArea(AreaName);
			Else
				AreaName = ?(IsDocument, "DocumentWrittenConnectorTop", "CatalogCCTConnectorTop");
				PictureArea = Template.GetArea(AreaName);
			EndIf;
		ElsIf IsSubordinateDocument = True Then
			If HasSubordinateItems Then
				AreaName = ?(IsDocument, "DocumentWrittenConnectorLeftBottom", "CatalogCCTConnectorLeftBottom");
				PictureArea = Template.GetArea(AreaName);
			Else
				AreaName = ?(IsDocument, "DocumentWritten", "CatalogCCTConnectorLeft");
				PictureArea = Template.GetArea(AreaName);
			EndIf;
		Else
			If HasSubordinateItems Then
				AreaName = ?(IsDocument, "DocumentWrittenConnectorLeftTop", "CatalogCCTConnectorLeftTop");
				PictureArea = Template.GetArea(AreaName);
			Else
				AreaName = ?(IsDocument, "DocumentWritten", "CatalogCCTConnectorLeft");
				PictureArea = Template.GetArea(AreaName);
			EndIf;
		EndIf;
	EndIf;
	
	If IsCurrentObject Then
		ReportTable.Put(PictureArea) 
	Else
		ReportTable.Join(PictureArea);
	EndIf;
	
	// Output object.
	ObjectArea = Template.GetArea(?(IsCurrentObject, "CurrentObject", "Object"));
	ObjectArea.Parameters.ObjectPresentation = TreeRow.Presentation;
	ObjectArea.Parameters.Object = TreeRow.Ref;
	ReportTable.Join(ObjectArea);
	
EndProcedure

// Determines whether a vertical connector is to be output to the spreadsheet.
//
// Parameters:
//  LevelUp  - Number - how many levels higher is the 
//                 parent, from which the vertical connector will be drawn.
//  TreeRow  - FormDataTreeItem - an original value tree row
//                  that starts the count.
// Returns:
//   Boolean   - indicates whether output in the vertical connector area is required.
//
&AtServer
Function OutputVerticalConnector(LevelUp, TreeRow, SearchSubordinateDocuments = True)
	
	CurrentRow = TreeRow;
	
	For Indus = 1 To LevelUp Do
		
		CurrentRow = CurrentRow.GetParent();
		If Indus = LevelUp Then
			SearchParent = CurrentRow;
		ElsIf Indus = (LevelUp-1) Then
			SearchRow = CurrentRow;
		EndIf;
		
	EndDo;
	
	If SearchParent = Undefined Then
		If SearchSubordinateDocuments Then
			SubordinateParentItems1 =  TreeSubordinateObjects.GetItems(); 
		Else
			SubordinateParentItems1 =  TreeParentObjects.GetItems();
		EndIf;
	Else
		SubordinateParentItems1 =  SearchParent.GetItems(); 
	EndIf;
	
	Return SubordinateParentItems1.IndexOf(SearchRow) < (SubordinateParentItems1.Count()-1);
	
EndFunction

// Outputs a row with the document, for which a hierarchy is being generated, to the spreadsheet document.
//
// Parameters:
//  Template - SpreadsheetDocument
//
&AtServer
Procedure OutputCurrentObject(Template)
	
	Selection = QueryByObjectsAttributes(MainObject).Execute().Select();
	If Selection.Next() Then
		
		Overridable_1Presentation = ObjectPresentationForOutput(Selection);
		If Overridable_1Presentation <> Undefined Then
			AttributesStructure1 = Common.ValueTableRowToStructure(Selection.Owner().Unload()[0]);
			AttributesStructure1.Presentation = Overridable_1Presentation;
			OutputPresentationAndPicture(AttributesStructure1, Template, True);
		Else
			AttributesStructure1 = Common.ValueTableRowToStructure(Selection.Owner().Unload()[0]);
			AttributesStructure1.Presentation = ObjectPresentationForReportOutput(Selection);
			OutputPresentationAndPicture(AttributesStructure1, Template, True);
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//  Selection - QueryResultSelection
//          - FormDataTreeItem - a data set used to generate a presentation.
//
// Returns:
//   String - a generated presentation.
//
&AtServer
Function ObjectPresentationForReportOutput(Selection)
	
	ObjectPresentation = Selection.Presentation;
	ObjectMetadata = Selection.Ref.Metadata();
	
	If Common.IsDocument(ObjectMetadata) Then
		If (Selection.DocumentAmount <> 0) And (Selection.DocumentAmount <> NULL) Then
			ObjectPresentation = ObjectPresentation
				+ " " + NStr("vi = 'với số tiền';
							|ru = 'на сумму';
							|en = 'in the amount of'; fa = 'به مبلغ';
							|it = 'per l''importo di';
							|pl = 'na kwotę';
							|tr = 'tutarında'")
				+ " " + Selection.DocumentAmount
				+ " " + Selection.Currency;
		EndIf;
	Else
		ObjectPresentation = ObjectPresentation + " (" + Common.ObjectPresentation(ObjectMetadata) + ")";
	EndIf;
	
	Return ObjectPresentation;
	
EndFunction

// Parameters:
//  TreeRows - FormDataTreeItemCollection
//  Template - SpreadsheetDocument
//  RecursionLevels - Number
//
&AtServer
Procedure OutputSubordinateTreeItems(TreeRows, Template, RecursionLevels = 1)

	For Each TreeRow In TreeRows Do
		
		IsInitialObject = (TreeRow.Ref = InitialObject);
		SubordinateTreeItems = TreeRow.GetItems();
		
		// Output connectors.
		For Level = 1 To RecursionLevels Do
			
			If RecursionLevels > Level Then
				
				If OutputVerticalConnector(RecursionLevels - Level + 1,TreeRow) Then
					Area = Template.GetArea("ConnectorTopBottom");
				Else
					Area = Template.GetArea("Indent");
				EndIf;
				
			Else 
				
				If TreeRows.Count() > 1 And (TreeRows.IndexOf(TreeRow) <> (TreeRows.Count() - 1)) Then
					Area = Template.GetArea("ConnectorTopRightBottom");
				Else
					Area = Template.GetArea("ConnectorTopRight");
				EndIf;
				
			EndIf;
			
			Area.Parameters.Document = ?(IsInitialObject, Undefined, TreeRow.Ref);
			
			If Level = 1 Then
				ReportTable.Put(Area);
			Else
				ReportTable.Join(Area);
			EndIf;
			
		EndDo;
		
		OutputPresentationAndPicture(TreeRow, Template, False, True);		
		OutputSubordinateTreeItems(SubordinateTreeItems, Template, RecursionLevels + 1);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure OutputHierarchy()

	UpdateHierarchicalTree();

EndProcedure

#EndRegion

#Region ProceduresForCreatingDocumentHierarchyTree

&AtServer
Procedure UpdateHierarchicalTree()

	If Not MainDocumentAvailable() Then
		
		MessageText = NStr("vi = 'Chứng từ mà dòng báo cáo đã được tạo không có sẵn.';
							|ru = 'Документ, для которого сформирован отчет о структуре подчиненности, стал недоступен.';
							|en = 'The source document is no longer available.'; fa = 'The source document is no longer available.';
							|it = 'Il documento per il quale è stata generata il report sulla struttura di subordinazione è diventato non disponibile.';
							|pl = 'Dokument, dla którego utworzono raport o strukturze podporządkowania, jest niedostępny.';
							|tr = 'Tabiiyet yapısıyla ilgili raporun oluşturulduğu belge artık erişilemiyor.'");
		Common.MessageToUser(MessageText);
		Return;
		
	EndIf;
	
	Title = Metadata.CommonForms.RelatedDocuments.Presentation()
		+ ": " + Common.SubjectString(MainObject);
	
	GenerateDocumentsTrees();
	OutputSpreadsheetDocument();
	
EndProcedure

&AtServer
Procedure GenerateDocumentsTrees()

	TreeParentObjects.GetItems().Clear();
	TreeSubordinateObjects.GetItems().Clear();
	
	DisplayedObjects = New Map;
	
	OutputParentObjects(MainObject, TreeParentObjects, DisplayedObjects);
	OutputSubordinateObjects(MainObject, TreeSubordinateObjects, DisplayedObjects);
	
EndProcedure

&AtServer
Function MainDocumentAvailable()

	Query = New Query(
	"SELECT ALLOWED
	|	1
	|FROM
	|	&TableName AS Tab
	|WHERE
	|	Tab.Ref = &CurrentObject
	|");
	Query.Text = StrReplace(Query.Text, "&TableName", MainObject.Metadata().FullName()); 
	Query.SetParameter("CurrentObject", MainObject);
	Return Not Query.Execute().IsEmpty();

EndFunction

// Parameters:
//  ListOfObjects - Array
//                 - DocumentRef
//                 - CatalogRef
//                 - ChartOfCharacteristicTypesRef
//
// Returns:
//   Query
//
&AtServer
Function QueryByObjectsAttributes(ListOfObjects)
	
	ObjectsByType = New Map;
	If TypeOf(ListOfObjects) = Type("Array") Then
		For Each CurrentObject In ListOfObjects Do
			Objects = ObjectsByType[CurrentObject.Metadata()];
			If Objects = Undefined Then
				Objects = New Array;
				ObjectsByType[CurrentObject.Metadata()] = Objects;
			EndIf;
			Objects.Add(CurrentObject);
		EndDo; 
	Else
		ObjectsByType[ListOfObjects.Metadata()] = CommonClientServer.ValueInArray(ListOfObjects);
	EndIf;
	
	Query = New Query;
	QueriesTexts = New Array;
	
	For Each ObjectType In ObjectsByType Do

		QueryText = 
			"SELECT ALLOWED
			|	&Date AS Date,
			|	Ref,
			|	&Posted AS Posted,
			|	DeletionMark,
			|	&Sum AS DocumentAmount,
			|	&Currency AS Currency,
			|	&Presentation
			|FROM
			|	&TableName
			|WHERE
			|	Ref IN (&Ref)
			|";
		
		ObjectMetadata = ObjectType.Key;
		QueryText = StrReplace(QueryText, "&TableName", ObjectMetadata.FullName());
		If Common.IsDocument(ObjectMetadata) Then
			AttributeNameAmount    = DocumentAttributeName(ObjectMetadata, "DocumentAmount");
			AttributeNameCurrency   = DocumentAttributeName(ObjectMetadata, "Currency");
			AttributeNamePosted = "Posted";
			TheNameOfThePropsDate     = "Date";
		Else
			AttributeNameAmount    = Undefined;
			AttributeNameCurrency   = Undefined;
			AttributeNamePosted = "False";
			TheNameOfThePropsDate     = "False";
		EndIf;
		
		ReplaceQueryText(QueryText, ObjectMetadata, "&Date", TheNameOfThePropsDate, True);
		ReplaceQueryText(QueryText, ObjectMetadata, "&Posted", AttributeNamePosted, True);
		ReplaceQueryText(QueryText, ObjectMetadata, "&Sum", AttributeNameAmount);
		ReplaceQueryText(QueryText, ObjectMetadata, "&Currency", AttributeNameCurrency);
		
		AddAttributes = AttributesForPresentation(ObjectMetadata.FullName(), ObjectMetadata.Name);
		TextPresentation = "Presentation AS Presentation"; // @query-part
		For IndexOf = 1 To 3 Do
			TextPresentation = TextPresentation + ",
				|	" + ?(AddAttributes.Count() >= IndexOf, AddAttributes[IndexOf - 1], "NULL") 
				+ " AS AdditionalAttribute" + IndexOf; // @query-part-2, @query-part-3
		EndDo;
		QueryText = StrReplace(QueryText, "&Presentation", TextPresentation);
		
		ParameterName = "Ref" + StrReplace(ObjectMetadata.FullName(), ".", "_");
		QueryText = StrReplace(QueryText, "&Ref", "&" + ParameterName);
		Query.SetParameter(ParameterName, ObjectType.Value);
		
		If QueriesTexts.Count() > 0 Then
			QueryText = StrReplace(QueryText, "SELECT ALLOWED", "SELECT"); // @query-part-1, @query-part-2
		EndIf;

		QueriesTexts.Add(QueryText);
		
	EndDo;
	
	Query.Text = StrConcat(QueriesTexts, Chars.LF + "UNION ALL" + Chars.LF); // @query-part
	Return Query; 
	
EndFunction

&AtServer
Procedure OutputParentObjects(CurrentObject, ParentTree, DisplayedObjects,
	ServiceObjects = Undefined, IndexOfObjectRelationships = Undefined)
	
	ObjectMetadata = CurrentObject.Metadata();
	AttributesList  = New Array;
	
	If ServiceObjects = Undefined Then 
		ServiceObjects = New Map;
	EndIf;
	
	If IndexOfObjectRelationships = Undefined Then 
		IndexOfObjectRelationships = New Map;
	EndIf;
	
	For Each Attribute In ObjectMetadata.Attributes Do
		
		If Not Metadata.FilterCriteria.RelatedDocuments.Content.Contains(Attribute) Then
			Continue;
		EndIf;
		
		For Each Current_Type In Attribute.Type.Types() Do
			
			AttributeMetadata = MetadataOfPropsType(Current_Type);
			If AttributeMetadata.Metadata = Undefined Then
				Continue;
			EndIf;
			
			AttributeValue = CurrentObject[Attribute.Name];
			If ValueIsFilled(AttributeValue)
				And TypeOf(AttributeValue) = Current_Type
				And AttributeValue <> CurrentObject
				And AttributesList.Find(AttributeValue) = Undefined Then
				
				AttributesList.Add(AttributeValue);
			EndIf;
		EndDo;
		
	EndDo;
	
	For Each TabularSection In ObjectMetadata.TabularSections Do
		
		AttributesNames = "";
		TSContent = CurrentObject[TabularSection.Name].Unload(); // ValueTable
		For Each Attribute In TabularSection.Attributes Do

			If Not Metadata.FilterCriteria.RelatedDocuments.Content.Contains(Attribute) Then
				Continue;
			EndIf;
				
			For Each Current_Type In Attribute.Type.Types() Do
				AttributeMetadata = MetadataOfPropsType(Current_Type);
				If AttributeMetadata.Metadata = Undefined Then
					Continue;
				EndIf;
	
				AttributesNames = AttributesNames + ?(AttributesNames = "", "", ", ") + Attribute.Name;
				Break;
			EndDo;
			
		EndDo;
		
		TSContent.GroupBy(AttributesNames);
		For Each TSColumn In TSContent.Columns Do
			
			For Each TSRow In TSContent Do
			
				AttributeValue = TSRow[TSColumn.Name];
				ValueMetadata = MetadataOfPropsType(TypeOf(AttributeValue));
				If ValueMetadata.Metadata = Undefined Then
					Continue;
				EndIf;
				
				If AttributeValue = CurrentObject
					Or AttributesList.Find(AttributeValue) <> Undefined Then
					Continue;
				EndIf;
				
				AttributesList.Add(AttributeValue);
			EndDo;
		EndDo;
	EndDo;
	
	If AttributesList.Count() > 0 Then
		ObjectsToOutput = QueryByObjectsAttributes(AttributesList).Execute().Unload();
		ObjectsToOutput.Sort("Date");
		For Each ObjectToOutput In ObjectsToOutput Do 
			
			If IndexOfObjectRelationships[CurrentObject] = ObjectToOutput.Ref Then 
				Continue;
			EndIf;
			
			IndexOfObjectRelationships[CurrentObject] = ObjectToOutput.Ref;
			
			NewRow = AddRowToTree(ParentTree, ObjectToOutput, DisplayedObjects);			
			If NewRow <> Undefined
				And Not ObjectToAddIsAmongParents(ParentTree, ObjectToOutput.Ref) Then
				
				// @skip-check query-in-loop - Recursive tree processing algorithm.
				OutputParentObjects(ObjectToOutput.Ref, NewRow, DisplayedObjects,
					ServiceObjects, IndexOfObjectRelationships);
				
			ElsIf ServiceObjects[ObjectToOutput.Ref] = Undefined Then 
				
				ServiceObjects[ObjectToOutput.Ref] = True;
				// @skip-check query-in-loop - Recursive tree processing algorithm.
				OutputParentObjects(ObjectToOutput.Ref, ParentTree, DisplayedObjects,
					ServiceObjects, IndexOfObjectRelationships);
				
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

// Parameters:
//  AttributeType - Type
// 
// Returns:
//  Structure:
//   * Metadata - MetadataObject
//   * IsDocument - Boolean
//
&AtServerNoContext
Function MetadataOfPropsType(AttributeType)

	Result = New Structure("Metadata, IsDocument", Undefined, False); 
	
	AttributeMetadata = Metadata.FindByType(AttributeType);
	If AttributeMetadata = Undefined Then
		Return Result;
	EndIf;
	
	If Not Common.MetadataObjectAvailableByFunctionalOptions(AttributeMetadata) 
		Or Not AccessRight("View", AttributeMetadata) Then
		Return Result;
	EndIf;
	
	Result.IsDocument = Metadata.Documents.Contains(AttributeMetadata);
	If Not Result.IsDocument
		And Not Metadata.Catalogs.Contains(AttributeMetadata)
		And Not Metadata.ChartsOfCharacteristicTypes.Contains(AttributeMetadata) Then
		Return Result;
	EndIf;
	Result.Metadata = AttributeMetadata;
	Return Result;

EndFunction

// Parameters:
//  ParentRow  - FormDataTree
//                  - FormDataTreeItem
//  SearchObject  - AnyRef
//
// Returns:
//   Boolean
//
&AtServer
Function ObjectToAddIsAmongParents(ParentRow, SearchObject)
	
	If SearchObject = MainObject Then
		Return True;
	EndIf;
	
	If TypeOf(ParentRow) = Type("FormDataTree") Then
		Return False; 
	EndIf;
	
	CurrentParent = ParentRow;
	While CurrentParent <> Undefined Do
		If CurrentParent.Ref = SearchObject Then
			Return True;
		EndIf;
		CurrentParent = CurrentParent.GetParent();
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Procedure ReplaceQueryText(QueryText, ObjectMetadata, WhatToReplace1, Var_AttributeName, DoNotSearchAttributes = False)

	ThereAreProps = DoNotSearchAttributes Or ObjectMetadata.Attributes.Find(Var_AttributeName) <> Undefined; 
	QueryText = StrReplace(QueryText, WhatToReplace1, ?(ThereAreProps, Var_AttributeName,  "NULL"));

EndProcedure

// Returns links to related objects.
// 
// Returns:
//   ValueTable:
//     * Ref - CatalogRef
//              - DocumentRef
//
&AtServer
Function ObjectsByFilterCriteria(FilterCriteriaValue)

	QueryTemplate = "SELECT ALLOWED
	|	TableAlias.Ref AS Ref
	|FROM
	|	TableName AS TableAlias
	|WHERE
	|	TableAlias.AttributeName = &FilterCriteriaValue";

	MergeQueryTemplate = "SELECT
	|	TableAlias.Ref AS Ref
	|FROM
	|	TableName AS TableAlias
	|WHERE
	|	TableAlias.AttributeName = &FilterCriteriaValue";

	QueryParts = New Array;
	TextOfRequestPart = "";

	For Each CompositionItem In Metadata.FilterCriteria.RelatedDocuments.Content Do

		If Not CompositionItem.Type.ContainsType(TypeOf(FilterCriteriaValue)) Then
			Continue;
		EndIf;

		DataPath = CompositionItem.FullName();
		
		If StrFind(DataPath, "TabularSection") Then
			MetadataObject = CompositionItem.Parent().Parent();
		Else
			MetadataObject = CompositionItem.Parent();
		EndIf;
				
		If Not AccessRight("Read", MetadataObject) Then
			Continue;
		EndIf;

		Point = StrFind(DataPath, ".", SearchDirection.FromEnd);
		AttributeName = Mid(DataPath, Point + 1);

		TableName = CompositionItem.Parent().FullName();
		TableName = StrReplace(TableName, "TabularSection.", "");

		Point = StrFind(TableName, ".", SearchDirection.FromEnd);
		TableAlias = "Table_" + Mid(TableName, Point + 1);

		TextOfRequestPart = ?(TextOfRequestPart = "", QueryTemplate, MergeQueryTemplate);
		TextOfRequestPart = StrReplace(TextOfRequestPart, "TableName", TableName);
		TextOfRequestPart = StrReplace(TextOfRequestPart, "TableAlias", TableAlias);
		TextOfRequestPart = StrReplace(TextOfRequestPart, "AttributeName", AttributeName);

		QueryParts.Add(TextOfRequestPart);

	EndDo;

	If QueryParts.Count() > 0 Then
		Query = New Query;
		Separator = Chars.LF + "UNION" + Chars.LF;
		Query.Text = StrConcat(QueryParts, Separator);
		Query.SetParameter("FilterCriteriaValue", FilterCriteriaValue);
		Return Query.Execute().Unload();
	Else
		Return New ValueTable;
	EndIf;

EndFunction

&AtServer
Procedure OutputSubordinateObjects(CurrentObject, ParentTree, DisplayedObjects,
	ServiceObjects = Undefined, IndexOfObjectRelationships = Undefined)
	
	Table = ObjectsByFilterCriteria(CurrentObject);
	If Table = Undefined Then
		Return;
	EndIf;
	
	If ServiceObjects = Undefined Then 
		ServiceObjects = New Map;
	EndIf;
	
	If IndexOfObjectRelationships = Undefined Then 
		IndexOfObjectRelationships = New Map;
	EndIf;
	
	ListOfObjects = New Array;
	For Each TableRow In Table Do

		CurrentRef = TableRow.Ref; // CatalogRef, DocumentRef		
		ObjectMetadata = CurrentRef.Metadata();
		If Not AccessRight("View", ObjectMetadata) Then
			Continue;
		EndIf;

		ListOfObjects.Add(CurrentRef);
	EndDo;
	
	If ListOfObjects.Count() = 0 Then
		Return;
	EndIf;
	
	ObjectsToOutput = QueryByObjectsAttributes(ListOfObjects).Execute().Unload();
	ObjectsToOutput.Sort("Date");

	For Each ObjectToOutput In ObjectsToOutput Do
		
		If IndexOfObjectRelationships[CurrentObject] = ObjectToOutput.Ref Then 
			Continue;
		EndIf;
		
		IndexOfObjectRelationships[CurrentObject] = ObjectToOutput.Ref;
		
		NewRow = AddRowToTree(ParentTree, ObjectToOutput, DisplayedObjects, True);		
		If NewRow <> Undefined
			And Not ObjectToAddIsAmongParents(ParentTree, ObjectToOutput.Ref) Then
			
			// @skip-check query-in-loop - Recursive tree processing algorithm.
			OutputSubordinateObjects(ObjectToOutput.Ref, NewRow, DisplayedObjects,
				ServiceObjects, IndexOfObjectRelationships);
			
		ElsIf ServiceObjects[ObjectToOutput.Ref] = Undefined Then 
			
			ServiceObjects.Insert(ObjectToOutput.Ref, True);
			// @skip-check query-in-loop - Recursive tree processing algorithm.
			OutputSubordinateObjects(ObjectToOutput.Ref, ParentTree, DisplayedObjects,
				ServiceObjects, IndexOfObjectRelationships);
			
		EndIf;
		
	EndDo;

EndProcedure

&AtServer
Function AddRowToTree(Parent, Data, DisplayedObjects, IsSubordinateDocument = False)
	
	SetObjectOutputFrequency(Data.Ref, DisplayedObjects, IsSubordinateDocument);	
	If Not NeedOutputCurrentObject(Parent, Data.Ref, DisplayedObjects, IsSubordinateDocument) Then 
		Return Undefined;
	EndIf;
	
	NewRow = Parent.GetItems().Add();
	CommonProperties = "Ref, Presentation, DocumentAmount, Currency, Posted, DeletionMark";
	FillPropertyValues(NewRow, Data, CommonProperties);
	
	OverriddenPresentation = ObjectPresentationForOutput(Data);
	If OverriddenPresentation <> Undefined Then
		NewRow.Presentation = OverriddenPresentation;
	Else
		NewRow.Presentation = ObjectPresentationForReportOutput(Data);
	EndIf;
	
	Return NewRow;
	
EndFunction

&AtServer
Function NeedOutputCurrentObject(Parent, CurrentObject, DisplayedObjects, IsSubordinateDocument, Cancel = False)
	
	WasOutput = DisplayedObjects[CurrentObject];
	If WasOutput = Undefined Then 
		WasOutput = NewObjectOutputFrequencyProperties();
	EndIf;
	
	ObjectProperties = NewObjectProperties();
	ObjectProperties.IsMain2 = (CurrentObject = MainObject);
	ObjectProperties.IsSubordinateDocument = IsSubordinateDocument;
	ObjectProperties.WasOutput = WasOutput;
	
	If ObjectProperties.IsMain2
		Or TheCurrentObjectWasDisplayedInTheBranch(Parent, CurrentObject) Then 
		
		Cancel = True;
	EndIf;
	
	SubordinationStructureOverridable.BeforeOutputLinkedObject(CurrentObject, ObjectProperties, Cancel);
	
	Return Not Cancel;
	
EndFunction

&AtServer
Function NewObjectProperties()
	
	ObjectProperties = New Structure;
	ObjectProperties.Insert("IsMain2", False);
	ObjectProperties.Insert("IsInternal", False);
	ObjectProperties.Insert("IsSubordinateDocument", False);
	ObjectProperties.Insert("WasOutput", NewObjectOutputFrequencyProperties());
	
	Return ObjectProperties;
	
EndFunction

&AtServer
Function TheCurrentObjectWasDisplayedInTheBranch(Val Parent, Val CurrentObject, WasOutput = False)
	
	While Parent <> Undefined Do
		
		IsString = (TypeOf(Parent) = Type("FormDataTreeItem"));
		
		If IsString And CurrentObject = Parent.Ref Then 
			WasOutput = True;
			Return WasOutput;
		EndIf;
		
		For Each Item In Parent.GetItems() Do 
			If CurrentObject = Item.Ref Then 
				WasOutput = True;
				Break;
			EndIf;
		EndDo;
		
		If IsString And Not WasOutput Then
			Parent = Parent.GetParent();
		Else
			Break;
		EndIf;
		
	EndDo;
	
	Return WasOutput;
	
EndFunction

&AtServer
Procedure SetObjectOutputFrequency(CurrentObject, DisplayedObjects, IsSubordinateDocument)
	
	WasOutput = DisplayedObjects[CurrentObject];
	If WasOutput = Undefined Then 
		WasOutput = NewObjectOutputFrequencyProperties();
	EndIf;
	
	WasOutput.InTotal = WasOutput.InTotal + 1;
	If IsSubordinateDocument Then 
		WasOutput.InSubordinates = WasOutput.InSubordinates + 1;
	EndIf;
	
	DisplayedObjects.Insert(CurrentObject, WasOutput);
	
EndProcedure

&AtServer
Function NewObjectOutputFrequencyProperties()
	
	OutputFrequencyProperties = New Structure;
	OutputFrequencyProperties.Insert("InTotal", 0);
	OutputFrequencyProperties.Insert("InSubordinates", 0);	
	Return OutputFrequencyProperties;
	
EndFunction

&AtServer
Function DocumentAttributeName(Val ObjectMetadata, Val Var_AttributeName) 
	
	AttributesNames = Settings.Attributes[ObjectMetadata.FullName()];
	If AttributesNames <> Undefined Then
		Result = AttributesNames[Var_AttributeName];
		Return ?(Result <> Undefined, Result, Var_AttributeName);
	EndIf;	
	
	// For backward compatibility purposes.
	DocumentAttributeName = SubordinationStructureOverridable.DocumentAttributeName(ObjectMetadata.Name, Var_AttributeName); // ACC:222
	If Var_AttributeName = "DocumentAmount" Then
		Return ?(DocumentAttributeName = Undefined, "DocumentAmount", DocumentAttributeName);
	ElsIf Var_AttributeName = "Currency" Then
		Return ?(DocumentAttributeName = Undefined, "Currency", DocumentAttributeName);
	EndIf;
	
EndFunction

&AtServer
Procedure DefineSettings()
	
	SubsystemSettings = New Structure;
	SubsystemSettings.Insert("Attributes", New Map);
	SubsystemSettings.Insert("AttributesForPresentation", New Map);
	SubordinationStructureOverridable.OnDefineSettings(SubsystemSettings);
	
	Settings = SubsystemSettings;

EndProcedure

&AtServer
Function AttributesForPresentation(Val FullMetadataObjectName, Val MetadataObjectName)
	
	Result = Settings.AttributesForPresentation[FullMetadataObjectName];
	If Result <> Undefined Then
		Return Result;
	EndIf;
	
	// For backward compatibility purposes.
	Return SubordinationStructureOverridable.ObjectAttributesArrayForPresentationGeneration(MetadataObjectName); // ACC:222
	
EndFunction

&AtServer
Function ObjectPresentationForOutput(Data) 
	
	Result = "";
	StandardProcessing = True;	
	SubordinationStructureOverridable.OnGettingPresentation(TypeOf(Data.Ref), Data, Result, StandardProcessing);
	If Not StandardProcessing Then
		Return Result;
	EndIf;
	
	// For backward compatibility purposes.
	Return SubordinationStructureOverridable.ObjectPresentationForReportOutput(Data); // ACC:222
	
EndFunction

#EndRegion

#Region ObjectStateChangeProcedures

&AtClient
Function SelectedItems()
	
	SelectedItems = New Array;
	
	SelectedAreas = Items.ReportTable.GetSelectedAreas();
	
	For Each SelectedArea1 In SelectedAreas Do 
		
		If TypeOf(SelectedArea1) <> Type("SpreadsheetDocumentRange") Then
			Continue;
		EndIf;
		
		Boundaries = SelectedAreaBorders(SelectedArea1);
		
		For ColumnNumber = Boundaries.Left To Boundaries.Right Do
			
			For LineNumber = Boundaries.Top To Boundaries.Bottom Do
				
				Cell = ReportTable.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber);
				
				Details = Cell.Details;
				
				If Not ValueIsFilled(Details) Then 
					Details = FirstRowFieldDrilldown(Cell.Top);
				EndIf;
				
				If ValueIsFilled(Details) Then 
					SelectedItems.Add(Details);
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	SelectedItems = CommonClientServer.CollapseArray(SelectedItems);
	
	Return SelectedItems;
	
EndFunction

&AtClient
Function SelectedAreaBorders(SelectedArea1)
	
	Boundaries = New Structure("Left, Top, Bottom, Right");
	FillPropertyValues(Boundaries, SelectedArea1);
	
	If Boundaries.Left = 0 Then 
		Boundaries.Left = 1;
	EndIf;
	
	If Boundaries.Top = 0 Then 
		Boundaries.Top = 1;
	EndIf;
	
	If Boundaries.Bottom = 0 Then 
		Boundaries.Bottom = 1;
	EndIf;
	
	If Boundaries.Right = 0 Then 
		Boundaries.Right = 1;
	EndIf;
	
	Return Boundaries;
	
EndFunction

// Changing the deletion mark.

&AtServerNoContext
Function StatisticsBySelectedItems(SelectedItems)
	
	Statistics = New Structure;
	Statistics.Insert("WithDeletionMark", New Map);
	Statistics.Insert("NoDeletionMark", New Map);
	
	ItemsProperties = Common.ObjectsAttributesValues(SelectedItems, "DeletionMark, Presentation");
	
	For Each Item In SelectedItems Do 
		
		ItemProperties = ItemsProperties[Item];
		
		If ItemProperties.DeletionMark Then 
			Statistics.WithDeletionMark.Insert(Item, ItemProperties.Presentation);
		Else
			Statistics.NoDeletionMark.Insert(Item, ItemProperties.Presentation);
		EndIf;
		
	EndDo;
	
	Return Statistics;
	
EndFunction

// Returns:
//  Structure:
//   * Explanation - String
//   * Ref - String
//   * Notification - String
//   * DoQueryBox - String
//   * Check - Boolean
//
&AtClient
Function DeletionMarkEditScenario(SelectedItems, StatisticsBySelectedItems)
	
	Scenario = New Structure;
	Scenario.Insert("Check", False);
	Scenario.Insert("DoQueryBox", "");
	Scenario.Insert("Notification", "");
	Scenario.Insert("Ref", "");
	Scenario.Insert("Explanation", "");
	
	SelectedItemsCount = SelectedItems.Count();
	ObjectsMarkedForDeletionCount = StatisticsBySelectedItems.WithDeletionMark.Count();
	
	If SelectedItemsCount = 1 Then 
		
		Item = SelectedItems[0];
		Scenario.Ref = GetURL(Item);
		
		If ObjectsMarkedForDeletionCount = 0 Then 
			
			ItemPresentation = StatisticsBySelectedItems.NoDeletionMark[Item];
			
			Scenario.Check = True;
			Scenario.Notification = NStr("vi = 'Đã đặt dấu xóa';
										|ru = 'Пометка удаления установлена';
										|en = 'Deletion mark set'; fa = 'Deletion mark set';
										|it = 'Il contrassegno per la cancellazione è stato impostato';
										|pl = 'Ustawiono zaznaczenie usunięcia';
										|tr = 'Silme işareti yerleştirildi'");
			Scenario.Explanation = ItemPresentation;
			Scenario.DoQueryBox = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đặt dấu xóa ""%1""?';
					|ru = 'Пометить ""%1"" на удаление?';
					|en = 'Do you want to mark %1 for deletion?'; fa = 'Do you want to mark %1 for deletion?';
					|it = 'Contrassegnare ""%1"" per cancellazione?';
					|pl = 'Zaznaczyć ""%1"" do usunięcia?';
					|tr = '""%1"" silinmek üzere işaretlensin mi?'"), ItemPresentation);
			
		Else
			
			ItemPresentation = StatisticsBySelectedItems.WithDeletionMark[Item];
			
			Scenario.Notification = NStr("vi = 'Bỏ dấu xóa';
										|ru = 'Пометка удаления снята';
										|en = 'Deletion mark cleared'; fa = 'Deletion mark cleared';
										|it = 'Il contrassegno per la cancellazione è stato rimosso';
										|pl = 'Usunięto zaznaczenie usunięcia';
										|tr = 'Silme işareti kaldırıldı'");
			Scenario.Explanation = ItemPresentation;
			Scenario.DoQueryBox = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Bỏ dấu xóa ""%1""?';
					|ru = 'Снять с ""%1"" пометку на удаление?';
					|en = 'Do you want to clear the deletion mark from ""%1""?'; fa = 'Do you want to clear the deletion mark from ""%1""?';
					|it = 'Rimuovere il contrassegno per cancellazione da ""%1""?';
					|pl = 'Usunąć z ""%1"" zaznaczenie do usunięcia?';
					|tr = '""%1"" için silme işareti kaldırılsın mı?'"), ItemPresentation);
			
		EndIf;
		
	Else
		
		Scenario.Explanation = Title;
		
		If ObjectsMarkedForDeletionCount = 0 Then 
			
			Scenario.Check = True;
			Scenario.DoQueryBox = NStr("vi = 'Đặt dấu xóa phần tử đã chọn?';
										|ru = 'Пометить выделенные элементы на удаление?';
										|en = 'Do you want to mark the selected items for deletion?'; fa = 'Do you want to mark the selected items for deletion?';
										|it = 'Contrassegnare gli elementi selezionati per la cancellazione?';
										|pl = 'Zaznaczyć wybrane elementy do usunięcia?';
										|tr = 'Seçilen öğeler silinmek üzere işaretlensin mi?'");
			Scenario.Notification = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã đặt dấu xóa (%1)';
					|ru = 'Пометка удаления установлена (%1)';
					|en = 'Deletion mark set (%1)'; fa = 'Deletion mark set (%1)';
					|it = 'Il contrassegno per la cancellazione è stato impostato (%1)';
					|pl = 'Ustawiono zaznaczenie usunięcia (%1)';
					|tr = 'Silme işareti ayarlandı (%1)'"), SelectedItemsCount);
		
		ElsIf ObjectsMarkedForDeletionCount = SelectedItemsCount Then 
			
			Scenario.DoQueryBox = NStr("vi = 'Bỏ dấu xóa các đối tượng đã chọn?';
										|ru = 'Снять с выделенных элементов пометку на удаление?';
										|en = 'Clear marks for deletion of the selected items?'; fa = 'Clear marks for deletion of the selected items?';
										|it = 'Rimuovere il contrassegno per la cancellazione dagli elementi selezionati?';
										|pl = 'Usunąć z wybranych elementów zaznaczenie do usunięcia?';
										|tr = 'Seçili öğelerin silme işareti kaldırılsın mı?'");
			Scenario.Notification = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Bỏ đặt dấu xóa (%1)';
					|ru = 'Пометка удаления снята (%1)';
					|en = 'Deletion mark cleared (%1)'; fa = 'Deletion mark cleared (%1)';
					|it = 'Il contrassegno per la cancellazione è stato rimosso (%1)';
					|pl = 'Usunięto zaznaczenie usunięcia (%1)';
					|tr = 'Silme işareti kaldırıldı (%1)'"), SelectedItemsCount);
			
		Else
			
			// If some of the items are marked for deletion, 1C:Enterprise will process only them and will clear the deletion mark.
			SelectedItems.Clear();
			
			For Each Item In StatisticsBySelectedItems.WithDeletionMark Do 
				SelectedItems.Add(Item.Key);
			EndDo;
			
			Scenario = DeletionMarkEditScenario(SelectedItems, StatisticsBySelectedItems);
			
		EndIf;
		
	EndIf;
	
	Return Scenario;
	
EndFunction

// Parameters:
//  Response - DialogReturnCode
//  Scenario - See DeletionMarkEditScenario
//
&AtClient
Procedure ExecuteDeletionMarkChangeScenario(Response, Scenario) Export 
	
	If Response <> DialogReturnCode.Yes Then 
		Return;
	EndIf;
	
	Errors = ChangeItemsDeletionMark(Scenario.SelectedItemsPresentations, Scenario.Check);
	If Errors.Count() > 0 Then 
		WarnAboutAnErrorWhenChangingElements(Errors, "DeletionMark");
	Else
		ShowUserNotification(
			Scenario.Notification,
			Scenario.Ref,
			Scenario.Explanation,
			PictureLib.DialogInformation);
	EndIf;
	CommonClient.NotifyObjectsChanged(Scenario.SelectedItems);
	
EndProcedure

&AtServer
Function ChangeItemsDeletionMark(SelectedItems, Check)
	
	ErrorTemplate = ?(Check, 
		NStr("vi = 'Không đủ quyền để đặt dấu xóa ""%1"".';
			|ru = 'Недостаточно прав на пометку на удаление ""%1"".';
			|en = 'Insufficient rights to mark the ""%1"" for deletion.'; fa = 'Insufficient rights to mark the ""%1"" for deletion.';
			|it = 'Insufficient rights to mark the ""%1"" for deletion.';
			|pl = 'Insufficient rights to mark the ""%1"" for deletion.';
			|tr = '""%1"" silme işareti koymak için yeterli erişim yetkisi yok.'"), 
		NStr("vi = 'Không đủ quyền để bỏ dấu xóa ""%1"".';
			|ru = 'Недостаточно прав на снятие пометки на удаление ""%1"".';
			|en = 'Insufficient rights to unmark the ""%1"" for deletion.'; fa = 'Insufficient rights to unmark the ""%1"" for deletion.';
			|it = 'Insufficient rights to unmark the ""%1"" for deletion.';
			|pl = 'Insufficient rights to unmark the ""%1"" for deletion.';
			|tr = '""%1"" silme işareti kaldırmak için yeterli erişim yetkisi yok.'"));
	
	Errors = New Array;
	For Each ItemProperties In SelectedItems Do
		
		Item = ItemProperties.Key;
			
		AvailableUpdate = False;
		If Check Then
			AvailableUpdate = AccessRight("InteractiveSetDeletionMark", Item.Metadata());
		Else
			AvailableUpdate = AccessRight("InteractiveClearDeletionMark", Item.Metadata());
		EndIf;

		If Not AvailableUpdate Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
				ItemProperties.Value);
			Errors.Add(ErrorText);
			Continue;
		EndIf;
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			LockItem = Block.Add(Item.Metadata().FullName());
			LockItem.SetValue("Ref", Item);
			Block.Lock();
			
			SelectedObject = Item.GetObject();
			LockDataForEdit(Item);
			SelectedObject.SetDeletionMark(Check);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			WriteLogEvent(NStr("vi = 'Chứng từ liên kết. Thay đổi dấu xóa';
								|ru = 'Связанные документы.Изменение пометки удаления';
								|en = 'Related documents.Change deletion mark'; fa = 'Related documents.Change deletion mark';
								|it = 'Documenti collegati.Modifica tag di eliminazione';
								|pl = 'Powiązane dokumenty.Zmiana zaznaczenie do usunięcia';
								|tr = 'Bağlı belgeler.Silme işaretinin değiştirilmesi'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,, Item,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Errors.Add(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			
		EndTry;
		
	EndDo;
	
	UpdateHierarchicalTree();
	Return Errors;
	
EndFunction

&AtClient
Procedure ChangeDocumentsPosting(Mode)
	
	ClearMessages();
	
	SelectedDocuments = SelectedItems();
	If SelectedDocuments.Count() = 0 Then
		Return;
	EndIf;
	
	Errors = New Array;
	ProcessedDocuments = ProcessedDocuments(SelectedDocuments, Mode, Errors);
	ProcessedDocumentsCount = ProcessedDocuments.Count();
	
	If Errors.Count() > 0 Then
		WarnAboutAnErrorWhenChangingElements(Errors, "Posting");
		Return;
	EndIf;
	
	If ProcessedDocumentsCount = 0 Then 
		Return;
	EndIf;
	
	If ProcessedDocumentsCount = 1 Then 
		Document = SelectedDocuments[0];
		Notification = NStr("vi = 'Thay đổi';
							|ru = 'Изменение';
							|en = 'Change'; fa = 'تغییر';
							|it = 'Modifica';
							|pl = 'Zmiana';
							|tr = 'Değişiklik'");
		Ref = GetURL(Document);
		Explanation = ProcessedDocuments[Document];
	Else
		Ref = "";
		Explanation = Title;
		Notification = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Thay đổi (%1)';
				|ru = 'Изменение (%1)';
				|en = 'Change (%1)'; fa = 'Change (%1)';
				|it = 'Modifica (%1)';
				|pl = 'Zmiana (%1)';
				|tr = 'Değişiklik (%1)'"), ProcessedDocumentsCount);
	EndIf;
	
	ShowUserNotification(Notification, Ref, Explanation, PictureLib.DialogInformation);
	CommonClient.NotifyObjectsChanged(SelectedDocuments);
	
EndProcedure

&AtServer
Function ProcessedDocuments(SelectedDocuments, Mode, Errors)
	
	ProcessedDocuments = New Map;
	IndexOf = SelectedDocuments.UBound();
	DocumentsThatCannotBePosted = New Array;
	While IndexOf >= 0 Do 
		
		ObjectMetadata = SelectedDocuments[IndexOf].Metadata();
		HoldingIsAllowed = Metadata.ObjectProperties.Posting.Allow;
		
		If Not Common.IsDocument(ObjectMetadata)
			Or ObjectMetadata.Posting <> HoldingIsAllowed Then 
			
			SelectedDocuments.Delete(IndexOf);
		Else
			If Mode = DocumentWriteMode.Posting Then
				RightInteractive = "InteractivePosting";
			ElsIf Mode = DocumentWriteMode.UndoPosting Then
				RightInteractive = "InteractiveUndoPosting";
			Else
				RightInteractive = Undefined;
			EndIf;
			If ValueIsFilled(RightInteractive) And Not AccessRight(RightInteractive, ObjectMetadata) Then
				DocumentsThatCannotBePosted.Add(SelectedDocuments[IndexOf]);
				SelectedDocuments.Delete(IndexOf);
			EndIf;
		EndIf;
		IndexOf = IndexOf - 1;
	EndDo;
	
	DocumentsProperties = Common.ObjectsAttributesValues(DocumentsThatCannotBePosted, "Presentation");
	ErrorTemplate = ?(Mode = DocumentWriteMode.Posting, NStr("vi = 'Không đủ quyền để kết chuyển ""%1"".';
															|ru = 'Недостаточно прав на проведение ""%1"".';
															|en = 'Insufficient rights to post ""%1"".'; fa = 'Insufficient rights to post ""%1"".';
															|it = 'Insufficient rights to post ""%1"".';
															|pl = 'Insufficient rights to post ""%1"".';
															|tr = '""%1"" kaydetme için yeterli erişim yetkisi yok.'"), NStr("vi = 'Không đủ quyền để hủy kết chuyển ""%1"".';
																												|ru = 'Недостаточно прав на отмену проведения ""%1"".';
																												|en = 'Insufficient rights to cancel posting of ""%1"".'; fa = 'Insufficient rights to cancel posting of ""%1"".';
																												|it = 'Insufficient rights to cancel posting of ""%1"".';
																												|pl = 'Insufficient rights to cancel posting of ""%1"".';
																												|tr = '""%1"" kaydetme iptal etmek için yeterli erişim yetkisi yok.'"));
	For Each DocumentProperty In DocumentsProperties Do
		PresentationOfDocument = DocumentProperty.Value.Presentation;
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, PresentationOfDocument);
		Errors.Add(ErrorText);
	EndDo;
	
	If SelectedDocuments.Count() = 0 Then 
		Return ProcessedDocuments;
	EndIf;
	
	DocumentsProperties = Common.ObjectsAttributesValues(SelectedDocuments, "Posted, Presentation");
	IndexOf = SelectedDocuments.UBound();
	While IndexOf >= 0 Do 
		
		Document = SelectedDocuments[IndexOf];
		DocumentProperties = DocumentsProperties[Document];
		If Mode = DocumentWriteMode.UndoPosting And Not DocumentProperties.Posted Then 
			SelectedDocuments.Delete(IndexOf);
			IndexOf = IndexOf - 1;
			Continue;
		EndIf;
		IndexOf = IndexOf - 1;
			
		BeginTransaction();
		Try
			
			Block = New DataLock;
			LockItem = Block.Add(Document.Metadata().FullName());
			LockItem.SetValue("Ref", Document);
			Block.Lock();
			
			SelectedObject = Document.GetObject(); // DocumentObject
			If SelectedObject.CheckFilling() Then 
				LockDataForEdit(Document);
				SelectedObject.Write(Mode);
			EndIf;
			
			ProcessedDocuments.Insert(Document, DocumentProperties.Presentation);
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			WriteLogEvent(NStr("vi = 'Chứng từ liên kết.Kết chuyển chứng từ';
								|ru = 'Связанные документы.Проведение документа';
								|en = 'Related documents.Post documents'; fa = 'Related documents.Post documents';
								|it = 'Documenti collegati.Esecuzione documento';
								|pl = 'Powiązane dokumenty.Zatwierdzenie dokumentu';
								|tr = 'Bağlı belgeler.Belgenin onaylanması'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,, Document,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Errors.Add(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			
		EndTry;
		
	EndDo;
	
	UpdateHierarchicalTree();
	Return ProcessedDocuments;
	
EndFunction

// General.

&AtClient
Procedure WarnAboutAnErrorWhenChangingElements(Errors, Scenario)
	
	ErrorsAreMinimized = CommonClientServer.CollapseArray(Errors);
	If ErrorsAreMinimized.Count() = 1 Then 
		WarningText = ErrorsAreMinimized[0];
	Else
		WarningTemplate = ?(Scenario = "DeletionMark", 
			NStr("vi = 'Không thể thay đổi dấu xóa chứng từ:
				|%1';
				|ru = 'Не удалось изменить пометку удаления документов:
				|%1';
				|en = 'Cannot change the following document deletion mark:
				|%1'; fa = 'Cannot change the following document deletion mark:
				|%1';
				|it = 'Non è stato possibile modificare il contrassegno di eliminazione dei documenti:
				|%1';
				|pl = 'Nie udało się zmienić zaznaczenie do usunięcia dokumentów:
				|%1';
				|tr = 'Belgelerin silme işareti değiştirilemedi:
				|%1'"),
			NStr("vi = 'Không thể kết chuyển chứng từ:
				|%1';
				|ru = 'Не удалось провести документы:
				|%1';
				|en = 'Cannot post the documents:
				|%1'; fa = 'Cannot post the documents:
				|%1';
				|it = 'Non è stato possibile eseguire i documenti:
				|%1';
				|pl = 'Nie udało się zatwierdzić dokumentów:
				|%1';
				|tr = 'Belgeler onaylanmadı:
				|%1'"));
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			WarningTemplate, StrConcat(ErrorsAreMinimized, Chars.LF));
	EndIf;
	
	ShowMessageBox(, WarningText);
	
EndProcedure

&AtClient
Function FirstRowFieldDrilldown(LineNumber)
	
	If LineNumber  = Undefined Then
		Return Undefined;
	EndIf;
	
	Details = Undefined;
	
	CurrentColumnNumber = 1;
	ColumnMaxNumber = 100;
	While CurrentColumnNumber <> ColumnMaxNumber Do
		Cell = ReportTable.Area(LineNumber, CurrentColumnNumber, LineNumber, CurrentColumnNumber);
		CurrentColumnNumber = CurrentColumnNumber + 1;
		If Cell = Undefined Then
			Continue;
		EndIf;
		Details = Cell.Details;
		
		If Details <> Undefined Then
			Break;
		EndIf;
	EndDo;
	
	Return Details;
	
EndFunction

#EndRegion

&AtClient
Procedure FindAndSelectString(SearchText, SearchStart = Undefined)
	
	If Not ValueIsFilled(SearchText) Then
		Return;
	EndIf;
	
	SearchResult = ReportTable.FindText(SearchText, SearchStart,,True,,,True);
	If SearchResult = Undefined And SearchStart <> Undefined Then
		SearchResult = ReportTable.FindText(SearchText,,,True,,,True);
	EndIf;
	
	If SearchResult <> Undefined Then
		RowsSelected = New Array;
		RowsSelected.Add(SearchResult);
		Items.ReportTable.SetSelectedAreas(RowsSelected);
		CurrentItem = Items.ReportTable;
	Else
		ShowMessageBox(, NStr("ru = 'Строка не найдена.';
								|vi = 'The line is not found.';
								|en = 'The line is not found.'; fa = 'The line is not found.';
								|it = 'The line is not found.';
								|pl = 'The line is not found.';
								|tr = 'Satır bulunamadı.'"));
	EndIf;
	
EndProcedure

#EndRegion