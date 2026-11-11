
#Region Variables

&AtClient
Var CacheOfElementTypes;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	SetConditionalAppearance();
	ReportingSet = Parameters.ReportingSet;
	
	TableOfCombinations = FinancialReportingCached.AcceptableCombinationsOfReportElements();
	CacheOfValidCombinations = CreateCacheBasedOnCombinationTable(TableOfCombinations);
	
	TableOfCombinations = FinancialReportingCached.InvalidCombinationsOfReportElements();
	CacheOfInvalidCombinations = CreateCacheBasedOnCombinationTable(TableOfCombinations);
	
	If Object.Ref.IsEmpty() And Not ValueIsFilled(Parameters.CopyingValue) Then
		Object.RowCodeHeader = NStr("vi = 'Mã';
									|ru = 'Код';
									|en = 'Code'; fa = 'کد';
									|it = 'Codice';
									|pl = 'Kod';
									|tr = 'Kod'");
		Object.CommentHeader = NStr("vi = 'Ghi chú';
									|ru = 'Примечание';
									|en = 'Note'; fa = 'یادداشت';
									|it = 'Nota';
									|pl = 'Adnotacja';
									|tr = 'Not'");
		Object.ReportLanguage =  CurrentLanguage().LanguageCode;
	EndIf;
	
	UpdateTreeOfNewElements();
	UpdateTheReportTreeServer(Parameters.CopyingValue);
	RefreshFormTitle();
	
	If ValueIsFilled(Parameters.CurrentReportItem) Then
		ReportRow = FinancialReportingServer.SubordinateItem(
			ReportItems, "ReportItem", Parameters.CurrentReportItem);
		If ReportRow <> Undefined Then
			Items.ReportItems.CurrentRow = ReportRow.GetID();
		EndIf;
	EndIf;
	
	AdditionalParameters = New Structure;
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ExpandReportTree();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ReportTree = FormAttributeToValue("ReportItems");
	Filter = New Structure("ItemKind", Enums.FinancialReportItemKinds.Rows);
	TableRows_ = ReportTree.Rows.FindRows(Filter, True);
	For Each String In TableRows_ Do
		If String.Rows.Count() = 0 Then
			ErrorText = NStr("vi = 'Không có dòng nào được chỉ định cho bảng""%1""
			|Thêm dòng hoặc xóa bảng.';
			|ru = 'Для таблицы ""%1"" не указаны строки
			|Добавьте строку или удалите таблицу.';
			|en = 'Rows are not specified for the ""%1"" table.
			|Add a row or delete the table.'; fa = 'Rows are not specified for the ""%1"" table.
			|Add a row or delete the table.';
			|it = 'Non sono indicate le righe per la tabella ""%1""
			|Aggiungere la riga oppure eliminare la tabella.';
			|pl = 'Dla tabeli ""%1"" nie podano wiersza
			|Dodaj wiersz lub usuń tabelę.';
			|tr = '""%1"" tablosu için satırlar belirtilmemiş
			|Satır ekleyin veya tabloyu silin.'");
			ErrorText = StrReplace(ErrorText, "%1", String.Parent.NameForPrinting);
			Common.MessageToUser(ErrorText, Object.Ref);
			Cancel = True;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	TreeReportElements = FormAttributeToValue("ReportItems");
	Catalogs.FinancialReportItems.WriteStructureOfReportView(CurrentObject.Ref, TreeReportElements, CurrentObject.DeletionMark);
	
	CurrentRow = Items.ReportItems.CurrentRow;
	TreeRow = ReportItems.FindByID(CurrentRow);
	CurrentReportItem = TreeRow.ReportItem;
	
	UpdateTheReportTreeServer();
	
	TreeRow = FinancialReportingServer.SubordinateItem(
		ReportItems,
		"ReportItem",
		CurrentReportItem);
	
	If TreeRow <> Undefined Then
		Items.ReportItems.CurrentRow = TreeRow.GetID();
	EndIf;
	
	RefreshFormTitle();
	
	CheckingForLooping();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	Items.ReportItems.Expand(ReportItems.GetItems()[0].GetID(), True);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Added\changed a non-monetary indicator
	If EventName = "Write_NonMonetaryItem" Then
		
		UpdateTreeOfNewElements();
		TreeRow = FinancialReportingClient.SubordinateElementOfFormElement(
			NewItemTree,
			"ReportingKindItem",
			Source);
		
		If TreeRow <> Undefined Then
			Items.NewItemTree.CurrentRow = TreeRow.GetID();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	If ChoiceSource.FormName = "Catalog.FinancialReportTypes.Form.ChoiceForm" Then
		If ValueIsFilled(ValueSelected) Then
			FilterByReportKind = ValueSelected;
			UpdateTreeOfSavedItems();
			InternationalReportingClient.ExpandTreeOfSavedItems(ThisForm, SavedItemsTree);
		EndIf;
	ElsIf ChoiceSource.FormName = "Catalog.FinancialReportTypes.Form.AccuracySettings" Then
		SetAccuracyOnServer(ValueSelected);
	ElsIf ChoiceSource.FormName = "Catalog.FinancialReportTypes.Form.SelectChartsOfAccounts" Then
		Object.ChartsOfAccounts.Clear();
		For Each ChartOfAccounts In ValueSelected Do
			NewRow = Object.ChartsOfAccounts.Add();
			NewRow.ChartOfAccounts = ChartOfAccounts;
		EndDo;
		UpdateTreeOfNewElements();
		UpdateTreeOfSavedItems();
		Modified = True;
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure QuickSearchOfNewOnChange(Item)
	
	UpdateTreeOfNewElements();
	
EndProcedure

&AtClient
Procedure QuickSearchForSavedFilesOnChange(Item)
	
	UpdateTreeOfSavedItems();
	If ValueIsFilled(FilterByReportKind) Then
		InternationalReportingClient.ExpandTreeOfSavedItems(ThisForm, SavedItemsTree);
	EndIf;
	
EndProcedure

&AtClient
Procedure ViewOfTheReportWhenChanged(Item)
	
	UpdateTreeOfSavedItems();
	InternationalReportingClient.ExpandTreeOfSavedItems(ThisForm, SavedItemsTree);
	
EndProcedure

&AtClient
Procedure ReportTypeStartOfSelection(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = New Structure();
	FormParameters.Insert("ExcludeReports", Object.Ref);
	
	AccountPlansSelection = New Array;
	For Each TableRow In Object.ChartsOfAccounts Do
		AccountPlansSelection.Add(TableRow.ChartOfAccounts);
	EndDo;
	FormParameters.Insert("ChartsOfAccounts", AccountPlansSelection);
	
	OpenForm("Catalog.FinancialReportTypes.ChoiceForm", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure DecorationTheInscriptionOnTheReportConfigurationClick(Item)
	
	ReportParameters =
			New Structure("ReportLanguage, DisplayRowCode, DisplayNoteInReport, RowCodeHeader, CommentHeader");
	FillPropertyValues(ReportParameters, Object);
	ReportParameters.Insert("ReadOnly", ReadOnly);
	
	Notification = New CallbackDescription("LoadReportSettings", ThisObject);
	OpenForm("Catalog.FinancialReportTypes.Form.ReportSettingsForm", ReportParameters, ThisForm,,,,Notification);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersNewItemTree

&AtClient
Procedure NewItemTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	TreeLineSender = "NewItemTree";
	RowsArray = New Array;
	RowsArray.Add(RowSelected);
	RowID = Items.ReportItems.CurrentRow;
	AddToReportStructure(RowsArray, RowID);
	
EndProcedure

&AtClient
Procedure NewItemTreeDragStart(Item, DragParameters, Perform)
	
	TreeLineSender = "NewItemTree";
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSavedItemsTree

&AtClient
Procedure SavedItemsTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	TreeLineSender = "SavedItemsTree";
	RowID = Items.ReportItems.CurrentRow;
	AddToReportStructure(RowSelected, RowID);
	
EndProcedure

&AtClient
Procedure SavedItemsTreeDragStart(Item, DragParameters, Perform)
	
	TreeLineSender = "SavedItemsTree";
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReportItems

&AtClient
Procedure ReportItemsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	EditReportElement();
	
EndProcedure

&AtClient
Procedure ReportItemsDragStart(Item, DragParameters, Perform)
	
	TreeLineSender = "ReportItems";
	
EndProcedure

&AtClient
Procedure ReportItemsDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	CanBeAddedToStructure = True;
	
	If TypeOf(DragParameters.Value) = Type("Array") Then
		For Each ElementViewString In DragParameters.Value Do
			CanBeAddedToStructure = DraggingIsAllowed(ElementViewString, String);
			If Not CanBeAddedToStructure Then
				Break;
			EndIf;
		EndDo;
	Else
		CanBeAddedToStructure = DraggingIsAllowed(DragParameters.Value, String);
	EndIf;
	
	If CanBeAddedToStructure Then
		If DragParameters.Action <> DragAction.Move
			And DragParameters.Action <> DragAction.Copy Then
			DragParameters.Action = DragAction.Move;
		EndIf;
	Else
		DragParameters.Action = DragAction.Cancel;
	EndIf;
	
EndProcedure

&AtClient
Procedure ReportItemsDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	RowsArray = DragParameters.Value;
	If TypeOf(DragParameters.Value) <> Type("Array") Then
		RowsArray = New Array;
		RowsArray.Add(DragParameters.Value);
	EndIf;
	
	If TreeLineSender = Item.Name Then
		For Each PortableString In RowsArray Do
			MoveLine(ReportItems, PortableString, String, DragParameters.Action = DragAction.Copy);
		EndDo;
	Else
		If String = Undefined Then
			TreeRoot = FinancialReportingClient.RootElementOfFormElement(ReportItems);
			String = TreeRoot.GetID();
		EndIf;
		AddToReportStructure(RowsArray, String);
	EndIf;
	Modified = True;
	
EndProcedure

&AtClient
Procedure ReportItemsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If (Item.CurrentData.ItemKind = ItemKind("EmptyRef")
			Or Item.CurrentData.ItemKind = ItemKind("Columns")
			Or Item.CurrentData.ItemKind = ItemKind("Rows")
			Or Item.CurrentData.ItemKind = ItemKind("TotalByGroup"))
			And Copy Then
		Cancel = True;
	EndIf;
			
	If Copy And Not Cancel Then
		Cancel = True;
		CopyRow(ReportItems, Item.CurrentData);
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ReportItemsBeforeDeleteRow(Item, Cancel)
	
	CurrentRow = Items.ReportItems.CurrentData;
	ItemKind = CurrentRow.ItemKind;
	
	If (ItemKind = ItemKind("EmptyRef") 
			And CurrentRow.GetParent() = Undefined)
		Or ItemKind = ItemKind("Columns")
		Or ItemKind = ItemKind("Rows")
		Or ItemKind = ItemKind("CellsSettings") Then
		
		Cancel = True;
		Return;
		
	EndIf;
	
	// For existing elements, check the links to them in other reports
	If ValueIsFilled(CurrentRow.ReportItem)
		And Not CurrentRow.ThisIsReference Then
		
		If InternationalReportingServerCall.ThereAreRefs(CurrentRow.ReportItem) Then
			
			FormParameters = New Structure("ReportItem", CurrentRow.ReportItem);
			FormParameters.Insert("DeletionMode", True);
			If ItemKind = ItemKind("TableIndicatorsInRows")
				Or ItemKind = ItemKind("TableIndicatorsInColumns")
				Or ItemKind = ItemKind("ComplexTable")
				Or ItemKind = ItemKind("Group")
				Or ItemKind = ItemKind("TotalByGroup") Then
				FormParameters.Insert("DeleteAll", True);
			EndIf;
			
			OpenForm("Catalog.FinancialReportTypes.Form.RefListForm",
				FormParameters,
				ThisForm);
			Cancel = True;
			Return;
			
		EndIf;// there are links to the item being deleted in other reports
	EndIf;// there is an element link
	
	Table = FinancialReportingClient.RootElementOfFormElement(CurrentRow, ItemKind("ComplexTable"));
	If Table <> Undefined Then
		CellsSettings = FinancialReportingClient.SubordinateElementOfFormElement(Table,
			"ItemKind", ItemKind("CellsSettings"));
		ClearDeletedReportElements(CellsSettings.GetID(), CurrentRow.GetID());
	EndIf;
	
	PutToTempStorage(Undefined, CurrentRow.AddressOfItemStructure);
	CurrentRow.AddressOfItemStructure = "";
	
EndProcedure

&AtClient
Procedure ReportItemsBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	If Item.CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentKind = Item.CurrentData.ItemKind;
	If Not ValueIsFilled(CurrentKind)
		Or CurrentKind = ItemKind("Columns")
		Or CurrentKind = ItemKind("Rows") Then
		Return;
	EndIf;
	
	EditReportElement();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateTheNewTree(Command)
	
	UpdateTreeOfNewElements();
	
EndProcedure

&AtClient
Procedure UpdateTheReportTree(Command)
	
	UpdateTheReportTreeServer();
	ExpandReportTree();
	
EndProcedure

&AtClient
Procedure FindNewItem(Command)
	
	UpdateTreeOfNewElements();
	
EndProcedure

&AtClient
Procedure FindItem(Command)

	UpdateTreeOfSavedItems();
	If ValueIsFilled(FilterByReportKind) Then
		InternationalReportingClient.ExpandTreeOfSavedItems(ThisForm, SavedItemsTree);
	EndIf;

EndProcedure

&AtClient
Procedure UnlinkItem(Command)

	If Items.ReportItems.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If Not Items.ReportItems.CurrentData.ThisIsReference Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Bỏ liên kết?';
					|ru = 'Разорвать связь?';
					|en = 'Unlink?'; fa = 'Unlink?';
					|it = 'Interrompere la connessione?';
					|pl = 'Usunąć łącze?';
					|tr = 'Bağlantı kaldırılsın mı?'");
	HandlerParameters = New Structure("CurrentRow", Items.ReportItems.CurrentRow);
	CurrentData = Items.ReportItems.CurrentData;
	If CurrentData.ItemKind = ItemKind("TotalByGroup") Then
		QueryText = NStr("vi = 'Xóa bỏ phần tử?';
						|ru = 'Удалить элемент?';
						|en = 'Remove the item?'; fa = 'Remove the item?';
						|it = 'Cancellare elemento?';
						|pl = 'Usunąć element?';
						|tr = 'Öğe silinsin mi?'");
		HandlerParameters.Insert("Delete");
	EndIf;
	
	CallbackDescription = New CallbackDescription("HandlerOfLinkBreakIssue", ThisObject, HandlerParameters);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);

EndProcedure

&AtClient
Procedure MoveUp(Command)
	
	MoveTreeElement(ReportItems);
	
EndProcedure

&AtClient
Procedure MoveDown(Command)
	
	MoveTreeElement(ReportItems, False);
	
EndProcedure

&AtClient
Procedure OpenIndicatorForm(Command)
	
	CurrentData = Items.NewItemTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.IsFolder Then
		Return;
	EndIf;
	If CurrentData.ItemKind = ItemKind("NonMonetaryItem") Then
		FormParameters = New Structure("Key",CurrentData.ReportingKindItem);
		OpenForm("Catalog.NonMonetaryItems.Form.ItemForm",FormParameters,ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
 
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
 
EndProcedure

&AtClient
Procedure SetAccuracy(Command)
	
	OpenForm("Catalog.FinancialReportTypes.Form.AccuracySettings",,ThisObject);
	
EndProcedure

&AtClient
Procedure ToSelectChartsOfAccounts(Command)
	
	FormParameters = AccountPlanSelectionFormParameters();
	OpenForm("Catalog.FinancialReportTypes.Form.SelectChartsOfAccounts", FormParameters, ThisObject);
	
EndProcedure

#EndRegion

#Region Private

#Region CheckingForAddingNewItemToReport

&AtClient
Function DraggingIsAllowed(TreeRow, ParentReceiver)
	
	ViewOfDraggableElement = Undefined;
	If TreeLineSender = "ReportItems" Then //dragging inside the tree
		RowData = ReportItems.FindByID(TreeRow);
		ViewOfDraggableElement = RowData.ItemKind;
		ThisIsReference = RowData.ThisIsReference;
		ThisIsAnExtraDimension = RowData.ThisIsAnExtraDimension;
	Else
		ViewOfDraggableElement = TreeRow.ItemKind;
		ThisIsReference = TreeRow.ThisIsReference;
		ThisIsAnExtraDimension = TreeRow.ThisIsAnExtraDimension;
	EndIf;
	
	If Not ValueIsFilled(ViewOfDraggableElement)
		Or Not CanBeAddedToReportStructure(ViewOfDraggableElement, ParentReceiver, ThisIsReference, ThisIsAnExtraDimension) Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

&AtClient
Function CanBeAddedToReportStructure(Val ElementTypeWhatToAdd, ParentIDWhereToAdd, ThisIsReference, ThisIsAnExtraDimension)
	
	If ElementTypeWhatToAdd = ItemKind("TotalByGroup")
		And ThisIsReference Then
		ElementTypeWhatToAdd = ItemKind("MonetaryIndicator");
	EndIf;
	
	TheStructureOfTheSearch = New Array;
	TheStructureOfTheSearch.Add(ElementTypeWhatToAdd); // Item
	
	If ParentIDWhereToAdd = Undefined Then
		TheStructureOfTheSearch.Add(ItemKind("EmptyRef")); // Parent
	Else
		ParentLevelRow = ReportItems.FindByID(ParentIDWhereToAdd);
		TheStructureOfTheSearch.Add(ParentLevelRow.ItemKind); // Parent
		
		FoundRows = CacheOfInvalidCombinations.Get(ElementTypeWhatToAdd);
		If FoundRows <> Undefined Then
			For Each InvalidCombination In FoundRows Do
				Item = FinancialReportingClient.RootElementOfFormElement(ParentLevelRow, InvalidCombination.Key);
				If Item <> Undefined Then
					Return False;
				EndIf;
			EndDo;
		EndIf;
		
		Item1 = Undefined;
		
		If ParentLevelRow.ItemKind <> ItemKind("Columns")
			And ParentLevelRow.ItemKind <> ItemKind("Rows") Then
			
			Item1 = GetParentByView(ParentLevelRow, ItemKind("Rows"));
			If Item1 = Undefined Then
				Item1 = GetParentByView(ParentLevelRow, ItemKind("Columns"));
			EndIf;
			If Item1 <> Undefined Then
				Item1 = Item1.ItemKind;
			EndIf;
			
		EndIf;
		
		If Not ValueIsFilled(Item1) Then
			Item1 = ItemKind("EmptyRef");
		EndIf;
		
		TheStructureOfTheSearch.Add(Item1); // ColumnRows
			
		Item2 = GetParentByView(ParentLevelRow, ItemKind("TableIndicatorsInRows"));
		If Item2 = Undefined Then
			Item2 = GetParentByView(ParentLevelRow, ItemKind("TableIndicatorsInColumns"));
		EndIf;
		If Item2 = Undefined Then
			Item2 = GetParentByView(ParentLevelRow, ItemKind("ComplexTable"));
		EndIf;
		If Item2 <> Undefined Then
			Item2 = Item2.ItemKind;
		EndIf;
		If Not ValueIsFilled(Item2) Then
			Item2 = ItemKind("EmptyRef");
		EndIf;
		
		AddingToLines =  (Item1 = ItemKind("Rows") Or ParentLevelRow.ItemKind = ItemKind("Rows"));
		If  ElementTypeWhatToAdd = ItemKind("Dimension")
				And Not ThisIsAnExtraDimension
				And (Item2 =  ItemKind("TableIndicatorsInRows")  And  AddingToLines
						Or (Item2 =  ItemKind("TableIndicatorsInColumns")  And  Not AddingToLines)) Then
			Return False;
		EndIf;
		
		TheStructureOfTheSearch.Add(Item2); // TableType
		
	EndIf;
	
	SearchPoint = CacheOfValidCombinations;
	For Each SearchItem In TheStructureOfTheSearch Do
		
		FoundRows = SearchPoint.Get(SearchItem);
		If FoundRows = True Then
			Return True;
		ElsIf FoundRows = Undefined Then
			Return False;
		ElsIf FoundRows.Count() Then
			SearchPoint = FoundRows;
		Else
			Return False;
		EndIf;
		
	EndDo;
	
	Return True;
	
EndFunction

&AtClient
Function GetParentByView(ElementString, ItemKind)
	
	If ElementString.ItemKind = ItemKind Then
		Return ElementString;
	EndIf;
	
	Return FinancialReportingClient.RootElementOfFormElement(ElementString, ItemKind);
	
EndFunction

#EndRegion

#Region AddingNewItemToReport

&AtClient
Procedure AddToReportStructure(NewItems, ParentID_)
	
	// Let's define the receiver branch of the report structure
	If ParentID_ = Undefined Then
		Parent = FinancialReportingClient.RootElementOfFormElement(ReportItems);
		ParentID_ = Parent.GetID();
	Else
		Parent = ReportItems.FindByID(ParentID_);
	EndIf;
	
	For Each NewReportElement In NewItems Do
		
		ElementData = NewReportElement;
		If TypeOf(NewReportElement) = Type("Number") Then
			ElementData = ThisForm[TreeLineSender].FindByID(NewReportElement);
		EndIf;
		
		If Parent.ItemKind = ItemKind("MonetaryIndicator") 
			And ElementData.ItemKind = ItemKind("Dimension")
			And TypeOf(ElementData.ReportingKindItem) <> Type("ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes") Then
			Continue;
		EndIf; 

		If ElementData.IsFolder Then
			Continue;
		EndIf;
		
		ItemKind = ElementData.ItemKind;
		If Not CanBeAddedToReportStructure(ItemKind, ParentID_, ElementData.ThisIsReference, ElementData.ThisIsAnExtraDimension) Then
			Continue;
		EndIf;
		
		Modified = True;
		
		// We create tables after selecting the type
		If ItemKind = ItemKind("ComplexTable") And Not ElementData.ThisIsReference Then
			
			AdditionalParameters = New Structure("Parent, ElementData", Parent, ElementData);
			Notification = New CallbackDescription("WhenSelectingTableType", ThisForm, AdditionalParameters);
			OpenForm("Catalog.FinancialReportItems.Form.TableTypeChoiceForm",,
																ThisForm,
																,,,
																Notification,
																FormWindowOpeningMode.LockOwnerWindow);
			Continue;
		EndIf;
		
		RowsDestination = Parent.GetItems();
		IndexOf = FinancialReportingClientServer.IndexOfNewRow(RowsDestination);//if there is a total for the group at the end of the group, then a new line should appear in front of it
		NewRow = RowsDestination.Insert(IndexOf);
		
		FillPropertyValues(NewRow, ElementData);
		NewRow.CustomPicture = NewRow.CustomPicture + ElementData.ThisIsReference;
		
		FillInDataOfNewElement(NewRow, ElementData);
		FillInDataOfSavedItem(NewRow, ElementData);
		
	EndDo;
	
	If NewRow <> Undefined Then
		If NewRow.ItemKind = ItemKind("DerivedItem") And Not NewRow.ThisIsReference Then
			Items.ReportItems.CurrentRow = NewRow.GetID();
			EditReportElement();
		Else
			Items.ReportItems.CurrentRow = ParentID_;
			Items.ReportItems.Expand(ParentID_);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure WhenSelectingTableType(TableType, AddlParameters) Export
	
	If TableType = Undefined Then
		Return;
	EndIf;
	
	Parent = AddlParameters.Parent;
	ElementData = AddlParameters.ElementData; // See FinancialReportingServerCall.ReportElementData 
	
	RowsDestination = Parent.GetItems(); // FormDataTreeItemCollection - 
	NewRow = RowsDestination.Add();
	
	FillPropertyValues(NewRow, ElementData);
	NewRow.NameForPrinting = ElementData.Description;
	
	If TableType = 0 Then
		NewRow.ItemKind = ItemKind("TableIndicatorsInRows");
	ElsIf TableType = 1 Then
		NewRow.ItemKind = ItemKind("TableIndicatorsInColumns");
	ElsIf TableType = 2 Then
		NewRow.ItemKind = ItemKind("ComplexTable");
	EndIf;
	
	SubordinateRows  = NewRow.GetItems();
	
	ItemKind = ItemKind("Columns");
	NewTableElement = SubordinateRows.Add();
	NewTableElement.ItemKind = ItemKind;
	NewTableElement.NameForPrinting = String(ItemKind);
	Postfix = ?(TableType = 1, "Return", "");
	NewTableElement.CustomPicture = FinancialReportingServerCall.CustomPicture(ItemKind, Postfix);
	
	ItemKind = ItemKind("Rows");
	NewTableElement = SubordinateRows.Add();
	NewTableElement.ItemKind = ItemKind;
	NewTableElement.NameForPrinting = String(ItemKind);
	Postfix = ?(TableType = 0, "Return", "");
	NewTableElement.CustomPicture = FinancialReportingServerCall.CustomPicture(ItemKind, Postfix);
	
	If TableType = 2 Then
		ItemKind = ItemKind("CellsSettings");
		NewTableElement = SubordinateRows.Add();
		NewTableElement.ItemKind = ItemKind;
		NewTableElement.NameForPrinting = String(ItemKind);
		NewTableElement.CustomPicture = FinancialReportingServerCall.CustomPicture(ItemKind);
	EndIf;
	
	Items.ReportItems.Expand(Parent.GetID());
	Items.ReportItems.Expand(NewRow.GetID(), True);
	Items.ReportItems.CurrentRow = NewRow.GetID();
	
EndProcedure

&AtClient
Procedure FillInDataOfNewElement(NewRow, ElementData)
	
	If ElementData.ThisIsReference Then
		Return;
	EndIf;
	
	ItemKind = ElementData.ItemKind;
	If ItemKind = ItemKind("RowColumn") Then  
			
		ElSpeakers = ItemKind("Columns");
		Parent = FinancialReportingClient.RootElementOfFormElement(NewRow, ElSpeakers);
		If Not Parent = Undefined Then
			NewRow.NameForPrinting = "Column";
		Else
			NewRow.NameForPrinting = "String";
		EndIf;
		
	ElsIf ItemKind = ItemKind("MonetaryIndicator") Then
		
		NewRow.GLAccount_ = ElementData.ReportingKindItem;
		NewRow.AccountIndicatorDimension = ElementData.ReportingKindItem;
		NewRow.TotalType = PredefinedValue("Enum.TypesOfTotals.Balance_Dr");
		
	ElsIf ItemKind = ItemKind("NonMonetaryItem")
		Or ItemKind = ItemKind("Dimension") Then
		
		NewRow.AccountIndicatorDimension = ElementData.ReportingKindItem;
		If TypeOf(ElementData.ReportingKindItem) = Type("String") Then
			NewRow.AccountIndicatorDimension = StrReplace(Title(ElementData.ReportingKindItem)," ","");
		ElsIf TypeOf(ElementData.ReportingKindItem) = Type("ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes") Then
			NewRow.ThisIsAnExtraDimension = True;
		EndIf;
		NewRow.Sort = "ASC";
		NewRow.PeriodPresentation = PredefinedValue("Enum.PeriodPresentation.EndingDate");
		
	ElsIf ItemKind = ItemKind("Group") Then
		NewRow.DisplayItemTitle = True;
		
	ElsIf ItemKind = ItemKind("TotalByGroup") Then
		NewRow.DisplayItemTitle = True;
		CurrentGroup = GetParentByView(NewRow, ItemKind("Group"));
		If CurrentGroup = Undefined Then
			CurrentGroup = GetParentByView(NewRow, ItemKind("Dimension"));
		EndIf;
		If CurrentGroup <> Undefined Then
			NameForPrinting = NStr("vi = 'Tổng số';
									|ru = 'Итого';
									|en = 'Total'; fa = 'جمع کل';
									|it = 'Totale';
									|pl = 'Łącznie';
									|tr = 'Toplam'") + " " + Lower(CurrentGroup.NameForPrinting);
			NewRow.NameForPrinting = NameForPrinting;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInDataOfSavedItem(NewRow, ElementData)
	
	If Not ElementData.ThisIsReference Then
		Return;
	EndIf;
	
	ItemKind = ElementData.ItemKind;
	If ItemKind = ItemKind("MonetaryIndicator") Then
		NewRow.AccountIndicatorDimension = ElementData.GLAccount_;
		
	ElsIf ItemKind = ItemKind("NonMonetaryItem") Then
		NewRow.AccountIndicatorDimension = ElementData.NonMonetaryItem;
		
	ElsIf ItemKind = ItemKind("Group")
		Or ItemKind = ItemKind("TotalByGroup")
		Or ItemKind = ItemKind("TableIndicatorsInRows")
		Or ItemKind = ItemKind("TableIndicatorsInColumns")
		Or ItemKind = ItemKind("ComplexTable") Then
		NewRow.DisplayItemTitle = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EditingReportElement

&AtClient
Procedure EditReportElement()
	
	CurrentRow = Items.ReportItems.CurrentData;
	
	If CurrentRow.ItemKind = ItemKind("Columns")
		Or CurrentRow.ItemKind = ItemKind("Rows")
		Or CurrentRow.ItemKind = ItemKind("EmptyRef") Then
		Return;
	EndIf;
	
	TheseAreLines = FinancialReportingClient.RootElementOfFormElement(CurrentRow,ItemKind("Rows")) <> Undefined;
	ThisIsComplexTable = FinancialReportingClient.RootElementOfFormElement(CurrentRow,ItemKind("ComplexTable")) <> Undefined;
	If IsBlankString(CurrentRow.AddressOfItemStructure) Then
		CurrentRow.AddressOfItemStructure = InternationalReportingClientServer.PlaceItemInStorage(CurrentRow, UUID);
	EndIf;
	If CurrentRow.ItemKind = ItemKind("CellsSettings") Then
		FillInStructureAddressBeforeSettingUpCells(CurrentRow.GetID(), CurrentRow.AddressOfItemStructure);
	EndIf;
	
	ReportAccountPlans = New Array;
	For Each TableRow In Object.ChartsOfAccounts Do
		ReportAccountPlans.Add(TableRow.ChartOfAccounts);
	EndDo;
	
	FormParameters = New Structure();
	FormParameters.Insert("LineIDOfReportItem",CurrentRow.GetID());
	FormParameters.Insert("Key",                           CurrentRow.ReportItem);
	FormParameters.Insert("ItemKind",                    CurrentRow.ItemKind);
	FormParameters.Insert("ItemAddressInStorage",        CurrentRow.AddressOfItemStructure);
	FormParameters.Insert("MainStorageID", ThisForm.UUID);
	FormParameters.Insert("ReportItems",                 ThisForm.ReportItems);
	FormParameters.Insert("AdditionalFormMode",       DefineAdditionalParameters(CurrentRow));
	FormParameters.Insert("ShowRowCodeNote",    True);
	FormParameters.Insert("TheseAreLines",                      TheseAreLines);
	FormParameters.Insert("ChartsOfAccounts",                    ReportAccountPlans);
	
	If CurrentRow.ItemKind = ItemKind("Dimension") And ThisIsComplexTable Then  
		FormParameters.Insert("DoNotOutputAccuracy", True);
	EndIf;
	
	PostHandler = New CallbackDescription("UpdateRowInReportViewAfterChange", ThisForm, FormParameters);
	
	OpenForm("Catalog.FinancialReportItems.ObjectForm", 
				FormParameters, ThisForm, , , , PostHandler, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure HowToFillInAddressOfElementStructureToConfigureCells(Rows, AddressOfItemStructure, CachedAddressInStorage)
	
	For Each Item In Rows.GetItems() Do
		
		If Not Item.ItemKind = ItemKindServer("Columns")
			And Not Item.ItemKind = ItemKindServer("Rows") Then
			
			If Not ValueIsFilled(Item.AddressOfItemStructure) Then
				Item.AddressOfItemStructure = 
						InternationalReportingClientServer.PlaceItemInStorage(Item, UUID);
			EndIf;
			
			SettingsData = GetFromTempStorage(AddressOfItemStructure);// See FinancialReportingServerCall.ReportElementData
		
			FoundRows = SettingsData.TableItems.FindRows(New Structure("String", Item.ReportItem)); // See BudgetReportingCacheCalculationServer.NewTableOfElements
			For Each FoundRow In FoundRows Do
				FoundRow.String = Item.AddressOfItemStructure;
			EndDo;
			FoundRows = SettingsData.TableItems.FindRows(New Structure("Column", Item.ReportItem));
			For Each FoundRow In FoundRows Do
				FoundRow.Column = Item.AddressOfItemStructure;
			EndDo;
			
			PutToTempStorage(SettingsData, AddressOfItemStructure);
			CachedAddressInStorage.Insert(Item.ReportItem, Item.AddressOfItemStructure);
			
		EndIf;
		
		If Not Item.ItemKind = ItemKindServer("CellsSettings") Then
			HowToFillInAddressOfElementStructureToConfigureCells(Item, AddressOfItemStructure, CachedAddressInStorage);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInStructureAddressBeforeSettingUpCells(Id, AddressOfItemStructure)
	
	String = ReportItems.FindByID(Id);
	ComplexTable = ItemKindServer("ComplexTable");
	Table = FinancialReportingServer.RootItem(String, ComplexTable);
	
	CachedAddressInStorage = New Map;
	HowToFillInAddressOfElementStructureToConfigureCells(Table, AddressOfItemStructure, CachedAddressInStorage);
	
	SettingsData = GetFromTempStorage(AddressOfItemStructure); // See FinancialReportingServerCall.ReportElementData
	For Each RowColumn In SettingsData.TableItems Do
		
		If TypeOf(RowColumn.Item) = Type("CatalogRef.FinancialReportItems") Then
			RowColumn.Item = FinancialReportingServerCall.PlaceItemInStorage(RowColumn.Item, UUID);
		EndIf;
		If TypeOf(RowColumn.String) = Type("CatalogRef.FinancialReportItems") Then
			RowColumn.String = CachedAddressInStorage[RowColumn.String];
		EndIf;
		If TypeOf(RowColumn.Column) = Type("CatalogRef.FinancialReportItems") Then
			RowColumn.Column = CachedAddressInStorage[RowColumn.Column];
		EndIf;
		
		ElementData = GetFromTempStorage(RowColumn.Item);
		For Each Operand In ElementData.FormulaOperands Do
			If Not ValueIsFilled(Operand.AddressOfItemStructure) Then
				Operand.AddressOfItemStructure = FinancialReportingServerCall.PlaceItemInStorage(Operand.Operand, UUID);
			EndIf;
			OperandData = GetFromTempStorage(Operand.AddressOfItemStructure);
			If OperandData.ItemKind = ItemKindServer("TableCell") Then
				ItemRef = FinancialReportingServerCall.ValueOfAdditionalProps(
																				OperandData, 
																				"CellRow");
				If TypeOf(ItemRef) = Type("CatalogRef.FinancialReportItems") Then
					FinancialReportingServerCall.SetValueOfAdditionalProps(
																	OperandData,
																	"CellRow",
																	CachedAddressInStorage[ItemRef]);
				EndIf;
				ItemRef = FinancialReportingServerCall.ValueOfAdditionalProps(
																				OperandData, 
																				"CellColumn");
				If TypeOf(ItemRef) = Type("CatalogRef.FinancialReportItems") Then
					FinancialReportingServerCall.SetValueOfAdditionalProps(
																	OperandData,
																	"CellColumn",
																	CachedAddressInStorage[ItemRef]);
				EndIf;
				PutToTempStorage(OperandData, Operand.AddressOfItemStructure);
			EndIf;
		EndDo;
		PutToTempStorage(ElementData, RowColumn.Item);
		
	EndDo;
	
EndProcedure

&AtClient
Function DefineAdditionalParameters(CurrentRow)
	
	NameOfAdditionalModes = "Enum.AdditionalModesOfReportItems.";
	If CurrentRow.ThisIsReference Then
		Return PredefinedValue(NameOfAdditionalModes + "LinkedItem1");
	EndIf;
	If CurrentRow.ItemKind = ItemKind("CellsSettings") 
		Or CurrentRow.ItemKind = ItemKind("DerivedItem")
		Or CurrentRow.ItemKind = ItemKind("Dimension") Then
		Return PredefinedValue(NameOfAdditionalModes + "ReportKind");
	ElsIf CurrentRow.ItemKind = ItemKind("Group")
		Or CurrentRow.ItemKind = ItemKind("TotalByGroup")
		Or CurrentRow.ItemKind = ItemKind("RowColumn") Then
		Return PredefinedValue(NameOfAdditionalModes + "ShowRowCodeNote");
	EndIf;
	
EndFunction

&AtClient
Procedure UpdateRowInReportViewAfterChange(Result, AdditionalParameters) Export
	
	FillingData = InternationalReportingClientServer.NewRowFillingData();
	FillingData.Source = Result;
	FillingData.DestinationRow = AdditionalParameters.LineIDOfReportItem;
	FillingData.ItemAddressInStorage = AdditionalParameters.ItemAddressInStorage;
	FillingData.Field = ReportItems;
	
	FinancialReportingClientServer.FillInTreeLine(FillingData);
	
	If Result <> Undefined Then
		Modified = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region HandlersOfAssociatedViewelement

// LongDesc
// 
// Parameters:
// 	QuestionResult - DialogReturnCode -
// 	AdditionalParameters - Structure of KeyAndValue - 
//
&AtClient
Procedure HandlerOfLinkBreakIssue(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.Yes Then
		
		Modified = True;
		If AdditionalParameters.Property("Delete") Then
			ReportRow = ReportItems.FindByID(AdditionalParameters.CurrentRow);
			CurSetOfLines = ReportRow.GetParent().GetItems();
			CurSetOfLines.Delete(ReportRow);
		Else
			BreakConnectionServer(AdditionalParameters.CurrentRow);
		EndIf;
		
	EndIf;

EndProcedure

&AtClient
Procedure EditReferences(Command)

	If Items.ReportItems.CurrentRow = Undefined Then
		ShowMessageBox(Undefined, NStr("vi = 'Hãy chỉ ra phần tử báo cáo.';
										|ru = 'Укажите элемент отчета.';
										|en = 'Specify report item.'; fa = 'Specify report item.';
										|it = 'Specificare un elemento del report.';
										|pl = 'Wskaż element raportu.';
										|tr = 'Rapor öğesini belirtin.'"));
		Return;
	EndIf;
	
	CurrentData = Items.ReportItems.CurrentData;
	CurrentReportItem = CurrentData.ReportItem;
	
	If ValueIsFilled(CurrentReportItem) Then 
		
		ItemKind = CurrentData.ItemKind;
		
		If InternationalReportingServerCall.ThereAreRefs(CurrentReportItem) Then
			
			FormParameters = New Structure("ReportItem", CurrentReportItem);
			FormParameters.Insert("GLAccount_", CurrentData.GLAccount_);
			If ItemKind = ItemKind("TotalByGroup")
				Or ItemKind = ItemKind("TableIndicatorsInRows")
				Or ItemKind = ItemKind("TableIndicatorsInColumns")
				Or ItemKind = ItemKind("ComplexTable")
				Or ItemKind = ItemKind("Group") Then
				FormParameters.Insert("DeleteAll", True);
			EndIf;
			PostHandler = New CallbackDescription("UpdateLineAfterEditingLinks", ThisForm, FormParameters);
			OpenForm("Catalog.FinancialReportTypes.Form.RefListForm",FormParameters,ThisForm, , , , PostHandler);
			Return;
			
		EndIf;
	EndIf;
	
	ShowMessageBox(Undefined, NStr("vi = 'Không tìm thấy tham chiếu đến phần tử báo cáo.';
									|ru = 'Ссылки на элемент отчета не обнаружены.';
									|en = 'References to the report item are not found.'; fa = 'References to the report item are not found.';
									|it = 'Nessun collegamento all''elemento del report rilevato.';
									|pl = 'Nie wykryto odnośników do elementu raportu.';
									|tr = 'Rapor ögesine giden hiçbir bağlantı tespit edilemedi.'"));
	
EndProcedure

&AtClient
Procedure UpdateLineAfterEditingLinks(Result, AdditionalParameters) Export
	
	If Result = True Then
		Items.ReportItems.CurrentData.CustomPicture = Items.ReportItems.CurrentData.CustomPicture - 2;
	EndIf;
	
EndProcedure

#EndRegion

#Region ProcessingTreeStrings

&AtClient
Procedure MoveLine(Tree, IdWhat, ToID = Undefined, Copy = False)
	
	CurrentRow = Tree.FindByID(IdWhat);
	
	If ToID = Undefined Then
		NewParent = FinancialReportingClient.RootElementOfFormElement(Tree);
	Else
		NewParent = Tree.FindByID(ToID);
	EndIf;
	
	// Let's check that the element is not transferred to its subordinate element
	Parent = NewParent.GetParent();
	While Parent <> Undefined Do
		If Parent = CurrentRow Then
			Return;
		EndIf;
		Parent = Parent.GetParent();
	EndDo;
	
	If Not CanBeAddedToReportStructure(CurrentRow.ItemKind, ToID, CurrentRow.ThisIsReference, CurrentRow.ThisIsAnExtraDimension) Then
		Return;
	EndIf;
	
	If ThereAreInaccessibleItemsAfterMigration(CurrentRow, ToID) Then
		Text = NStr("vi = 'Chuyển bị hủy. Các phần tử không hợp lệ được tìm thấy trong các mục phụ của chuỗi được bọc';
					|ru = 'Перенос отменен. В подчиненных элементах переносимой строки обнаружены недопустимые элементы';
					|en = 'Transfer is canceled. Invalid items are found in the subordinate items of the line to be transferred'; fa = 'Transfer is canceled. Invalid items are found in the subordinate items of the line to be transferred';
					|it = 'Trasferimento annullato. Elementi non validi trovati negli elementi subordinati della riga da trasferire';
					|pl = 'Przeniesienie zostało anulowane. W elementach podporządkowanych przenoszonego wiersza wykryto niedostępne elementy';
					|tr = 'Erteleme iptal edildi. Satırların taşınan alt öğelerinde izin verilemeyecek öğeler tespit edildi'");
		ShowMessageBox(, Text, 60);
		Return;
	EndIf;
	
	RowElements = FinancialReportingClient.SubordinateLinesOfFormElement(NewParent);
	TotalItems = RowElements.Count();
	If TotalItems Then
		ReturnTotalToItsPlace = RowElements[TotalItems - 1].ItemKind = ItemKind("TotalByGroup");
	EndIf;
	
	InstallationParameters = FinancialReportingClient.TemplateForNewParentInstallationOptions();
	InstallationParameters.FormIdentifier = UUID;
	InstallationParameters.Copy = Copy;
	FinancialReportingClient.SetNewParentOfFormElement(CurrentRow, NewParent, InstallationParameters);
	
	Items.ReportItems.Expand(NewParent.GetID(), True);
	
EndProcedure

&AtClient
Function CopyRow(Tree, SourceRow, NewParent = Undefined)

	If NewParent = Undefined Then
		NewParent = SourceRow.GetParent();
	EndIf;

	ParentRows = NewParent.GetItems();
	IndexOf = FinancialReportingClientServer.IndexOfNewRow(ParentRows);//if there is a total for the group at the end of the group, then a new line should appear in front of it
	NewRow = ParentRows.Insert(IndexOf);
	FillPropertyValues(NewRow, SourceRow,,"ReportItem");

	If Not (SourceRow.ItemKind = ItemKind("Columns")
		Or SourceRow.ItemKind = ItemKind("Rows")) Then
		If ValueIsFilled(SourceRow.AddressOfItemStructure) Then
			NewRow.AddressOfItemStructure = CopyStorageData(SourceRow.AddressOfItemStructure);
		Else
			NewRow.AddressOfItemStructure = InternationalReportingClientServer.PlaceCopyOfItemInRepository(SourceRow, UUID);
		EndIf;
	EndIf;

	LinesOfCurLine = SourceRow.GetItems();
	For Each Substring In LinesOfCurLine Do
		CopyRow(Tree, Substring, NewRow);
	EndDo;

	Return NewRow;

EndFunction

&AtClient
Function ThereAreInaccessibleItemsAfterMigration(Parent, ToID)
	
	ParentItems1 = Parent.GetItems();
	For Each Item In ParentItems1 Do
		
		If Item.ItemKind = ItemKind("TotalByGroup") Then
			Continue;
		EndIf;
		
		If Not CanBeAddedToReportStructure(Item.ItemKind, ToID, Item.ThisIsReference, Item.ThisIsAnExtraDimension) Then
			Return True;
		EndIf;
		
		If ThereAreInaccessibleItemsAfterMigration(Item, ToID) Then
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	// Forbidding editing of service elements
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportItems.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReportItems.ItemKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.FinancialReportItemKinds.EmptyRef());
	ValueList.Add(Enums.FinancialReportItemKinds.Columns);
	ValueList.Add(Enums.FinancialReportItemKinds.Rows);
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	// Prohibiting editing links to items from other reports (related items)
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportItems.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReportItems.LinkedItem1");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	// Design of an empty element name
	ItemsKinds = Enums.FinancialReportItemKinds;
	IssueEmptyPresentation(ItemsKinds.TableIndicatorsInRows, NStr("vi = 'Bảng';
																	|ru = 'Таблица';
																	|en = 'Table'; fa = 'جدول';
																	|it = 'Tabella';
																	|pl = 'Table';
																	|tr = 'Tablo'"));
	IssueEmptyPresentation(ItemsKinds.TableIndicatorsInColumns, NStr("vi = 'Bảng';
																	|ru = 'Таблица';
																	|en = 'Table'; fa = 'جدول';
																	|it = 'Tabella';
																	|pl = 'Table';
																	|tr = 'Tablo'"));
	IssueEmptyPresentation(ItemsKinds.ComplexTable		, NStr("vi = 'Bảng';
																|ru = 'Таблица';
																|en = 'Table'; fa = 'جدول';
																|it = 'Tabella';
																|pl = 'Table';
																|tr = 'Tablo'"));
	IssueEmptyPresentation(ItemsKinds.Group				, NStr("vi = 'Nhóm';
																	|ru = 'Группа';
																	|en = 'Group'; fa = 'گروه';
																	|it = 'Gruppo';
																	|pl = 'Group';
																	|tr = 'Grup'"));
	IssueEmptyPresentation(ItemsKinds.TotalByGroup			, NStr("vi = 'Kết quả của một nhóm các chỉ số';
																	|ru = 'Итог по группе показателей';
																	|en = 'Total by indicator group'; fa = 'Total by indicator group';
																	|it = 'Totale per un gruppo di parametri';
																	|pl = 'Wynik dla grupy wskaźników';
																	|tr = 'Gösterge grubuna göre toplam'"));
	
	// Design of the total monetary indicators type
	TypesOfTotals = Enums.TypesOfTotals;
	IssuePresentationTotalType(TypesOfTotals.Balance_,	NStr("vi = 'Dư đầu';
																|ru = 'Начальное сальдо';
																|en = 'Opening balance'; fa = 'مانده ابتدای دوره';
																|it = 'Saldo iniziale';
																|pl = 'Saldo początkowe';
																|tr = 'Açılış bakiyesi'"), True);
	IssuePresentationTotalType(TypesOfTotals.Balance_Dr,	NStr("vi = 'Dư đầu bên Nợ';
																|ru = 'Начальное сальдо Дт';
																|en = 'Opening balance Dr'; fa = 'مانده افتتاحیه بدهکار';
																|it = 'Saldo iniziale a debito';
																|pl = 'Saldo początkowe Wn';
																|tr = 'Açılış bakiyesi Borç'"), True);
	IssuePresentationTotalType(TypesOfTotals.Balance_Cr,	NStr("vi = 'Dư đầu bên Có';
																|ru = 'Начальное сальдо Кт';
																|en = 'Opening balance Cr'; fa = 'مانده افتتاحیه بستانکار';
																|it = 'Saldo iniziale a credito';
																|pl = 'Saldo początkowe Ma';
																|tr = 'Açılış bakiyesi Alacak'"), True);
	IssuePresentationTotalType(TypesOfTotals.Balance_,	NStr("vi = 'Dư cuối';
																|ru = 'Конечное сальдо';
																|en = 'Closing balance'; fa = 'مانده پایان دوره';
																|it = 'Saldo finale';
																|pl = 'Saldo końcowe';
																|tr = 'Kapanış bakiyesi'"), False);
	IssuePresentationTotalType(TypesOfTotals.Balance_Dr,	NStr("vi = 'Dư cuối bên Nợ';
																|ru = 'Конечное сальдо Дт';
																|en = 'Closing balance Dr'; fa = 'مانده اختتامیه بدهکار';
																|it = 'Saldo finale a debito';
																|pl = 'Saldo końcowe Wn';
																|tr = 'Kapanış bakiyesi Borç'"), False);
	IssuePresentationTotalType(TypesOfTotals.Balance_Cr,	NStr("vi = 'Dư cuối bên Có';
																|ru = 'Конечное сальдо Кт';
																|en = 'Closing balance Cr'; fa = 'مانده اختتامیه بستانکار';
																|it = 'Saldo finale a credito';
																|pl = 'Saldo końcowe Ma';
																|tr = 'Kapanış bakiyesi Alacak'"), False);

	// Design of the total type for all other elements
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportItemsTotalType.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReportItems.ItemKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.FinancialReportItemKinds.MonetaryIndicator;

	Item.Appearance.SetParameterValue("Text", "");

	// Let's design the reverse sign field for those who have it set
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportItemsReverseSign.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReportItems.ReverseSign");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReportItems.ItemKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.FinancialReportItemKinds.MonetaryIndicator);
	ValueList.Add(Enums.FinancialReportItemKinds.NonMonetaryItem);
	ValueList.Add(Enums.FinancialReportItemKinds.DerivedItem);
	ValueList.Add(Enums.FinancialReportItemKinds.TotalByGroup);
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("Text", "(-)");
	
	// Let's design the reverse sign field for those who do NOT have it set
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportItemsReverseSign.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReportItems.ReverseSign");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text", "");

EndProcedure

&AtServer
Function AccountPlanSelectionFormParameters()
	
	FormParameters = New Structure();
	FormParameters.Insert("SelectedAccountPlans", Object.ChartsOfAccounts.Unload().UnloadColumn("ChartOfAccounts"));
	FormParameters.Insert("AccountPlansUsed", AccountPlansUsed());
	Return FormParameters;
	
EndFunction

&AtServer
Procedure IssueEmptyPresentation(ItemKind, EmptyPresentationText)
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportItemsPresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReportItems.ItemKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = ItemKind;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReportItems.DisplayItemTitle");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", New Color(192, 192, 192));
	Item.Appearance.SetParameterValue("Text", EmptyPresentationText);
	
EndProcedure

&AtServer
Procedure IssuePresentationTotalType(TotalType, PresentationText, OpeningBalance)
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportItemsTotalType.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReportItems.OpeningBalance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = OpeningBalance;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReportItems.TotalType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = TotalType;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReportItems.ItemKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.FinancialReportItemKinds.MonetaryIndicator;

	Item.Appearance.SetParameterValue("Text", PresentationText);
	
EndProcedure

&AtServer
Procedure RefreshFormTitle()
	
	TypePresentation = NStr("vi = 'Dạng báo cáo';
							|ru = 'Вид отчета';
							|en = 'Report kind'; fa = 'نوع گزارش';
							|it = 'Tipo di report';
							|pl = 'Rodzaj raportu';
							|tr = 'Rapor türü'");
	If Not ValueIsFilled(Object.Ref) Then
		ThisForm.Title = TypePresentation + " (" + NStr("vi = 'tạo';
														|ru = 'создание';
														|en = 'create'; fa = 'ایجاد';
														|it = 'creazione';
														|pl = 'create';
														|tr = 'oluşturma'") + ")";
	Else
		ThisForm.Title = Object.Description + " (" + TypePresentation + ")";
	EndIf;
	
EndProcedure

&AtServer
Function CreateCacheBasedOnCombinationTable(TableOfCombinations, Level = 0)
	
	If Level = TableOfCombinations.Columns.Count() Then
		Return True;
	EndIf;
	
	Values = TableOfCombinations.Copy();
	CurColumnName = Values.Columns[Level].Name;
	Values.GroupBy(CurColumnName);
	
	CacheResult = New Map;
	For Each Value In Values Do
		CurrentValue = Value[CurColumnName];
		SelectedCombinations = TableOfCombinations.Copy(New Structure(CurColumnName, CurrentValue));
		LowerLevelCache = CreateCacheBasedOnCombinationTable(SelectedCombinations, Level + 1);
		CacheResult.Insert(CurrentValue, LowerLevelCache);
	EndDo;
	
	Return New FixedMap(CacheResult);
	
EndFunction

&AtClient
Function ItemKind(ElementTypeName)
	
	If CacheOfElementTypes = Undefined Then
		CacheOfElementTypes = New Map;
	EndIf;
	
	Value = CacheOfElementTypes[ElementTypeName];
	If Value = Undefined Then
		Value = PredefinedValue("Enum.FinancialReportItemKinds." + ElementTypeName);
		CacheOfElementTypes.Insert(ElementTypeName, Value);
	EndIf;
	
	Return Value;
	
EndFunction

&AtServer
Function ItemKindServer(ElementTypeName)
	
	Return Enums.FinancialReportItemKinds[ElementTypeName];
	
EndFunction

&AtServer 
Procedure UpdateTreeOfNewElements()
	
	TreeParameters = InternationalReportingClientServer.NewElementTreeParameters();
	TreeParameters.QuickSearch = QuickSearchOfNew;
	TreeParameters.ChartsOfAccounts = Object.ChartsOfAccounts.Unload().UnloadColumn("ChartOfAccounts");
	
	InternationalReportingServer.UpdateTreeOfNewElements(ThisForm, TreeParameters);
	
EndProcedure

&AtServer 
Procedure UpdateTreeOfSavedItems()
	
	If Not ValueIsFilled(QuickSearchForSavedFiles)
		And Not ValueIsFilled(FilterByReportKind) Then
		SavedItems = SavedItemsTree.GetItems();
		SavedItems.Clear();
		Return;
	EndIf;
	
	TreeParameters = InternationalReportingClientServer.NewElementTreeParameters();
	TreeParameters.NameOfTreeElement = "SavedItemsTree";
	TreeParameters.FilterByReportKind = FilterByReportKind;
	TreeParameters.CurReportView = Object.Ref;
	TreeParameters.QuickSearch = QuickSearchForSavedFiles;
	TreeParameters.ChartsOfAccounts = Object.ChartsOfAccounts.Unload().UnloadColumn("ChartOfAccounts");
	
	InternationalReportingServer.UpdateTreeOfSavedItems(ThisForm, TreeParameters);
	
EndProcedure

&AtServer 
Procedure UpdateTheReportTreeServer(CopyingValue = Undefined)
	
	CurReportView = Object.Ref;
	If ValueIsFilled(CopyingValue) Then
		CurReportView = CopyingValue;
	EndIf;
	
	IndexOfRootRowImage = 100;
	ReportElementsLine = NStr("vi = 'Phần tử báo cáo';
								|ru = 'Элементы отчета';
								|en = 'Report items'; fa = 'اقلام گزارش';
								|it = 'Elementi del report';
								|pl = 'Elementy raportu';
								|tr = 'Rapor öğeleri'");
	If Not ValueIsFilled(CurReportView) Then
		TreeRows = ReportItems.GetItems();
		If Not TreeRows.Count() 
			Or TreeRows.Count() And TreeRows[0].CustomPicture <> IndexOfRootRowImage Then
			RootRow = TreeRows.Add();
			RootRow.NameForPrinting = ReportElementsLine;
			RootRow.ItemKind = Enums.FinancialReportItemKinds.EmptyRef();
			RootRow.CustomPicture = IndexOfRootRowImage;
		EndIf;
		Return;
	EndIf;
	
	ItemsTree = InternationalReportingServer.UpdateTheReportTree(CurReportView);
	
	RootRow = ItemsTree.Rows.Add();
	RootRow.NameForPrinting = ReportElementsLine;
	RootRow.ItemKind = Enums.FinancialReportItemKinds.EmptyRef();
	RootRow.CustomPicture = IndexOfRootRowImage;
	
	LineNumber = 0;
	While LineNumber < ItemsTree.Rows.Count() Do
		
		Page1 = ItemsTree.Rows[LineNumber];
		// Delete the lines by condition
		If Page1.CustomPicture <> IndexOfRootRowImage Then
			InstallationParameters = FinancialReportingServer.TemplateForNewParentInstallationOptions();
			InstallationParameters.TheseAreSavedOnes = True;
			FinancialReportingServer.SetNewParent(Page1, RootRow, InstallationParameters);
			ItemsTree.Rows.Delete(Page1);
			Continue;
		EndIf;
		LineNumber = LineNumber + 1;
		
	EndDo;
	
	If ValueIsFilled(CopyingValue) Then
		PutTreeInStorage(ItemsTree);
	EndIf;
	
	ValueToFormAttribute(ItemsTree, "ReportItems");
	
EndProcedure

&AtServer
Procedure ClearDeletedReportElements(SettingUpIDCells, IDCurrentRow)
	
	CellsSettings = ReportItems.FindByID(SettingUpIDCells);
	CurrentRow = ReportItems.FindByID(IDCurrentRow);
	
	If Not ValueIsFilled(CellsSettings.AddressOfItemStructure) Then
		CellsSettings.AddressOfItemStructure = InternationalReportingClientServer.PlaceItemInStorage(CellsSettings, UUID);
	EndIf;
	ElementStructure = GetFromTempStorage(CellsSettings.AddressOfItemStructure);
	FoundRows = ElementStructure.TableItems.FindRows(New Structure("String", CurrentRow.ReportItem));
	For Each FoundRow In FoundRows Do
		ElementStructure.TableItems.Delete(FoundRow);
	EndDo;
	FoundRows = ElementStructure.TableItems.FindRows(New Structure("String", CurrentRow.AddressOfItemStructure));
	For Each FoundRow In FoundRows Do
		ElementStructure.TableItems.Delete(FoundRow);
	EndDo;
	FoundRows = ElementStructure.TableItems.FindRows(New Structure("Column", CurrentRow.ReportItem));
	For Each FoundRow In FoundRows Do
		ElementStructure.TableItems.Delete(FoundRow);
	EndDo;
	FoundRows = ElementStructure.TableItems.FindRows(New Structure("Column", CurrentRow.AddressOfItemStructure));
	For Each FoundRow In FoundRows Do
		ElementStructure.TableItems.Delete(FoundRow);
	EndDo;
	PutToTempStorage(ElementStructure, CellsSettings.AddressOfItemStructure);
	
EndProcedure

&AtClient
Procedure MoveTreeElement(Tree, Up = True)
	
	ViewOfSummaryElement = ItemKind("TotalByGroup");
	CurrentRow = Tree.FindByID(Items.ReportItems.CurrentRow);
	Parent = CurrentRow.GetParent();
	If Parent = Undefined Then
		Return;
	EndIf;
	CurCollection = Parent.GetItems();
	CurrentIndex = CurCollection.IndexOf(CurrentRow);
	FirstIndex = 0;
	LastIndex = CurCollection.Count() - 1;
	
	// Let's check the conditions under which moving does not work
	If CurCollection.Count() = 1 Then
		Return;
	EndIf;
	
	If Up And CurrentIndex = 0 Or Not Up And CurrentIndex = LastIndex Then
		Return;
	EndIf;
	
	If CurrentRow.ItemKind = ItemKind("Columns")
		Or CurrentRow.ItemKind = ItemKind("Rows") Then
		Return;
	EndIf;
	
	// Let's determine the position of the total in the group
	TotalIndex = -1;
	For Each Page1 In CurCollection Do
		If Page1.ItemKind = ViewOfSummaryElement And Not Page1.ThisIsReference Then
			TotalIndex = CurCollection.IndexOf(Page1);
			Break;
		EndIf;
	EndDo;
	
	// According to the position of the result , we will approve the extreme positions for simple elements of the group
	If TotalIndex = 0 Then
		FirstIndex = 1;
	ElsIf TotalIndex = LastIndex Then
		LastIndex = LastIndex - 1;
	EndIf;
	
	// Calculate the magnitude and direction of the shift
	Direction = ?(Up,-1,1);
	Move = 1;
	If CurrentRow.ItemKind = ViewOfSummaryElement And Not CurrentRow.ThisIsReference Then
		Move = LastIndex + 1;
		If Not Up Then
			Move = LastIndex;
		EndIf;
	ElsIf CurrentIndex = FirstIndex And Up 
			Or CurrentIndex = LastIndex And Not Up Then
		Return;
	EndIf;
	
	// Perform a shift
	CurCollection.Move(CurrentIndex,Move * Direction);
	Modified = True;
	
EndProcedure

&AtServer
Procedure BreakConnectionServer(CurrentRowID)
	
	CurrentRow = ReportItems.FindByID(CurrentRowID);
	CurrentRow.AddressOfItemStructure = InternationalReportingClientServer.PlaceItemInStorage(CurrentRow.LinkedItem1, UUID);
	
	RelatedData = GetFromTempStorage(CurrentRow.AddressOfItemStructure); // See FinancialReportingServerCall.ReportElementData
	FillPropertyValues(RelatedData, CurrentRow,"NameForPrinting,Comment,ReverseSign");
	FinancialReportingServerCall.SetValueOfAdditionalProps(RelatedData,"ReportRowCode",CurrentRow.ReportRowCode);
	FinancialReportingServerCall.SetValueOfAdditionalProps(RelatedData,"Note",CurrentRow.Note);
	RelatedData.Ref = Undefined;
	PutToTempStorage(RelatedData, CurrentRow.AddressOfItemStructure);
	
	ElementTree = InternationalReportingServer.UpdateTheReportTree(Common.ObjectAttributeValue(
		CurrentRow.LinkedItem1, "Owner"), CurrentRow.LinkedItem1);
	If ElementTree.Rows.Count() > 0 Then
		CopyElementTree(ElementTree.Rows[0], CurrentRow);
	EndIf;
	
	CurrentRow.ReportItem = Undefined;
	CurrentRow.LinkedItem1 = Undefined;
	CurrentRow.ThisIsReference = False;
	CurrentRow.CustomPicture = CurrentRow.CustomPicture - 1;
	
EndProcedure

&AtServer
Procedure CopyElementTree(SourceTree_1, Copy = Undefined, ElementAddresses = Undefined, DeleteSourceFiles = False)
	
	CopyCellSettingsToStorage(SourceTree_1, ElementAddresses);
	
	OriginalLines = FinancialReportingServer.SubordinateRows(SourceTree_1);
	CopiesOfStrings = FinancialReportingServer.SubordinateRows(Copy);
	For Each InitialString In OriginalLines Do
		
		NewRow = CopiesOfStrings.Add();
		FillPropertyValues(NewRow, InitialString,,"ReportItem");
		If Not InitialString.ItemKind.IsEmpty()
			And Not InitialString.ItemKind = ItemKindServer("Columns")
			And Not InitialString.ItemKind = ItemKindServer("Rows")
			And Not InitialString.ItemKind = ItemKindServer("CellsSettings") Then
		
			NewRow.AddressOfItemStructure = PutCopyInStorage(InitialString.ReportItem, ElementAddresses);
			
		EndIf;
		
		If InitialString.Rows.Count() Then
			CopyElementTree(InitialString, NewRow, ElementAddresses);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure PutTreeInStorage(SourceTree_1, ElementAddresses = Undefined)
	
	CopyCellSettingsToStorage(SourceTree_1, ElementAddresses);
	
	OriginalLines = FinancialReportingServer.SubordinateRows(SourceTree_1);
	For Each InitialString In OriginalLines Do
		
		If Not InitialString.ItemKind.IsEmpty()
			And Not InitialString.ItemKind = ItemKindServer("Columns")
			And Not InitialString.ItemKind = ItemKindServer("Rows")
			And Not InitialString.ItemKind = ItemKindServer("CellsSettings") Then
		
			InitialString.AddressOfItemStructure = PutCopyInStorage(InitialString.ReportItem, ElementAddresses);
			
		EndIf;
		
		InitialString.ReportItem = Undefined;
		If InitialString.Rows.Count() Then
			PutTreeInStorage(InitialString, ElementAddresses);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function PutCopyInStorage(SourceElement, ElementAddresses = Undefined)
	
	If ElementAddresses = Undefined Then
		ElementAddresses = New Map;
	EndIf;
	
	AddressOfItemStructure = ElementAddresses[SourceElement];
	If AddressOfItemStructure <> Undefined Then
		Return AddressOfItemStructure;
	EndIf;
	AddressOfItemStructure = InternationalReportingClientServer.PlaceItemInStorage(SourceElement, UUID);
	ElementData = GetFromTempStorage(AddressOfItemStructure); // See FinancialReportingServerCall.ReportElementData
	ElementData.Ref = Undefined;
	ElementAddresses.Insert(SourceElement, AddressOfItemStructure);

	For Each Operand In ElementData.FormulaOperands Do
		Operand.AddressOfItemStructure = PutCopyInStorage(Operand.Operand, ElementAddresses);
		ElementAddresses.Insert(Operand.Operand, Operand.AddressOfItemStructure);
		Operand.Operand = Undefined;
	EndDo;
	Fields = New Structure("String,Column,Item");
	For Each RowColumn In ElementData.TableItems Do
		
		For Each Field In Fields Do
			Address = ElementAddresses[RowColumn[Field.Key]];
			If Address = Undefined Then
				Address = PutCopyInStorage(RowColumn[Field.Key], ElementAddresses);
				ElementAddresses.Insert(RowColumn[Field.Key], Address);
			EndIf;
			RowColumn[Field.Key] = Address;
		EndDo;
		
	EndDo;
	PutToTempStorage(ElementData, AddressOfItemStructure);
	Return AddressOfItemStructure;
	
EndFunction

&AtServer
Procedure CopyCellSettingsToStorage(SourceTree_1, ElementAddresses)
	
	If ElementAddresses = Undefined Then
		ElementAddresses = New Map;
		ItemKind = Enums.FinancialReportItemKinds.CellsSettings;
		FoundRows = SourceTree_1.Rows.FindRows(New Structure("ItemKind", ItemKind), True);
		For Each CellsSettings In FoundRows Do
			CellsSettings.AddressOfItemStructure = PutCopyInStorage(CellsSettings.ReportItem, ElementAddresses);
			CellsSettings.ReportItem = Undefined;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Function CopyStorageData(SourceDataAddress, ElementAddresses = Undefined)
	
	If ElementAddresses = Undefined Then
		ElementAddresses = New Map;
	EndIf;
	
	RawData = GetFromTempStorage(SourceDataAddress); // See FinancialReportingServerCall.ReportElementData
	RawData.Ref = Undefined;
	
	For Each Operand In RawData.FormulaOperands Do
		If ValueIsFilled(Operand.AddressOfItemStructure) Then
			Operand.AddressOfItemStructure = CopyStorageData(Operand.AddressOfItemStructure);
		Else
			Operand.AddressOfItemStructure = PutCopyInStorage(Operand.Operand, ElementAddresses);
		EndIf;
		Operand.Operand = Undefined;
	EndDo;
	
	Fields = New Structure("String,Column,Item");
	For Each RowColumn In RawData.TableItems Do
		
		For Each Field In Fields Do
			If TypeOf(RowColumn[Field.Key]) = Type("CatalogRef.FinancialReportItems") Then
				Address = PutCopyInStorage(RowColumn[Field.Key], ElementAddresses);
			Else
				Address = CopyStorageData(RowColumn[Field.Key]);
			EndIf;
			RowColumn[Field.Key] = Address;
		EndDo;
		
	EndDo;
	
	Return PutToTempStorage(RawData, UUID);
	
EndFunction

&AtClient
Procedure ExpandReportTree()
	
	ReportTreeElements = ReportItems.GetItems();
	If ReportTreeElements.Count() Then 
		Items.ReportItems.Expand(ReportTreeElements[0].GetID(), True);
	EndIf;
	
EndProcedure

&AtServer
Function AccountPlansUsed()
	
	AccountsUsed = New Array;
	ReportTree = FormAttributeToValue("ReportItems");
	
	MonetaryIndicator = ItemKindServer("MonetaryIndicator");
	FoundRows = ReportTree.Rows.FindRows(New Structure("ItemKind", MonetaryIndicator), True);
	For Each ReportRow In FoundRows Do
		AccountsUsed.Add(ReportRow.GLAccount_);
	EndDo;// by monetary indicators
	
	DerivedItem = ItemKindServer("DerivedItem");
	FoundRows = ReportTree.Rows.FindRows(New Structure("ItemKind", DerivedItem), True);
	For Each ReportRow In FoundRows Do
		ElementData = ElementData(ReportRow);
		GetFormulaAccounts(ElementData, AccountsUsed)
	EndDo;// by derived indicators
	
	ItemKind = ItemKindServer("CellsSettings");
	FoundRows = ReportTree.Rows.FindRows(New Structure("ItemKind", ItemKind), True);
	For Each ReportRow In FoundRows Do
		CellData_ = ElementData(ReportRow); // See FinancialReportingServerCall.ReportElementData
		For Each TableItems In CellData_.TableItems Do
			ElementData = ElementData(TableItems.Item);
			If ElementData.ItemKind = MonetaryIndicator Then
				Account = FinancialReportingServerCall.ValueOfAdditionalProps(TableItems.Item,"GLAccount_");
				AccountsUsed.Add(Account);
			EndIf;// this is a monetary indicator
			If ElementData.ItemKind = DerivedItem Then
				GetFormulaAccounts(ElementData, AccountsUsed);
			EndIf;// this is a derived indicator
		EndDo;// by table elements
	EndDo;// by cell settings
	
	AccountsUsedByType = TMCommonUse.DecomposeArrayOfReferencesByType(AccountsUsed);
	
	AccountPlansUsed = New Array;
	For Each KeyAndValue In AccountsUsedByType Do
		If KeyAndValue.Key = FinancialAccountingClientServer.TypeChartOfAccounts() Then
			ChartsOfAccountsByLinks = Common.ObjectsAttributeValue(KeyAndValue.Value, "ChartOfAccounts");
			For Each KeyAndValue In ChartsOfAccountsByLinks Do
				If AccountPlansUsed.Find(KeyAndValue.Value) = Undefined Then
					AccountPlansUsed.Add(KeyAndValue.Value);
				EndIf;
			EndDo;
		Else
			MetadataObjectIdentifier = Common.MetadataObjectID(KeyAndValue.Key, False);
			If ValueIsFilled(MetadataObjectIdentifier) Then
				AccountPlansUsed.Add(MetadataObjectIdentifier);
			EndIf;
		EndIf;
	EndDo;
	
	Return AccountPlansUsed;
	
EndFunction

&AtServer
Function ElementData(ReportRow)
	
	Address = "";
	If TypeOf(ReportRow) = Type("ValueTreeRow") Then
		Address = ReportRow.AddressOfItemStructure;
	ElsIf TypeOf(ReportRow) = Type("String") Then
		Address = ReportRow;
	EndIf;
	
	If IsBlankString(Address) Then
		Address = InternationalReportingClientServer.PlaceItemInStorage(ReportRow,UUID);
	EndIf;
	Return GetFromTempStorage(Address);
	
EndFunction

&AtServer
Procedure GetFormulaAccounts(ElementData, Accounts) 
	
	For Each Operand In ElementData.FormulaOperands Do
		If ValueIsFilled(Operand.AddressOfItemStructure) Then
			Account = FinancialReportingServerCall.ValueOfAdditionalProps(Operand.AddressOfItemStructure,"GLAccount_");
		ElsIf ValueIsFilled(Operand.Operand) Then
			Account = FinancialReportingServerCall.ValueOfAdditionalProps(Operand.Operand,"GLAccount_");
		EndIf;
		Accounts.Add(Account);
	EndDo;
	
EndProcedure

&AtServer
Procedure CheckingForLooping()
	
	TreeReportElements = FormAttributeToValue("ReportItems");
	
	ErrorText = "";
	InternationalReportingServer.CheckingLoopingOfReportTypes(TreeReportElements, ErrorText);
	If ValueIsFilled(ErrorText) Then
		Common.MessageToUser(ErrorText, Object.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure LoadReportSettings(Settings, AdditionalParameters) Export
	
	If TypeOf(Settings) = Type("Structure") Then
		FillPropertyValues(Object, Settings);
		Modified = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAccuracyOnServer(Accuracy)
	
	For Each ItemID In Items.ReportItems.SelectedRows Do
		
		TreeItem = ReportItems.FindByID(ItemID);
		If TreeItem.ItemKind = Enums.FinancialReportItemKinds.MonetaryIndicator 
					Or TreeItem.ItemKind = Enums.FinancialReportItemKinds.NonMonetaryItem
					Or TreeItem.ItemKind = Enums.FinancialReportItemKinds.DerivedItem
					Or TreeItem.ItemKind = Enums.FinancialReportItemKinds.TotalByGroup
					Or TreeItem.ItemKind = Enums.FinancialReportItemKinds.Dimension Then
			
			If ValueIsFilled(TreeItem.ReportItem) Then
				FinElementOfReport = TreeItem.ReportItem.GetObject();
				FinElementOfReport.Lock();
				FinancialReportingServerCall.SetValueOfAdditionalProps(FinElementOfReport, "Accuracy", Accuracy);
				FinElementOfReport.Write();
				
				TreeItem.AddressOfItemStructure = "";
				
				FillingData = InternationalReportingClientServer.NewRowFillingData();
				FillingData.Source = FinElementOfReport;
				FillingData.DestinationRow = TreeItem;
				FillingData.ItemAddressInStorage = "";
				FillingData.Field = Undefined;
				FinancialReportingClientServer.FillInTreeLine(FillingData);
			Else
				If Not ValueIsFilled(TreeItem.AddressOfItemStructure) Then
					TreeItem.AddressOfItemStructure = InternationalReportingClientServer.PlaceItemInStorage(TreeItem, UUID);
				EndIf;
				FinancialReportingServerCall.SetValueOfAdditionalProps(TreeItem.AddressOfItemStructure, "Accuracy", Accuracy);
				Modified = True;
			EndIf;
			
		EndIf;
		
	EndDo; 
	
EndProcedure

#EndRegion

#EndRegion
