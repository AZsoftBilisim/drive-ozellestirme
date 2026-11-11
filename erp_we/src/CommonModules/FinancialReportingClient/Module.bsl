
#Region Public

// This procedure completes editing of the budget report element
//
// Parameters:
//  Form - ManagedFormExtensionForObjects - form of the element.
//  AdditionalInfo - Structure - additional information to return to the owner form.
//
Procedure FinishEditingReportElement(Form, AdditionalInfo = Undefined) Export
	
	If Form.CheckFilling() Then
		If Not Form.ReadOnly Then
			Form.Write();
			Form.Modified = False;
		EndIf;
		Structure = FinancialReportingClientServer.ReportElementStructure();
		FillPropertyValues(Structure, Form.Object, , "FormulaOperands, ItemKindAttributes, CalculationsRules");
		If ValueIsFilled(AdditionalInfo) Then
			For Each KeyAndValue In AdditionalInfo Do
				Structure.Insert(KeyAndValue.Key, KeyAndValue.Value);
			EndDo;
		EndIf;
		Form.Close(Structure);
	EndIf;
	
EndProcedure

// The procedure adds a new operand in the text of the formula
//
// Parameters:
//  Form  - ClientApplicationForm - formula constructor form
//  NewOperands - Array of FormDataCollectionItem - array of added rows of the operand table:
//   *Id - String - ID of the operand.
//
Procedure AddFormulaText(Form, NewOperands) Export
	
	For Each Operand In NewOperands Do
		
		Id = Operand.Id;
		
		Form.Items.Formula.SelectedText = "[" + Id + "]";
		
		BeginningOfTheLine = Undefined; BeginningOfTheColumn = Undefined;
		EndOfRow = Undefined; EndOfColumn = Undefined;
		Form.Items.Formula.GetTextSelectionBounds(BeginningOfTheLine, BeginningOfTheColumn, EndOfRow, EndOfColumn);
		
		PositionLineStart = Undefined; PositionColumnStart = Undefined;
		PositionLineEnd = Undefined; PositionColumnEnd = Undefined;
		If ThereIsOpeningTag(Form.Formula, BeginningOfTheLine, BeginningOfTheColumn, PositionLineStart, PositionColumnStart)
			And ThereIsClosingTag(Form.Formula, BeginningOfTheLine, BeginningOfTheColumn, PositionLineEnd, PositionColumnEnd) Then
			
			NewFormula = "";
			
			SelectLineStart = Undefined; SelectStartColumn = Undefined;
			SelectLineEnd = Undefined; SelectEndColumn = Undefined;
			For Cnt = 1 To StrLineCount(Form.Formula) Do
				If Cnt > 1 Then
					NewFormula = NewFormula + Chars.LF;
				EndIf;
				FormulaString = StrGetLine(Form.Formula, Cnt);
				If Cnt < PositionLineStart Then
					NewFormula = NewFormula + FormulaString;
				ElsIf Cnt = PositionLineStart Then
					NewFormula = NewFormula + 
									Left(FormulaString, PositionColumnStart - 1) + 
									"[" + Id + "]";
					SelectLineStart = Cnt;
					SelectStartColumn = PositionColumnStart;
					SelectEndColumn = PositionColumnStart + StrLen(Id);
				EndIf;
				If Cnt > PositionLineEnd Then
					NewFormula = NewFormula + FormulaString;
				ElsIf Cnt = PositionLineEnd Then
					NewFormula = NewFormula + Mid(FormulaString, PositionColumnEnd + 1);
					SelectLineEnd = Cnt;
				EndIf;
			EndDo;
			
			Form.Formula = NewFormula;
			Form.Items.Formula.SetTextSelectionBounds(SelectLineStart, SelectStartColumn, SelectLineEnd, SelectEndColumn);
			
		EndIf;
		
		If Not Form.Modified Then
			Form.Modified = True;
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns the structure of parameters for setting the new parent.
//
// Returns:
// 	Structure - The structure of the installation parameters of the new parent.
//
Function TemplateForNewParentInstallationOptions() Export
	
	ParameterTemplate = New Structure;
	ParameterTemplate.Insert("TheseAreSavedOnes", False);
	ParameterTemplate.Insert("LoopControl", True);
	ParameterTemplate.Insert("FormIdentifier", Undefined);
	ParameterTemplate.Insert("Copy", False);
	ParameterTemplate.Insert("IDParameters_", Undefined);
	
	Return ParameterTemplate;
	
EndFunction

// Moves a string and all its subordinate elements to a new branch of the tree.
//
//	Parameters:
//		CurrentRow - FormDataTreeItem, ValueTreeRow - row in the report item tree
//		NewParent - FormDataTreeItem, ValueTreeRow - a new parent branch of a tree of report elements
//		ParentInstallationOptions - Structure - Structure of parameters with properties:
//			*TheseAreSavedOnes - Boolean - flag indicating that these are rows in the tree of saved elements
//			*LoopControl - Boolean - flag that specifies whether string looping control is performed
//			*FormIdentifier - UUID - unique ID of the form in the temporary storage 
//			                                               of which you want to place the element data.
//			*Copy - Boolean - Flag for copying an element.
//			*IDParameters_ - Structure - Structure containing the parameters of the IDs.
//
Procedure SetNewParentOfFormElement(CurrentRow, NewParent, ParentInstallationOptions) Export
	
	TheseAreSavedOnes = ParentInstallationOptions.TheseAreSavedOnes;
	LoopControl = ParentInstallationOptions.LoopControl;
	FormIdentifier = ParentInstallationOptions.FormIdentifier;
	Copy = ParentInstallationOptions.Copy;
	IDParameters_ = ParentInstallationOptions.IDParameters_;
	
	If LoopControl Then
		Parent = FinancialReportingClientServer.RowParent(NewParent);
		While Parent <> Undefined Do
			If TypeOf(Parent) = Type("FormDataTreeItem") And Parent.GetID() = CurrentRow.GetID()
				Or ValueIsFilled(Parent.ReportItem) And Parent.ReportItem = CurrentRow.ReportItem
				Or ValueIsFilled(Parent.AddressOfItemStructure) And Parent.AddressOfItemStructure = CurrentRow.AddressOfItemStructure Then
				Return;
			EndIf;
			Parent = FinancialReportingClientServer.RowParent(Parent);
		EndDo;
	EndIf;
	
	ParentRows = SubordinateLinesOfFormElement(NewParent);
	If TheseAreSavedOnes Then
		NewRow = ParentRows.Add();
	Else
		IndexOf = FinancialReportingClientServer.IndexOfNewRow(ParentRows);//if there is a total for the group at the end of the group, then a new line should appear in front of it
		NewRow = ParentRows.Insert(IndexOf);
	EndIf;
	
	FillPropertyValues(NewRow, CurrentRow);
	
	If IDParameters_ <> Undefined Then
		IDsMap = IDParameters_.IDsMap;
		If IDParameters_.Mode = "Remember" Then
			IDsMap.Insert(CurrentRow.GetID(), NewRow.GetID());
		ElsIf IDParameters_.Mode = "Refresh" Then
			NewRow.LineIndexOfReportItems = IDsMap[NewRow.LineIndexOfReportItems];
			For Cnt = 2 To IDParameters_.NumberOfIDs Do
				If NewRow["LineIndexOfReportItems" + Cnt] = Undefined Then
					Continue;
				EndIf;
				NewRow["LineIndexOfReportItems" + Cnt] = 
					IDsMap[NewRow["LineIndexOfReportItems" + Cnt]];
			EndDo;
		EndIf;
	EndIf;
	
	If FormIdentifier <> Undefined Then
		If Copy Then
			
			If ValueIsFilled(NewRow.AddressOfItemStructure) Then
				NewRow.AddressOfItemStructure = 
					FinancialReportingServerCall.CopyElementTo(
						NewRow.AddressOfItemStructure, FormIdentifier);
						
			ElsIf Not ValueIsFilled(NewRow.AddressOfItemStructure)
					And ValueIsFilled(NewRow.ReportItem) Then
			
				NewRow.AddressOfItemStructure = 
					FinancialReportingServerCall.PlaceItemInStorage(
						NewRow.ReportItem, FormIdentifier, True);
			EndIf;
			
			NewRow.ReportItem = Undefined;
		
		ElsIf Not ValueIsFilled(NewRow.AddressOfItemStructure)
			And ValueIsFilled(NewRow.ReportItem) Then
			
			NewRow.AddressOfItemStructure = 
				FinancialReportingServerCall.PlaceItemInStorage(
					NewRow.ReportItem, FormIdentifier);
		
		EndIf;
	EndIf;
	
	LinesOfCurLine = SubordinateLinesOfFormElement(CurrentRow);
	Cnt = LinesOfCurLine.Count();
	
	While Cnt > 0 Do
		
		LineNumber = LinesOfCurLine.Count() - Cnt;
		Substring = LinesOfCurLine[LineNumber];
		ParentInstallationOptions = TemplateForNewParentInstallationOptions();
		ParentInstallationOptions.TheseAreSavedOnes = TheseAreSavedOnes;
		ParentInstallationOptions.LoopControl = False;
		ParentInstallationOptions.FormIdentifier = FormIdentifier;
		ParentInstallationOptions.Copy = Copy;
		ParentInstallationOptions.IDParameters_ = IDParameters_;
		SetNewParentOfFormElement(Substring, NewRow, ParentInstallationOptions);
		Cnt = Cnt - 1;
		
	EndDo;
	
	If Not Copy Then
		CurrentParent = FinancialReportingClientServer.RowParent(CurrentRow);
		If CurrentParent <> Undefined Then
			CurCollectionOfStrings = SubordinateLinesOfFormElement(CurrentParent);
			CurCollectionOfStrings.Delete(CurrentRow);
		EndIf;
	EndIf;
	
EndProcedure

