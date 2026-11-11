#Region Variables

&AtClient
Var ClosingForm_;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	MethodOfFillingInArticle = Undefined;
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ObjectData = Catalogs.FinancialReportItems.FormWhenCreatedOnServer(ThisObject);
	MainStorageID = Parameters.MainStorageID;
	UseToEnterPlan = Parameters.UseToEnterPlan;
	LocationOptionOfActualDataOffset = Parameters.LocationOptionOfActualDataOffset;
	
	If Parameters.Property("UseStatusFilter") Then
		UseStatusFilter = Parameters.UseStatusFilter;
	ElsIf Parameters.Property("BudgetingModel") Then
		UseStatusFilter = Common.ObjectAttributeValue(Parameters.BudgetingModel,
			"UseBudgetConfirmation");
	EndIf;
	
	If Parameters.Property("CellsSettings") Then
		TreeMode = Enums.ModesOfNewItemTreeDisplay.DerivedItemOfComplexTable;
		AddressOfReportItems = Parameters.AddressOfReportItems;
		ItemTableAddress = Parameters.ItemTableAddress;
		LineIDOfReportItem = Parameters.LineIDOfReportItem;
		EditedValues = Parameters.EditedValues;
		Items.OperandsLockVertically.Visible = True;
		Items.OperandsLockHorizontally.Visible = True;
	ElsIf Parameters.Property("FillingMethod", MethodOfFillingInArticle) Then
		If MethodOfFillingInArticle = 1 Then
			TreeMode = Enums.ModesOfNewItemTreeDisplay.SetUpAutomaticCalculationOfComplexTable;
			LineIDOfReportItem = Parameters.LineIDOfReportItem;
			Items.OperandsLockVertically.Visible = True;
			Items.OperandsLockHorizontally.Visible = True;
		ElsIf MethodOfFillingInArticle = 2 Then
			TreeMode = Enums.ModesOfNewItemTreeDisplay.BudgetFlowItemsFilling;
		EndIf;
		AddressOfReportItems = Parameters.AddressOfReportItems;
		ItemTableAddress = Parameters.ItemTableAddress;
		AddressOfEditedItem = Parameters.AddressOfEditedItem;
	Else
		ItemsTree = FormDataToValue(Parameters.ReportItems, Type("ValueTree"));
		AddressOfReportItems = PutToTempStorage(ItemsTree, UUID);
		TreeMode = Enums.ModesOfNewItemTreeDisplay.DerivedItemOfBudgetProfile;
		LineIDOfReportItem = Parameters.LineIDOfReportItem;
		EditedValues = Parameters.EditedValues;
	EndIf;
	
	UpdateTreeOfNewElements();
	
	OperatorsTree = FinancialReportingServerCall.BuildTreeOfOperators(False);
	BudgetReportingServerCall.AugmentOperatorTree(OperatorsTree);
	ValueToFormAttribute(OperatorsTree, "Operators");
	RefreshFormTitle();
	
	For Each OperandString_ In ObjectData.FormulaOperands Do
		NewRow = Operands.Add();
		NewRow.ReportItem = OperandString_.Operand;
		NewRow.Id = OperandString_["Id"];
		NewRow.AddressOfItemStructure = OperandString_.AddressOfItemStructure;
		If ValueIsFilled(NewRow.AddressOfItemStructure) Then
			ElementData = GetFromTempStorage(NewRow.AddressOfItemStructure);
		Else
			ElementData = NewRow.ReportItem;
		EndIf;
		BudgetReportingClientServer.FillInLineInListOfReportElements(ElementData, 
					NewRow, 
					NewRow.AddressOfItemStructure);
		NameOfAuxiliaryData = Undefined;
		If ElementData.ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem Then
			AttributesOfBudgetFlowItem = ElementData.ItemKindAttributes.Find(
				ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.BudgetFlowItem, "Attribute");
			If TypeOf(AttributesOfBudgetFlowItem.Value) = Type("CatalogRef.BudgetBalanceItems") Then
				NameOfAuxiliaryData = "SpecialPurpose";
			EndIf;
		EndIf;
		NewRow.CustomPicture = FinancialReportingCached.CustomPicture(NewRow.ItemKind,
			NameOfAuxiliaryData);
		
		NewRow.PrivilegedModePicture = Not Number(NewRow.PrivilegedMode);
		
	EndDo;
	
	Parameters.Property("ParentItemKind", ParentItemKind);
	
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
		
	If Not Cancel Then
		PrivilegedMode = False;
		Catalogs.FinancialReportItems.FormBeforeWritingToServer(ThisObject, CurrentObject, Cancel);
		If ValueIsFilled(ItemAddressInStorage) Then
			ElementStructure = GetFromTempStorage(ItemAddressInStorage);
			ElementStructure.FormulaOperands.Clear();
			For Each OperandString_ In Operands Do
				If Not ValueIsFilled(OperandString_.AddressOfItemStructure) Then
					OperandString_.AddressOfItemStructure = BudgetReportingClientServer.PlaceItemInStorage(OperandString_, MainStorageID);
				EndIf;
				NewOperandString = ElementStructure.FormulaOperands.Add();
				FillPropertyValues(NewOperandString, OperandString_);
				NewOperandString.Operand = OperandString_.ReportItem;
			EndDo;
			ElementStructure.Insert("ThereIsPrivilegedMode", ThereIsPrivilegedMode);
			PutToTempStorage(ElementStructure, ItemAddressInStorage);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	RefreshFormTitle();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_BudgetBalanceItems" Then
		If ValueIsFilled(Object.Ref) Then
			Read();
		Else
			Object.NameForPrinting = Parameter;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If ValueIsFilled(ItemAddressInStorage) Then
		StandardProcessing = False;
		If Modified And Not ClosingForm_ = True Then
			CallbackDescription = New CallbackDescription("BeforeClosingNotificationProcessing", ThisObject);
			QueryText = NStr("vi = 'Tất cả các thay đổi sẽ bị mất. Đóng mẫu?';
							|ru = 'Все внесенные изменения будут потеряны. Закрыть форму?';
							|en = 'All changes you have made will be lost. Close the form?'; fa = 'All changes you have made will be lost. Close the form?';
							|it = 'Tutte le modifiche apportate andranno perse. Chiudere il modulo?';
							|pl = 'Wszystkie wprowadzone zmiany zostaną utracone. Zamknąć formularz?';
							|tr = 'Yapılan tüm değişiklikler kaybolacak. Form kapatılsın mı?'");
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
			Cancel = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	LimitingLengthOfFormula = Common.ObjectAttributeValue(
		ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.Formula, "ValueType").StringQualifiers.Length;
	If StrLen(Formula) > LimitingLengthOfFormula Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Vượt quá độ dài công thức tối đa, đã nhập %1 ký tự, cho phép %2 ký tự.';
				|ru = 'Превышена максимальная длина формулы, введено %1 символов, доступно %2 символов.';
				|en = 'Maximum formula length exceeded: %1 characters entered, %2 characters available.'; fa = 'Maximum formula length exceeded: %1 characters entered, %2 characters available.';
				|it = 'Superata la lunghezza massima della formula, immessi %1 caratteri, disponibili %2 caratteri.';
				|pl = 'Przekroczono maksymalną długość formuły, wprowadzono %1 symboli, jest dostępne %2 symboli.';
				|tr = 'Aşılan maksimum formül uzunluğu, %1 sembolünde tanımlandı, %2 sembolü mevcut.'"),
			StrLen(Formula),
			LimitingLengthOfFormula);
		Common.MessageToUser(MessageText,,"Formula",,Cancel);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
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
Procedure QuickSearchOfNewClearing(Item, StandardProcessing)
	
	UpdateTreeOfNewElements();
	
