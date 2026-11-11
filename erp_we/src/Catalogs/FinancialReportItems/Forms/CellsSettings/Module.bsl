
#Region Variables

&AtClient
Var MCopyPasteCache;

&AtClient
Var ClosingForm_;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FormData1 = Catalogs.FinancialReportItems.FormWhenCreatedOnServer(ThisForm);
	ValueToFormAttribute(FormData1.TableItems, "TableItems");
	
	MainStorageID = Parameters.MainStorageID;
	UseToEnterPlan = Parameters.UseToEnterPlan;
	LocationOptionOfActualDataOffset = Parameters.LocationOptionOfActualDataOffset;
	EditedValues = Parameters.EditedValues;
	AdjustEditableValuesToCurTableElements();
	If Parameters.Property("UseStatusFilter") Then
		UseStatusFilter = Parameters.UseStatusFilter;
	ElsIf Parameters.Property("BudgetingModel") Then
		UseStatusFilter = Common.ObjectAttributeValue(Parameters.BudgetingModel,
			"UseBudgetConfirmation");
	EndIf;
	
	If Parameters.Property("CheckTableView") Then
		TableType = Undefined;
		Parameters.Property("TableType", TableType);
		If TableType = Enums.FinancialReportItemKinds.TableIndicatorsInColumns
		 Or TableType = Enums.FinancialReportItemKinds.TableIndicatorsInRows Then
			ThisIsASimpleTable = True;
		EndIf;
	EndIf;
	
	Header = FormAttributeToValue("Object").GetTemplate("CellSetupLegend");
	ReportPresentation.Clear();
	
	If ThisIsASimpleTable Then
		Items.ReportPresentationContextMenuCut.Visible = False;
		Items.ReportPresentationContextMenuCut.Enabled = False;
		Items.ReportPresentationContextMenuCopy.Visible = False;
		Items.ReportPresentationContextMenuCopy.Enabled = False;
		Items.ReportPresentationContextMenuInsert.Visible = False;
		Items.ReportPresentationContextMenuInsert.Enabled = False;
		Items.ReportPresentationContextMenuClear.Visible = False;
		Items.ReportPresentationContextMenuClear.Enabled = False;
		Items.ReportPresentationContextMenuProperties.Visible = False;
		Items.ReportPresentationContextMenuProperties.Enabled = False;
	ElsIf Not ThisIsASimpleTable Then
		Legend = Header.GetArea(?(UseToEnterPlan, "LegendOfInputArea", "LegendOfRegion"));
		ReportPresentation.Put(Legend);
	EndIf;
	
	ReportRow = Parameters.ReportItems.FindByID(Parameters.LineIDOfReportItem);
	LineIDOfReportItem = ReportRow.AddressOfItemStructure;
	ItemsTree = FormDataToValue(Parameters.ReportItems, Type("ValueTree"));
	CopyOfElementTree = ItemsTree.Copy();
	CopyOfElementTree.Rows.Clear();
	
	TreeRow = FinancialReportingServer.ElementTable(ItemsTree, ItemAddressInStorage);
	If TreeRow = Undefined Then
		Raise NStr("vi = 'Sai tham số dữ liệu thiết lập ô';
					|ru = 'Неверные параметры данных настройки ячеек';
					|en = 'Incorrect parameters of cell setting data'; fa = 'Incorrect parameters of cell setting data';
					|it = 'Parametri dei dati dell''impostazione delle celle errati';
					|pl = 'Nieprawidłowe parametry danych ustawień komórek';
					|tr = 'Geçersiz hücre ayar veri parametreleri'")
	EndIf;
	
	InstallationParameters = FinancialReportingServer.TemplateForNewParentInstallationOptions();
	InstallationParameters.LoopControl = False;
	FinancialReportingServer.SetNewParent(TreeRow, CopyOfElementTree, InstallationParameters);
	
	StructureOfWidths = Catalogs.FinancialReportItems.OutputComplexTableSetupTable(
				ThisForm, CopyOfElementTree);
	
	AddressOfReportItems = PutToTempStorage(CopyOfElementTree, UUID);
	
	TemplateWidth = StructureOfWidths.MWidthOfTemplate;
	TemplateHeight = StructureOfWidths.MTemplateHeight;
	HeaderHeight = StructureOfWidths.MCapHeight;
	MergeDepth = BudgetReportingCacheCalculationServer.CalculateDepthOfLevels(CopyOfElementTree);
	
	ElementStructure  = GetFromTempStorage(ItemAddressInStorage); // See FinancialReportingClientServer.ReportElementStructure
	For Each DesignElementString In ElementStructure.AppearanceItems Do
		
		NewRow = ListOfDesignElements.Add();
		NewRow.AppearanceItemKey = DesignElementString.AppearanceItemKey;
		NewRow.CreatedAreaType  = DesignElementString.CreatedAreaType;
		
		NewRow.StorageCondition    = PutToTempStorage(DesignElementString.Condition.Get(), UUID);
		NewRow.StorageDesign = PutToTempStorage(DesignElementString.Appearance.Get(), UUID);
		
		TheStructureOfTheSearch = New Structure("AppearanceItemKey", NewRow.AppearanceItemKey);
		
		TableOfFormalizedElements = ElementStructure.RegisteredRows.Copy(TheStructureOfTheSearch);
		NewRow.StorageLinesToBeFormed  = PutToTempStorage(TableOfFormalizedElements, UUID);
		
		TableOfFormalizedElements = ElementStructure.DesigningColumns.Copy(TheStructureOfTheSearch);
		NewRow.CustomColumnsStorage = PutToTempStorage(TableOfFormalizedElements, UUID);
		
		TableOfFormalizedElements = ElementStructure.DrillDownOfAppearanceItemFilterFields.Copy(TheStructureOfTheSearch);
		NewRow.DecryptionOfEStorageSelectionFields = PutToTempStorage(TableOfFormalizedElements, UUID);
		
		FillInPresentationLines(NewRow);
		
	EndDo;
	
	UpdateConditionalAppearanceLineNumbers();
	
	FormControl();
	SetVisibilityOfDesignElements();
	
	SetCellColor();
	
	AppearanceItemVisibility = False;
	
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EditingArea = GetEditingArea(ThisForm);
	Total = EditingArea.Right - EditingArea.Left + 1;
	
	If Total Then
		WidthOccupied = 0;
		For Cnt = 1 To EditingArea.Left - 1 Do
			WidthOccupied = WidthOccupied + ReportPresentation.Area(,Cnt,,Cnt).ColumnWidth;
		EndDo;
		TotalWidth = 120; // recommended table width
		WidthFreely = TotalWidth - WidthOccupied;
		RecommendedColumnWidth = Max(Min(WidthFreely / Total, 30), 15);
		
		For Cnt = EditingArea.Left To EditingArea.Right Do
			ReportPresentation.Area(,Cnt,,Cnt).ColumnWidth = RecommendedColumnWidth;
		EndDo;
	EndIf;
	
	ReportPresentation.FixedTop = GetEditingArea(ThisForm).Top - 1;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Catalogs.FinancialReportItems.FormBeforeWritingToServer(ThisForm, CurrentObject, Cancel);
	If ValueIsFilled(ThisForm.ItemAddressInStorage) Then
		
		ElementStructure = GetFromTempStorage(ThisForm.ItemAddressInStorage); // See FinancialReportingClientServer.ReportElementStructure
		AddressInStorage = ReportItems();
		ElementStructure.TableItems = GetFromTempStorage(AddressInStorage);
		
		ElementStructure.AppearanceItems.Clear();
		ElementStructure.RegisteredRows.Clear();
		ElementStructure.DesigningColumns.Clear();
		ElementStructure.DrillDownOfAppearanceItemFilterFields.Clear();
		
		For Each ConditionalAppearanceString In ListOfDesignElements Do
			
			NewDesignElement = ElementStructure.AppearanceItems.Add();
			FillPropertyValues(NewDesignElement, ConditionalAppearanceString);
			NewDesignElement.Appearance = New ValueStorage(
						GetFromTempStorage(ConditionalAppearanceString.StorageDesign));
			NewDesignElement.Condition = New ValueStorage(
						GetFromTempStorage(ConditionalAppearanceString.StorageCondition));
			
			Table = GetFromTempStorage(ConditionalAppearanceString.StorageLinesToBeFormed);
			If Table.Columns.Find("AppearanceItemKey") = Undefined Then
				Table.Columns.Add("AppearanceItemKey");
			EndIf;
			Table.FillValues(ConditionalAppearanceString.AppearanceItemKey, "AppearanceItemKey");
			CommonClientServer.SupplementTable(Table, ElementStructure.RegisteredRows);
			
			Table = GetFromTempStorage(ConditionalAppearanceString.CustomColumnsStorage);
			If Table.Columns.Find("AppearanceItemKey") = Undefined Then
				Table.Columns.Add("AppearanceItemKey");
			EndIf;
			Table.FillValues(ConditionalAppearanceString.AppearanceItemKey, "AppearanceItemKey");
			CommonClientServer.SupplementTable(Table, ElementStructure.DesigningColumns);
			
			Table = GetFromTempStorage(ConditionalAppearanceString.DecryptionOfEStorageSelectionFields);
			If Table.Columns.Find("AppearanceItemKey") = Undefined Then
				Table.Columns.Add("AppearanceItemKey");
			EndIf;
			Table.FillValues(ConditionalAppearanceString.AppearanceItemKey, "AppearanceItemKey");
			CommonClientServer.SupplementTable(Table, ElementStructure.DrillDownOfAppearanceItemFilterFields);
			
		EndDo;
		
		PutToTempStorage(ElementStructure, ThisForm.ItemAddressInStorage);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	StandardProcessing = False;
	If Modified And Not ClosingForm_ = True Then
		CallbackDescription = New CallbackDescription("BeforeClosingNotificationProcessing", ThisForm);
		QueryText = NStr("vi = 'Sẽ mất tất cả các thay đổi. Đóng biểu mẫu?';
						|ru = 'Все внесенные изменения будут потеряны. Закрыть форму?';
						|en = 'All changes you have made will be lost. Close the form?'; fa = 'All changes you have made will be lost. Close the form?';
						|it = 'Tutte le modifiche apportate andranno perse. Chiudere il modulo?';
						|pl = 'Wszystkie wprowadzone zmiany zostaną utracone. Zamknąć formularz?';
						|tr = 'Yapılan tüm değişiklikler kaybolacak. Form kapatılsın mı?'");
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PresentationOfCellUseOptionStartChoice(Item, ChoiceData, StandardProcessing)
	
	Modified = True;
	StandardProcessing = False;
	CallbackDescription = New CallbackDescription("SelectElementType", ThisForm);
	
	FormParameters = New Structure();
	FormParameters.Insert("UseToEnterPlan", UseToEnterPlan);
	OpenForm("Catalog.FinancialReportItems.Form.SelectATableItemType", FormParameters,
		ThisForm,,,,CallbackDescription,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure PresentationOfCellUseOptionClearing(Item, StandardProcessing)
	
	Area = Items.ReportPresentation.CurrentArea;
	If AreaInEditingArea(ThisForm, Area) Then
		Modified = True;
		PresentationOfUseCaseOfCleaningCellOnServer();
		SetCellColor_(Area, UseToEnterPlan, ThisIsASimpleTable);
	EndIf;
	
EndProcedure

&AtClient
Procedure TabularDocumentWhenTheAreaIsActivated(Item)
	
	Area = Item.CurrentArea;
	If Not AreaInEditingArea(ThisForm, Area) Then
		
		CellName = ""; Formula = "";
		Items.PresentationOfCellUseOption.Enabled = False;
		FormControl();
		Return;
		
	EndIf;
	
	Details = DecodingTabularDocumentArea(Area);
	If TypeOf(Details) = Type("Structure") Then
		
		Items.PresentationOfCellUseOption.Enabled = True;
		String = Details["String"]["Description"];
		Column = Details["Column"]["Description"];
		CellName = "[" + String + "; " + Column + "]";
		FormControl();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FormulaOnChange(Item)
	
	Area = Items.ReportPresentation.CurrentArea;
	If AreaInEditingArea(ThisForm, Area) Then
		FormulaWhenChangedOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure FormulaOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	ReportPresentationSelection(Undefined, Items.ReportPresentation.CurrentArea, Undefined);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	FinancialReportingClient.FinishEditingReportElement(ThisForm);
	
EndProcedure

&AtClient
Procedure Cut(Command)
	
	CopyValues(True);
	
EndProcedure

&AtClient
Procedure Insert(Command)
	
	If MCopyPasteCache = Undefined Then
		Return;
	EndIf;
	
	CurrentArea = Items.ReportPresentation.CurrentArea;
	If Not AreaInEditingArea(ThisForm, CurrentArea) Then
		WarningText = NStr("vi = 'Không thể thay thế khu vực đã chọn';
							|ru = 'Невозможно заменить выбранную область';
							|en = 'Cannot replace the selected area'; fa = 'Cannot replace the selected area';
							|it = 'Impossibile sostituire l''area selezionata';
							|pl = 'Wybrany obszar nie może zostać zamieniony';
							|tr = 'Seçili alan değiştirilemez'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	EditingArea = GetEditingArea(ThisForm);
	
	AreaHeight = MCopyPasteCache.Count();
	AreaWidth = MCopyPasteCache[0].Count();
	
	Cancel = False;
	
	If AreaHeight > 1 Or AreaWidth > 1 Then
		// There are several cells in the buffer - you can only specify where to copy
		If EditingArea.Right < CurrentArea.Left + MCopyPasteCache[0].UBound()
			Or EditingArea.Bottom < CurrentArea.Top + MCopyPasteCache.UBound() Then
			
			// Went beyond the boundaries of the editing area
			Cancel = True;
			
		EndIf;
	Else
		// There is one cell in the buffer - you can copy anywhere within the editing area.
		If Not AreaInEditingArea(ThisForm, CurrentArea) Then
			
			// Went beyond the boundaries of the editing area
			Cancel = True;
			
		EndIf;
	EndIf;
	
	If Cancel Then
		WarningText = NStr("vi = 'Không thể thay thế lựa chọn';
							|ru = 'Невозможно заменить выделенную область';
							|en = 'Cannot replace the highlighted area'; fa = 'Cannot replace the highlighted area';
							|it = 'Impossibile sostituire l''area evidenziata';
							|pl = 'Zaznaczony obszar nie może zostać zamieniony';
							|tr = 'İşaretli alan değiştirilemez'");
		ShowMessageBox(, WarningText);
		Return;
		
	EndIf;
	
	InsertOnServer(MCopyPasteCache, AreaHeight, AreaWidth);
	
	TabularDocumentWhenTheAreaIsActivated(Items.ReportPresentation);
	
EndProcedure

&AtClient
Procedure Copy(Command)
	
	CopyValues();
	
EndProcedure

&AtClient
Procedure Clear(Command)
	
	ClearServer();
	
EndProcedure

&AtClient
Procedure Properties(Command)
	
	ShowAreaProperties(Items.ReportPresentation.CurrentArea)
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure OpenItem(Command)
	
	RowSelected = Items.ListOfDesignElements.CurrentRow;
	If RowSelected = Undefined Then
		Return;
	EndIf;
	
	FormParameters = ParametersForOpeningConditionalAppearanceElement(Items.ListOfDesignElements.CurrentRow);
	
	CallbackDescription = New CallbackDescription("WhenChangingConditionalAppearance", ThisForm, RowSelected);
	
	OpenForm("Catalog.FinancialReportItems.Form.EditConditionalAppearanceItem",
		FormParameters,,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
	
EndProcedure

&AtClient
Procedure NumberingSystem(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("DisplayColumnNumbering", DisplayColumnNumbering);
	FormParameters.Insert("DisplayRowsNumbering", DisplayRowsNumbering);
	
	CallbackDescription = New CallbackDescription("EndOfEditingNumbering", ThisForm);
	OpenForm("Catalog.FinancialReportItems.Form.CellsSettingsNumbering",
		FormParameters,,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ArrangeTheSelectedCells(Command)
	
	WarningText = NStr("vi = 'Có thể áp dụng trang trí quy ước đối với các vùng sau:
										|- Vùng ô hình chữ nhật có các chỉ tiêu báo cáo
										|- Dòng hoặc cột
										|- Tiêu đề dòng và cột
										|- Toàn bộ bảng';
										|ru = 'Условное оформление можно применять к областям:
										|- Прямоугольные области ячеек с показателями отчета
										|- Строки или колонки
										|- Заголовки строк и колонок
										|- Вся таблица';
										|en = 'Conditional appearance can be applied to the following areas:
										|- Rectangular cell areas with the report indicators
										|- Rows or columns
										|- Titles of rows and columns
										|- The whole table'; fa = 'Conditional appearance can be applied to the following areas:
										|- Rectangular cell areas with the report indicators
										|- Rows or columns
										|- Titles of rows and columns
										|- The whole table';
										|it = 'L''esecuzione condizionale può essere applicata alle aree:
										| - Aree rettangolari di celle con indicatori del report
										| - Righe o colonne
										| - Intestazioni di righe e colonne
										| -  l''intera tabella';
										|pl = 'Widok warunkowy może być stosowany do obszarów:
										|- Prostokątne obszary komórek ze wskaźnikami raportu
										|- Wiersze lub kolumny
										|- Nagłówki wierszy i kolumn
										|- Cała tabela';
										|tr = 'Koşullu görünüm şu alanlarda uygulanabilir:
										|-Rapor göstergeleriyle dikdörtgen hücre alanları
										|-Satırlar veya sütunlar
										|- Satır ve sütun başlıkları
										|- Tablonun tamamı'");
	SelectedAreas = ReportPresentation.SelectedAreas;
	If SelectedAreas.Count() > 1 Then
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	AppearanceArea = SelectedAreas[0];
	
	EditingArea = GetEditingArea(ThisForm);
	IsString = AppearanceArea.Left <= 2 And (AppearanceArea.Right = 0 Or AppearanceArea.Right >= EditingArea.Right);
	
	CreatedAreaType = Undefined;
	
	If IsString Then
		If AppearanceArea.Top <= FirstRow
			And (AppearanceArea.Bottom = 0 Or AppearanceArea.Bottom >= EditingArea.Bottom) Then
			
			CreatedAreaType = PredefinedValue("Enum.DesignedAreaTypesOfBudgetReports.EntireTable");
			
		ElsIf AppearanceArea.Top >= EditingArea.Top And AppearanceArea.Bottom <= EditingArea.Bottom Then
			
			CreatedAreaType = PredefinedValue("Enum.DesignedAreaTypesOfBudgetReports.EntireRow");
			
		EndIf;
	EndIf;
	
	If CreatedAreaType = Undefined Then
		ThisIsColumn = AppearanceArea.Top <= FirstRow And (AppearanceArea.Bottom = 0 Or AppearanceArea.Bottom >= EditingArea.Bottom);
		If ThisIsColumn
			And AppearanceArea.Left >= EditingArea.Left And AppearanceArea.Right <= EditingArea.Right Then
			
			CreatedAreaType = PredefinedValue("Enum.DesignedAreaTypesOfBudgetReports.EntireColumn");
			
		EndIf;
	EndIf;
	
	If CreatedAreaType = Undefined
		And (AppearanceArea.Left <= 1 
			Or AppearanceArea.Right > EditingArea.Right
			Or AppearanceArea.Top < FirstRow
			Or AppearanceArea.Bottom > EditingArea.Bottom) Then
		
		ShowMessageBox(,WarningText);
		Return;
		
	EndIf;
	
	If CreatedAreaType = Undefined Then
		If AppearanceArea.Bottom < EditingArea.Top And AppearanceArea.Top >= FirstRow Then
			
			CreatedAreaType = PredefinedValue("Enum.DesignedAreaTypesOfBudgetReports.ColumnHeaders");
			
		EndIf;
	EndIf;
	
	If CreatedAreaType = Undefined Then
		If AppearanceArea.Left >= 2 And AppearanceArea.Right < EditingArea.Left Then
			
			CreatedAreaType = PredefinedValue("Enum.DesignedAreaTypesOfBudgetReports.RowsHeaders");
			
		EndIf;
	EndIf;
	
	If CreatedAreaType = Undefined Then
		If AppearanceArea.Left >= EditingArea.Left And AppearanceArea.Right <= EditingArea.Right
			And AppearanceArea.Top >= EditingArea.Top And AppearanceArea.Bottom <= EditingArea.Bottom Then
			
			CreatedAreaType = PredefinedValue("Enum.DesignedAreaTypesOfBudgetReports.CellsAtIntersectionOfRowsAndColumns");
			
		EndIf;
	EndIf;
	
	If CreatedAreaType = Undefined Then
		
		ShowMessageBox(,WarningText);
		Return;
		
	EndIf;
	
	StringsList = New Array;
	ColumnsList = New Array;
	FilterFields = New Array;
	ValueSelectionFields = New Array;
	
	If CreatedAreaType = PredefinedValue("Enum.DesignedAreaTypesOfBudgetReports.CellsAtIntersectionOfRowsAndColumns") Then
		For Column = AppearanceArea.Left To AppearanceArea.Right Do
			For String = AppearanceArea.Top To AppearanceArea.Bottom Do
				Area = ReportPresentation.Area(String, Column);
				Details = DecodingTabularDocumentArea(Area);
				StringsList.Add(Details["String"].ReportItem);
				ColumnsList.Add(Details["Column"].ReportItem);
				FilterFields.Add(Details["String"].ReportItem);
				FilterFields.Add(Details["Column"].ReportItem);
			EndDo;
		EndDo;
	ElsIf CreatedAreaType = PredefinedValue("Enum.DesignedAreaTypesOfBudgetReports.ColumnHeaders") Then
		For Column = AppearanceArea.Left To AppearanceArea.Right Do
			For String = AppearanceArea.Top To AppearanceArea.Bottom Do
				Area = ReportPresentation.Area(String, Column);
				ColumnsList.Add(Area.Details);
			EndDo;
		EndDo;
	ElsIf CreatedAreaType = PredefinedValue("Enum.DesignedAreaTypesOfBudgetReports.RowsHeaders") Then
		For Column = AppearanceArea.Left To AppearanceArea.Right Do
			For String = AppearanceArea.Top To AppearanceArea.Bottom Do
				Area = ReportPresentation.Area(String, Column);
				StringsList.Add(Area.Details);
				If ValueIsFilled(Area.Details) Then
					FilterFields.Add(Area.Details);
				EndIf;
			EndDo;
		EndDo;
	ElsIf CreatedAreaType = PredefinedValue("Enum.DesignedAreaTypesOfBudgetReports.EntireRow") Then
		For Column = 2 To 2 + MergeDepth - 1 Do
			For String = AppearanceArea.Top To AppearanceArea.Bottom Do
				Area = ReportPresentation.Area(String, Column);
				StringsList.Add(Area.Details);
				FilterFields.Add(Area.Details);
				For SelectionColumn = EditingArea.Left To EditingArea.Right Do
					ValueArea = ReportPresentation.Area(String, SelectionColumn);
					ValueSelectionFields.Add(ValueArea.Details.Column.ReportItem);
				EndDo;
			EndDo;
		EndDo;
	ElsIf CreatedAreaType = PredefinedValue("Enum.DesignedAreaTypesOfBudgetReports.EntireColumn") Then
		For Column = AppearanceArea.Left To AppearanceArea.Right Do
			For String = FirstRow To FirstRow + HeaderHeight Do
				Area = ReportPresentation.Area(String, Column);
				ColumnsList.Add(Area.Details);
				FilterFields.Add(Area.Details);
				For FIlterRow = EditingArea.Top To EditingArea.Bottom Do
					ValueArea = ReportPresentation.Area(FIlterRow, Column);
					Details = DecodingTabularDocumentArea(ValueArea);
					ValueSelectionFields.Add(Details["String"].ReportItem);
				EndDo;
			EndDo;
		EndDo;
	EndIf;
	
	If StringsList.Find(Undefined) <> Undefined Then
		CommonClientServer.DeleteAllValueOccurrencesFromArray(StringsList, Undefined);
		StringsList.Add(Undefined);
	EndIf;
	StringsList = CommonClientServer.CollapseArray(StringsList);
	
	If ColumnsList.Find(Undefined) <> Undefined Then
		CommonClientServer.DeleteAllValueOccurrencesFromArray(ColumnsList, Undefined);
		ColumnsList.Add(Undefined);
	EndIf;
	ColumnsList = CommonClientServer.CollapseArray(ColumnsList);
	
	FilterFields = CommonClientServer.CollapseArray(FilterFields);
	AddParentDimensions(FilterFields);
	ValueSelectionFields = CommonClientServer.CollapseArray(ValueSelectionFields);
	
	FormParameters = New Structure;
	FormParameters.Insert("CellsSettings", True);
	FormParameters.Insert("ThisIsASimpleTable", ThisIsASimpleTable);
	FormParameters.Insert("RegisteredRows", StringsList);
	FormParameters.Insert("DesigningColumns", ColumnsList);
	FormParameters.Insert("FilterFields", FilterFields);
	FormParameters.Insert("ValueSelectionFields", ValueSelectionFields);
	FormParameters.Insert("CreatedAreaType", CreatedAreaType);
	FormParameters.Insert("AddressOfReportItems", AddressOfReportItems);
	FormParameters.Insert("ItemAddressInStorage", ItemAddressInStorage);
	
	CallbackDescription = New CallbackDescription("WhenChangingConditionalAppearance", ThisForm);
	
	OpenForm("Catalog.FinancialReportItems.Form.EditConditionalAppearanceItem",
		FormParameters,,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AppearanceItems(Command)
	
	AppearanceItemVisibility = Not AppearanceItemVisibility;
	SetVisibilityOfDesignElements();
	
EndProcedure

#EndRegion

#Region FormTableCommandHandlers

&AtClient
Procedure ListOfDesignElementsSelection(Item, RowSelected, Field, StandardProcessing)
	
	FormParameters = ParametersForOpeningConditionalAppearanceElement(RowSelected);
	
	CallbackDescription = New CallbackDescription("WhenChangingConditionalAppearance", ThisForm, RowSelected);
	
	OpenForm("Catalog.FinancialReportItems.Form.EditConditionalAppearanceItem",
		FormParameters,,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
	
EndProcedure

&AtClient
Procedure ListOfDesignElementsOnChange(Item)
	
	UpdateConditionalAppearanceLineNumbers();
	
EndProcedure

&AtClient
Procedure ListOfDesignElementsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure BeforeClosingNotificationProcessing(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		ClosingForm_ = True;
		ThisForm.Close();
	EndIf;
	
EndProcedure

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
&AtClientAtServerNoContext
Function DecodingTabularDocumentArea(Area)
	Return Area.Details;
EndFunction

&AtServerNoContext
Function ArrayOfCurTableNames(ItemTableAddress)
	
	TableOfElements = GetFromTempStorage(ItemTableAddress); // See BudgetReportingCacheCalculationServer.NewTableOfElements
	ArrayOfCurTableNames = New Array;
	For Each StringOfElements In TableOfElements Do
		ElementStructure = GetFromTempStorage(StringOfElements.Item); // See FinancialReportingClientServer.ReportElementStructure
		If ElementStructure.ItemKind = Enums.FinancialReportItemKinds.EditedValue Then
			ArrayOfCurTableNames.Add(ElementStructure.NameForPrinting);
		EndIf;
	EndDo;
	
	Return ArrayOfCurTableNames;
	
EndFunction

&AtServer
Procedure AdjustEditableValuesToCurTableElements()
	
	NamesArray = GetFromTempStorage(EditedValues);
	SubtractionArray = ArrayOfCurTableNames(PutToTempStorage(TableItems.Unload()));
	NamesArray = CommonClientServer.ArraysDifference(NamesArray, SubtractionArray);
	PutToTempStorage(NamesArray, EditedValues);
	
EndProcedure

&AtClient
Procedure CopyValues(Cut = False)
	LocalCache = Undefined;
	
	CurrentArea = Items.ReportPresentation.CurrentArea;
	
	If Not AreaInEditingArea(ThisForm, CurrentArea) Then
		WarningText = NStr("vi = 'Không thể sao chép vùng đã chọn';
							|ru = 'Невозможно скопировать выбранную область';
							|en = 'Cannot copy the selected area'; fa = 'Cannot copy the selected area';
							|it = 'Non è possibile copiare l''area selezionata';
							|pl = 'Kopiowanie wybranego obszaru nie jest możliwe';
							|tr = 'Seçili alan kopyalanamaz'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	AreaHeight = CurrentArea.Bottom - CurrentArea.Top + 1;
	AreaWidth = CurrentArea.Right - CurrentArea.Left + 1;
	
	Array = New Array(AreaHeight, AreaWidth);
	
	If Cut Then
		UpdateTableOfCutElements(
			CurrentArea.Top,
			CurrentArea.Left,
			CurrentArea.Top + AreaHeight - 1,
			CurrentArea.Left + AreaWidth - 1);
	EndIf;
	
	For CountHeight = 0 To AreaHeight - 1 Do
		For CountTotalWidth = 0 To AreaWidth - 1 Do
			Area = ReportPresentation.Area(
											CurrentArea.Top + CountHeight,
											CurrentArea.Left + CountTotalWidth);
			Array[CountHeight][CountTotalWidth] = Area.Details.ReportItem;
			If Cut Then
				Area.Details.ReportItem = "";
				Area.Details.ItemKind = Undefined;
				Area.Text = NStr("vi = '<chọn loại ô>';
								|ru = '<выберите тип ячейки>';
								|en = '<select a cell type>'; fa = '<select a cell type>';
								|it = '<selezionare tipo di cella>';
								|pl = '<wybierz typ komórki>';
								|tr = '<hücre türünü seçiniz>'");
				SetCellColor_(Area, UseToEnterPlan, ThisIsASimpleTable, LocalCache);
			EndIf;
		EndDo;
	EndDo;
	
	MCopyPasteCache = Array;
	
EndProcedure

&AtServer
Procedure UpdateTableOfCutElements(BeginningRow, StartColumn, EndingRow, EndColumn)
	
	BufferTableElements = New ValueTable;
	BufferTableElements.Columns.Add("String");
	BufferTableElements.Columns.Add("Column");
	BufferTableElements.Columns.Add("Item");
	For Column = StartColumn To EndColumn Do
		For String = BeginningRow To EndingRow Do
			DecryptionArea = ReportPresentation.Area(String, Column);
			Details = DecodingTabularDocumentArea(DecryptionArea);
			If ValueIsFilled(Details.ReportItem)
				And Not Details.ItemKind = Enums.FinancialReportItemKinds.GroupFormula
				And Not Details.ItemKind = Enums.FinancialReportItemKinds.Group Then
				NewRow = BufferTableElements.Add();
				NewRow.String = Details["String"].ReportItem;
				NewRow.Column = Details["Column"].ReportItem;
				NewRow.Item = Details.ReportItem;
			EndIf;
		EndDo;
	EndDo;
	
	AddressOfTheCutElements = PutToTempStorage(BufferTableElements, UUID);
	
EndProcedure

&AtServer
Procedure InsertOnServer(Array, AreaHeight, AreaWidth)
	LocalCache = Undefined;
	
	CurrentArea = Items.ReportPresentation.CurrentArea;
	If Not (AreaWidth = 1 And AreaHeight = 1) Then
		If CurrentArea.Right - CurrentArea.Left + 1 <> AreaWidth
		 Or CurrentArea.Bottom - CurrentArea.Top + 1 <> AreaHeight Then
			
			CurrentArea = ReportPresentation.Area(CurrentArea.Top, CurrentArea.Left,
										CurrentArea.Top + AreaHeight - 1,
										CurrentArea.Left + AreaWidth - 1);
										
		EndIf;
	EndIf;
	
	Items.ReportPresentation.CurrentArea = CurrentArea;
	CurTableOfElements = GetFromTempStorage(ReportItems()); // See BudgetReportingCacheCalculationServer.NewTableOfElements
	
	For CountHeight = CurrentArea.Top To CurrentArea.Bottom Do
		For CountTotalWidth = CurrentArea.Left To CurrentArea.Right Do
			
			Area = ReportPresentation.Area(CountHeight, CountTotalWidth);
			
			If AreaWidth = 1 And AreaHeight = 1 Then
				ElementAddress = Array[0][0];
			Else
				ElementAddress = Array[CountHeight - CurrentArea.Top][CountTotalWidth - CurrentArea.Left];
			EndIf;
			If ValueIsFilled(ElementAddress) Then
				ItemKind = Undefined;
				Area.Details.ReportItem = FinancialReportingServerCall.CopyElementTo(
					ElementAddress, MainStorageID, ItemKind);
				
				ShiftReferencesToFormulaCells(Area.Details.ReportItem, ElementAddress, Area, CurTableOfElements);
				
				Area.Details.ItemKind = ItemKind;
			Else
				Area.Details.ReportItem = Undefined;
				Area.Details.ItemKind = Undefined;
			EndIf;
			Catalogs.FinancialReportItems.SetCellText(ThisForm, Area.Name);
			
		EndDo;
	EndDo;
	
	CurrentArea = Items.ReportPresentation.CurrentArea;
	
	For CountHeight = CurrentArea.Top To CurrentArea.Bottom Do
		For CountTotalWidth = CurrentArea.Left To CurrentArea.Right Do
			
			Area = ReportPresentation.Area(CountHeight, CountTotalWidth);
			SetCellColor_(Area, UseToEnterPlan, ThisIsASimpleTable, LocalCache);
			
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Procedure ClearServer()
	
	CurrentArea = Items.ReportPresentation.CurrentArea;
	For CountHeight = CurrentArea.Top To CurrentArea.Bottom Do
		For CountTotalWidth = CurrentArea.Left To CurrentArea.Right Do
			
			Area = ReportPresentation.Area(CountHeight, CountTotalWidth);
			If AreaInEditingArea(ThisForm, Area) Then
				Area.Details.ReportItem = Undefined;
				Area.Details.ItemKind = Undefined;
				Catalogs.FinancialReportItems.SetCellText(ThisForm, Area.Name);
				SetCellColor_(Area, UseToEnterPlan, ThisIsASimpleTable);
			EndIf;
			
		EndDo;
	EndDo;
	
	FormControl();
	
EndProcedure

&AtClient
Function DefineAdditionalParameters(Details)
	
	If Details.ItemKind = ItemKind("BudgetFlowItem") Then
		If UseToEnterPlan Then
			Return PredefinedValue("Enum.AdditionalModesOfReportItems.BudgetFlowItemInInputMode");
		EndIf;
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function GetEditingArea(Form)
	
	Result = New Structure;
	Result.Insert("Top",  Form.FirstRow + Form.HeaderHeight + 1); //the first line after the header
	Result.Insert("Left",  2 + Form.MergeDepth);               //all lines in the second column, so we edit from the third column + output together
	Result.Insert("Bottom",   Form.FirstRow + Form.TemplateHeight);    //up to the last line
	Result.Insert("Right", 2 + Form.MergeDepth - 1 + Form.TemplateWidth); //up to the last column
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function AreaInEditingArea(Form, Area)
	
	EditingArea = GetEditingArea(Form);
	If Area.Left >= EditingArea.Left
		And Area.Right <= EditingArea.Right
		And Area.Bottom <= EditingArea.Bottom
		And Area.Top >= EditingArea.Top Then
		
		Return True;
		
	EndIf;
	
	Return False;
	
EndFunction

&AtServer
Function TableCellProperty(PropertyName, Default = Undefined)
	
	Area = Items.ReportPresentation.CurrentArea;
	Try
		Details = Area.Details;
	Except
		Return Undefined;
	EndTry;
	
	If Not ValueIsFilled(Details)
		Or TypeOf(Details) <> Type("Structure") Then
		Return Default;
	EndIf;
	
	PropertyValue = Undefined;
	If Not Details.Property(PropertyName, PropertyValue) Then
		Return Default;
	EndIf;
	
	Return PropertyValue;
	
EndFunction

&AtServer
Procedure FormControl()
	
	ItemKind = TableCellProperty("ItemKind");
	ReportItem = TableCellProperty("ReportItem");
	CellValue = "";
	
	If ThisIsASimpleTable Then
		Items.LabelCellType.Visible = False;
		Items.GroupOfImagesOfTheElementType.Visible = False;
		Items.PresentationOfCellUseOption.Visible = False;
	ElsIf ItemKind = ItemKind("DerivedItem") Then
		Items.GroupOfImagesOfTheElementType.CurrentPage = Items.DerivedItem;
		CellValue = FinancialReportingServerCall.ValueOfAdditionalProps(ReportItem, "BudgetBalanceItem");
	ElsIf ItemKind = ItemKind("NonFinancialItem") Then
		Items.GroupOfImagesOfTheElementType.CurrentPage = Items.NonFinancialItem;
		CellValue = FinancialReportingServerCall.ValueOfAdditionalProps(ReportItem, "NonFinancialItem");
	ElsIf ItemKind = ItemKind("EditedValue") Then
		Items.GroupOfImagesOfTheElementType.CurrentPage = Items.EditedValue;
		CellValue = GetFromTempStorage(ReportItem).NameForPrinting;
	ElsIf ItemKind = ItemKind("BudgetFlowItem")
		Or ItemKind = ItemKind("AllBudgetFlowItems") Then
		Items.GroupOfImagesOfTheElementType.CurrentPage = Items.BudgetFlowItem;
		CellValue = FinancialReportingServerCall.ValueOfAdditionalProps(ReportItem, "BudgetFlowItem");
	ElsIf ItemKind = ItemKind("BudgetBalanceItem")
		Or ItemKind = ItemKind("AllBudgetBalanceItems") Then
		Items.GroupOfImagesOfTheElementType.CurrentPage = Items.BudgetBalanceItem;
		CellValue = FinancialReportingServerCall.ObjectAttributeValue(ReportItem, "NameForPrinting");
	ElsIf ItemKind = ItemKind("GroupFormula")
		Or ItemKind = ItemKind("Group") Then
		Items.GroupOfImagesOfTheElementType.CurrentPage = Items.DerivedItem;
	Else
		Items.GroupOfImagesOfTheElementType.CurrentPage = Items.Undefined;
	EndIf;
	
	PresentationOfCellUseOption = "" + ItemKind;
	If ValueIsFilled(CellValue) Then
		PresentationOfCellUseOption = PresentationOfCellUseOption + " """ + CellValue + """";
	EndIf;
	
	If ThisIsASimpleTable Then
		
		Items.Formula.Visible = False;
		
	ElsIf ItemKind = ItemKind("DerivedItem") Then
		
		Items.Formula.Title = NStr("vi = 'Tính toán';
									|ru = 'Вычисление';
									|en = 'Calculation'; fa = 'محاسبه';
									|it = 'Calcolo';
									|pl = 'Calculation';
									|tr = 'Hesaplama'");
		Formula = FinancialReportingServerCall.ValueOfAdditionalProps(ReportItem, "Formula");
		Items.Formula.Enabled = True;
		Items.Formula.TextEdit = True;
		
	ElsIf ItemKind = ItemKind("GroupFormula") Then
		
		Items.Formula.Title = NStr("vi = 'Tính toán';
									|ru = 'Вычисление';
									|en = 'Calculation'; fa = 'محاسبه';
									|it = 'Calcolo';
									|pl = 'Calculation';
									|tr = 'Hesaplama'");
		Formula = FinancialReportingServerCall.ValueOfAdditionalProps(ReportItem, "GroupFormula");
		Items.Formula.Enabled = True;
		Items.Formula.TextEdit = False;
		
	ElsIf ItemKind = ItemKind("Group") Then
		
		Items.Formula.Title = NStr("vi = 'Tùy chỉnh';
									|ru = 'Настройка';
									|en = 'Setting'; fa = 'تنظیم';
									|it = 'Impostazione';
									|pl = 'Setting';
									|tr = 'Ayar'");
		ShowTitle = FinancialReportingServerCall.ValueOfAdditionalProps(ReportItem, "DisplayItemTitle");
		Items.Formula.Enabled = True;
		Items.Formula.TextEdit = False;
		If Not ShowTitle Then
			Formula = NStr("vi = '<không hiển thị trên báo cáo>';
							|ru = '<в отчете не отображается>';
							|en = '<not displayed in the report>'; fa = '<not displayed in the report>';
							|it = '<non mostrato nel report>';
							|pl = '<nie jest pokazywane w raporcie>';
							|tr = '<raporda görüntülenmiyor>'");
		EndIf;
		
	Else
		
		If Not ValueIsFilled(CellValue) Then
			
			Items.Formula.Title = NStr("vi = 'Tính toán';
										|ru = 'Вычисление';
										|en = 'Calculation'; fa = 'محاسبه';
										|it = 'Calcolo';
										|pl = 'Calculation';
										|tr = 'Hesaplama'");
			Formula = "";
			Items.Formula.Enabled = False;
			
		Else
			
			Items.Formula.Enabled = True;
			Items.Formula.TextEdit = False;
			
			If UseToEnterPlan And ItemKind = ItemKind("BudgetFlowItem") Then
				
				Items.Formula.Title = NStr("vi = 'Tự động điền';
											|ru = 'Автозаполнение';
											|en = 'Auto population'; fa = 'تکمیل خودکار';
											|it = 'Compilazione automatica';
											|pl = 'Auto population';
											|tr = 'Otomatik doldurma'");
				Formula = FinancialReportingServerCall.ValueOfAdditionalProps(ReportItem, "Formula");
				
			Else
				
				Items.Formula.Title = NStr("vi = 'Tùy chỉnh';
											|ru = 'Настройка';
											|en = 'Setting'; fa = 'تنظیم';
											|it = 'Impostazione';
											|pl = 'Setting';
											|tr = 'Ayar'");
				Formula = "";
				HasSettings = FinancialReportingServerCall.ObjectAttributeValue(ReportItem, "HasSettings");
				If HasSettings = True Then
					Formula = NStr("vi = 'Thiết lập bộ lọc bổ sung chỉ tiêu';
									|ru = 'Установлены дополнительные отборы показателя';
									|en = 'Additional indicator filters are set'; fa = 'Additional indicator filters are set';
									|it = 'Sono stati installati selezioni aggiuntive di indicatore';
									|pl = 'Ustawiono dodatkowy filtr wskaźnika';
									|tr = 'Göstergenin ek filtreleri oluşturuldu'");
				EndIf;
				
				PeriodOfShift = FinancialReportingServerCall.ValueOfAdditionalProps(ReportItem, "PeriodOfShift");
				If ValueIsFilled(PeriodOfShift) Then
					If Not IsBlankString(Formula) Then
						Formula = Formula + "; ";
					EndIf;
					PresentationParameters = New Structure;
					PresentationParameters.Insert("PeriodOfShift");
					PresentationParameters.Insert("OffsetFrequency");
					PresentationParameters.Insert("UpperBoundOfData");
					PresentationParameters.Insert("LowerBoundOfData");
					PresentationParameters.Insert("GroupingPeriodStart");
					PresentationParameters.Insert("GroupingPeriodEnd");
					ParametersToTransmit = New Structure;
					For Each KeyAndValue In PresentationParameters Do
						Value = FinancialReportingServerCall.ValueOfAdditionalProps(ReportItem, KeyAndValue.Key);
						ParametersToTransmit.Insert(KeyAndValue.Key, Value);
					EndDo;
					EmptyValue = False;
					ParametersToTransmit.Insert("FormName", "CellsSettings");
					OffsetPresentation = BudgetReportingClientServer.OffsetPresentation(ParametersToTransmit, EmptyValue);
					If Not EmptyValue Then
						Formula = Formula + OffsetPresentation;
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetCellValue(Result)
	
	Prefix = "AdditionalAttribute_";
	
	ElementStructure = FinancialReportingClientServer.ReportElementStructure();
	FillPropertyValues(ElementStructure, Result);
	
	PeriodVariables = BudgetReportingClientServer.VariablesOfBudgetingPeriods();
	
	If ElementStructure.ItemKind = ItemKind("BudgetFlowItem")
		Or ElementStructure.ItemKind = ItemKind("AllBudgetFlowItems") Then
		
		If ElementStructure.ItemKind = ItemKind("BudgetFlowItem") Then
			ElementStructure.Insert(Prefix + "BudgetFlowItem", Result.ReportItem);
		EndIf;
		ElementStructure.Insert(Prefix + "DisplayedIndicators", Enums.TypesOfDisplayedBudgetReportIndicators.Sum);
		ElementStructure.Insert(Prefix + "OffsetFrequency", Enums.Periodicity.Year);
		ElementStructure.Insert(Prefix + "LowerBoundOfData", PeriodVariables.DataPeriodStart.Name);
		ElementStructure.Insert(Prefix + "UpperBoundOfData", PeriodVariables.DataPeriodEnd.Name);
		ElementStructure.Insert(Prefix + "GroupingPeriodStart", PeriodVariables.PeriodOfGrouping.Name);
		ElementStructure.Insert(Prefix + "GroupingPeriodEnd", PeriodVariables.PeriodOfGrouping.Name);
		
	ElsIf ElementStructure.ItemKind = ItemKind("BudgetBalanceItem")
		Or ElementStructure.ItemKind = ItemKind("AllBudgetBalanceItems") Then
		
		If ElementStructure.ItemKind = ItemKind("BudgetBalanceItem") Then
			ElementStructure.Insert(Prefix + "BudgetBalanceItem", Result.ReportItem);
		EndIf;
		ElementStructure.Insert(Prefix + "IndicatorValueType", Enums.ValueTypesOfBudgetReportIndicators.Turnover);
		ElementStructure.Insert(Prefix + "DisplayedIndicators", Enums.TypesOfDisplayedBudgetReportIndicators.Sum);
		ElementStructure.Insert(Prefix + "OffsetFrequency", Enums.Periodicity.Year);
		ElementStructure.Insert(Prefix + "LowerBoundOfData", PeriodVariables.DataPeriodStart.Name);
		ElementStructure.Insert(Prefix + "UpperBoundOfData", PeriodVariables.DataPeriodEnd.Name);
		ElementStructure.Insert(Prefix + "GroupingPeriodStart", PeriodVariables.PeriodOfGrouping.Name);
		ElementStructure.Insert(Prefix + "GroupingPeriodEnd", PeriodVariables.PeriodOfGrouping.Name);
		
	ElsIf ElementStructure.ItemKind = ItemKind("NonFinancialItem") Then
		
		ElementStructure.Insert(Prefix + "NonFinancialItem", Result.ReportItem);
		ElementStructure.Insert(Prefix + "OffsetFrequency",  Enums.Periodicity.Year);
		
	ElsIf ElementStructure.ItemKind = ItemKind("EditedValue") Then
		
		NamesArray = CommonClientServer.CopyArray(GetFromTempStorage(EditedValues));
		CommonClientServer.SupplementArray(NamesArray, ArrayOfCurTableNames(ReportItems()));
		ElementStructure.Insert("NameForPrinting", BudgetReportingClientServer.NameOfBudgetValueToEdit(NamesArray));
		ElementStructure.Insert(Prefix + "EditedValueType", "Number");
		
	EndIf;
	
	ItemRef = BudgetReportingClientServer.PlaceItemInStorage(ElementStructure, MainStorageID);
	
	CurrentArea = Items.ReportPresentation.CurrentArea;
	Details = CurrentArea.Details;
	Details.ItemKind = ElementStructure.ItemKind;
	Details.ReportItem = ItemRef;
	
	FormControl();
	Catalogs.FinancialReportItems.SetCellText(ThisForm, CurrentArea.Name);
	
EndProcedure

&AtClient
Procedure SelectElementType(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Area = Items.ReportPresentation.CurrentArea;
	Area.Font = New Font(,,False);
	SetCellValue(Result);
	SetCellColor_(Area, UseToEnterPlan, ThisIsASimpleTable);
	
	If Area.Details.ItemKind = 
		PredefinedValue("Enum.FinancialReportItemKinds.DerivedItem") Then
		EditReportElement(Area);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetCellColor_(Area, UseToEnterPlan, ThisIsASimpleTable, LocalCache = Undefined)
	
	If ThisIsASimpleTable Then
		Area.HorizontalAlign  = HorizontalAlign.Center;
		Area.VerticalAlign    = VerticalAlign.Center;
		Return;
	EndIf;
	
	CellDescription = Area.Details;
	If Not ValueIsFilled(CellDescription.ReportItem) Then
		Area.BackColor = BudgetReportingClientServer.GetStyleColor(LocalCache, "FieldWithAnErrorBackground");
		Area.TextColor = BudgetReportingClientServer.GetStyleColor(LocalCache, "EmptyTableField");
		Area.Font = New Font(,,True);
		Area.HorizontalAlign = HorizontalAlign.Center;
		Area.VerticalAlign = VerticalAlign.Center;
	Else
		If UseToEnterPlan
		   And (CellDescription.ItemKind = ItemKind("BudgetFlowItem")
		  Or CellDescription.ItemKind = ItemKind("EditedValue")) Then
			Area.BackColor = New Color(192, 220, 192);
		Else
			Area.BackColor = BudgetReportingClientServer.GetStyleColor(LocalCache, "FieldBackColor");
		EndIf;
		Area.TextColor = BudgetReportingClientServer.GetStyleColor(LocalCache, "FieldTextColor");
		Area.Font = New Font(,,False);
		Area.HorizontalAlign = HorizontalAlign.Left;
		Area.VerticalAlign = VerticalAlign.Top;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetCellColor()
	LocalCache = Undefined;
	
	EditingArea = GetEditingArea(ThisForm);
	For Column = EditingArea.Left To EditingArea.Right Do
		For String = EditingArea.Top To EditingArea.Bottom Do
			Area = ReportPresentation.Area(String, Column);
			SetCellColor_(Area, UseToEnterPlan, ThisIsASimpleTable, LocalCache);
		EndDo;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function ItemKind(ElementTypeName)
	
	#If Client Then
	
		Return PredefinedValue("Enum.FinancialReportItemKinds."+ElementTypeName);
		
	#Else
		
		Return Enums.FinancialReportItemKinds[ElementTypeName];
		
	#EndIf
	
EndFunction

&AtClient
Procedure ShowAreaProperties(Area)
	
	If AreaInEditingArea(ThisForm, Area) Then
		
		Details = Area.Details;
		If Not ValueIsFilled(Details.ReportItem) Then
			PresentationOfCellUseOptionStartChoice(Undefined, Undefined, Undefined);
		Else
			EditReportElement(Area);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReportPresentationSelection(Item, Area, StandardProcessing)
	
	StandardProcessing = False;
	
	If ThisIsASimpleTable Then
		WarningText = NStr("vi = 'Chọn giá trị ô chỉ có sẵn trong một bảng phức tạp';
							|ru = 'Выбор значений ячеек доступен только в сложной таблице';
							|en = 'Selection of cell values is available only in a complex table'; fa = 'Selection of cell values is available only in a complex table';
							|it = 'La selezione dei valori delle celle è disponibile solo nella tabella avanzata';
							|pl = 'Wybór wartości komórek jest dostępny tylko w tabeli złożonej';
							|tr = 'Hücre değer seçimi sadece karmaşık tabloda mevcuttur'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	ShowAreaProperties(Area);
	
EndProcedure

&AtClient
Procedure EditReportElement(Area)
	
	Modified = True;
	Details = Area.Details;
	
	If Details.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.GroupFormula")
		Or Details.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.Group") Then
		WarningText = NStr("vi = 'Thiết lập các thuộc tính mục có sẵn như là một ngân sách';
							|ru = 'Настройка свойств элемента доступна в виде бюджета';
							|en = 'Setting of item properties is available in the budget profile.'; fa = 'Setting of item properties is available in the budget profile.';
							|it = 'L''impostazione delle proprietà degli oggetti è disponibile come bilancio';
							|pl = 'Ustawienia właściwości elementu są dostępne w rodzaju budżetu';
							|tr = 'Öğe özellik ayarları bütçe profilinde mevcuttur'");
		ShowMessageBox( , WarningText);
		Return;
	EndIf;
	
	AddressOfItemStructure = Details.ReportItem;
	
	FormParameters = New Structure();
	FormParameters.Insert("ItemKind", 						Details.ItemKind);
	FormParameters.Insert("ItemAddressInStorage", 			AddressOfItemStructure);
	FormParameters.Insert("MainStorageID", 	MainStorageID);
	FormParameters.Insert("UseToEnterPlan", 		UseToEnterPlan);
	FormParameters.Insert("UseStatusFilter",		UseStatusFilter);
	FormParameters.Insert("CellsSettings", 					True);
	AddressOfCurTableOfElements = ReportItems();
	FormParameters.Insert("ItemTableAddress", 			AddressOfCurTableOfElements);
	FormParameters.Insert("AddressOfReportItems", 			AddressOfReportItems);
	FormParameters.Insert("AdditionalFormMode", 		DefineAdditionalParameters(Details));
	FormParameters.Insert("LocationOptionOfActualDataOffset", LocationOptionOfActualDataOffset);
	FormParameters.Insert("LineIDOfReportItem", LineIDOfReportItem);
	
	NamesArray = CommonClientServer.CopyArray(GetFromTempStorage(EditedValues));
	CommonClientServer.SupplementArray(NamesArray, ArrayOfCurTableNames(AddressOfCurTableOfElements));
	FormParameters.Insert("EditedValues", PutToTempStorage(NamesArray, UUID));
	
	Notification = New CallbackDescription("UpdateFieldAfterChangingElement", ThisForm, FormParameters);
	
	OpenForm("Catalog.FinancialReportItems.ObjectForm",
				FormParameters, ThisForm, , , , Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure UpdateInformationAfterEditingReportItem(Name)
	
	Catalogs.FinancialReportItems.SetCellText(ThisForm, Name);
	FormControl();
	
EndProcedure

&AtClient
Procedure UpdateFieldAfterChangingElement(Result, AdditionalParameters) Export
	
	AreaName = Items.ReportPresentation.CurrentArea.Name;
	Details = ReportPresentation.Area(AreaName).Details;
	CopyStructure_ = CommonClientServer.CopyStructure(Details);
	CopyStructure_.ItemKind = AdditionalParameters.ItemKind;
	CopyStructure_.ReportItem = AdditionalParameters.ItemAddressInStorage;
	ReportPresentation.Area(AreaName).Details = CopyStructure_;
	
	UpdateInformationAfterEditingReportItem(
			Items.ReportPresentation.CurrentArea.Name
			);
	
EndProcedure

&AtServer
Procedure FormulaWhenChangedOnServer()
	
	Area = Items.ReportPresentation.CurrentArea;
	FinancialReportingServerCall.SetValueOfAdditionalProps(Area.Details.ReportItem, "Formula", Formula);
	Catalogs.FinancialReportItems.SetCellText(ThisForm, Area.Name);
	
EndProcedure

&AtServer
Procedure PresentationOfUseCaseOfCleaningCellOnServer()
	
	Area = Items.ReportPresentation.CurrentArea;
	Area.Details.ReportItem = Undefined;
	Area.Details.ItemKind = Undefined;
	Catalogs.FinancialReportItems.SetCellText(ThisForm, Area.Name);
	FormControl();
	
EndProcedure

&AtServer
Function ReportItems()
	
	EditingArea = GetEditingArea(ThisForm);
	BufferTableElements = New ValueTable;
	BufferTableElements.Columns.Add("String");
	BufferTableElements.Columns.Add("Column");
	BufferTableElements.Columns.Add("Item");
	For Column = EditingArea.Left To EditingArea.Right Do
		For String = EditingArea.Top To EditingArea.Bottom Do
			Details = ReportPresentation.Area(String, Column).Details; // See DecodingTabularDocumentArea
			If ValueIsFilled(Details.ReportItem)
				And Not Details.ItemKind = Enums.FinancialReportItemKinds.GroupFormula
				And Not Details.ItemKind = Enums.FinancialReportItemKinds.Group Then
				NewRow = BufferTableElements.Add();
				NewRow.String = Details.String.ReportItem;
				NewRow.Column = Details.Column.ReportItem;
				NewRow.Item = Details.ReportItem;
			EndIf;
		EndDo;
	EndDo;
	
	Return PutToTempStorage(BufferTableElements, UUID);
	
EndFunction

&AtServer
Procedure ShiftReferencesToFormulaCells(Receiver, Source, ReceiverArea, CurTableOfElements)
	
	ReceiverStructure_ = GetFromTempStorage(Receiver); // See FinancialReportingClientServer.ReportElementStructure
	SourceStructure_ = GetFromTempStorage(Source); // See FinancialReportingClientServer.ReportElementStructure
	FinReports = FinancialReportingServerCall;
	
	OperandsToDelete = New Array;
	OperandIdentifiersUsed = New Map;
	Operands = ReceiverStructure_.FormulaOperands;
	
	TableOfCutElements = Undefined;
	If Not IsBlankString(AddressOfTheCutElements) Then
		TableOfCutElements = GetFromTempStorage(AddressOfTheCutElements); // ValueTable -
	EndIf;
	
	For Each Operand In Operands Do
		
		ElementOperand = GetFromTempStorage(Operand.AddressOfItemStructure); // See FinancialReportingClientServer.ReportElementStructure
		If ElementOperand.ItemKind = Enums.FinancialReportItemKinds.TableCell Then
			
			SourceOperand_ = SourceStructure_.FormulaOperands.Find(Operand.Id, "Id");
			
			OperandString_ = FinReports.ValueOfAdditionalProps(SourceOperand_.AddressOfItemStructure, "CellRow");
			OperandColumn = FinReports.ValueOfAdditionalProps(SourceOperand_.AddressOfItemStructure, "CellColumn");
			
			FoundRows = CurTableOfElements.FindRows(New Structure("Item", Source));
			FoundSourceOperandString = Undefined;
			If FoundRows.Count() > 0 Then
				FoundSourceOperandString = FoundRows[0];
			ElsIf TypeOf(TableOfCutElements) = Type("ValueTable") Then
				FoundRows = TableOfCutElements.FindRows(New Structure("Item", Source));
				If FoundRows.Count() > 0 Then
					FoundSourceOperandString = FoundRows[0];
				EndIf;
			EndIf;
			If Not FoundSourceOperandString = Undefined Then
				SourceRow1 = FoundSourceOperandString.String;
				SourceColumn1 = FoundSourceOperandString.Column;
			Else
				ErrorText = NStr("vi = 'Không thể sao chép toán hạng của ô';
								|ru = 'Не удалось скопировать операнды ячейки';
								|en = 'Cannot copy cell operands'; fa = 'Cannot copy cell operands';
								|it = 'Non è stato possibile copiare gli operandi della cella';
								|pl = 'Nie udało się skopiować operandów komórki';
								|tr = 'Hücre işleneni kopyalanamadı'");
				Raise ErrorText;
			EndIf;
			
			IndexSourceString = -1;
			SourceColumnIndex = -1;
			
			IndexOperandString = -1;
			OperandColumnIndex = -1;
			
			IndexOfReceiverString = ReceiverArea.Top;
			ReceiverColumnIndex = ReceiverArea.Left;
			
			EditingArea = GetEditingArea(ThisForm);
			For Column = EditingArea.Left To EditingArea.Right Do
				CurrentColumn = ReportPresentation.Area(EditingArea.Top, Column).Details.Column.ReportItem;
				If CurrentColumn = OperandColumn Then
					OperandColumnIndex = Column;
				EndIf;
				If CurrentColumn = SourceColumn1 Then
					SourceColumnIndex = Column;
				EndIf;
				If OperandColumnIndex <> -1 And SourceColumnIndex <> -1 Then
					Break;
				EndIf;
			EndDo;
			
			For String = EditingArea.Top To EditingArea.Bottom Do
				Details = ReportPresentation.Area(String, EditingArea.Left).Details; // See DecodingTabularDocumentArea
				CurrentRow = Details.String.ReportItem;
				If CurrentRow = OperandString_ Then
					IndexOperandString = String;
				EndIf;
				If CurrentRow = SourceRow1 Then
					IndexSourceString = String;
				EndIf;
				If IndexOperandString <> -1 And IndexSourceString <> -1 Then
					Break;
				EndIf;
			EndDo;
			
			IDParameters = Catalogs.FinancialReportItems.ParseOperandNameIntoComponents(Operand.Id);
			
			If IDParameters.StringIsFixed Then
				NewIndexOfRow = IndexOperandString;
			Else
				ShiftingRows = IndexOperandString - IndexSourceString;
				NewIndexOfRow = IndexOfReceiverString + ShiftingRows;
			EndIf;
			
			If IDParameters.FixedColumn Then
				NewColumnIndex = OperandColumnIndex;
			Else
				ColumnOffset = OperandColumnIndex - SourceColumnIndex;
				NewColumnIndex = ReceiverColumnIndex + ColumnOffset;
			EndIf;
			
			HasErrors = True;
			If NewColumnIndex > 0 And NewIndexOfRow > 0 Then
				TableCellArea = ReportPresentation.Area(NewIndexOfRow, NewColumnIndex);
				If AreaInEditingArea(ThisForm, TableCellArea) Then
					Details = TableCellArea.Details; // See DecodingTabularDocumentArea
					AddressOfIdString = Details.String.Description;
					If IDParameters.StringIsFixed Then
						AddressOfIdString = "$" + AddressOfIdString;
					EndIf;
					AddressOfIdColumn = Details.Column.Description;
					If IDParameters.FixedColumn Then
						AddressOfIdColumn = "$" + AddressOfIdColumn;
					EndIf;
					
					CellName = AddressOfIdString + "; " + AddressOfIdColumn;
					NewID1 = BudgetReportingClientServer.OperandName(CellName, Operand, Operands, False);
					
					// If the operand identifier is already used,
					// then we will make it unique and remember it.
					If OperandIdentifiersUsed[NewID1] <> Undefined Then
						Postfix = OperandIdentifiersUsed.Count();
						NewID1 = NewID1 + " " + Postfix;
					EndIf;
					OperandIdentifiersUsed.Insert(NewID1, Operand);
					
					NewIDPresentation = "[" + NewID1 + "]";
					
					Formula = FinReports.ValueOfAdditionalProps(ReceiverStructure_, "Formula");
					Formula = StrReplace(Formula, "[" + Operand.Id + "]", NewIDPresentation);
					
					Operand.Id = NewID1;
					
					FinReports.SetValueOfAdditionalProps(ReceiverStructure_,
							"Formula", Formula);
					FinReports.SetValueOfAdditionalProps(Operand.AddressOfItemStructure,
							"CellRow", Details["String"].ReportItem);
					FinReports.SetValueOfAdditionalProps(Operand.AddressOfItemStructure,
							"CellColumn", Details["Column"].ReportItem);
					
					HasErrors = False;
				EndIf;
			EndIf;
			
			If HasErrors Then
				OperandsToDelete.Add(Operand);
				
				Formula = FinReports.ValueOfAdditionalProps(ReceiverStructure_, "Formula");
				Formula = StrReplace(Formula, "[" + Operand.Id + "]", "#Invalid_link");
				
				FinReports.SetValueOfAdditionalProps(ReceiverStructure_, "Formula", Formula);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	For Each Operand In OperandsToDelete Do
		ReceiverStructure_.FormulaOperands.Delete(Operand);
	EndDo;
	
	PutToTempStorage(ReceiverStructure_, Receiver);
	
EndProcedure

&AtServer
Procedure AddParentDimensions(MainField)
	
	AdditionalFields = New Array;
	ReportItems = GetFromTempStorage(AddressOfReportItems);
	
	For Each ExtensionString In MainField Do
		
		FoundRow = FinancialReportingServer.SubordinateItem(ReportItems,
			"AddressOfItemStructure", ExtensionString);
		While FoundRow <> Undefined Do
			
			Parent = FinancialReportingClientServer.RowParent(FoundRow);
			If Parent.ItemKind = ItemKind("Rows")
				Or Parent.ItemKind = ItemKind("Columns")
				Or Parent.ItemKind = ItemKind("TableIndicatorsInRows")
				Or Parent.ItemKind = ItemKind("TableIndicatorsInColumns")
				Or Parent.ItemKind = ItemKind("ComplexTable") Then
				Break;
			EndIf;
			
			AdditionalFields.Add(Parent.AddressOfItemStructure);
			
			FoundRow = Parent;
			
		EndDo;
		
	EndDo;
	
	CommonClientServer.SupplementArray(MainField, AdditionalFields, True);
	
EndProcedure

&AtServer
Procedure FillInPresentationLines(ConditionalAppearanceString)
	
	Condition = GetFromTempStorage(ConditionalAppearanceString.StorageCondition);
	If TypeOf(Condition) = Type("DataCompositionSettings") Then
		ConditionalAppearanceString.Condition = String(Condition.Filter);
	EndIf;
	
	If IsBlankString(ConditionalAppearanceString.Condition) Then
		ConditionalAppearanceString.Condition = NStr("vi = '<không lọc>';
													|ru = '<без отбора>';
													|en = '<No filter>'; fa = '<بدون فیلتر>';
													|it = '<senza selezione>';
													|pl = '<bez filtru>';
													|tr = '<filtresiz>'");
	EndIf;
	
	Appearance = GetFromTempStorage(ConditionalAppearanceString.StorageDesign);
	If TypeOf(Appearance) <> Type("ValueTable") Or Not ValueIsFilled(Appearance) Then
		ConditionalAppearanceString.Appearance = NStr("vi = '<không được chỉ định để lập>';
														|ru = '<оформление не указано>';
														|en = '<appearance is not specified>'; fa = '<appearance is not specified>';
														|it = '<esecuzione non indicata>';
														|pl = '<widok nie został okeślony>';
														|tr = '<görünüm belirlenmemiş>'");
	Else
		PresentationsArray = New Array;
		For Each String In Appearance Do
			PresentationsArray.Add(String.Parameter + ": " + String.Appearance);
		EndDo;
		ConditionalAppearanceString.Appearance = StrConcat(PresentationsArray, "; ");
	EndIf;
	
	RegisteredRows = GetFromTempStorage(ConditionalAppearanceString.StorageLinesToBeFormed);
	DesigningColumns = GetFromTempStorage(ConditionalAppearanceString.CustomColumnsStorage);
	
	If ConditionalAppearanceString.CreatedAreaType = Enums.DesignedAreaTypesOfBudgetReports.EntireTable Then
		ConditionalAppearanceString.FormattedFields = NStr("vi = 'Toàn bộ bàn';
															|ru = 'Вся таблица';
															|en = 'Entire table'; fa = 'کل جدول';
															|it = 'Tutta la tabella';
															|pl = 'Cała tabela';
															|tr = 'Tablonun tamamı'");
	ElsIf ConditionalAppearanceString.CreatedAreaType = Enums.DesignedAreaTypesOfBudgetReports.EntireRow Then
		ConditionalAppearanceString.FormattedFields = NStr("vi = 'Dòng:';
															|ru = 'Строки:';
															|en = 'Lines:'; fa = 'Lines:';
															|it = 'Righe:';
															|pl = 'Lines:';
															|tr = 'Satırlar:'");
		For Each String In RegisteredRows Do
			If Not ValueIsFilled(String.ReportItem) Then
				Continue;
			EndIf;
			ConditionalAppearanceString.FormattedFields = ConditionalAppearanceString.FormattedFields + "
			|-" + GetFromTempStorage(String.ReportItem).NameForPrinting;
		EndDo;
	ElsIf ConditionalAppearanceString.CreatedAreaType = Enums.DesignedAreaTypesOfBudgetReports.EntireColumn Then
		ConditionalAppearanceString.FormattedFields = NStr("vi = 'Cột:';
															|ru = 'Колонки:';
															|en = 'Columns:'; fa = 'Columns:';
															|it = 'Colonne:';
															|pl = 'Columns:';
															|tr = 'Sütunlar:'");
		For Each String In DesigningColumns Do
			If Not ValueIsFilled(String.ReportItem) Then
				Continue;
			EndIf;
			ConditionalAppearanceString.FormattedFields = ConditionalAppearanceString.FormattedFields + "
			|-" + GetFromTempStorage(String.ReportItem).NameForPrinting;
		EndDo;
	ElsIf ConditionalAppearanceString.CreatedAreaType = Enums.DesignedAreaTypesOfBudgetReports.RowsHeaders Then
		ConditionalAppearanceString.FormattedFields = NStr("vi = 'Tiêu đề hàng:';
															|ru = 'Заголовки строк:';
															|en = 'Row headers:'; fa = 'Row headers:';
															|it = 'Righe di intestazione:';
															|pl = 'Nagłówki wierszy:';
															|tr = 'Satır başlıkları:'");
		For Each String In RegisteredRows Do
			If ValueIsFilled(String.ReportItem) Then
				ReportElementStructure = GetFromTempStorage(String.ReportItem);
				NameForPrinting = ReportElementStructure.NameForPrinting;
			Else
				NameForPrinting = NStr("vi = 'Phần đầu';
										|ru = 'Шапка';
										|en = 'Header'; fa = 'سرصفحه';
										|it = 'Testata';
										|pl = 'Nagłówek';
										|tr = 'Üst bilgi'");
			EndIf;
			ConditionalAppearanceString.FormattedFields = ConditionalAppearanceString.FormattedFields + "
			|-" + NameForPrinting;
		EndDo;
	ElsIf ConditionalAppearanceString.CreatedAreaType = Enums.DesignedAreaTypesOfBudgetReports.ColumnHeaders Then
		ConditionalAppearanceString.FormattedFields = NStr("vi = 'Tiêu đề cột:';
															|ru = 'Заголовки колонок:';
															|en = 'Column headers:'; fa = 'Column headers:';
															|it = 'Colonne di intestazione:';
															|pl = 'Nagłówki kolumn:';
															|tr = 'Sütun başlıkları:'");
		For Each String In DesigningColumns Do
			If ValueIsFilled(String.ReportItem) Then
				ReportElementStructure = GetFromTempStorage(String.ReportItem);
				NameForPrinting = ReportElementStructure.NameForPrinting;
			Else
				NameForPrinting = NStr("vi = 'Phần đầu';
										|ru = 'Шапка';
										|en = 'Header'; fa = 'سرصفحه';
										|it = 'Testata';
										|pl = 'Nagłówek';
										|tr = 'Üst bilgi'");
			EndIf;
			ConditionalAppearanceString.FormattedFields = ConditionalAppearanceString.FormattedFields + "
			|-" + NameForPrinting;
		EndDo;
	ElsIf ConditionalAppearanceString.CreatedAreaType = Enums.DesignedAreaTypesOfBudgetReports.CellsAtIntersectionOfRowsAndColumns Then
		ConditionalAppearanceString.FormattedFields = NStr("vi = 'Các ô tại giao điểm của các cột:';
															|ru = 'Ячейки на пересечении колонок:';
															|en = 'Cells at the intersection of columns:'; fa = 'Cells at the intersection of columns:';
															|it = 'Celle all''intersezione di colonne:';
															|pl = 'Komórki na styku kolumn:';
															|tr = 'Sütunların kesişimindeki hücreler:'");
		For Each String In DesigningColumns Do
			If Not ValueIsFilled(String.ReportItem) Then
				Continue;
			EndIf;
			ConditionalAppearanceString.FormattedFields = ConditionalAppearanceString.FormattedFields + "
			|-" + GetFromTempStorage(String.ReportItem).NameForPrinting;
		EndDo;
		ConditionalAppearanceString.FormattedFields = ConditionalAppearanceString.FormattedFields + "
		|" + NStr("vi = 'và dòng:';
					|ru = 'и строк:';
					|en = 'and lines:'; fa = 'and lines:';
					|it = 'e righe:';
					|pl = 'i wierszy:';
					|tr = 've satır:'");
		For Each String In RegisteredRows Do
			If Not ValueIsFilled(String.ReportItem) Then
				Continue;
			EndIf;
			ConditionalAppearanceString.FormattedFields = ConditionalAppearanceString.FormattedFields + "
			|-" + GetFromTempStorage(String.ReportItem).NameForPrinting;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateConditionalAppearanceLineNumbers()
	
	For Each String In ListOfDesignElements Do
		String.LineNumber = ListOfDesignElements.IndexOf(String) + 1;
	EndDo;
	
EndProcedure


// Returns the described conditional formatting settings.
// 
// Parameters:
// 	TempStorageAddress - String - 
// Returns:
// 	Structure -:
// 	 *AppearanceItemKey - UUID - 
// 	 *Appearance - ValueTable - 
// 	 *DesigningColumns - ValueTable - 
// 	 *RegisteredRows - ValueTable -
// 	 *DrillDownOfAppearanceItemFilterFields - ValueTable -
// 	 *CreatedAreaType - EnumRef.DesignedAreaTypesOfBudgetReports -
// 	 *Condition - DataCompositionSettings -
//
&AtServer
Function StructureOfConditionalAppearanceFromTemporaryStorage(TempStorageAddress)
	Return GetFromTempStorage(TempStorageAddress);
EndFunction

&AtServer
Procedure AddConditionalAppearanceOnServer(ResultAddress)
	
	StructureOfConditionalAppearance = StructureOfConditionalAppearanceFromTemporaryStorage(ResultAddress);
	DesignLines = ListOfDesignElements.FindRows(New Structure("AppearanceItemKey", StructureOfConditionalAppearance.AppearanceItemKey));
	If DesignLines.Count() Then
		NewRow = DesignLines[0];
	Else
		NewRow = ListOfDesignElements.Add();
	EndIf;
	NewRow.CreatedAreaType = StructureOfConditionalAppearance.CreatedAreaType;
	NewRow.AppearanceItemKey = StructureOfConditionalAppearance.AppearanceItemKey;
	NewRow.StorageDesign = PutToTempStorage(StructureOfConditionalAppearance.Appearance, UUID);
	NewRow.StorageLinesToBeFormed = PutToTempStorage(StructureOfConditionalAppearance.RegisteredRows, UUID);
	NewRow.CustomColumnsStorage = PutToTempStorage(StructureOfConditionalAppearance.DesigningColumns, UUID);
	NewRow.DecryptionOfEStorageSelectionFields = PutToTempStorage(StructureOfConditionalAppearance.DrillDownOfAppearanceItemFilterFields, UUID);
	NewRow.StorageCondition = PutToTempStorage(StructureOfConditionalAppearance.Condition, UUID);
	FillInPresentationLines(NewRow);
	UpdateConditionalAppearanceLineNumbers();
	
	SetVisibilityOfDesignElements();
	
EndProcedure

&AtClient
Procedure WhenChangingConditionalAppearance(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	AddConditionalAppearanceOnServer(Result);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfDesignElements()
	
	Items.ListOfDesignElements.Visible = AppearanceItemVisibility;
	If AppearanceItemVisibility Then
		Items.AppearanceItems.Title = NStr("vi = 'Ẩn các yếu tố thiết kế';
											|ru = 'Скрыть элементы оформления';
											|en = 'Hide appearance items'; fa = 'Hide appearance items';
											|it = 'Nascondere elementi di esecuzione';
											|pl = 'Ukryj elementy widoku';
											|tr = 'Görünüm öğelerini gizle'");
	Else
		Items.AppearanceItems.Title = NStr("vi = 'Hiển thị (%1)';
											|ru = 'Показать элементы оформления (%1)';
											|en = 'Show appearance items (%1)'; fa = 'Show appearance items (%1)';
											|it = 'Mostrare elementi di esecuzione (%1)';
											|pl = 'Pokaż elementy widoku (%1)';
											|tr = 'Görünüm öğelerini göster (%1)'");
		Items.AppearanceItems.Title = 
			StringFunctionsClientServer.SubstituteParametersToString(Items.AppearanceItems.Title, ListOfDesignElements.Count());
	EndIf;
	
EndProcedure

&AtServer
Function ParametersForOpeningConditionalAppearanceElement(RowIndex)
	
	UOString = ListOfDesignElements.FindByID(RowIndex);
	CreatedAreaType = UOString.CreatedAreaType;
	
	FilterFields = New Array;
	ValueSelectionFields = New Array;
	
	RegisteredRows = GetFromTempStorage(UOString.StorageLinesToBeFormed);
	DesigningColumns = GetFromTempStorage(UOString.CustomColumnsStorage);
	
	ReportItems = GetFromTempStorage(AddressOfReportItems);
	Table = FinancialReportingServer.ElementTable(ReportItems, ItemAddressInStorage);
	
	If CreatedAreaType = PredefinedValue("Enum.DesignedAreaTypesOfBudgetReports.CellsAtIntersectionOfRowsAndColumns") Then
		For Each Cell In RegisteredRows Do
			FilterFields.Add(Cell.ReportItem);
		EndDo;
		For Each Cell In DesigningColumns Do
			FilterFields.Add(Cell.ReportItem);
		EndDo;
	ElsIf CreatedAreaType = PredefinedValue("Enum.DesignedAreaTypesOfBudgetReports.ColumnHeaders") Then
		For Each Cell In DesigningColumns Do
			FilterFields.Add(Cell.ReportItem);
		EndDo;
	ElsIf CreatedAreaType = PredefinedValue("Enum.DesignedAreaTypesOfBudgetReports.RowsHeaders") Then
		For Each Cell In RegisteredRows Do
			FilterFields.Add(Cell.ReportItem);
		EndDo;
	ElsIf CreatedAreaType = PredefinedValue("Enum.DesignedAreaTypesOfBudgetReports.EntireRow") Then
		For Each Cell In RegisteredRows Do
			FilterFields.Add(Cell.ReportItem);
		EndDo;
		FoundRows = FinancialReportingServer.SubordinateItem(Table, "ItemKind", ItemKind("Columns"));
		FoundRows = BudgetReportingCacheCalculationServer.GetFinalElementsOfTree(FoundRows);
		For Each FoundRow In FoundRows Do
			ValueSelectionFields.Add(FoundRow.AddressOfItemStructure);
		EndDo;
	ElsIf CreatedAreaType = PredefinedValue("Enum.DesignedAreaTypesOfBudgetReports.EntireColumn") Then
		For Each Cell In DesigningColumns Do
			FilterFields.Add(Cell.ReportItem);
		EndDo;
		FoundRows = FinancialReportingServer.SubordinateItem(Table, "ItemKind", ItemKind("Rows"));
		FoundRows = BudgetReportingCacheCalculationServer.GetFinalElementsOfTree(FoundRows);
		For Each FoundRow In FoundRows Do
			ValueSelectionFields.Add(FoundRow.AddressOfItemStructure);
		EndDo;
	EndIf;
	
	FilterFields = CommonClientServer.CollapseArray(FilterFields);
	AddParentDimensions(FilterFields);
	ValueSelectionFields = CommonClientServer.CollapseArray(ValueSelectionFields);
	
	FormParameters = New Structure;
	FormParameters.Insert("ThisIsASimpleTable", ThisIsASimpleTable);
	FormParameters.Insert("RegisteredRows", UOString.StorageLinesToBeFormed);
	FormParameters.Insert("DesigningColumns", UOString.CustomColumnsStorage);
	FormParameters.Insert("AppearanceItemKey", UOString.AppearanceItemKey);
	FormParameters.Insert("FilterFields", FilterFields);
	FormParameters.Insert("ValueSelectionFields", ValueSelectionFields);
	FormParameters.Insert("CreatedAreaType", CreatedAreaType);
	FormParameters.Insert("Appearance", UOString.StorageDesign);
	FormParameters.Insert("Condition", UOString.StorageCondition);
	FormParameters.Insert("AddressOfReportItems", AddressOfReportItems);
	FormParameters.Insert("ItemAddressInStorage", ItemAddressInStorage);
	
	Return FormParameters;
	
EndFunction

&AtClient
Procedure EndOfEditingNumbering(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		DisplayColumnNumbering = Result["DisplayColumnNumbering"];
		DisplayRowsNumbering = Result["DisplayRowsNumbering"];
	EndIf;
	
EndProcedure

#EndRegion
