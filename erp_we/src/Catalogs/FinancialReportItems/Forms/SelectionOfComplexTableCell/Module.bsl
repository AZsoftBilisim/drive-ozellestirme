
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.Property("ItemTableAddress")
		Or Not Parameters.Property("AddressOfReportItems")
		Or Not Parameters.Property("UseToEnterPlan", UseToEnterPlan)
		Or Not Parameters.Property("AddressOfEditedItem", AddressOfEditedItem) Then
		
		MessageText = NStr("vi = 'Không cho phép mở trực tiếp biểu mẫu này.';
							|ru = 'Непосредственное открытие этой формы не предусмотрено.';
							|en = 'Application cannot open this form explicitly.'; fa = 'Application cannot open this form explicitly.';
							|it = 'L''apertura diretta di questo modulo non è prevista.';
							|pl = 'Bezpośrednie otwieranie tego formularza nie jest przewidziane.';
							|tr = 'Bu formun doğrudan açılması sağlanamadı.'");
		Raise MessageText;
	EndIf;
	
	Catalogs.FinancialReportItems.FormWhenCreatedOnServer(ThisObject);
	ValueToFormAttribute(GetFromTempStorage(Parameters.ItemTableAddress), "TableItems");
	
	Items.FormCompleteEditing.Title = NStr("vi = 'Chọn';
											|ru = 'Выбрать';
											|en = 'Select'; fa = 'انتخاب';
											|it = 'Selezionare';
											|pl = 'Select';
											|tr = 'Seç'");
	
	ThisIsASimpleTable = False;
	
	Header = FormAttributeToValue("Object").GetTemplate("CellSetupLegend");
	ReportPresentation.Clear();
	ReportPresentation.Put(Header.GetArea("SelectionAreaLegend"));
	
	ReportItemTree = GetFromTempStorage(Parameters.AddressOfReportItems);
	ValueToFormAttribute(ReportItemTree, "ReportItems");
	StructureOfWidths = Catalogs.FinancialReportItems.OutputComplexTableSetupTable(
		ThisObject, ReportItemTree);
	
	TemplateWidth = StructureOfWidths.MWidthOfTemplate;
	TemplateHeight = StructureOfWidths.MTemplateHeight;
	HeaderHeight = StructureOfWidths.MCapHeight;
	MergeDepth = BudgetReportingCacheCalculationServer.CalculateDepthOfLevels(ReportItemTree);
	
	EditableCell = TableItems.FindRows(New Structure("Item", AddressOfEditedItem))[0];
	
	AvailableControls = New Map;
	
	StartOfCalculation = FinancialReportingServer.SubordinateItem(
		ReportItemTree, "AddressOfItemStructure", EditableCell.String);
	CalculateAvailableParentElements(AvailableControls, StartOfCalculation);
	
	StartOfCalculation = FinancialReportingServer.SubordinateItem(
		ReportItemTree, "AddressOfItemStructure", EditableCell.Column);
	CalculateAvailableParentElements(AvailableControls, StartOfCalculation);

	AvailableItems = New FixedMap(AvailableControls);
	
	CalculateCellAvailability();

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Catalogs.FinancialReportItems.FormBeforeWritingToServer(ThisObject, CurrentObject, Cancel);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReportPresentationSelection(Item, Area, StandardProcessing)
	
	StandardProcessing = False;
	CompleteEditing(Undefined);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	Area = Items.ReportPresentation.CurrentArea;
	
	Details = DecodingTabularDocumentArea(Area);
	DecodingIsStructure = (TypeOf(Details) = Type("Structure"));
	
	If Area.Left <> Area.Right
		Or Area.Top <> Area.Bottom
		Or Not DecodingIsStructure
		Or Not Area.Details.Property("AvailableForSelection")
		Or Not Area.Details.AvailableForSelection Then
		
		If Not DecodingIsStructure Or Not Area.Details.Property("CellType") Then
			
			WarningText = NStr("vi = 'Khu vực này không có sẵn để lựa chọn.';
								|ru = 'Область недоступна для выбора.';
								|en = 'Area cannot be selected.'; fa = 'Area cannot be selected.';
								|it = 'Area non disponibile per la selezione.';
								|pl = 'Obszar nie może zostać wybrany.';
								|tr = 'Alan seçime müsait değil.'");
			
		ElsIf Area.Details.Property("CellType") Then
			
			If Area.Details.CellType = -1 Then // The type of element is not specified
				WarningText = NStr("vi = 'Ô không có sẵn vì nó không có loại được chọn.';
									|ru = 'Ячейка не доступна, так как у нее не выбран тип.';
									|en = 'Bin is not available since its type is not selected.'; fa = 'Bin is not available since its type is not selected.';
									|it = 'Cella non disponibile, poiché non è stato selezionato il suo tipo.';
									|pl = 'Komórka jest niedostępna, ponieważ nie wybrano typu.';
									|tr = 'Tür seçili olmadığı için hücre erişilebilir değil.'");
			ElsIf Area.Details.CellType = 0 Then // Not available for selection
				WarningText = NStr("vi = 'Khu vực này không có sẵn để lựa chọn.';
									|ru = 'Область недоступна для выбора.';
									|en = 'Area cannot be selected.'; fa = 'Area cannot be selected.';
									|it = 'Area non disponibile per la selezione.';
									|pl = 'Obszar nie może zostać wybrany.';
									|tr = 'Alan seçime müsait değil.'");
			ElsIf Area.Details.CellType = 2 Then // Current selected cell
				WarningText = NStr("vi = 'Đã chọn ô hiện tại.';
									|ru = 'Текущая ячейка уже выбрана.';
									|en = 'The current bin is already selected.'; fa = 'The current bin is already selected.';
									|it = 'La cella corrente è già selezionata.';
									|pl = 'Bieżąca komórka została już wybrana.';
									|tr = 'Mevcut hücre zaten seçildi.'");
			ElsIf Area.Details.CellType = 3 Then // Source cell
				WarningText = NStr("vi = 'Ô hiện tại không thể được chọn làm toán hạng cho chính nó.';
									|ru = 'Текущая ячейка не может быть выбрана в качестве операнда для самой себя.';
									|en = 'The current bin cannot be selected as an operand for itself.'; fa = 'The current bin cannot be selected as an operand for itself.';
									|it = 'La cella corrente non può essere selezionata come operando per se stessa.';
									|pl = 'Bieżąca komórka nie może zostać wybrana jako operand dla siebie samej.';
									|tr = 'Mevcut hücre kendisi için bir işlenen olarak seçilemez.'");
			EndIf;
			
		EndIf;
		
		ShowMessageBox(, WarningText);
		Return;
		
	EndIf;
	
	CellRow = Undefined;
	CellColumn = Undefined;
		
	CellName = "";
	If DecodingIsStructure Then
		CellRow = Details["String"].ReportItem;
		CellColumn = Details["Column"].ReportItem;
		CellName = Details["String"]["Description"] + BudgetReportingClientServer.CellSeparatorForComplexTable()
			+ " " + Details["Column"]["Description"];
	EndIf;
	
	AdditionalParameters = New Structure("CellName", CellName);
	
	FinancialReportingClient.FinishEditingReportElement(ThisObject, AdditionalParameters);
	
EndProcedure


&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private


// Described returns the value of the decoding region of the tabular document.
// 
// Parameters:
// 	Area - SpreadsheetDocumentRange - 
// Returns:
// 	Structure - Decryption structure:
// 	 *String - Structure -:
// 	   **Description - String -
// 	   **ReportItem - CatalogRef.FinancialReportItems, String - The report item or the address of a temporary storage.
// 	 *Column - Structure -:
// 	   **Description - String -
// 	   **ReportItem - CatalogRef.FinancialReportItems, String - The report item or the address of a temporary storage.
// 	 *ItemKind - EnumRef.FinancialReportItemKinds -
// 	 *ReportItem - CatalogRef.FinancialReportItems, String - The report item or the address of a temporary storage.
// 	 *ThisIsReference - Boolean -
// 	
&AtClient
Function DecodingTabularDocumentArea(Area)
	Return Area.Details;
EndFunction

&AtServer
Procedure AugmentAvailableElementsWithSubordinates(AvailableLines, StartOfCalculation, FixedOnly = False)
	
	For Each Item In StartOfCalculation.Rows Do
		If FixedOnly And Not BudgetReportingCacheCalculationServer.ThisIsFixedElement(Item) Then
			Continue;
		EndIf;
		
		AvailableLines.Insert(Item.AddressOfItemStructure, True);
		AugmentAvailableElementsWithSubordinates(AvailableLines, Item, FixedOnly);
			
	EndDo;
	
EndProcedure

&AtServer
Procedure CalculateAvailableParentElements(AvailableItems, StartOfCalculation)
	
	// all "fixed" columns of the current and upper levels are available
	InOrderOfParentsThereWasEnumeratedType = Not BudgetReportingCacheCalculationServer.ThisIsFixedElement(StartOfCalculation);
	CurrentParent = StartOfCalculation.Parent;
	While True Do
		
		AvailableItems.Insert(CurrentParent.AddressOfItemStructure, True);
		
		For Each CurLevelElement In CurrentParent.Rows Do
			
			ThisIsCurColumn = CurLevelElement.AddressOfItemStructure = StartOfCalculation.AddressOfItemStructure;
			If BudgetReportingCacheCalculationServer.ThisIsFixedElement(CurLevelElement)
				Or ThisIsCurColumn Then
				
				AvailableItems.Insert(CurLevelElement.AddressOfItemStructure, True);
				AugmentAvailableElementsWithSubordinates(AvailableItems,
							CurLevelElement,
							InOrderOfParentsThereWasEnumeratedType
							And Not ThisIsCurColumn);
				
			EndIf;
			
		EndDo;
		
		If CurrentParent.ItemKind = Enums.FinancialReportItemKinds.Rows
			Or CurrentParent.ItemKind = Enums.FinancialReportItemKinds.Columns Then
			Return;
		EndIf;
		
		InOrderOfParentsThereWasEnumeratedType = InOrderOfParentsThereWasEnumeratedType
				Or Not BudgetReportingCacheCalculationServer.ThisIsFixedElement(CurrentParent);
		
		CurrentParent = CurrentParent.Parent;
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function GetEditingArea(Form)
	
	Result = New Structure;
	Result.Insert("Top",  Form.FirstRow + Form.HeaderHeight + 1); //the first line after the header
	Result.Insert("Left",  2 + Form.MergeDepth);               //all lines are in the second column, so we edit from the third column
	Result.Insert("Bottom",   Form.FirstRow + Form.TemplateHeight);    //up to the last line
	Result.Insert("Right", 2 + Form.MergeDepth - 1 + Form.TemplateWidth); //up to the last column
	
	Return Result;
	
EndFunction

// Returns the cell type.
// 
// Parameters:
// 	CellDescription - See DecodingTabularDocumentArea
// Returns:
// 	Number - tia of the cell.
// 		1 - the type of element is not specified.
// 		0 - not available for selection.
// 		1 - available for selection.
// 		2 - the currently selected cell.
// 		3 is the source cell.
&AtServer
Function CellType(CellDescription)
	
	If CellDescription.String.ReportItem = CellRow
		And CellDescription.Column.ReportItem = CellColumn Then
		Return 2;
	EndIf;
	
	If Not ValueIsFilled(CellDescription.ReportItem) Then
		Return -1;
	EndIf;
	
	If CellDescription.ReportItem = AddressOfEditedItem Then
		Return 3;
	EndIf;
	
	AvailableTimeElements = AvailableItems; // FixedMap
	If AvailableTimeElements.Get(CellDescription.String.ReportItem) <> True Then
		Return 0;
	EndIf;
	
	If AvailableTimeElements.Get(CellDescription.Column.ReportItem) <> True Then
		Return 0;
	EndIf;
	
	Return 1;
	
EndFunction

&AtServer
Procedure CalculateCellAvailability()
	
	LocalCache = New Structure;
	
	EditingArea = GetEditingArea(ThisObject);
	For Column = EditingArea.Left To EditingArea.Right Do
		For String = EditingArea.Top To EditingArea.Bottom Do
			Area = ReportPresentation.Area(String, Column);
			CellDescription = Area.Details;
			CellType = CellType(CellDescription);
			CellDescription.Insert("AvailableForSelection", CellType = 1);
			CellDescription.Insert("CellType", CellType);
			If CellType = -1 Then
				Area.TextColor = 
					BudgetReportingClientServer.GetStyleColor(LocalCache, "InaccessibleCellTextColor");
				Area.HorizontalAlign	 = HorizontalAlign.Center;
				Area.VerticalAlign	 = VerticalAlign.Center;
			Else
				Area.HorizontalAlign	 = HorizontalAlign.Left;
				Area.VerticalAlign	 = VerticalAlign.Top;
				If CellType = 0 Then
					Area.TextColor = 
						BudgetReportingClientServer.GetStyleColor(LocalCache, "InaccessibleCellTextColor");
				ElsIf CellType = 2 Then
					Area.BackColor = New Color(201, 226, 255);
				ElsIf CellType = 3 Then
					Area.BackColor = 
						BudgetReportingClientServer.GetStyleColor(LocalCache, "FieldSelectionBackColor");
					Area.TextColor = 
						BudgetReportingClientServer.GetStyleColor(LocalCache, "FieldSelectedTextColor");
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion
