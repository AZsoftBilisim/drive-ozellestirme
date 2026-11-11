#Region Public

#Region StringCaching

// Initializes the row cache on the for form for the specified table.
// To use string caching, you must add the "cached Strings" attribute with the "Custom"type to the form.
//
// Parameters:
//  FormTable - FormTable - a form element that contains the table part.
//
Procedure InitializeRowCache(FormTable) Export
	
	Form = FormTable.Parent;
	While TypeOf(Form) <> Type("ClientApplicationForm") Do
		Form = Form.Parent;
	EndDo;
	
	LineCache = New Structure;
	
	TableAttributes = Form.GetAttributes(FormTable.DataPath);
	For Each Attribute In TableAttributes Do
		LineCache.Insert(Attribute.Name, Undefined);
	EndDo;
	
	If Form.CachedLines = Undefined Then
		Form.CachedLines = New Structure;
	EndIf;
	Form.CachedLines.Insert(FormTable.Name, New FixedStructure(LineCache));
	
EndProcedure

#EndRegion

#Region CopyPasteLines

// Checks for saved table part rows in the clipboard.
//
// Returns:
//  Boolean - True - there are lines in the buffer, False - otherwise.
//
Function ThereAreLinesInClipboard() Export
	
	Return Not Common.EmptyClipboard("CopyPasteLines");
	
EndFunction

// Copies the specified rows of the table part to the clipboard.
//
// Parameters:
//  TabularSection - TabularSection - 
//  Rows - Array - row IDs (the selected row property of the form table).
//
Procedure CopyRowsToClipboard(TabularSection, Rows) Export
	
	ValueTable = TabularSection.Unload(New Array);
	
	ColumnsToDelete = New Array;
	ColumnsToDelete.Add("SourceLineNumber");
	ColumnsToDelete.Add("RowCode");
	ColumnsToDelete.Add("DeliveryLineCode");
	ColumnsToDelete.Add("RowID");
	ColumnsToDelete.Add("ConnectionKey");
	
	For Each ColumnName In ColumnsToDelete Do
		Column = ValueTable.Columns.Find(ColumnName);
		If Column <> Undefined Then
			ValueTable.Columns.Delete(Column);
		EndIf;
	EndDo;
	
	IndexOf = 0;
	OriginalLines = New Array(Rows.Count());
	For Each RowID In Rows Do
		OriginalLines[IndexOf] = TabularSection.FindByID(RowID);
		
		NewRow = ValueTable.Add();
		FillPropertyValues(NewRow, OriginalLines[IndexOf]);
		NewRow.LineNumber = IndexOf;
		
		IndexOf = IndexOf + 1;
	EndDo;
	
	SetsServerCall.AddToFullSet(TabularSection, OriginalLines);
	While IndexOf < OriginalLines.Count() Do
		NewRow = ValueTable.Add();
		FillPropertyValues(NewRow, OriginalLines[IndexOf]);
		NewRow.LineNumber = IndexOf;
		
		IndexOf = IndexOf + 1;
	EndDo;
	
	Common.CopyToClipboard(ValueTable, "CopyPasteLines");
	
EndProcedure

// Copies the specified table of values to the clipboard.
//
// Parameters:
//  Table - ValueTable - a table of values to put on the clipboard.
//
Procedure PlaceValueTableOnClipboard(Table) Export
	
	TableForBuffer = Table.Copy();
	TMCommonUse.NumberValueTable(TableForBuffer, "LineNumber");
	
	Common.CopyToClipboard(TableForBuffer, "CopyPasteLines");
	
EndProcedure

// Retrieves rows from the table from the clipboard.
//
// Parameters:
//  FilterParameters - Map - sets the search criteria:
//      the key defines the path to the data that will be searched, and the value is the value you are looking for;
//      If the data path does not match the data of the original buffer table, the method returns Undefined.
//  Columns - String, Array - list of columns for the returned table;
//      Columns that are not in the source buffer table are ignored. if there are no specified columns
//      in the source table, the method returns Undefined.
//
// Returns:
//  ValueTable, Undefined - lines from the buffer, if the buffer is not empty and the data in it corresponds to the specified selection.
//
Function RowsFromClipboard(FilterParameters = Undefined, Columns = Undefined) Export
	
	Clipboard = Common.RowsFromClipboard();
	
	If Clipboard.Source <> "CopyPasteLines" Then
		Return Undefined;
	EndIf;
	
	If ValueIsFilled(FilterParameters) Then
		
		Query = New Query;
		Query.SetParameter("ValueTable", Clipboard.Data);
		
		SelectionFields1 = New Array;
		FilterConditions = New Array;
		NumberOfParameters = 0;
		
		For Each Condition In FilterParameters Do
			If StrFind(String(Condition.Key), ".") > 0 Then
				ColumnName = Left(Condition.Key, StrFind(Condition.Key, ".") - 1);
			Else
				ColumnName = Condition.Key;
			EndIf;
			
			If Clipboard.Data.Columns.Find(ColumnName) = Undefined Then
				Return Undefined;
			Else
				SelectionFields1.Add(ColumnName);
				FilterConditions.Add(Condition.Key + " IN (&VALUE" + NumberOfParameters + ")");
				Query.SetParameter("Value" + NumberOfParameters, Condition.Value);
				NumberOfParameters = NumberOfParameters + 1;
			EndIf;
		EndDo;
		
		Query.Text =
			"SELECT
			|	LineNumber,
			|	&ReplacingSelectionField
			|INTO ValueTable
			|FROM &ValueTable AS VT
			|;
			|SELECT
			|	LineNumber
			|FROM ValueTable AS VT
			|WHERE
			|	&ReplacingSelectionCondition";
		ReplacingSelectionField = StrConcat(SelectionFields1, ", ");
		ReplacingSelectionCondition = StrConcat(FilterConditions, " And ");
		Query.Text = StrReplace(Query.Text, "&ReplacingSelectionField", ReplacingSelectionField);
		Query.Text = StrReplace(Query.Text, "&ReplacingSelectionCondition", ReplacingSelectionCondition);
		Result = Query.Execute();
		
		If Result.IsEmpty() Then
			Return Undefined;
		EndIf;
		
		Selection = Result.Select();
		RowFilter = New Array(Selection.Count());
		
		IndexOf = 0;
		While Selection.Next() Do
			RowFilter[IndexOf] = Clipboard.Data[Selection.LineNumber];
			IndexOf = IndexOf + 1;
		EndDo;
		
	Else
		RowFilter = Undefined;
	EndIf;
	
	If ValueIsFilled(Columns) Then
		
		If TypeOf(Columns) = Type("String") Then
			ColumnsList = StrSplit(Columns, ",", False);
		Else
			ColumnsList = Columns;
		EndIf;
		
		PreparationForSelection = New Array;
		For Each Property In ColumnsList Do
			If Clipboard.Data.Columns.Find(TrimAll(Property)) <> Undefined Then
				PreparationForSelection.Add(Property);
			EndIf;
		EndDo;
		
		If Not ValueIsFilled(PreparationForSelection) Then
			Return Undefined;
		EndIf;
		
		FilterColumns1 = StrConcat(PreparationForSelection, ",");
		
	Else
		FilterColumns1 = Undefined;
	EndIf;
	
	VT = Clipboard.Data.Copy(RowFilter, FilterColumns1);
	
	Return VT;
	
EndFunction

#EndRegion

#EndRegion