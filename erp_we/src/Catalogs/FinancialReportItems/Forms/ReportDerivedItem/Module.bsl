
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ObjectData = Catalogs.FinancialReportItems.FormWhenCreatedOnServer(ThisObject); // See FinancialReportingClientServer.ReportElementStructure
	MainStorageID = Parameters.MainStorageID;
	CommonClientServer.SupplementTableFromArray(ChartsOfAccounts, Parameters.ChartsOfAccounts, "ChartOfAccounts");
	
	If Parameters.Property("CellsSettings") Then
		AddressOfReportItems = Parameters.AddressOfReportItems;
		ItemTableAddress = Parameters.ItemTableAddress;
	EndIf;
	
	UpdateTreeOfNewElements();
	
	OperatorsTree = FinancialReportingServerCall.BuildTreeOfOperators();
	ValueToFormAttribute(OperatorsTree, "Operators");
	FillingData = InternationalReportingClientServer.NewRowFillingData();
	For Each OperandString_ In ObjectData.FormulaOperands Do
		NewRow = Operands.Add();
		NewRow.ReportItem = OperandString_.Operand;
		NewRow.Id = OperandString_.Id;
		If TypeOf(OperandString_) = Type("ValueTableRow") Then
			NewRow.AddressOfItemStructure = OperandString_.AddressOfItemStructure;
		Else
			NewRow.AddressOfItemStructure = FinancialReportingServerCall.PlaceItemInStorage(OperandString_.Operand, Parameters.MainStorageID);
		EndIf;
		If ValueIsFilled(NewRow.AddressOfItemStructure) Then
			ElementData = GetFromTempStorage(NewRow.AddressOfItemStructure);
		Else
			ElementData = NewRow.ReportItem;
		EndIf;
		FillingData.Source = ElementData;
		FillingData.DestinationRow = NewRow;
		FillingData.ItemAddressInStorage = NewRow.AddressOfItemStructure;
		FinancialReportingClientServer.FillInTreeLine(FillingData);
		
		AuxiliaryElement = "";
		If TypeOf(NewRow.AccountIndicatorDimension) = LocalAccntingClientServer.TypeChartOfAccounts() Then
			AuxiliaryElement = Common.MetadataObjectID(LocalAccntingClientServer.TypeChartOfAccounts());
		ElsIf TypeOf(NewRow.AccountIndicatorDimension) = FinancialAccountingClientServer.TypeChartOfAccounts() Then
			AuxiliaryElement = Common.ObjectAttributeValue(NewRow.AccountIndicatorDimension, "ChartOfAccounts");
		EndIf;
		NewRow.CustomPicture = FinancialReportingCached.CustomPicture(NewRow.ItemKind, AuxiliaryElement);
	EndDo;
	
	Items.GroupAddAttributes.Visible = Parameters.ShowRowCodeNote;
	RefreshFormTitle();

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	OperatorSections = Operators.GetItems();
	If OperatorSections.Count() > 0 Then
		Items.Operators.Expand(OperatorSections[0].GetID());
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	CheckFormulaServer(Cancel);
	If Not Cancel Then
		AdditionalMode_ = Enums.AdditionalModesOfReportItems.ReportKind;
		Catalogs.FinancialReportItems.FormBeforeWritingToServer(ThisObject, CurrentObject, Cancel, AdditionalMode_);
		If ValueIsFilled(ItemAddressInStorage) Then
			ElementStructure = GetFromTempStorage(ItemAddressInStorage);
			ElementStructure.FormulaOperands.Clear();
			For Each OperandString_ In Operands Do
				If Not ValueIsFilled(OperandString_.AddressOfItemStructure) Then
					ElementAddress = InternationalReportingClientServer.PlaceItemInStorage(OperandString_, MainStorageID);
					OperandString_.AddressOfItemStructure = ElementAddress;
				EndIf;
				FillPropertyValues(ElementStructure.FormulaOperands.Add(), OperandString_);
			EndDo;
			PutToTempStorage(ElementStructure, ItemAddressInStorage);
		EndIf;
	EndIf;
	Return;// in UT11, the handler is empty
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	RefreshFormTitle();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If ValueIsFilled(ItemAddressInStorage) Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ValueIsFilled(ValueSelected) Then
		ReportKind = ValueSelected;
		UpdateTreeOfSavedItems();
	EndIf;
	InternationalReportingClient.ExpandTreeOfSavedItems(ThisObject, SavedItemsTree);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NameForPrintingOnChange(Item)
	
	Object.Description = Object.NameForPrinting;
	
