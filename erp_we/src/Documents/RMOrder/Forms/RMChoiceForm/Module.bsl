
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	AnyRepairPresentation = NStr("vi = '<sửa chữa ngoài kế hoạch>';
								|ru = '<произвольный ремонт>';
								|en = '<any R&M>'; fa = '<any R&M>';
								|it = '<manutenzione arbitraria>';
								|pl = '<dowolny remont>';
								|tr = '<keyfi onarım>'");
	
	If Parameters.Property("Asset") Then
		
		Asset = Parameters.Asset;
		
	Else
		
		Cancel = True;
		
	EndIf;
	
	FillInRepairTree();

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not Exit And Modified Then
		
		Cancel = True;
		
		ShowQueryBox(
			New CallbackDescription("TransferRepairsToDocument", ThisForm),
			NStr("vi = 'Dữ liệu bị thay đổi. Đưa các thay đổi vào chứng từ?';
				|ru = 'Данные были изменены. Перенести изменения в документ?';
				|en = 'The data was modified. Migrate the changes to the document?'; fa = 'The data was modified. Migrate the changes to the document?';
				|it = 'I dati sono stati modificati. Trasferire le modifiche nel documento?';
				|pl = 'Dane zostały zmienione. Przenieść zmiany do dokumentu?';
				|tr = 'Veriler değiştirildi. Değişiklikler belgeye aktarılsın mı?'"),
			QuestionDialogMode.YesNoCancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	TransferRepairsToDocument();
	
EndProcedure

&AtClient
Procedure SelectRows(Command)
	MarkElementsByTreeRows(True);
EndProcedure

&AtClient
Procedure ClearRows(Command)
	MarkElementsByTreeRows(False);
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RepairTreeMarked.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RepairTree.ItIsARepairKindLine");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Show", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RepairTreePresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RepairTree.ItIsARepairKindLine");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RepairTree.RMType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("AnyRepairPresentation"));

EndProcedure

&AtClient
Procedure TransferRepairsToDocument(Val Result=Undefined, AdditionalParameters=Undefined) Export
	
	If Result = Undefined Then
		Result = DialogReturnCode.Yes;
	EndIf;
	
	If Result = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;
	
	If Result = DialogReturnCode.Yes Then
		
		// Removal of modification, because before closing, the attribute is checked.
		Modified = False;
		
		NotificationParameters = DocumentFormNotificationParameters();
		
		Close();
		
		NotifyChoice(NotificationParameters);
		
	EndIf;
	
EndProcedure

// Forms a tree of repairs
//
&AtServer
Procedure FillInRepairTree()
	
	RepairTree.GetItems().Clear();
	
	If ValueIsFilled(Asset) Then
		
		Query = New Query(
			"SELECT
			|	CAST(FillingData.Node AS Catalog.SubAssets) AS Node,
			|	CAST(FillingData.RMType AS Catalog.RMTypes) AS RMType,
			|	CAST(FillingData.ExpenseItem AS ChartOfCharacteristicTypes.ExpenseItems) AS ExpenseItem,
			|	CAST(FillingData.RMCode AS NUMBER(10, 0)) AS RMCode
			|INTO TableData
			|FROM
			|	&FillingData AS FillingData
			|
			|INDEX BY
			|	Node,
			|	RMType
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	FillingData.Node,
			|	FillingData.RMType,
			|	MAX(FillingData.ExpenseItem) AS ExpenseItem,
			|	MAX(FillingData.RMCode) AS RMCode
			|INTO FillingData
			|FROM
			|	TableData AS FillingData
			|
			|GROUP BY
			|	FillingData.Node,
			|	FillingData.RMType
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Nodes.Parent AS Parent,
			|	Nodes.Ref AS Node,
			|	Nodes.Class AS Class
			|INTO Nodes
			|FROM
			|	Catalog.SubAssets AS Nodes
			|WHERE
			|	Nodes.Owner = &Asset
			|	AND NOT Nodes.DeletionMark
			|	AND Nodes.Status IN (VALUE(Enum.AssetStatuses.InOperation))
			|
			|INDEX BY
			|	Node,
			|	Class
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Nodes.Parent AS Parent,
			|	Nodes.Node AS Node,
			|	RMTypes.Owner AS Class,
			|	RMTypes.Ref AS RMType
			|INTO NodeRepairs
			|FROM
			|	Nodes AS Nodes
			|		INNER JOIN Catalog.RMTypes AS RMTypes
			|		ON Nodes.Class = RMTypes.Owner
			|			AND (NOT RMTypes.DeletionMark)
			|
			|UNION ALL
			|
			|SELECT
			|	Nodes.Parent,
			|	Nodes.Node,
			|	Nodes.Class,
			|	VALUE(Catalog.RMTypes.EmptyRef)
			|FROM
			|	Nodes AS Nodes
			|
			|INDEX BY
			|	Class,
			|	RMType
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	NodeRepairs.Parent AS Parent,
			|	NodeRepairs.Node AS Node,
			|	NodeRepairs.Class AS Class,
			|	NodeRepairs.RMType AS RMType,
			|	CASE
			|		WHEN FillingData.Node IS NULL 
			|			THEN FALSE
			|		ELSE TRUE
			|	END AS Marked,
			|	ISNULL(FillingData.ExpenseItem, UNDEFINED) AS ExpenseItem,
			|	ISNULL(FillingData.RMCode, 0) AS RMCode
			|FROM
			|	NodeRepairs AS NodeRepairs
			|		LEFT JOIN FillingData AS FillingData
			|		ON NodeRepairs.Node = FillingData.Node
			|			AND NodeRepairs.RMType = FillingData.RMType
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	RMTypes.Ref AS RMType,
			|	CASE
			|		WHEN FillingData.RMCode IS NULL 
			|			THEN FALSE
			|		ELSE TRUE
			|	END AS Marked,
			|	ISNULL(FillingData.ExpenseItem, UNDEFINED) AS ExpenseItem,
			|	ISNULL(FillingData.RMCode, 0) AS RMCode
			|FROM
			|	Catalog.Assets AS Objects
			|		LEFT JOIN Catalog.RMTypes AS RMTypes
			|		ON Objects.Class = RMTypes.Owner
			|			AND (NOT RMTypes.DeletionMark)
			|		LEFT JOIN FillingData AS FillingData
			|		ON (RMTypes.Ref = FillingData.RMType)
			|			AND (FillingData.Node = VALUE(Catalog.SubAssets.EmptyRef))
			|WHERE
			|	Objects.Ref = &Asset
			|	AND NOT RMTypes.Owner IS NULL 
			|
			|UNION ALL
			|
			|SELECT
			|	VALUE(Catalog.RMTypes.EmptyRef),
			|	CASE
			|		WHEN FillingData.RMCode IS NULL 
			|			THEN FALSE
			|		ELSE TRUE
			|	END,
			|	ISNULL(FillingData.ExpenseItem, UNDEFINED),
			|	ISNULL(FillingData.RMCode, 0)
			|FROM
			|	Catalog.Assets AS Objects
			|		LEFT JOIN FillingData AS FillingData
			|		ON (FillingData.Node = VALUE(Catalog.SubAssets.EmptyRef))
			|			AND (FillingData.RMType = VALUE(Catalog.RMTypes.EmptyRef))
			|WHERE
			|	Objects.Ref = &Asset");
		
		UseNodes = GetFunctionalOption("UseSubAssets");
		
		TableOfRepairs = GetFromTempStorage(Parameters.Tables.RM);
		If Not UseNodes Then
			TableOfRepairs.FillValues(Catalogs.SubAssets.EmptyRef(), "Node");
		EndIf;
		
		Query.SetParameter("Asset", Asset);
		Query.SetParameter("FillingData", TableOfRepairs);
		
		ResultsPackage = Query.ExecuteBatch();
		
		TreeRows = RepairTree.GetItems();
		
		// Adding an operation object as the root of a tree
		OperationObjectString = TreeRows.Add();
		OperationObjectString.Presentation = String(Asset);
		OperationObjectString.PictureIndex = 1;
		
		LinesOfObjectOfOperation = OperationObjectString.GetItems();
		
		// Filling in the types of repairs of the object
		Selection = ResultsPackage[5].Select();
		While Selection.Next() Do
			
			RepairTypeString = LinesOfObjectOfOperation.Insert(0);
			RepairTypeString.PictureIndex = 3;
			RepairTypeString.Presentation = Selection.RMType;
			RepairTypeString.ItIsARepairKindLine = True;
			FillPropertyValues(RepairTypeString, Selection, "RMType, Marked, ExpenseItem, RMCode");
			
		EndDo;
		
		If UseNodes Then
			
			// Adding nodes of the object of operation and their types of repairs
			Selection = ResultsPackage[4].Select();
			
			RowsMap = NewRowMatching();
			RowsMap.Insert(Catalogs.SubAssets.EmptyRef(), OperationObjectString.GetItems());
			
			SelectionTraversalArray = New Array;
			SelectionTraversalArray.Add(Catalogs.SubAssets.EmptyRef());
			
			SampleTraversalCount = 0;
			While SampleTraversalCount < SelectionTraversalArray.Count() Do
				
				Selection.Reset();
				TheStructureOfTheSearch = New Structure("Parent", SelectionTraversalArray[SampleTraversalCount]);
				While Selection.FindNext(TheStructureOfTheSearch) Do
					
					NodeLines = RowsMap.Get(Selection.Node); // FormDataTreeItemCollection
					
					If NodeLines = Undefined Then
						
						ParentRows = RowsMap.Get(SelectionTraversalArray[SampleTraversalCount]); // FormDataTreeItemCollection
						
						NewRow = ParentRows.Add();
						NewRow.Presentation = String(Selection.Node);
						NewRow.Node = Selection.Node;
						NewRow.PictureIndex = 2;
						
						NodeLines = NewRow.GetItems();
						
						RowsMap.Insert(Selection.Node, NodeLines);
						SelectionTraversalArray.Add(Selection.Node);
						
					EndIf;
					
					RepairTypeString = NodeLines.Insert(0);
					RepairTypeString.PictureIndex = 3;
					RepairTypeString.Presentation = Selection.RMType;
					RepairTypeString.ItIsARepairKindLine = True;
					FillPropertyValues(RepairTypeString, Selection, "Node, RMType, Marked, ExpenseItem, RMCode");
					
				EndDo;
				
				SampleTraversalCount = SampleTraversalCount + 1;
				
			EndDo;
			
		EndIf;
	EndIf;
	
EndProcedure

//  
// Returns:
// Map of KeyAndValue:
// * Key - CatalogRef.SubAssets -
// * Value - FormDataTreeItemCollection -
&AtServer
Function NewRowMatching()
	Return New Map();
EndFunction

// Recursive tree traversal procedure with copying the data of the marked rows
//
&AtServer
Procedure CompleteTableByRowsOfTree(Table, Val Rows=Undefined)
	
	If Rows = Undefined Then
		Rows = RepairTree.GetItems();
	EndIf;
	
	For Each String In Rows Do
		
		If String.ItIsARepairKindLine Then
			If String.Marked Then
				FillPropertyValues(Table.Add(), String);
			EndIf;
		Else
			CompleteTableByRowsOfTree(Table, String.GetItems());
		EndIf;
		
	EndDo;
	
EndProcedure

// The procedure recursively sets the flag "Marked" to the specified value in the rows of the repair tree.
//
&AtServer
Procedure MarkElementsByTreeRows(Marked, Val Rows=Undefined)
	
	If Rows = Undefined Then
		Rows = RepairTree.GetItems();
	EndIf;
	
	For Each String In Rows Do
		
		If String.ItIsARepairKindLine Then
			String.Marked = Marked;
		Else
			MarkElementsByTreeRows(Marked, String.GetItems());
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns the completed parameters of the notification form for the repair order document
//
// Returns:
// 		Structure - Structure of notification parameters.
//
&AtServer
Function DocumentFormNotificationParameters()
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("CurrentOperation1", "SelectRepairs");
	NotificationParameters.Insert("Tables", New Structure);
	
	TableOfRepairs = New ValueTable;
	TableOfRepairs.Columns.Add("Node", New TypeDescription("CatalogRef.SubAssets"));
	TableOfRepairs.Columns.Add("RMType", New TypeDescription("CatalogRef.RMTypes"));
	TableOfRepairs.Columns.Add("ExpenseItem", New TypeDescription("ChartOfCharacteristicTypesRef.ExpenseItems"));
	TableOfRepairs.Columns.Add("RMCode", New TypeDescription("Number"));
	
	CompleteTableByRowsOfTree(TableOfRepairs);
	
	NotificationParameters.Tables.Insert("RM", PutToTempStorage(TableOfRepairs));
	
	Return NotificationParameters;
	
EndFunction

#EndRegion
