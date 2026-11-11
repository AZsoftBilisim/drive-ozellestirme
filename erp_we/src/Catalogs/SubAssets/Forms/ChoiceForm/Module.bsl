
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	List.Parameters.SetParameterValue("RunningTimeSource", False);
	List.Parameters.SetParameterValue("SelectionRestriction", False);
	
	SelectionRestriction = False;
	
	If Parameters.Property("RunningTimeSource") Then
		List.Parameters.SetParameterValue("RunningTimeSource", Parameters.RunningTimeSource);
		List.Parameters.SetParameterValue("SelectionRestriction", True);
		SelectionRestriction = True;
	EndIf;
	
	If Parameters.Property("Filter") Then
		If Parameters.Filter.Property("Owner") Then
			
			Asset = Parameters.Filter.Owner;
			
		EndIf;
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	
	CurrentData = Items.List.CurrentData;
	If CurrentData <> Undefined And Not CurrentData.AvailabilityOfChoice Then
		
		StandardProcessing = False;
		
		WarningText = NStr("vi = 'Không thể chọn nút ""%Node%"" trong chứng từ.
		|Không có chỉ báo thời gian chạy hợp lệ mà được ghi nhận thông qua nguồn';
		|ru = 'Узел ""%Node%"" недоступен для выбора в документ.
		|Нет доступных показателей наработки, регистрируемых без источника';
		|en = 'Cannot select the ""%Node%"" sub-asset for the document.
		|No available operating time units registered without a source were found'; fa = 'Cannot select the ""%Node%"" sub-asset for the document.
		|No available operating time units registered without a source were found';
		|it = 'Il nodo ""%Node%""  non è accessibile per la scelta nel documento. 
		| Non ci sono indicatori disponibili di tempo di funzionamento registrati senza fonte';
		|pl = 'Węzeł ""%Node%"" nie może być wybrany do dokumentu.
		|Brak dostępnych wskaźników średniego czasu pracy, rejestrowanych bez źródła';
		|tr = '""%Node%"" alt varlığı belgede seçim için mevcut değil. 
		| Kaydedilecek mevcut kaynaksız faaliyet süresi yok'");
		WarningText = StrReplace(WarningText, "%Node%", CurrentData.Description);
		ShowMessageBox(Undefined, WarningText);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Description.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Description");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text", Asset);

EndProcedure

#EndRegion
