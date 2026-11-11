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
	
	If Parameters.TypeDetails.Types().Count() > 0 Then
		FoundParameterType = Parameters.TypeDetails.Types()[0];
	EndIf;
	
	FillChoiceListInputOnBasis(FoundParameterType);
	
	For Each ParameterFromForm In Parameters.ParametersList Do
		If StrStartsWith(Parameters.ParameterName, MessageTemplatesClientServer.ArbitraryParametersTitle()) Then
			ParameterNameToCheck = Mid(Parameters.ParameterName, StrLen(MessageTemplatesClientServer.ArbitraryParametersTitle()) + 2);
		Else
			ParameterNameToCheck = Parameters.ParameterName;
		EndIf;
		If ParameterFromForm.ParameterName = ParameterNameToCheck Then
			Continue;
		EndIf;
		ParametersList.Add(ParameterFromForm.ParameterName, ParameterFromForm.ParameterPresentation);
	EndDo;
	
	If StrStartsWith(Parameters.ParameterName, MessageTemplatesClientServer.ArbitraryParametersTitle()) Then
		ParameterName = Mid(Parameters.ParameterName, StrLen(MessageTemplatesClientServer.ArbitraryParametersTitle()) + 2);
	Else
		ParameterName = Parameters.ParameterName;
	EndIf;
	ParameterPresentation = Parameters.ParameterPresentation;
	ParameterType = Parameters.TypeDetails;
	
EndProcedure

&AtServerNoContext
Function ParameterTypeAsString(FullTypeName)
	
	If StrCompare(FullTypeName, "Date") = 0 Then
		Result = Type("Date");
	ElsIf StrCompare(FullTypeName, "String") = 0 Then
		Result = Type("String");
	Else
		ObjectManager = Common.ObjectManagerByFullName(FullTypeName);
		If ObjectManager <> Undefined Then
			Result = TypeOf(ObjectManager.EmptyRef());
		EndIf;
	EndIf;
	
	Return Result;
