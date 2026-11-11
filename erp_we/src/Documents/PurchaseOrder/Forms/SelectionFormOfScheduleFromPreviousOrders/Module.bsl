
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Parameters.TemplateTableAddress) Or
		Not ValueIsFilled(Parameters.DocumentsCount)Then
		
		MessageText = NStr("vi = 'Không cho phép mở trực tiếp biểu mẫu này.
			|Để mở biểu mẫu, có thể sử dụng lệnh ""Điền các giai đoạn theo đơn hàng trước"" trong biểu mẫu chứng từ ""Đơn hàng đặt nhà cung cấp""';
			|ru = 'Непосредственное открытие этой формы не предусмотрено. 
			|Для открытия формы можно воспользоваться командой ""Заполнить этапы по предыдущим заказам"" в форме документа ""Заказ поставщику""';
			|en = 'Application cannot open this form explicitly.
			|It opens implicitly when you select the ""Fill in steps by previous orders"" command in the form of ""Purchase order"" document.'; fa = 'Application cannot open this form explicitly.
			|It opens implicitly when you select the ""Fill in steps by previous orders"" command in the form of ""Purchase order"" document.';
			|it = 'L''apertura diretta di questo modulo non è prevista.
			|Per aprire il modulo, è possibile utilizzare il comando ""Compilare le fasi di ordini precedenti"" nel modulo del documento ""Ordine al fornitore""';
			|pl = 'Bezpośrednie otwarcie tego formularza nie przewidziano. 
			|Aby otworzyć formularz można używać polecenie ""Заполнить этапы по предыдущим заказам"" w formularzu dokumentu ""Заказ поставщику""';
			|tr = 'Bu formun doğrudan açılması mümkün değildir. 
			|Formu açmak için ""Satın alma siparişi"" belge formundaki ""Önceki siparişlerden aşamaları doldur"" komutunu kullanabilirsiniz'");
		Raise MessageText;
		
	EndIf;
	
	DocumentsCount = Parameters.DocumentsCount;
	
	TemplateTable_1 = GetFromTempStorage(Parameters.TemplateTableAddress);
	
	For Each Template In TemplateTable_1 Do
		FillPropertyValues(ChartTemplates.Add(), Template);
	EndDo;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ScheduleTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.ScheduleTable.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ScheduleCode = CurrentData.ScheduleCode;
	
	Close(ScheduleCode);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure ScheduleTableOnActivateRow(Item)
	
	CurrentData = Items.ScheduleTable.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	InfoString = NStr("vi = 'Được sử dụng trong %1 từ %2, ngày sử dụng cuối cùng %3';
						|ru = 'Используется в %1 из %2, дата последнего использования %3';
						|en = 'Used in %1 out of %2, last used on %3'; fa = 'Used in %1 out of %2, last used on %3';
						|it = 'Viene utilizzato in %1 da %2, data dell''ultimo utilizzo %3';
						|pl = 'Jest używane w %1 z %2, data ostatniego używania %3';
						|tr = '%1nin %2sında kullanılmış, son kullanım tarihi %3 '");
	InfoString = StringFunctionsClientServer.SubstituteParametersToString(
		InfoString, 
		CurrentData.UsageFrequency,
		DocumentsCount,
		Format(CurrentData.DateOfLastUse, "DLF=DD"));
	
	Information = InfoString;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	CurrentData = Items.ScheduleTable.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ScheduleCode = CurrentData.ScheduleCode;
	
	Close(ScheduleCode);
	
EndProcedure

&AtClient
Procedure SortByFrequency(Command)
	
	ChartTemplates.Sort("UsageFrequency Desc, DateOfLastUse Desc");
	
	Items.SortByFrequency.Check = True;
	Items.SortByDate.Check = False;
	
EndProcedure

&AtClient
Procedure SortByDate(Command)
	
	ChartTemplates.Sort("DateOfLastUse Desc,UsageFrequency Desc");
	
	Items.SortByFrequency.Check = False;
	Items.SortByDate.Check = True;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
