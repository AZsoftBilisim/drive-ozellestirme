
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.Property("ChartsOfAccounts") Then
		MessageText = NStr("vi = 'Không xem xét việc mở trực tiếp biểu mẫu này. Thực hiện mở biểu mẫu này khi bắt đầu lựa chọn loại ô trong biểu mẫu ""Tùy chỉnh các ô của loại báo cáo"" của thư mục ""Thành phần báo cáo tài chính"".';
							|ru = 'Непосредственное открытие этой формы не предусмотрено. Открытие данной формы выполняется при начале выбора вида ячейки в форме ""Настройка ячеек вида отчета"" справочника ""Элементы финансовых отчетов"".';
							|en = 'Application cannot open this form explicitly. It opens implicitly when you select a cell kind in the ""Report kind cell settings"" form of the ""Financial report items"" catalog.'; fa = 'Application cannot open this form explicitly. It opens implicitly when you select a cell kind in the ""Report kind cell settings"" form of the ""Financial report items"" catalog.';
							|it = 'L''apertura diretta di questo modulo non è prevista. L''apertura di questo modulo viene eseguita all''inizio della selezione del tipo di cella nel modulo ""Impostazione delle celle del tipo di report"" della directory ""Elementi dei report finanziari"".';
							|pl = 'Bezpośrednie otwieranie tego formularza nie jest przewidziane. Otwieranie danego formularza jest wykonywane przy rozpoczęciu wyboru rodzaju komórki w formularzu ""Ustawienia komórek rodzaju raportu"" katalogu ""Elementy raportów finansowych"".';
							|tr = 'Bu formun doğrudan açılması sağlanamadı. Bu formun açılması, ""Finansal rapor öğeleri"" kataloğunun ""Rapor türü hücre ayarı"" formunda hücre türünün seçimiyle gerçekleştirilir.'");
		Raise MessageText;
	EndIf;
	
	CommonClientServer.SupplementTableFromArray(ChartsOfAccounts, Parameters.ChartsOfAccounts, "ChartOfAccounts");
	
	UpdateTreeOfNewElements();

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure QuickSearchOfNewOnChange(Item)
	
	UpdateTreeOfNewElements();
	For Each String In NewItemTree.GetItems() Do
		Items.NewItemTree.Collapse(String.GetID());
		Items.NewItemTree.Expand(String.GetID(), False);
	EndDo;
	
EndProcedure

#EndRegion

#Region EventHandlersFormTablesTreeOfNewElements

&AtClient
Procedure NewItemTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	ProcessingReportItemSelection();
	
EndProcedure

#EndRegion

#Region EventHandlersFormTablesTreeOfSavedItems

&AtClient
Procedure SavedItemsTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	ProcessingReportItemSelection();
	
EndProcedure

&AtClient
Procedure FindSavedItem(Command)
	
	UpdateTreeOfSavedItems();
	
EndProcedure

&AtClient
Procedure QuickSearchForSavedFilesOnChange(Item)

	UpdateTreeOfSavedItems();

EndProcedure

&AtClient
Procedure FilterByReportKindOnChange(Item)
	
	UpdateTreeOfSavedItems();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FindNewItem(Command)
	
	UpdateTreeOfNewElements();
	For Each String In NewItemTree.GetItems() Do
		Items.NewItemTree.Collapse(String.GetID());
		Items.NewItemTree.Expand(String.GetID(), False);
	EndDo;
	
EndProcedure

&AtClient
Procedure Select(Command)
	
	ProcessingReportItemSelection();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ProcessingReportItemSelection()
	
	CurrentData = CurrentItem.CurrentData;
	If Not ValueIsFilled(CurrentData.ItemKind)
		Or CurrentData.IsFolder Then
		WarningText = NStr("vi = 'Không thể chọn phần tử';
							|ru = 'Элемент не может быть выбран';
							|en = 'Item cannot be selected'; fa = 'Item cannot be selected';
							|it = 'L''elemento non può essere selezionato';
							|pl = 'Element nie może zostać wybrany';
							|tr = 'Öğe seçilemez'");
		ShowMessageBox(Undefined, WarningText);
		Return;
	EndIf;
	
	Result = New Structure("ReportItem,ItemKind,NameForPrinting");
	Result.ItemKind = CurrentData.ItemKind;
	Result.NameForPrinting = CurrentData.NameForPrinting;
	If CurrentData.Property("ThisIsReference") Then
		Result.Insert("LinkedItem1", CurrentData.LinkedItem1);
		Result.Insert("ThisIsReference", True);
	Else
		Result.Insert("ReportItem", CurrentData.ReportingKindItem);
		Result.Insert("ThisIsReference", False);
	EndIf;
	Close(Result);
	
EndProcedure

&AtServer 
Procedure UpdateTreeOfNewElements()
	TreeParameters = InternationalReportingClientServer.NewElementTreeParameters();
	TreeParameters.ChartsOfAccounts = ChartsOfAccounts.Unload().UnloadColumn("ChartOfAccounts");
	TreeParameters.WorkMode = Enums.ModesOfNewItemTreeDisplay.SetUpReportKindIndicatorsOnly;
	TreeParameters.QuickSearch = QuickSearchOfNew;
	
	InternationalReportingServer.UpdateTreeOfNewElements(ThisForm, TreeParameters);
	Return;// in UT11, the handler is empty

EndProcedure

&AtClient
Procedure UpdateTreeOfSavedItems()

	UpdateTreeOfSavedItemsOnServer();
	If ValueIsFilled(FilterByReportKind) Then
		InternationalReportingClient.ExpandTreeOfSavedItems(ThisForm, SavedItemsTree);
	EndIf;
EndProcedure

&AtServer 
Procedure UpdateTreeOfSavedItemsOnServer()
	
	If Not ValueIsFilled(QuickSearchForSavedFiles)
		And Not ValueIsFilled(FilterByReportKind) Then
		SavedItems = SavedItemsTree.GetItems();
		SavedItems.Clear();
		Return;
	EndIf;
	TreeParameters = InternationalReportingClientServer.NewElementTreeParameters();
	TreeParameters.NameOfTreeElement = "SavedItemsTree";
	TreeParameters.WorkMode = Enums.ModesOfNewItemTreeDisplay.SetUpReportKindIndicatorsOnly;
	TreeParameters.FilterByReportKind = FilterByReportKind;
	TreeParameters.QuickSearch = QuickSearchForSavedFiles;
	TreeParameters.ChartsOfAccounts = ChartsOfAccounts.Unload().UnloadColumn("ChartOfAccounts");

	InternationalReportingServer.UpdateTreeOfSavedItems(ThisForm, TreeParameters);
EndProcedure

#EndRegion