EndFunction

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ParameterTypeOnChange(Item)
	If IsBlankString(ParameterPresentation) And IsBlankString(ParameterName) Then
		ParameterPresentation = Items.TypeAsString.EditText;
		Position = StrFind(TypeAsString, ".", SearchDirection.FromEnd);
		If Position > 0 And Position < StrLen(TypeAsString) Then
			ParameterName = Mid(TypeAsString, Position + 1);
		Else
			ParameterName = TypeAsString;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	For Each ParameterFromForm In ParametersList Do
		If StrCompare(ParameterFromForm.Value, ParameterName) = 0 Then
			ShowMessageBox(, NStr("vi = 'Sai tên tham số. Đã thêm từ trước tham số có tên như vậy.';
									|ru = 'Некорректное имя параметра. Параметр с таким именем уже был добавлен ранее.';
									|en = 'Placeholder name error. A placeholder with this name already exists.'; fa = 'Placeholder name error. A placeholder with this name already exists.';
									|it = 'Nome del parametro non valido. Un parametro con questo nome è già stato aggiunto in precedenza.';
									|pl = 'Nieprawidłowa nazwa parametru. Parametr z taką nazwą został już wcześniej dodany.';
									|tr = 'Yer tutucu adı hatası. Bu ada sahip bir yer tutucu zaten var.'"));
			Return;
		EndIf;
		If StrCompare(ParameterFromForm.Presentation, ParameterPresentation) = 0 Then
			ShowMessageBox(, NStr("vi = 'Trình bày sai tham số. Đã bổ sung từ trước tham số có trình bày như vậy.';
									|ru = 'Некорректное представление параметра. Параметр с таким представлением уже был добавлен ранее.';
									|en = 'Placeholder presentation error. A placeholder with this presentation already exists.'; fa = 'Placeholder presentation error. A placeholder with this presentation already exists.';
									|it = 'Rappresentazione del parametro non valida. Un parametro con questa rappresentazione è già stato aggiunto in precedenza.';
									|pl = 'Nieprawidłowa prezentacja parametru. Parametr z taką prezentacją został już wcześniej dodany.';
									|tr = 'Yer tutucu gösterim hatası. Bu gösterime sahip bir yer tutucu zaten mevcut.'"));
			Return;
		EndIf;
	EndDo;
	
	If InvalidParameterName(ParameterName) Or IsBlankString(ParameterName) Then
		ShowMessageBox(, NStr("vi = 'Sai tên tham số. Không nên sử dụng dấu cách, dấu chấm câu và ký tự đặc biệt khác.';
								|ru = 'Некорректное имя параметра. Нельзя использовать пробелы, знаки пунктуации и другие спец. символы.';
								|en = 'Invalid placeholder name. Special characters and whitespace are not allowed.'; fa = 'Invalid placeholder name. Special characters and whitespace are not allowed.';
								|it = 'Nome del parametro non valido. Non è possibile utilizzare spazi, punteggiatura e altri caratteri speciali.';
								|pl = 'Nieprawidłowa nazwa parametru. Nie można używać spacji, znaków interpunkcyjnych i innych symboli specjalnych.';
								|tr = 'Geçersiz yer tutucu adı. Özel karakterler ve boşluk kullanılamaz.'"));
		Return;
	EndIf;
	
	If IsBlankString(ParameterPresentation) Then
		ShowMessageBox(, NStr("vi = 'Trình bày sai tham số.';
								|ru = 'Некорректное представление параметра.';
								|en = 'Invalid placeholder presentation.'; fa = 'Invalid placeholder presentation.';
								|it = 'Rappresentazione del parametro non valida.';
								|pl = 'Nieprawidłowa prezentacja parametru.';
								|tr = 'Geçersiz yer tutucu gösterimi.'"));
		Return;
	EndIf;
	
	If IsBlankString(TypeAsString) Then
		ShowMessageBox(, NStr("vi = 'Sai kiểu tham số.';
								|ru = 'Некорректный тип параметра.';
								|en = 'Invalid placeholder type.'; fa = 'Invalid placeholder type.';
								|it = 'Tipo del parametro non valido.';
								|pl = 'Niepoprawny typ parametru.';
								|tr = 'Geçersiz yer tutucu türü.'"));
		Return;
	EndIf;
	
	Result = New Structure("ParameterName, ParameterPresentation, ParameterType");
	FillPropertyValues(Result, ThisObject);
	Result.ParameterType = ParameterTypeAsString(TypeAsString);
	Close(Result);
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close(Undefined);
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function InvalidParameterName(ParameterName)
	
	Try
		Test = New Structure(ParameterName, ParameterName);
	Except
		Return True;
	EndTry;
	
	Return TypeOf(Test) <> Type("Structure");
	
EndFunction

&AtServer
Procedure FillChoiceListInputOnBasis(ParameterType)
	
	TypePresentation = "";
	MessageTemplatesSettings = MessageTemplatesInternalCached.OnDefineSettings();
	For Each TemplateSubject In MessageTemplatesSettings.TemplatesSubjects Do
		If StrCompare(TemplateSubject.Name, Parameters.InputOnBasisParameterTypeFullName) = 0 Then
			Continue;
		EndIf;
		ObjectMetadata = Common.MetadataObjectByFullName(TemplateSubject.Name);
		If ObjectMetadata = Undefined Then
			Continue;
		EndIf;
		Items.TypeAsString.ChoiceList.Add(TemplateSubject.Name, TemplateSubject.Presentation);
		
		ObjectManager = Common.ObjectManagerByFullName(TemplateSubject.Name);
		If ObjectManager <> Undefined Then
			If ParameterType = TypeOf(ObjectManager.EmptyRef()) Then
				TypePresentation = TemplateSubject.Name;
			EndIf;
		EndIf;
	EndDo;
	
	If ParameterType = Type("String") Then
		TypePresentation = NStr("vi = 'Xâu ký tự';
								|ru = 'Строка';
								|en = 'String'; fa = 'رشته';
								|it = 'Riga';
								|pl = 'Wiersz';
								|tr = 'Satır'");
	ElsIf ParameterType = Type("Date") Then
		TypePresentation = NStr("vi = 'Ngày';
								|ru = 'Дата';
								|en = 'Date'; fa = 'تاریخ';
								|it = 'Data';
								|pl = 'Data';
								|tr = 'Tarih'");
	EndIf;
	
	Items.TypeAsString.ChoiceList.Insert(0, "Date", NStr("vi = 'Ngày';
														|ru = 'Дата';
														|en = 'Date'; fa = 'تاریخ';
														|it = 'Data';
														|pl = 'Data';
														|tr = 'Tarih'"));
	Items.TypeAsString.ChoiceList.Insert(0, "String", NStr("vi = 'Xâu ký tự';
															|ru = 'Строка';
															|en = 'String'; fa = 'رشته';
															|it = 'Riga';
															|pl = 'String';
															|tr = 'Satır'"));
	
	TypeAsString = TypePresentation;
	
EndProcedure

#EndRegion