// Finds the parent element of the specified type that is closest to the top of the hierarchy.
// Parameters:
//	Tree - FormDataTree, FormDataTreeItem - tree element to define the parent element
//					for if a tree is specified, the result will be determined among the subordinate rows of the first level.
//	RootElementView - EnumRef.FinancialReportItemKinds - type of parent.
//
//	Returns:
//		FormDataTreeItem - the root element.
//		The assignment tree string is the root element.
//
Function RootElementOfFormElement(Tree, RootElementView = Undefined) Export
	
	If RootElementView = Undefined Then
		RootElementView = PredefinedValue("Enum.FinancialReportItemKinds.EmptyRef");
	EndIf;
	
	RootItem = Undefined;
	If TypeOf(Tree) = Type("FormDataTree") Then
		SubordinateRows = SubordinateLinesOfFormElement(Tree);
		For Each TreeRow In SubordinateRows Do
			If TreeRow.ItemKind = RootElementView Then
				RootItem = TreeRow;
				Break;
			EndIf;
		EndDo;
	Else
		RootItem = FinancialReportingClientServer.RowParent(Tree);
		While RootItem <> Undefined Do
			If RootItem.ItemKind = RootElementView Then
				Break;
			EndIf;
			RootItem = FinancialReportingClientServer.RowParent(RootItem);
		EndDo;
	EndIf;
	
	Return RootItem;
	
EndFunction

// Returns, depending on the type, a collection of subordinate elements of the first level of the passed row in the report element tree.
//
//	Parameters:
//		TreeRow - FormDataTreeItem, ValueTreeRow, ValueTreeRowCollection, FormDataTree - a row in the report item tree.
//
//	Returns:
//		FormDataTreeItemCollection - collection of subordinate strings.
//		A collection of string tree assignments is a collection of subordinate strings.
//
Function SubordinateLinesOfFormElement(TreeRow) Export
	
	TreeRowType = TypeOf(TreeRow);
	ThisIsCollectionOfStrings = TreeRowType = Type("FormDataTreeItemCollection");
	
	If ThisIsCollectionOfStrings Then
		SubordinateRows = TreeRow;
	Else
		If TypeOf(TreeRow) = Type("FormDataTreeItem")
			Or TypeOf(TreeRow) = Type("FormDataTree") Then
			SubordinateRows = TreeRow.GetItems();
		EndIf;
	EndIf;
	
	Return SubordinateRows;
	
EndFunction

// Finds the element closest to the bottom of the hierarchy by the value of the specified props.
//
// Parameters:
//	Tree - FormDataTree, FormDataTreeItem - the element of wood or string of the tree in which to search
//	AttributeName - String - name of the tree attribute whose value is compared with the one set for the search
//	AttributeValue - Arbitrary - the value of the tree's props to find.
//
// Returns:
//	FormDataTreeItem, ValueTreeRow - a subordinate element.
//
Function SubordinateElementOfFormElement(Tree, AttributeName, AttributeValue) Export
	
	SubordinateItem = Undefined;
	SubordinateRows = SubordinateLinesOfFormElement(Tree);
	For Each TreeRow In SubordinateRows Do
		If TreeRow[AttributeName] = AttributeValue Then
			SubordinateItem = TreeRow;
			Break;
		EndIf;
		SubordinateItem = SubordinateElementOfFormElement(TreeRow, AttributeName, AttributeValue);
		If SubordinateItem <> Undefined Then
			Break;
		EndIf;
	EndDo;
	
	Return SubordinateItem;
	
EndFunction

#EndRegion

#Region Private

Function ThereIsOpeningTag(Formula, LineNumber, ColumnNumber, NewLineNumber = Undefined, NewColumnNumber = Undefined)
	
	ThereIsOpeningTag = False;
	For LineCounter = 1 To LineNumber Do
		StringByNumber = StrGetLine(Formula, LineCounter);
		If LineCounter = LineNumber Then
			End = ColumnNumber;
		Else
			End = StrLen(StringByNumber);
		EndIf;
		For ColumnsCounter = 1 To End Do
			If Mid(StringByNumber, ColumnsCounter, 1) = "<" Then
				ThereIsOpeningTag = True;
				NewLineNumber = LineCounter;
				NewColumnNumber = ColumnsCounter;
			EndIf;
			If Mid(StringByNumber, ColumnsCounter, 1) = ">" Then
				ThereIsOpeningTag = False;
			EndIf;
		EndDo;
	EndDo;
	
	Return ThereIsOpeningTag;
			
EndFunction

Function ThereIsClosingTag(Formula, LineNumber, ColumnNumber, NewLineNumber = Undefined, NewColumnNumber = Undefined)
	
	For NewLineNumber = LineNumber To StrLineCount(Formula) Do
		StringByNumber = StrGetLine(Formula, NewLineNumber);
		If NewLineNumber = LineNumber Then
			Begin = ColumnNumber;
		Else
			Begin = 1;
		EndIf;
		For NewColumnNumber = Begin To StrLen(StringByNumber) Do
			String = StringByNumber;
			If Mid(String, NewColumnNumber, 1) = "<" Then
				Return False; // looking for the first closing tag
			EndIf;
			If Mid(String, NewColumnNumber, 1) = ">" Then
				Return True;
			EndIf;
		EndDo;
	EndDo;
	
	Return False;
			
EndFunction

#EndRegion

