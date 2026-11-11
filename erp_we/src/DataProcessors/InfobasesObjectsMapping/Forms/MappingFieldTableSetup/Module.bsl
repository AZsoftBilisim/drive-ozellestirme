///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Verify that the form is opened with the required parameters
	If Not Parameters.Property("FieldList") Then
		
		Raise NStr("vi = 'Biểu mẫu này không được dùng để mở trực tiếp.';
					|ru = 'Эта форма не предназначена для непосредственного открытия.';
					|en = 'This is a dependent form and opens from a different form.'; fa = 'This is a dependent form and opens from a different form.';
					|it = 'Эта форма не предназначена для непосредственного открытия.';
					|pl = 'This is a dependent form and opens from a different form.';
					|tr = 'Bu form doğrudan açılmak üzere tasarlanmamıştır.'", Common.DefaultLanguageCode());
		
	EndIf;
		
	FieldList = Parameters.FieldList;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Apply(Command)
	
	Cancel = False;
	
	MarkedListItemArray = CommonClientServer.MarkedItems(FieldList);
	
	If MarkedListItemArray.Count() = 0 Then
		
		NString = NStr("vi = 'Hãy chỉ ra ít nhất một trường';
						|ru = 'Укажите хотя бы одно поле';
						|en = 'Specify at least one field'; fa = 'Specify at least one field';
						|it = 'Indicare almeno un campo';
						|pl = 'Wskaż co najmniej jedno pole';
						|tr = 'En az bir alan belirtin'");
		
		CommonClient.MessageToUser(NString,,"FieldList",, Cancel);
		
	ElsIf MarkedListItemArray.Count() > MaxUserFields() Then
		
		// The value must not exceed the specified number.
		MessageString = NStr("vi = 'Hãy giảm số lượng trường (có thể chọn không quá [FieldsCount] trường)';
							|ru = 'Уменьшите количество полей (можно выбирать не более [FieldsCount] полей)';
							|en = 'Reduce the number of fields (you can select no more than [FieldsCount] fields)'; fa = 'Reduce the number of fields (you can select no more than [FieldsCount] fields)';
							|it = 'Ridurre il numero di campi (è possibile selezionare non più di [FieldsCount] campi)';
							|pl = 'Zmniejsz ilość pól (można wybierać nie więcej  niż [FieldsCount] pól)';
							|tr = 'Alan sayısını azaltın (en fazla [FieldsCount] alan seçilebilir)'");
		MessageString = StrReplace(MessageString, "[FieldsCount]", String(MaxUserFields()));
		CommonClient.MessageToUser(MessageString,,"FieldList",, Cancel);
		
	EndIf;
	
	If Not Cancel Then
		
		NotifyChoice(FieldList.Copy());
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	NotifyChoice(Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Function MaxUserFields()
	
	Return DataExchangeClient.MaxObjectsMappingFieldsCount();
	
EndFunction

#EndRegion
