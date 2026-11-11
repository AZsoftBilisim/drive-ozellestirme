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
	If Not Parameters.Property("MappingFieldsList") Then
		
		Raise NStr("vi = 'Biểu mẫu này không được dùng để mở trực tiếp.';
					|ru = 'Эта форма не предназначена для непосредственного открытия.';
					|en = 'This is a dependent form and opens from a different form.'; fa = 'This is a dependent form and opens from a different form.';
					|it = 'Эта форма не предназначена для непосредственного открытия.';
					|pl = 'This is a dependent form and opens from a different form.';
					|tr = 'Bu form doğrudan açılmak üzere tasarlanmamıştır.'", Common.DefaultLanguageCode());
		
	EndIf;
	
	MappingFieldsList = Parameters.MappingFieldsList;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateCommentLabelText();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MappingFieldsListOnChange(Item)
	
	UpdateCommentLabelText();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RunMapping(Command)
	
	NotifyChoice(MappingFieldsList.Copy());
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	NotifyChoice(Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateCommentLabelText()
	
	MarkedListItemArray = CommonClientServer.MarkedItems(MappingFieldsList);
	
	If MarkedListItemArray.Count() = 0 Then
		
		NoteLabel = NStr("vi = 'Sẽ chỉ thực hiện so sánh theo tên định danh nội bộ của đối tượng.';
						|ru = 'Сопоставление будет выполнено только по внутренним идентификаторам объектов.';
						|en = 'Mapping will be performed by internal object UUIDs only.'; fa = 'Mapping will be performed by internal object UUIDs only.';
						|it = 'Associazione verrà eseguita solo per gli identificatori interni degli oggetti.';
						|pl = 'Porównanie będzie wykonane tylko według wewnętrznych identyfikatorów obiektów.';
						|tr = 'Eşleştirme sadece UUID''ler ile gerçekleştirilecek.'");
		
	Else
		
		NoteLabel = NStr("vi = 'Sẽ thực hiện so sánh theo tên định danh nội bộ của đối tượng và theo các trường được chọn.';
						|ru = 'Сопоставление будет выполнено по внутренним идентификаторам объектов и по выбранным полям.';
						|en = 'Mapping will be performed by internal object UUIDs and the selected fields.'; fa = 'Mapping will be performed by internal object UUIDs and the selected fields.';
						|it = 'Associazione verrà eseguita per gli identificatori interni degli oggetti e per i campi selezionati.';
						|pl = 'Porównanie będzie wykonano według wewnętrznych identyfikatorów obiektów i według wybranych pól.';
						|tr = 'Eşleştirme UUID''ler ve seçilen alanlar ile gerçekleştirilecek.'");
		
	EndIf;
	
EndProcedure

#EndRegion
