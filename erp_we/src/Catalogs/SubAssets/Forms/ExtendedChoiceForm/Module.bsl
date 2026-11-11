
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Filter.Property("Owner") Then
		If ValueIsFilled(Parameters.Filter.Owner) Then
			Asset = Parameters.Filter.Owner;
			Items.Owner.Visible = False;
		Else
			Parameters.Filter.Delete("Owner");
		EndIf;
	EndIf;
	
	List.Parameters.SetParameterValue("ListOfAvailableNodes", RMManagement.NodesAvailableForSelection(Parameters));
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	
	CurrentData = Items.List.CurrentData;
	If CurrentData <> Undefined And Not CurrentData.AvailabilityOfChoice Then
		
		StandardProcessing = False;
		
		WarningText = NStr(
			"vi = 'Không thể chọn nút ""%Node%"".
			|Không có chỉ báo thời gian hoạt động hợp lệ';
			|ru = 'Узел ""%Node%"" недоступен для выбора.
			|Нет доступных показателей наработки';
			|en = 'Cannot select the ""%Node%"" sub-asset.
			|No available operating time units were found'; fa = 'Cannot select the ""%Node%"" sub-asset.
			|No available operating time units were found';
			|it = 'Il nodo ""%Node%""  non è accessibile per la scelta.
			| Non ci sono indicatori disponibili di tempo di funzionamento';
			|pl = 'Węzeł ""%Node%"" nie może zostać wybrany.
			|Brak dostępnych wskaźników średniego czasu pracy';
			|tr = '""%Node%"" alt varlığı seçim için uygun değil. 
			| Kullanılabilir faaliyet süresi yok'");
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
