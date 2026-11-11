
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.Property("Factor") Then
		MessageText = NStr("vi = 'Không cho phép mở trực tiếp biểu mẫu này. Để mở biểu mẫu, có thể sử dụng lệnh ""Khuôn mẫu nhập"" trong biểu mẫu tùy chỉnh khuôn mẫu nhập các chỉ tiêu phi tài chính.';
							|ru = 'Непосредственное открытие этой формы не предусмотрено. Для открытия формы можно воспользоваться командой ""Шаблоны ввода"" в форме нефинансовых показателей.';
							|en = 'Application cannot open this form explicitly. To open the form, use the ""Input templates"" command in the non-financial item form.'; fa = 'Application cannot open this form explicitly. To open the form, use the ""Input templates"" command in the non-financial item form.';
							|it = 'L''apertura diretta di questo modulo non è prevista. Per aprire un modulo è possibile utilizzare il comando ""Modelli di inserimento"" nel modulo degli indicatori non finanziari.';
							|pl = 'Bezpośrednie otwarcie tego formularza nie jest przewidziane. Aby otworzyć formularz, możesz użyć polecenia ""Szablony wprowadzania"" w postaci wskaźników niefinansowych.';
							|tr = 'Bu formun doğrudan açılması sağlanamadı. Formun açılması için finansal olmayan öğe formunda yer alan ""Giriş şablonları"" komutundan faydalanabilirsiniz.'");
		Raise MessageText;
	EndIf;
	
	Parameter = List.Parameters.Items.Find("Factor");
	Parameter.Value = Parameters.Factor;
	Parameter.Use = True;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Not Var_Group Then
		Cancel = True;
		FormParameters = New Structure("FillingIndicator", List.Parameters.Items.Find("Factor").Value);
		OpenForm("Catalog.NonFinancialItemProfiles.Form.ItemForm", FormParameters);
	EndIf;
	
EndProcedure

#EndRegion