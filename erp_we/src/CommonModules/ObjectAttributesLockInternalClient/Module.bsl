///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

Procedure AllowObjectAttributeEditAfterWarning(ContinuationHandler) Export
	
	If ContinuationHandler <> Undefined Then
		RunCallback(ContinuationHandler, False);
	EndIf;
	
EndProcedure

Procedure AllowEditingObjectAttributesAfterFormClosed(Result, Parameters) Export
	
	UnlockedAttributes = Undefined;
	
	If Result = True Then
		UnlockedAttributes = Parameters.LockedAttributes;
	ElsIf TypeOf(Result) = Type("Array") Then
		UnlockedAttributes = Result;
	Else
		UnlockedAttributes = Undefined;
	EndIf;
	
	If UnlockedAttributes <> Undefined Then
		ObjectAttributesLockClient.SetAttributeEditEnabling(
			Parameters.Form, UnlockedAttributes);
		
		ObjectAttributesLockClient.SetFormItemEnabled(Parameters.Form);
	EndIf;
	
	Parameters.Form = Undefined;
	
	If Parameters.ContinuationHandler <> Undefined Then
		ContinuationHandler = Parameters.ContinuationHandler;
		Parameters.ContinuationHandler = Undefined;
		RunCallback(ContinuationHandler, Result);
	EndIf;
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// For ObjectAttributesLockClient.CheckObjectRefs
Procedure CheckObjectReferenceAfterValidationConfirm(Response, Parameters) Export
	
	If Response <> DialogReturnCode.Yes Then
		RunCallback(Parameters.ContinuationHandler, False);
		Return;
	EndIf;
		
	If Parameters.ReferencesArrray.Count() = 0 Then
		RunCallback(Parameters.ContinuationHandler, True);
		Return;
	EndIf;
	
	If CommonServerCall.RefsToObjectFound(Parameters.ReferencesArrray) Then
		
		If Parameters.ReferencesArrray.Count() = 1 Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Phần tử ""%1"" đã được sử dụng ở nơi khác trong ứng dụng. 
				           |Không nên bật chỉnh sửa do nguy cơ mâu thuẫn dữ liệu.';
				           |ru = 'Элемент ""%1"" уже используется в других местах в приложении.
				           |Не рекомендуется разрешать редактирование из-за риска рассогласования данных.';
				           |en = '%1 is used elsewhere in the app.
				           |Editing this object might lead to data inconsistency.'; fa = '%1 is used elsewhere in the app.
				           |Editing this object might lead to data inconsistency.';
				           |it = 'Элемент ""%1"" уже используется в других местах в приложении.
				           |Не рекомендуется разрешать редактирование из-за риска рассогласования данных.';
				           |pl = '%1 is used elsewhere in the app.
				           |Editing this object might lead to data inconsistency.';
				           |tr = '""%1"" Öğesi, uygulamadaki diğer yerlerde zaten kullanılıyor. 
				           |Veri yanlış hizalama riskinden dolayı düzenlemeye izin verilmemesi önerilir.'"),
				Parameters.ReferencesArrray[0]);
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đối tượng đã chọn (%1) đã được sử dụng ở nơi khác trong ứng dụng. 
				           |Không nên cho phép chỉnh sửa do rủi ro mâu thuẫn dữ liệu.';
				           |ru = 'Выбранные элементы (%1) уже используются в других местах в приложении.
				           |Не рекомендуется разрешать редактирование из-за риска рассогласования данных.';
				           |en = '%1 selected items are used elsewhere in the app.
				           |Editing these items might lead to data inconsistency.'; fa = '%1 selected items are used elsewhere in the app.
				           |Editing these items might lead to data inconsistency.';
				           |it = 'Выбранные элементы (%1) уже используются в других местах в приложении.
				           |Не рекомендуется разрешать редактирование из-за риска рассогласования данных.';
				           |pl = '%1 selected items are used elsewhere in the app.
				           |Editing these items might lead to data inconsistency.';
				           |tr = 'Seçilmiş öğeler (%1), uygulamadaki diğer yerlerde zaten kullanılıyor. 
				           |Veri yanlış hizalama riskinden dolayı düzenlemeye izin verilmemesi önerilir.'"),
				Parameters.ReferencesArrray.Count());
		EndIf;
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Cho phép chỉnh sửa';
												|ru = 'Разрешить редактирование';
												|en = 'Allow editing'; fa = 'اجازه ویرایش';
												|it = 'Consentire la modifica';
												|pl = 'Zezwól na edycję';
												|tr = 'Düzenlemeyi etkinleştir'"));
		Buttons.Add(DialogReturnCode.No, NStr("vi = 'Hủy bỏ';
												|ru = 'Отмена';
												|en = 'Cancel'; fa = 'انصراف';
												|it = 'Annulla';
												|pl = 'Cancel';
												|tr = 'İptal'"));
		ShowQueryBox(
			New CallbackDescription(
				"CheckObjectRefsAfterEditConfirmation", ThisObject, Parameters),
			MessageText, Buttons, , DialogReturnCode.No, Parameters.DialogTitle);
	Else
		If Parameters.ReferencesArrray.Count() = 1 Then
			ShowUserNotification(NStr("vi = 'Cho phép soạn các mục tin';
										|ru = 'Редактирование реквизитов разрешено';
										|en = 'Attribute editing allowed'; fa = 'Attribute editing allowed';
										|it = 'La modifica dei requisiti è permessa';
										|pl = 'Edycja atrybutów jest dozwolona';
										|tr = 'Öznitelik düzenlemeye izin verilir'"),
				GetURL(Parameters.ReferencesArrray[0]), Parameters.ReferencesArrray[0]);
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Cho phép soạn các mục tin đối tượng (%1)';
					|ru = 'Разрешено редактирование реквизитов объектов (%1)';
					|en = 'Allowed to edit attributes of %1 objects'; fa = 'Allowed to edit attributes of %1 objects';
					|it = 'È permessa la modifica dei requisiti per gli oggetti (%1)';
					|pl = 'Dozwolona jest edycja atrybutów obiektów (%1)';
					|tr = 'Nesne özniteliklerinin düzenlenmesine izin verilir (%1)'"),
				Parameters.ReferencesArrray.Count());
			
			ShowUserNotification(NStr("vi = 'Cho phép soạn các mục tin';
										|ru = 'Редактирование реквизитов разрешено';
										|en = 'Attribute editing allowed'; fa = 'Attribute editing allowed';
										|it = 'La modifica dei requisiti è permessa';
										|pl = 'Edycja atrybutów jest dozwolona';
										|tr = 'Öznitelik düzenlemeye izin verilir'"),,
				MessageText);
		EndIf;
		RunCallback(Parameters.ContinuationHandler, True);
	EndIf;
	
EndProcedure

Procedure CheckObjectRefsAfterEditConfirmation(Response, Parameters) Export
	
	RunCallback(Parameters.ContinuationHandler, Response = DialogReturnCode.Yes);
	
EndProcedure

#EndRegion

#EndRegion