EndProcedure

#EndRegion

#Region FormTableEventHandlers

&AtClient
Procedure OperatorsDragStart(Item, DragParameters, Perform)
	
	If ValueIsFilled(Item.CurrentData.StructureToInsert) Then
		DragParameters.Value = Item.CurrentData.StructureToInsert;
	EndIf;
	
	TreeLineSender = "Operators";
	
EndProcedure

&AtClient
Procedure OperatorsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	InsertOperatorIntoFormula();
	
EndProcedure

&AtClient
Procedure NewItemTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	SelectedOperands = New Array;
	SelectedOperands.Add(Item.CurrentData);
	BudgetReportingClientServer.AddFormulaOperands(ThisObject, SelectedOperands, Operands, True);
	
EndProcedure

&AtClient
Procedure NewItemTreeDragStart(Item, DragParameters, Perform)
	
	TreeLineSender = "NewItemTree";
	CurrentData = Item.CurrentData;
	
	If Not BudgetReportingClientServer.ElementIsAvailableAsOperand(CurrentData) Then
		Perform = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure NewItemTreeDragEnd(Item, DragParameters, StandardProcessing)
	
	If DragParameters.Action = DragAction.Cancel Then
		Return;
	EndIf;
	
	If ThisIsDraggingCell(DragParameters.Value) Then
		
		NewOperands = BudgetReportingClientServer.AddFormulaOperands(ThisObject,
				DragParameters.Value,
				Operands,
				False);
		TableCell = PredefinedValue("Enum.FinancialReportItemKinds.TableCell");
		
		For Each NewOperand In NewOperands Do
			
			If NewOperand.ItemKind <> TableCell Then
				Continue;
			EndIf;
			
			NewOperand.AddressOfItemStructure = BudgetReportingClientServer.PlaceItemInStorage(
				NewOperand, MainStorageID);
			
			FormParameters = New Structure();
			FormParameters.Insert("ItemKind", 						 TableCell);
			FormParameters.Insert("UseToEnterPlan",		 UseToEnterPlan);
			FormParameters.Insert("ItemTableAddress", 			 ItemTableAddress);
			FormParameters.Insert("AddressOfReportItems", 			 AddressOfReportItems);
			FormParameters.Insert("ItemAddressInStorage", 			 NewOperand.AddressOfItemStructure);
			FormParameters.Insert("Operand", 							 Operands.IndexOf(NewOperand));
			If TreeMode = PredefinedValue("Enum.ModesOfNewItemTreeDisplay.SetUpAutomaticCalculationOfComplexTable") Then
				FormParameters.Insert("AddressOfEditedItem", 	 AddressOfEditedItem);
			Else
				FormParameters.Insert("AddressOfEditedItem", 	 ItemAddressInStorage);
			EndIf;
			
			Notification = New CallbackDescription("ProcessingCellSelection", ThisObject, FormParameters);
			
			OpenForm("Catalog.FinancialReportItems.ObjectForm",
							FormParameters, ThisObject, , , , Notification, FormWindowOpeningMode.LockOwnerWindow);
			
		EndDo;
		
	Else
		
		NewOperands = BudgetReportingClientServer.AddFormulaOperands(ThisObject,
				DragParameters.Value,
				Operands,
				False);
		FinancialReportingClient.AddFormulaText(ThisObject, NewOperands);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OperatorsDragEnd(Item, DragParameters, StandardProcessing)
	
	OpenAdditionalParametersForm(DragParameters.Value);
	