EndProcedure

&AtClient
Procedure CommentTheBeginningOfTheSelection(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure QuickSearchOfNewOnChange(Item)

	UpdateTreeOfNewElements();

EndProcedure

&AtClient
Procedure QuickSearchForSavedFilesWhenChangingThem(Item)

	UpdateTreeOfSavedItems();

EndProcedure

&AtClient
Procedure ViewOfTheReportWhenChanged(Item)
	
	UpdateTreeOfSavedItems();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOperators

&AtClient
Procedure OperatorsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	InsertOperatorIntoFormula();
	
EndProcedure

&AtClient
Procedure OperatorsDragStart(Item, DragParameters, Perform)
	
	If ValueIsFilled(Item.CurrentData.StructureToInsert) Then
		DragParameters.Value = Item.CurrentData.StructureToInsert;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersNewItemTree

&AtClient
Procedure NewItemTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	SelectedOperands = New Array;
	SelectedOperands.Add(Item.CurrentData);
	InternationalReportingClient.AddFormulaOperands(ThisObject, SelectedOperands, Operands);
EndProcedure

&AtClient
Procedure NewItemTreeDragStart(Item, DragParameters, Perform)
	
	IndexOf = 0;
	While IndexOf < DragParameters.Value.Count() Do
		
		ID = DragParameters.Value[IndexOf];
		Operand = NewItemTree.FindByID(ID);
		If Operand.IsFolder Then
			DragParameters.Value.Delete(IndexOf);
			Continue;
		EndIf;
		IndexOf = IndexOf + 1;
		
	EndDo;
	
	If DragParameters.Value.Count() = 0 Then
		Perform = False;
	EndIf;

	
EndProcedure

&AtClient
Procedure NewItemTreeDragEnd(Item, DragParameters, StandardProcessing)
	NewOperands = InternationalReportingClient.AddFormulaOperands(ThisObject,
			DragParameters.Value,
			Operands);
	FinancialReportingClient.AddFormulaText(ThisObject, NewOperands);
	Return;// in UT11, the handler is empty
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSavedItemsTree

&AtClient
Procedure SavedItemsTreeSelection(Item, RowSelected, Field, StandardProcessing)
	SelectedOperands = New Array;
	SelectedOperands.Add(Item.CurrentData);
	InternationalReportingClient.AddFormulaOperands(ThisObject, SelectedOperands, Operands);
	Return;// in UT11, the handler is empty
	
EndProcedure

&AtClient
Procedure SavedItemsTreeDragEnd(Item, DragParameters, StandardProcessing)
	InternationalReportingClient.AddFormulaOperands(ThisObject, DragParameters.Value, Operands);
	Return;// in UT11, the handler is empty
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOperands

&AtClient
Procedure OperandsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name <> "MetricsID" Then
		EditMetric();
	EndIf;
	
EndProcedure

&AtClient
Procedure OperandsDragEnd(Item, DragParameters, StandardProcessing)
	
	FinancialReportingClient.AddFormulaText(ThisObject, DragParameters.Value);
	
EndProcedure

&AtClient
Procedure OperandsDrag(Item, DragParameters, StandardProcessing, String, Field)
	InternationalReportingClient.AddFormulaOperands(ThisObject, DragParameters.Value, Operands);
	// to avoid triggering the end event for dragging the tree of new elements
	DragParameters.Value.Clear();
	
EndProcedure

&AtClient
Procedure OperandsIDEndOfTextInput(Item, Text, ChoiceData, StandardProcessing)
	
	Text = TrimAll(Text);
	NewID = "[" + Text + "]";
	OldID_ = "[" + Items.Operands.CurrentData.Id + "]";
	Formula = StrReplace(Formula, OldID_, NewID);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	FinancialReportingClient.FinishEditingReportElement(ThisObject);
	
EndProcedure

&AtClient
Procedure FindNewItem(Command)
	
	UpdateTreeOfNewElements();
	
EndProcedure

&AtClient
Procedure FindSavedItem(Command)
	
	UpdateTreeOfSavedItems();
	InternationalReportingClient.ExpandTreeOfSavedItems(ThisObject, SavedItemsTree);
EndProcedure

&AtClient
Procedure CheckFormula(Command)
	
	ClearMessages();
	Cancel = False;
	CheckFormulaServer(Cancel);
	If Not Cancel Then
		WarningText = NStr("vi = 'Không phát hiện lỗi cú pháp';
							|ru = 'Синтаксических ошибок не обнаружено';
							|en = 'Syntax errors were not found'; fa = 'Syntax errors were not found';
							|it = 'Non sono stati rilevati errori di sintassi';
							|pl = 'Nie wykryto błędów składni';
							|tr = 'Herhangi bir sözdizimi hatası tespit edilmedi'");
		ShowMessageBox(Undefined, WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure EditOperand(Command)
	
	EditMetric();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OperandsTotalType.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operands.OpeningBalance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operands.TotalType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfTotals.Balance_;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operands.ItemKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.FinancialReportItemKinds.MonetaryIndicator;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Dư đầu';
													|ru = 'Начальное сальдо';
													|en = 'Opening balance'; fa = 'مانده ابتدای دوره';
													|it = 'Saldo iniziale';
													|pl = 'Saldo początkowe';
													|tr = 'Açılış bakiyesi'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OperandsTotalType.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operands.OpeningBalance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operands.TotalType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfTotals.Balance_Dr;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operands.ItemKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.FinancialReportItemKinds.MonetaryIndicator;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Dư đầu bên Nợ';
													|ru = 'Начальное сальдо Дт';
													|en = 'Opening balance Dr'; fa = 'مانده افتتاحیه بدهکار';
													|it = 'Saldo iniziale a debito';
													|pl = 'Saldo początkowe Wn';
													|tr = 'Açılış bakiyesi Borç'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OperandsTotalType.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operands.OpeningBalance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operands.TotalType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfTotals.Balance_Cr;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operands.ItemKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.FinancialReportItemKinds.MonetaryIndicator;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Dư đầu bên Có';
													|ru = 'Начальное сальдо Кт';
													|en = 'Opening balance Cr'; fa = 'مانده افتتاحیه بستانکار';
													|it = 'Saldo iniziale a credito';
													|pl = 'Saldo początkowe Ma';
													|tr = 'Açılış bakiyesi Alacak'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OperandsTotalType.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operands.OpeningBalance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operands.TotalType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfTotals.Balance_;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operands.ItemKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.FinancialReportItemKinds.MonetaryIndicator;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Dư cuối';
													|ru = 'Конечное сальдо';
													|en = 'Closing balance'; fa = 'مانده پایان دوره';
													|it = 'Saldo finale';
													|pl = 'Saldo końcowe';
													|tr = 'Kapanış bakiyesi'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OperandsTotalType.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operands.OpeningBalance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operands.TotalType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfTotals.Balance_Dr;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operands.ItemKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.FinancialReportItemKinds.MonetaryIndicator;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Dư cuối bên Nợ';
													|ru = 'Конечное сальдо Дт';
													|en = 'Closing balance Dr'; fa = 'مانده اختتامیه بدهکار';
													|it = 'Saldo finale a debito';
													|pl = 'Saldo końcowe Wn';
													|tr = 'Kapanış bakiyesi Borç'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OperandsTotalType.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operands.OpeningBalance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operands.TotalType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfTotals.Balance_Cr;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operands.ItemKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.FinancialReportItemKinds.MonetaryIndicator;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Dư cuối bên Có';
													|ru = 'Конечное сальдо Кт';
													|en = 'Closing balance Cr'; fa = 'مانده اختتامیه بستانکار';
													|it = 'Saldo finale a credito';
													|pl = 'Saldo końcowe Ma';
													|tr = 'Kapanış bakiyesi Alacak'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OperandsTotalType.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operands.ItemKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.FinancialReportItemKinds.MonetaryIndicator;

	Item.Appearance.SetParameterValue("Text", ""); 

EndProcedure

&AtServer 
Procedure UpdateTreeOfNewElements()
	TreeParameters = InternationalReportingClientServer.NewElementTreeParameters();
	TreeParameters.ChartsOfAccounts = ChartsOfAccounts.Unload().UnloadColumn("ChartOfAccounts");
	TreeParameters.WorkMode = Undefined;
	TreeParameters.QuickSearch = QuickSearchOfNew;
	
	InternationalReportingServer.UpdateTreeOfNewElements(ThisObject, TreeParameters);
	Return;// in UT11, the handler is empty
	
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
	TreeParameters.ChartsOfAccounts = ChartsOfAccounts.Unload().UnloadColumn("ChartOfAccounts");
	TreeParameters.WorkMode = Enums.ModesOfNewItemTreeDisplay.SetUpReportKindIndicatorsOnly;
	TreeParameters.QuickSearch = QuickSearchForSavedFiles;
	TreeParameters.FilterByReportKind = FilterByReportKind;
	
	InternationalReportingServer.UpdateTreeOfSavedItems(ThisObject, TreeParameters);
EndProcedure

&AtClient
Procedure EditMetric()
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.Operands);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CurrentData = Items.Operands.CurrentData;
	If IsBlankString(CurrentData.AddressOfItemStructure) Then
		CurrentData.AddressOfItemStructure = InternationalReportingClientServer.PlaceItemInStorage(CurrentData, MainStorageID);
	EndIf;
	
	FormParameters = New Structure();
	FormParameters.Insert("IDOfOperandString",		CurrentData.GetID());
	FormParameters.Insert("Key", 							CurrentData.ReportItem);
	FormParameters.Insert("ItemKind", 						CurrentData.ItemKind);
	FormParameters.Insert("ItemAddressInStorage", 			CurrentData.AddressOfItemStructure);
	FormParameters.Insert("MainStorageID", 	MainStorageID);
	FormParameters.Insert("AddressOfReportItems", 			AddressOfReportItems);
	FormParameters.Insert("ItemTableAddress", 			ItemTableAddress);
	FormParameters.Insert("AddressOfEditedItem", 		ItemAddressInStorage);
	FormParameters.Insert("ShowRowCodeNote", 		False);
	
	Notification = New CallbackDescription("UpdateOperandStringAfterChange", ThisObject, FormParameters);
	
	OpenForm("Catalog.FinancialReportItems.ObjectForm",
		FormParameters, ThisObject,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure UpdateOperandStringAfterChange(Result, AdditionalParameters) Export
	FillingData = InternationalReportingClientServer.NewRowFillingData();
	FillingData.Source = Result;
	FillingData.DestinationRow = AdditionalParameters.IDOfOperandString;
	FillingData.ItemAddressInStorage = AdditionalParameters.ItemAddressInStorage;
	FillingData.Field = Operands;
	
	FinancialReportingClientServer.FillInTreeLine(FillingData);
	Return;// in UT11, the handler is empty
	
EndProcedure

&AtClient
Procedure InsertOperatorIntoFormula()
	
	If ValueIsFilled(Items.Operators.CurrentData.StructureToInsert) Then
		TextForInsert = Items.Operators.CurrentData.StructureToInsert;
		If Items.Operators.CurrentData.Id = "( )" 
			And ValueIsFilled(Items.Formula.SelectedText) Then
			TextForInsert = "(" + Items.Formula.SelectedText + ")";
		EndIf;
		Items.Formula.SelectedText = TextForInsert;
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckFormulaServer(Cancel)
	InternationalReportingServerCall.CheckFormula(Formula, Operands.Unload(),Cancel,"Formula","Object.Formula");
	Return;// in UT11, the handler is empty
	
EndProcedure

&AtServer
Procedure RefreshFormTitle(Record = False)
	
	If Not ValueIsFilled(Object.NameForPrinting) Then
		Title = NStr("vi = 'Chỉ tiêu tùy ý (tạo)';
					|ru = 'Производный показатель (создание)';
					|en = 'Derived item (Create)'; fa = 'Derived item (Create)';
					|it = 'Indicatore derivato (creazione)';
					|pl = 'Wskaźnik pochodny (tworzenie)';
					|tr = 'Türetilmiş madde (oluşturma)'");
	Else
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 %2';
				|ru = '%1 %2';
				|en = '%1 %2'; fa = '%1 %2';
				|it = '%1 %2';
				|pl = '%1 %2';
				|tr = '%1 %2'"),
			Object.NameForPrinting,
			NStr("vi = '(Tham số tự do)';
				|ru = '(Производный показатель)';
				|en = '(Derived item)'; fa = '(Derived item)';
				|it = '(Indice derivato)';
				|pl = '(Wskaźnik pochodny)';
				|tr = '(Türetilmiş madde)'"));
	EndIf;
	
EndProcedure

#EndRegion
