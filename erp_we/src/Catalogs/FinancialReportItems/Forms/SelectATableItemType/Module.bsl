
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.Property("UseToEnterPlan", UseToEnterPlan) Then
		MessageText = NStr("vi = 'Không xem xét việc mở trực tiếp biểu mẫu này. Thực hiện mở biểu mẫu này khi bắt đầu lựa chọn loại ô trong biểu mẫu ""Cài đặt ô"" của thư mục ""Thành phần báo cáo tài chính"".';
							|ru = 'Непосредственное открытие этой формы не предусмотрено. Открытие данной формы выполняется при начале выбора вида ячейки в форме ""Настройка ячеек"" справочника ""Элементы финансовых отчетов"".';
							|en = 'Application cannot open this form explicitly. It opens implicitly when you start selecting a cell kind in the ""Cell settings"" form of the ""Financial report items"" catalog.'; fa = 'Application cannot open this form explicitly. It opens implicitly when you start selecting a cell kind in the ""Cell settings"" form of the ""Financial report items"" catalog.';
							|it = 'L''apertura diretta di questo modulo non è prevista. L''apertura di questo modulo viene effettuata all''inizio della selezione del tipo di cella nel modulo ""Configurazione celle"" della directory ""Elementi di report finanziari"".';
							|pl = 'Bezpośrednie otwieranie tego formularza nie jest przewidziane. Otwieranie danego formularza jest wykonywane przy rozpoczęciu wyboru rodzaju komórki w formularzu ""Ustawienia komórek"" katalogu ""Elementy raportów finansowych"".';
							|tr = 'Bu formun doğrudan açılması sağlanamadı. Bu formun açılması, ""Finansal rapor öğeleri"" kataloğunun ""Hücre ayarı"" formunda hücre türünün seçimiyle gerçekleştirilir.'");
		Raise MessageText;
	EndIf;
	
	UpdateTreeOfNewBudgetViewItems();

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	For Each String In NewItemTree.GetItems() Do
		Items.BudgetProfileItems.Collapse(String.GetID());
	EndDo;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure QuickSearchOfNewOnChange(Item)
	
	UpdateTreeOfNewBudgetViewItems();
	
	For Each String In NewItemTree.GetItems() Do
		Items.BudgetProfileItems.Collapse(String.GetID());
		Items.BudgetProfileItems.Expand(String.GetID(), False);
	EndDo;
	
EndProcedure

&AtClient
Procedure QuickSearchOfNewClearing(Item, StandardProcessing)
	
	UpdateTreeOfNewBudgetViewItems();
	
	For Each String In NewItemTree.GetItems() Do
		Items.BudgetProfileItems.Collapse(String.GetID());
		Items.BudgetProfileItems.Expand(String.GetID(), False);
	EndDo;
	
EndProcedure

#EndRegion

#Region TableEventHandlersForms

&AtClient
Procedure BudgetProfileItemsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	Select(Undefined);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FindNewItem(Command)
	
	UpdateTreeOfNewBudgetViewItems();
	
	For Each String In NewItemTree.GetItems() Do
		Items.BudgetProfileItems.Collapse(String.GetID());
		Items.BudgetProfileItems.Expand(String.GetID(), False);
	EndDo;
	
EndProcedure

&AtClient
Procedure Select(Command)
	
	CurrentData = Items.BudgetProfileItems.CurrentData;
	If Not ValueIsFilled(CurrentData.ItemKind) Then
		ShowMessageBox(Undefined, NStr("vi = 'Không thể chọn phần tử!';
										|ru = 'Элемент не может быть выбран!';
										|en = 'Item cannot be selected.'; fa = 'Item cannot be selected.';
										|it = 'L''elemento non può essere selezionato!';
										|pl = 'Element nie może zostać wybrany!';
										|tr = 'Öğe seçilemez!'"));
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("ItemKind", CurrentData.ItemKind);
	Result.Insert("ReportItem", CurrentData.ReportingKindItem);
	Result.Insert("NameForPrinting", CurrentData.Description);
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer 
Procedure UpdateTreeOfNewBudgetViewItems()
	
	TreeParameters = New Structure;
	
	TreeParameters.Insert("NameOfTreeElement", "NewItemTree");
	TreeParameters.Insert("QuickSearch", QuickSearchOfNew);
	TreeParameters.Insert("UseToEnterPlan", UseToEnterPlan);
	TreeParameters.Insert("TreeMode", Enums.ModesOfNewItemTreeDisplay.SelectAComplexTableCellKind);
	
	BudgetReportingServerCall.UpdateTreeOfNewElements(ThisForm, TreeParameters);
	
EndProcedure

#EndRegion