EndProcedure

&AtClient
Procedure SelectingFormulaTotalType(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		Items.Formula.SelectedText = "TOTAL(<Value>, """ + Result + """)";
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectingDateDifferenceParameters(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		Items.Formula.SelectedText = "DATEDIFF("
			+ Result.BeginOfPeriod + ", "
			+ Result.EndOfPeriod + " , """
			+ FinancialReportingClientServerCached.PeriodicityByString(Result.Periodicity) + """)";
	EndIf;
	
EndProcedure

&AtClient
Procedure OperandsDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	If ThisIsDraggingCell(DragParameters.Value) Then
		
		NewOperands = BudgetReportingClientServer.AddFormulaOperands(ThisObject,
				DragParameters.Value,
				Operands,
				True);
		TableCell = PredefinedValue("Enum.FinancialReportItemKinds.TableCell");
		
		For Each NewOperand In NewOperands Do
			
			If NewOperand.ItemKind <> TableCell Then
				Continue;
			EndIf;
			
			NewOperand.AddressOfItemStructure = BudgetReportingClientServer.PlaceItemInStorage(NewOperand, MainStorageID);
			
			FormParameters = New Structure();
			FormParameters.Insert("ItemKind", 						 TableCell);
			FormParameters.Insert("UseToEnterPlan",		 UseToEnterPlan);
			FormParameters.Insert("ItemTableAddress", 			 ItemTableAddress);
			FormParameters.Insert("AddressOfReportItems", 			 AddressOfReportItems);
			FormParameters.Insert("ItemAddressInStorage", 			 NewOperand.AddressOfItemStructure);
			FormParameters.Insert("Operand", 							 Operands.IndexOf(NewOperand));
			FormParameters.Insert("DoNotSetFormulaText", 		 True);
			If TreeMode = PredefinedValue("Enum.ModesOfNewItemTreeDisplay.SetUpAutomaticCalculationOfComplexTable") Then
				FormParameters.Insert("AddressOfEditedItem", 		AddressOfEditedItem);
			Else
				FormParameters.Insert("AddressOfEditedItem", 		ItemAddressInStorage);
			EndIf;
			
			Notification = New CallbackDescription("ProcessingCellSelection", ThisObject, FormParameters);
		
			OpenForm("Catalog.FinancialReportItems.ObjectForm",
				FormParameters, ThisObject,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
			
		EndDo;
		
	Else
		
		BudgetReportingClientServer.AddFormulaOperands(ThisObject,
				DragParameters.Value,
				Operands,
				True);
		
	EndIf;
	
	// to avoid triggering the end event of dragging the tree of new elements
	DragParameters.Value.Clear();
	
EndProcedure

&AtClient
Procedure OperandsDragEnd(Item, DragParameters, StandardProcessing)
	
	If DragParameters.Action = DragAction.Cancel Then
		Return;
	EndIf;
	
	FinancialReportingClient.AddFormulaText(ThisObject, DragParameters.Value);
	
EndProcedure

&AtClient
Procedure AddToFormula(Command)
	CurrentData = Items.Operands.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	NewOperands = New Array;
	NewOperands.Add(CurrentData);
	FinancialReportingClient.AddFormulaText(ThisObject, NewOperands);
EndProcedure

&AtClient
Procedure OperandsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name <> "MetricsID" Then
		EditMetric();
	EndIf;
	
EndProcedure

&AtClient
Procedure OperandsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	If DuplicateID And Not CancelEdit Then
		Cancel = True;
	EndIf;
EndProcedure

&AtClient
Procedure OperandsIDEndOfTextInput(Item, Text, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	// Let's check the uniqueness of the identifiers
	SourceID_ = Items.Operands.CurrentData.Id;
	NewID1 = Text;
	
	FoundRows = Operands.FindRows(New Structure("Id", NewID1));
	If FoundRows.Count() > 0 Then
		WarningText = NStr("vi = 'Id trùng lặp ""%1"".';
							|ru = 'Дублирующий идентификатор ""%1"".';
							|en = 'The ""%1"" duplicate ID.'; fa = 'The ""%1"" duplicate ID.';
							|it = 'Identificativo duplicato ""%1"".';
							|pl = 'Duplikujący się identyfikator ""%1"".';
							|tr = 'Tekrarlanan tanımlayıcı: ""%1"".'");
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			WarningText,
			NewID1);
		ShowMessageBox(, WarningText);
		
		DuplicateID = True;
		
		Return;
	Else
		DuplicateID = False;
	EndIf;
	
	// Update the identifiers in the formula
	ChoiceData = New ValueList;
	ChoiceData.Add(NewID1);
	
	Items.Operands.CurrentData.Id = NewID1;
	
	Text = TrimAll(Text);
	OriginalIDExpression = "[" + SourceID_ + "]";
	NewIDExpression = "[" + NewID1 + "]";
	Formula = StrReplace(Formula, OriginalIDExpression, NewIDExpression);
	
EndProcedure

&AtClient
Procedure OperandsDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	If TreeLineSender <> "NewItemTree" Then
		StandardProcessing = False;
		DragParameters.Action = DragAction.Cancel;
	EndIf;
	
EndProcedure

&AtClient
Procedure OperandsDragStart(Item, DragParameters, Perform)
	
	TreeLineSender = "Operands";
	
EndProcedure

&AtClient
Procedure OperandsOnActivateRow(Item)
	
	Items.OperandsLockVertically.Enabled = False;
	Items.OperandsLockHorizontally.Enabled = False;
	
	CurrentData = Items.Operands.CurrentData;
	If CurrentData <> Undefined And
		CurrentData.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.TableCell") Then
		
		Items.OperandsLockVertically.Enabled = True;
		Items.OperandsLockHorizontally.Enabled = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	ThereIsPrivilegedMode = Operands.FindRows(New Structure("PrivilegedMode",True)).Count() > 0;
	AdditionalInfo = New Structure();
	AdditionalInfo.Insert("ThereIsPrivilegedMode", ThereIsPrivilegedMode);
	FinancialReportingClient.FinishEditingReportElement(ThisObject, AdditionalInfo);
	
EndProcedure

&AtClient
Procedure FindNewItem(Command)
	
	UpdateTreeOfNewElements();
	
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
		ShowMessageBox(, WarningText);
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

&AtClient
Procedure LockHorizontally(Command)
	
	DoNotOffsetWhenCopyingToServer(True, False);
	
EndProcedure

&AtClient
Procedure LockVertically(Command)
	
	DoNotOffsetWhenCopyingToServer(False, True);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure BeforeClosingNotificationProcessing(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		ClosingForm_ = True;
		ThisObject.Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckFormulaServer(Cancel)
	
	BudgetReportingDisplayServer.CheckFormula(Formula, Operands.Unload(), Cancel);
	
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

&AtServer
Procedure UpdateTreeOfNewElements()
	
	TreeParameters = New Structure;
	TreeParameters.Insert("NameOfTreeElement", "NewItemTree");
	TreeParameters.Insert("QuickSearch", QuickSearchOfNew);
	TreeParameters.Insert("TreeMode", TreeMode);
	TreeParameters.Insert("BudgetingModel", Object.Owner);
	TreeParameters.Insert("LineIDOfReportItem", LineIDOfReportItem);
	TreeParameters.Insert("UseToEnterPlan", UseToEnterPlan);
	TreeParameters.Insert("EditedValues", EditedValues);
	
	BudgetReportingServerCall.UpdateTreeOfNewElements(ThisObject, TreeParameters);
	
EndProcedure

&AtClient
Procedure OpenAdditionalParametersForm(FormulaText)
	
	FormParameters = New Structure();
	FormParameters.Insert("ItemTableAddress", ItemTableAddress);
	FormParameters.Insert("AddressOfReportItems", AddressOfReportItems);
	If ValueIsFilled(AddressOfEditedItem) Then
		FormParameters.Insert("AddressOfEditedItem", AddressOfEditedItem);
	Else
		FormParameters.Insert("AddressOfEditedItem", ItemAddressInStorage);
	EndIf;
	If StrFind(FormulaText, "TOTAL(") Then
		Notification = New CallbackDescription("SelectingFormulaTotalType", ThisObject);
		OpenForm("Catalog.FinancialReportItems.Form.SelectTotalDimensions",
			FormParameters, ThisObject,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	ElsIf StrFind(FormulaText, "DATEDIFF(") Then
		Notification = New CallbackDescription("SelectingDateDifferenceParameters", ThisObject);
		OpenForm("Catalog.FinancialReportItems.Form.SelectParametersDataDifference",
			FormParameters, ThisObject,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertOperatorIntoFormula()
	
	If ValueIsFilled(Items.Operators.CurrentData.StructureToInsert) Then
		TextForInsert = Items.Operators.CurrentData.StructureToInsert;
		If Items.Operators.CurrentData.Id = "( )" 
			And ValueIsFilled(Items.Formula.SelectedText) Then
			TextForInsert = "(" + Items.Formula.SelectedText + ")";
		EndIf;
		FirstRow = 0;
		FirstColumn = 0;
		LastRow = 0;
		LastColumn = 0;
		Items.Formula.GetTextSelectionBounds(FirstRow,
			FirstColumn, LastRow, LastColumn);
		Items.Formula.SelectedText = TextForInsert;
		Items.Formula.SetTextSelectionBounds(FirstRow,
			FirstColumn, FirstRow, FirstColumn + StrLen(TextForInsert));
		OpenAdditionalParametersForm(TextForInsert);
	EndIf;
	
EndProcedure


// Returns a row in the Operands table.
// 
// Parameters:
// 	RowIndex - Number - 
// Returns:
// 	FormDataCollectionItem - :
// 	 *ReportItem - CatalogRef.FinancialReportItems -
// 	 *Id - String -
// 	 *NameForPrinting - String -
// 	 *CustomPicture - Number - 
// 	 *ItemKind - EnumRef.FinancialReportItemKinds -
// 	 *HasSettings - Boolean -
// 	 *AddressOfItemStructure - String -
// 	 *Comment - String -
// 	 *DisplayedIndicators - EnumRef.TypesOfDisplayedBudgetReportIndicators -
// 	 *IndicatorValueType - EnumRef.ValueTypesOfBudgetReportIndicators -
// 	 *ReverseSign - Boolean - 
// 	 *ItemIndicatorDimensionType - CatalogRef.BudgetFlowItems -
// 	 								- EnumRef.Periodicity -
// 	 								- CatalogRef.BudgetBalanceItems -
// 	 								- String -
// 	 								- ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions -
// 	 								- CatalogRef.NonFinancialItemsOfBudgets -
// 	 								- CatalogRef.BudgetingScenarios - 
// 	 *PrivilegedModePicture - Number -
// 	 *PrivilegedMode - Boolean -
// 	
&AtClient
Function OperandStringByStringIndex(RowIndex)
	Return Operands[RowIndex];
EndFunction

&AtClient
Procedure ProcessingCellSelection(Result, AdditionalParameters) Export
	
	Operand = AdditionalParameters.Operand;
	If Result = Undefined Then
		Operands.Delete(Operand);
		Items.Formula.SelectedText = "";
		Return;
	EndIf;
	
	Operand = OperandStringByStringIndex(Operand);
	Operand.Id = BudgetReportingClientServer.OperandName(Result.CellName, Operand, Operands, False);
	For Each OperandString_ In Operands Do
		If OperandString_.Id = Operand.Id 
			And OperandString_.AddressOfItemStructure <> Operand.AddressOfItemStructure Then
			Operands.Delete(Operand);
			Break;
		EndIf;
	EndDo;
	
	If Not AdditionalParameters.Property("DoNotSetFormulaText") Then
		Array = New Array;
		Array.Add(Operand);
		FinancialReportingClient.AddFormulaText(ThisObject, Array);
	EndIf;
	
EndProcedure

&AtClient
Function ThisIsDraggingCell(Value)
	
	For Each DragAndDropString In Value Do
		If DragAndDropString.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.TableCell") Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtClient
Procedure EditMetric()
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.Operands);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CurrentData = Items.Operands.CurrentData;
	
	If IsBlankString(CurrentData.AddressOfItemStructure) Then
		CurrentData.AddressOfItemStructure = BudgetReportingClientServer.PlaceItemInStorage(CurrentData, MainStorageID);
	EndIf;
	
	FormParameters = New Structure();
	FormParameters.Insert("Key", 							CurrentData.ReportItem);
	FormParameters.Insert("ItemKind", 						CurrentData.ItemKind);
	FormParameters.Insert("ItemAddressInStorage", 			CurrentData.AddressOfItemStructure);
	FormParameters.Insert("MainStorageID", 	MainStorageID);
	FormParameters.Insert("UseToEnterPlan", 		UseToEnterPlan);
	FormParameters.Insert("ArbitraryIndicator", 			True);
	FormParameters.Insert("AddressOfReportItems", 			AddressOfReportItems);
	FormParameters.Insert("ItemTableAddress", 			ItemTableAddress);
	If ValueIsFilled(AddressOfEditedItem) Then
		FormParameters.Insert("AddressOfEditedItem", AddressOfEditedItem);
	Else
		FormParameters.Insert("AddressOfEditedItem", ItemAddressInStorage);
	EndIf;
	FormParameters.Insert("LocationOptionOfActualDataOffset", LocationOptionOfActualDataOffset);
	If Not ParentItemKind = PredefinedValue("Enum.FinancialReportItemKinds.BudgetFlowItem") Then
		// If the Derived indicator does not belong to the Budget Item, then the flag "Exclude data from the year of the document calculation" is displayed.
		FormParameters.Insert("ParentItemKind",
			PredefinedValue("Enum.FinancialReportItemKinds.DerivedItem"));
	EndIf;
	FormParameters.Insert("UseStatusFilter", UseStatusFilter);
	
	Notification = New CallbackDescription("UpdateBudgetViewLineAfterChange", ThisObject, FormParameters);
	
	OpenForm("Catalog.FinancialReportItems.ObjectForm",
		FormParameters, ThisObject,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure UpdateBudgetViewLineAfterChange(Result, AdditionalParameters) Export
	
	BudgetReportingClientServer.FillInLineInListOfReportElements(Result, 
					Items.Operands.CurrentData,
					AdditionalParameters.ItemAddressInStorage, 
					Operands);
		
	CurrentData = Items.Operands.CurrentData;
	CurrentData.PrivilegedModePicture = Not Number(CurrentData.PrivilegedMode);
		
EndProcedure

&AtServer
Procedure DoNotOffsetWhenCopyingToServer(Horizontal, Vertical)
	
	CellSeparator = BudgetReportingClientServer.CellSeparatorForComplexTable();
	
	StringOfOperands = Operands.FindByID(Items.Operands.CurrentRow);
	Id = StringOfOperands.Id;
	IDParameters = Catalogs.FinancialReportItems.ParseOperandNameIntoComponents(Id);
	
	If Horizontal Then
		IDParameters.FixedColumn = Not IDParameters.FixedColumn;
		If Not ValueIsFilled(IDParameters.Column) Then
			IDParameters.StringIsFixed = IDParameters.FixedColumn;
		EndIf;
	EndIf;
	
	If Vertical Then
		IDParameters.StringIsFixed = Not IDParameters.StringIsFixed;
	EndIf;
	
	Text = ?(IDParameters.StringIsFixed, "$", "") + IDParameters.String;
	If ValueIsFilled(IDParameters.Column) Then
		Text = Text + CellSeparator + ?(IDParameters.FixedColumn, "$", "") + IDParameters.Column;
	EndIf;
	
	StringOfOperands.Id = Text;
	
	Text = TrimAll(Text);
	NewID = "[" + Text + "]";
	OldID_ = "[" + Id + "]";
	Formula = StrReplace(Formula, OldID_, NewID);
	
EndProcedure

#EndRegion
