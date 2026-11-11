#Region Variables

&AtClient
Var MCopyPasteCache;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.Property("MainStorageID", MainStorageID)
	 Or Not Parameters.Property("ChartsOfAccounts")
	 Or Not Parameters.Property("ReportItems") Then
		MessageText = NStr("vi = 'Không xem xét mở trực tiếp biểu mẫu này.';
							|ru = 'Непосредственное открытие этой формы не предусмотрено.';
							|en = 'Application cannot open this form explicitly.'; fa = 'Application cannot open this form explicitly.';
							|it = 'L''apertura diretta di questo modulo non è prevista.';
							|pl = 'Bezpośrednie otwieranie tego formularza nie jest przewidziane.';
							|tr = 'Bu formun doğrudan açılması sağlanamadı.'");
		Raise MessageText;
	EndIf;
	
	CommonClientServer.SupplementTableFromArray(ChartsOfAccounts, Parameters.ChartsOfAccounts, "ChartOfAccounts");
	
	FormData1 = Catalogs.FinancialReportItems.FormWhenCreatedOnServer(ThisForm);
	ValueToFormAttribute(FormData1.TableItems, "TableItems");
	
	Header = FormAttributeToValue("Object").GetTemplate("CellSetupLegend");
	ReportPresentation.Clear();
	Legend = Header.GetArea("LegendOfRegion");
	ReportPresentation.Put(Legend);
	FirstRow = 2;
	
	ItemsTree = FormDataToValue(Parameters.ReportItems, Type("ValueTree"));
	CopyOfElementTree = ItemsTree.Copy();
	CopyOfElementTree.Rows.Clear();
	
	TreeRow = FinancialReportingServer.SubordinateItem(
		ItemsTree,
		"AddressOfItemStructure",
		ItemAddressInStorage);
	TreeRow = FinancialReportingServer.RootItem(
		TreeRow,
		ItemKind("ComplexTable"));
	InstallationParameters = FinancialReportingServer.TemplateForNewParentInstallationOptions();
	InstallationParameters.TheseAreSavedOnes = True;
	InstallationParameters.LoopControl = False;
	FinancialReportingServer.SetNewParent(TreeRow, CopyOfElementTree, InstallationParameters);
	
	StructureOfWidths = Catalogs.FinancialReportItems.OutputComplexTableSetupTable(
					ThisForm,
					CopyOfElementTree);
	
	AddressOfReportItems = PutToTempStorage(CopyOfElementTree, UUID);
	
	TemplateWidth = StructureOfWidths.MWidthOfTemplate;
	TemplateHeight = StructureOfWidths.MTemplateHeight;
	HeaderHeight  = StructureOfWidths.MCapHeight;
	
	FormControl();
	
	SetCellColor();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EditingArea = GetEditingArea(ThisForm);
	Total = EditingArea.Right - EditingArea.Left + 1;
	
	ReportPresentation.Area(,2,,2).ColumnWidth = 30;
	
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
		ElementStructure = GetFromTempStorage(ThisForm.ItemAddressInStorage);
		AddressInStorage = ReportItems();
		ElementStructure.TableItems = GetFromTempStorage(AddressInStorage);
		PutToTempStorage(ElementStructure, ThisForm.ItemAddressInStorage);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PresentationOfCellUseOptionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	CallbackDescription = New CallbackDescription("SelectElementType", ThisForm);
	
	AccountPlansToConfigure = New Array;
	For Each TableRow In ChartsOfAccounts Do
		AccountPlansToConfigure.Add(TableRow.ChartOfAccounts);
	EndDo;
	
	FormParameters = New Structure;
	FormParameters.Insert("ChartsOfAccounts", AccountPlansToConfigure);
	OpenForm("Catalog.FinancialReportItems.Form.SelectAReportIndicatorType", FormParameters,
				ThisForm,,,,CallbackDescription,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure PresentationOfCellUseOptionClearing(Item, StandardProcessing)
	
	Area = Items.ReportPresentation.CurrentArea;
	If AreaInEditingArea(ThisForm, Area) Then
		PresentationOfUseCaseOfCleaningCellOnServer();
		SetCellColor_(Area, UseToEnterPlan);
	EndIf;
	
EndProcedure

&AtClient
Procedure TabularDocumentWhenTheAreaIsActivated(Item)
	
	Area = Item.CurrentArea;
	If Not AreaInEditingArea(ThisForm, Area) Then
		
		CellName = "";
		Formula = "";
		Items.PresentationOfCellUseOption.Enabled = False;
		FormControl();
		Return;
		
	EndIf;
	
	Details = DecodingTabularDocumentArea(Area);
	If TypeOf(Details) = Type("Structure") Then
		
		Items.PresentationOfCellUseOption.Enabled = True;
		String 	= Details["String"]["Description"];
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
	
	For CountHeight = 0 To AreaHeight - 1 Do
		For CountTotalWidth = 0 To AreaWidth - 1 Do
			Area = ReportPresentation.Area(
											CurrentArea.Top + CountHeight,
											CurrentArea.Left + CountTotalWidth);
			Array[CountHeight][CountTotalWidth] = Area.Details.ReportItem;
			If Cut Then
				Area.Details.ReportItem = "";
				Area.Text = NStr("vi = '<chọn loại ô>';
								|ru = '<выберите тип ячейки>';
								|en = '<select a cell type>'; fa = '<select a cell type>';
								|it = '<selezionare tipo di cella>';
								|pl = '<wybierz typ komórki>';
								|tr = '<hücre türünü seçiniz>'");
				SetCellColor_(Area, UseToEnterPlan, LocalCache);
			EndIf;
		EndDo;
	EndDo;
	
	MCopyPasteCache = Array;
	
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
			SetCellColor_(Area, UseToEnterPlan, LocalCache);
			
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
				SetCellColor_(Area, UseToEnterPlan);
			EndIf;
			
		EndDo;
	EndDo;
	
	FormControl();
	
EndProcedure

&AtClient
Function DefineAdditionalParameters(Details)
	
	If Details.ThisIsReference Then
		Return PredefinedValue("Enum.AdditionalModesOfReportItems.LinkedItem1");
	ElsIf Details.ItemKind = ItemKind("DerivedItem") Then
		Return PredefinedValue("Enum.AdditionalModesOfReportItems.ReportKind");
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function GetEditingArea(Form)
	
	Result = New Structure;
	Result.Insert("Top",  4 + Form.HeaderHeight + 1); //the first line after the header
	Result.Insert("Left",  3);                         //all lines are in the second column, so we edit from the third column
	Result.Insert("Bottom",   4 + Form.TemplateHeight);    //up to the last line
	Result.Insert("Right", 2 + Form.TemplateWidth);    //up to the last column
	
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
	
	If Not ValueIsFilled(Details) Or TypeOf(Details) <> Type("Structure") Then
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
	
	FinReports = FinancialReportingServerCall;
	ItemKind = TableCellProperty("ItemKind");
	ReportItem = TableCellProperty("ReportItem");
	ThisIsReference = TableCellProperty("ThisIsReference", False);
	
	CellValue = "";
	PresentationOfCellUseOption = "";
	Formula = "";
	If ItemKind = ItemKind("MonetaryIndicator")
		Or ItemKind = ItemKind("NonMonetaryItem") 
		Or ItemKind = ItemKind("DerivedItem") Then
		
		Items.GroupOfImagesOfTheElementType.CurrentPage = Items.ReportItem;
		ItemPicture = FinancialReportingCached.CustomPicture(ItemKind) + Number(ThisIsReference);
		CellValue = FinReports.ObjectAttributeValue(ReportItem, "NameForPrinting");
		
	Else
		Items.GroupOfImagesOfTheElementType.CurrentPage = Items.Undefined;
	EndIf;
	
	If ItemKind = Undefined And ReportItem = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CellValue) Then
		PresentationOfCellUseOption = PresentationOfCellUseOption + " " + CellValue;
	EndIf;
	
	Items.Formula.Title = NStr("vi = 'Tùy chỉnh';
								|ru = 'Настройка';
								|en = 'Setting'; fa = 'تنظیم';
								|it = 'Impostazione';
								|pl = 'Setting';
								|tr = 'Ayar'");
	StringCalculation = NStr("vi = 'Tính toán';
							|ru = 'Вычисление';
							|en = 'Calculation'; fa = 'محاسبه';
							|it = 'Calcolo';
							|pl = 'Obliczanie';
							|tr = 'Hesaplama'");
	Items.Formula.Enabled = True;
	Formula = "";
	If ThisIsReference Then
		Formula = NStr("vi = '<tính toán, xem phần tử liên quan>';
						|ru = '<расчет смотри в связанном элементе>';
						|en = '<see associated item for calculation>'; fa = '<see associated item for calculation>';
						|it = '<visualizzare calcolo nell''elemento correlato>';
						|pl = '<rozliczenie patrz w elemencie powiązanym>';
						|tr = '<bağlanılan öğede gösterilen hesaplama>'");
		
	ElsIf ItemKind = ItemKind("DerivedItem") Then
		
		Items.Formula.Title = StringCalculation;
		Formula = FinReports.ValueOfAdditionalProps(ReportItem, "Formula");
	
	ElsIf ItemKind = ItemKind("MonetaryIndicator") Then
		
		Account = FinReports.ValueOfAdditionalProps(ReportItem, "GLAccount_");
		TotalType = FinReports.ValueOfAdditionalProps(ReportItem, "TotalType");
		OpeningBalance = FinReports.ValueOfAdditionalProps(ReportItem, "OpeningBalance");
		HasSettings = FinReports.ObjectAttributeValue(ReportItem, "HasSettings");
		Formula = ShortNameOfMonetaryIndicator(Account, TotalType, OpeningBalance);
		If HasSettings = True Then
			Formula = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 <%2>';
					|ru = '%1 <%2>';
					|en = '%1 <%2>'; fa = '%1 <%2>';
					|it = '%1 <%2>';
					|pl = '%1 <%2>';
					|tr = '%1 <%2>'"),
				Formula,
				NStr("vi = 'Thiết lập bộ lọc bổ sung chỉ tiêu';
					|ru = 'установлены дополнительные отборы показателя';
					|en = 'additional indicator filters are set'; fa = 'additional indicator filters are set';
					|it = 'sono stati installati selezioni aggiuntive di indicatore';
					|pl = 'ustawiono dodatkowy filtr wskaźnika';
					|tr = 'göstergenin ek filtreleri oluşturuldu'"));
		EndIf;
		
		If TypeOf(Account) = LocalAccntingClientServer.TypeChartOfAccounts() Then
			ItemPicture = FinancialReportingCached.CustomPicture(ItemKind, "Compl") + Number(ThisIsReference);
		EndIf;
	
	ElsIf ItemKind = ItemKind("NonMonetaryItem") Then
		
		Formula = FinReports.ValueOfAdditionalProps(ReportItem, "NonMonetaryItem");
		
	ElsIf ItemKind = ItemKind("TotalByGroup") Then
		
		Items.Formula.Title = StringCalculation;
		Formula = NStr("vi = 'Tổng số';
						|ru = 'Сумма';
						|en = 'Amount'; fa = 'مبلغ';
						|it = 'Importo';
						|pl = 'Wartość';
						|tr = 'Tutar'")+"()";
		Items.Formula.Enabled = False;
		ShowTitle = FinReports.ValueOfAdditionalProps(ReportItem, "DisplayItemTitle");
		If Not ShowTitle Then
			Formula = NStr("vi = '<không hiển thị trên báo cáo>';
							|ru = '<в отчете не отображается>';
							|en = '<not displayed in the report>'; fa = '<not displayed in the report>';
							|it = '<non mostrato nel report>';
							|pl = '<nie jest pokazywane w raporcie>';
							|tr = '<raporda görüntülenmiyor>'");
		EndIf;
		
	ElsIf ItemKind = ItemKind("Group") Then
		
		Items.Formula.Enabled = False;
		ShowTitle = FinReports.ValueOfAdditionalProps(ReportItem, "DisplayItemTitle");
		If Not ShowTitle Then
			Formula = NStr("vi = '<không hiển thị trên báo cáo>';
							|ru = '<в отчете не отображается>';
							|en = '<not displayed in the report>'; fa = '<not displayed in the report>';
							|it = '<non mostrato nel report>';
							|pl = '<nie jest pokazywane w raporcie>';
							|tr = '<raporda görüntülenmiyor>'");
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetCellValue(Result)
	
	FinReports = FinancialReportingServerCall;
	ElementStructure = FinancialReportingClientServer.ReportElementStructure();
	FillPropertyValues(ElementStructure, Result);
	If Result.ThisIsReference Then
		FinReports.SetValueOfAdditionalProps(ElementStructure, "ReportRowCode", "");
		FinReports.SetValueOfAdditionalProps(ElementStructure, "Note", "");
		
	ElsIf ElementStructure.ItemKind = ItemKind("MonetaryIndicator") Then
		FinReports.SetValueOfAdditionalProps(
			ElementStructure, "GLAccount_", Result.ReportItem);
		FinReports.SetValueOfAdditionalProps(
			ElementStructure, "TotalType", Enums.TypesOfTotals.Balance_Dr);
		FinReports.SetValueOfAdditionalProps(
			ElementStructure, "OpeningBalance",False);
		
	ElsIf ElementStructure.ItemKind = ItemKind("NonMonetaryItem") Then
		FinReports.SetValueOfAdditionalProps(
			ElementStructure, "NonMonetaryItem", Result.ReportItem);
	EndIf;
	ItemRef = InternationalReportingClientServer.PlaceItemInStorage(ElementStructure, MainStorageID);
	
	CurrentArea = Items.ReportPresentation.CurrentArea;
	Details = CurrentArea.Details;
	Details.ItemKind = ElementStructure.ItemKind;
	Details.ReportItem = ItemRef;
	Details.ThisIsReference = Result.ThisIsReference;
	
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
	SetCellColor_(Area, UseToEnterPlan);
	
	If Not Result.ThisIsReference
		And Area.Details.ItemKind = 
			PredefinedValue("Enum.FinancialReportItemKinds.DerivedItem") Then
		EditReportElement(Area);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetCellColor_(Area, UseToEnterPlan, LocalCache = Undefined)
	
	CellDescription = Area.Details;
	If Not ValueIsFilled(CellDescription.ReportItem)
		And Not ValueIsFilled(CellDescription.ItemKind) Then
		Area.BackColor = BudgetReportingClientServer.GetStyleColor(LocalCache, "FieldWithAnErrorBackground");
		Area.TextColor = BudgetReportingClientServer.GetStyleColor(LocalCache, "EmptyTableField");
		Area.Font = New Font(,,True);
		Area.HorizontalAlign	 = HorizontalAlign.Center;
		Area.VerticalAlign	 = VerticalAlign.Center;
	Else
		Area.BackColor = BudgetReportingClientServer.GetStyleColor(LocalCache, "FieldBackColor");
		Area.TextColor = BudgetReportingClientServer.GetStyleColor(LocalCache, "FieldTextColor");
		Area.Font = New Font(,,False);
		Area.HorizontalAlign	 = HorizontalAlign.Left;
		Area.VerticalAlign	 = VerticalAlign.Top;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetCellColor()
	LocalCache = Undefined;
	
	EditingArea = GetEditingArea(ThisForm);
	For Column = EditingArea.Left To EditingArea.Right Do
		For String = EditingArea.Top To EditingArea.Bottom Do
			Area = ReportPresentation.Area(String, Column);
			SetCellColor_(Area, UseToEnterPlan, LocalCache);
		EndDo;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function ItemKind(ElementTypeName)
	
	Return PredefinedValue("Enum.FinancialReportItemKinds."+ElementTypeName);
	
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
	ShowAreaProperties(Area);
	
EndProcedure

&AtClient
Procedure EditReportElement(Area)
	
	Details = Area.Details;
	
	If Details.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.Group")
		Or Details.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.Dimension")
		Or Details.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.TotalByGroup") Then
		ShowMessageBox(Undefined, NStr("vi = 'Thiết lập thuộc tính mục có sẵn như là một báo cáo!';
										|ru = 'Настройка свойств элемента доступна в виде отчета!';
										|en = 'Setting of item properties is available as a report.'; fa = 'Setting of item properties is available as a report.';
										|it = 'L''impostazione delle proprietà degli oggetti è disponibile come report!';
										|pl = 'Konfiguracja właściwości elementu jest dostępna w rodzaju raportu!';
										|tr = 'Öğe özellik ayarları rapor türünde mevcuttur!'"));
		Return;
	EndIf;
	
	AddressOfItemStructure = Details.ReportItem;
	
	ItemAccountPlans = New Array;
	For Each TableRow In ChartsOfAccounts Do
		ItemAccountPlans.Add(TableRow.ChartOfAccounts);
	EndDo;
	
	FormParameters = New Structure();
	FormParameters.Insert("ItemKind", Details.ItemKind);
	FormParameters.Insert("ItemAddressInStorage", AddressOfItemStructure);
	FormParameters.Insert("MainStorageID", MainStorageID);
	FormParameters.Insert("CellsSettings", True);
	FormParameters.Insert("ItemTableAddress", ReportItems());
	FormParameters.Insert("AddressOfReportItems", AddressOfReportItems);
	FormParameters.Insert("AdditionalFormMode", DefineAdditionalParameters(Details));
	FormParameters.Insert("ChartsOfAccounts", ItemAccountPlans);
	
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
				And Not Details.ItemKind = Enums.FinancialReportItemKinds.TotalByGroup
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
Function ShortNameOfMonetaryIndicator(Account, TotalType, OpeningBalance)
	
	TotalName = String(TotalType);
	PeriodBoundary = ?(OpeningBalance,NStr("vi = 'Ban đầu';
											|ru = 'Начальное';
											|en = 'Initial'; fa = 'اولیه';
											|it = 'Iniziale';
											|pl = 'Początkowe';
											|tr = 'Başlangıç'"),NStr("vi = 'Cuối';
																	|ru = 'Конечное';
																	|en = 'Closing'; fa = 'بستن';
																	|it = 'Conclusivo';
																	|pl = 'Końcowe';
																	|tr = 'Son'")) + " ";
	If StrFind(TotalName, "Turnover") > 0 Then
		PeriodBoundary = "";
	EndIf;
	TotalLine = Lower(Left(TotalName,1)) + Right(TotalName,StrLen(TotalName)-1);
	Return PeriodBoundary + TotalLine + " " + NStr("vi = 'theo tài khoản';
													|ru = 'по счету';
													|en = 'by account'; fa = 'by account';
													|it = 'Per conto';
													|pl = 'wg rachunku';
													|tr = 'hesaplamaya göre'") + " " + String(Account);
	
EndFunction

#EndRegion
