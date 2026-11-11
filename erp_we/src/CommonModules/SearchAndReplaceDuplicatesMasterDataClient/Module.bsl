#Region Public

// Marks the selected items in the list as duplicates and offers to open a workplace for confirmation.
//
// Parameters:
//   List - FormTable - a dynamic list containing items to mark with duplicates.
//
Procedure MarkSelectedOnesWithDuplicates(List) Export
	
	References = New Array;
	
	For Each SelectedRow In List.SelectedRows Do
		If TypeOf(SelectedRow) = Type("DynamicListGroupRow") Then
			Continue;
		EndIf;
		
		CurrentRow = List.RowData(SelectedRow);
		If CurrentRow <> Undefined And ValueIsFilled(CurrentRow.Ref) Then
			References.Add(CurrentRow.Ref);
		EndIf;
	EndDo;
	
	If References.Count() < 2 Then
		CommonClient.MessageToUser((NStr("ru = 'Для отметки дублей необходимо выделить минимум два элемента.';
										|vi = 'To mark duplicates, select at least two items.';
										|en = 'To mark duplicates, select at least two items.'; fa = 'To mark duplicates, select at least two items.';
										|it = 'To mark duplicates, select at least two items.';
										|pl = 'To mark duplicates, select at least two items.';
										|tr = 'Yinelenen öğeleri işaretlemek için en az iki öğe seçilmelidir.'")));
		Return;
	EndIf;
	
	AddDuplicates(References);
	
	Notify("UpdateWorkplaceDeleteMasterDataDuplicates", TypeOf(References[0]));
	
EndProcedure

#EndRegion

#Region Private

Procedure AfterConfirmationOpenWorkplace(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		GroupID = SearchAndReplaceMasterDataDuplicatesServerCall.DuplicateGroup(AdditionalParameters.Duplicate1);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("RefType", AdditionalParameters.RefType);
		OpeningParameters.Insert("GroupID", GroupID);
		
		OpenForm("DataProcessor.MasterDataDuplicates.Form.CompareAndConfirmDuplicates", OpeningParameters);
	EndIf;
	
EndProcedure

Procedure AddDuplicates(References)
	
	SearchAndReplaceMasterDataDuplicatesServerCall.AddDuplicates(References);
	
	InteractiveTaggingIsAvailable = SearchAndReplaceMasterDataDuplicatesServerCall.InteractiveTaggingIsAvailable(References[0]);
	
	If InteractiveTaggingIsAvailable Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("RefType", TypeOf(References[0]));
		AdditionalParameters.Insert("Duplicate1", References[0]);
		
		Notification = New CallbackDescription("AfterConfirmationOpenWorkplace", ThisObject, AdditionalParameters);
		QueryText = NStr("ru = 'Выбранные элементы были отмечены как дубли. Открыть рабочее место для подтверждения дублей?';
						|vi = 'The selected items were marked as duplicates. Open a workplace to confirm duplicates?';
						|en = 'The selected items were marked as duplicates. Open a workplace to confirm duplicates?'; fa = 'The selected items were marked as duplicates. Open a workplace to confirm duplicates?';
						|it = 'The selected items were marked as duplicates. Open a workplace to confirm duplicates?';
						|pl = 'The selected items were marked as duplicates. Open a workplace to confirm duplicates?';
						|tr = 'Seçilen öğeler yinelenen olarak işaretlendi. Yinelenen öğeleri onaylama çalışma alanı açılsın mı?'");
		
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
	Else
		ShowUserNotification(NStr("ru = 'Элементы отмечены как дубли.';
									|vi = 'The items are marked as duplicates.';
									|en = 'The items are marked as duplicates.'; fa = 'The items are marked as duplicates.';
									|it = 'The items are marked as duplicates.';
									|pl = 'The items are marked as duplicates.';
									|tr = 'Öğeler yinelenen olarak işaretlendi.'"));
	EndIf;
	
EndProcedure

#EndRegion