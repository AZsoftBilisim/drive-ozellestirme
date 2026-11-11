///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Or AdditionalProperties.Property("DoNotCheckUniqueness") Then
		Return;
	EndIf;
	
	If Predefined And Not IsNew() Then
		
		CheckTheChangeOfAPredefinedElement();
		
	EndIf;
	
	If Not CheckFilling() Then
		Cancel = True;
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	ErrorList = CheckTheUniquenessOfTheElements();
	
	If ErrorList.Count() > 0 Then
		
		Cancel = True;
		For Each ErrorDescription In ErrorList Do
			Common.MessageToUser(ErrorDescription.MessageText,, ErrorDescription.FieldName);
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	If FillingData<>Undefined Then
		FillPropertyValues(ThisObject, FillingData);
	EndIf;
EndProcedure

#EndRegion

#Region Private

// Controls item uniqueness in the infobase.
// If there are code or description duplicates, returns its list.
//
//  Returns:
//      Array of See NewErrorMessage - Details of duplicate items (if found).
//        
//
Function CheckTheUniquenessOfTheElements()
	
	Result = New Array;
	
	// Skip non-numerical codes.
	NumberType = New TypeDescription("Number", New NumberQualifiers(3, 0, AllowedSign.Nonnegative));
	If Code= "0" Or Code = "00" Or Code = "000" Then
		SearchCode = "000";
	Else
		SearchCode = Format(NumberType.AdjustValue(Code), "ND=3; NZ=; NLZ=");
	EndIf;
		
	Query = New Query("
		|SELECT TOP 10
		|	Code                AS Code,
		|	Description       AS Description,
		|	DescriptionFull AS DescriptionFull,
		|	CodeAlpha2          AS CodeAlpha2,
		|	CodeAlpha3          AS CodeAlpha3,
		|	EEUMember       AS EEUMember,
		|	Ref             AS Ref
		|FROM
		|	Catalog.WorldCountries
		|WHERE
		|	(Code = &Code
		|	OR Description = &Description
		|	OR CodeAlpha2 = &CodeAlpha2
		|	OR CodeAlpha3 = &CodeAlpha3
		|	OR DescriptionFull = &DescriptionFull)
		|	AND Ref <> &Ref
		|");
	Query.SetParameter("Ref",                Ref);
	Query.SetParameter("Code",                   SearchCode);
	Query.SetParameter("Description",          Description);
	Query.SetParameter("DescriptionFull",    DescriptionFull);
	Query.SetParameter("CodeAlpha2",             CodeAlpha2);
	Query.SetParameter("CodeAlpha3",             CodeAlpha3);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return Result;
	EndIf;
	
	Selection = QueryResult.Select();
	While Selection.Next() Do
		
		Message = NewErrorMessage();
		If StrCompare(Selection.Code, Code) = 0 Then
			
			Message.MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Mã %1 đất nước đã có%2. Thay đổi mã hoặc sử dụng dữ liệu hiện có.';
					|ru = 'С кодом %1 уже существует страна %2. Измените код или используйте уже существующие данные.';
					|en = 'Code %1 already assigned to country %2. Change the code, or use the existing data.'; fa = 'Code %1 already assigned to country %2. Change the code, or use the existing data.';
					|it = 'Esiste già un paese %2 con il codice %1. Modificate il codice o utilizzate dei dati già esistenti.';
					|pl = 'Istnieje już kraj %2 z kodem %1. Zmień kod lub użyj istniejących danych.';
					|tr = '%1 kodlu %2 ülkesi zaten var. Kodu değiştirin veya varolan verileri kullanın.'"),
				Code, Selection.Description);
			Message.FieldName = "Object.Code";
			
		ElsIf StrCompare(Selection.Description, Description) = 0 Then
			
			Message.MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Quốc gia có tên %1 đã tồn tại. Thay đổi tên hoặc sử dụng dữ liệu hiện có.';
					|ru = 'Страна с наименованием %1 уже существует. Измените наименование или используйте уже существующие данные.';
					|en = 'Description %1 already assigned to the country. Change the description, or use the existing data.'; fa = 'Description %1 already assigned to the country. Change the description, or use the existing data.';
					|it = 'Il paese denominato %1 esiste già. Bisogna modificare il nome o usare i dati esistenti.';
					|pl = 'Kraj o nazwie %1 już istnieje. Zmień nazwę lub używaj istniejących danych.';
					|tr = '%1 adlı ülke artık mevcut. Adı değiştirin veya artık varolan verileri kullanın.'"),
				Selection.Description);
			Message.FieldName = "Object.Description";
			
		ElsIf ValueIsFilled(DescriptionFull)
				  And StrCompare(Selection.DescriptionFull, DescriptionFull) = 0 Then
			
			Message.MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã có quốc gia %2 với tên đầy đủ %1. Thay đổi tên đầy đủ hoặc sử dụng dữ liệu hiện có.';
					|ru = 'Уже существует страна %2 с полным наименованием %1. Измените полное наименование или используйте уже существующие данные.';
					|en = 'Full description %1 already assigned to country %2. Change the full description, or use the existing data.'; fa = 'Full description %1 already assigned to country %2. Change the full description, or use the existing data.';
					|it = 'Il paese %2 con nome completo %1 esiste già. Bisogna modificare il nome completo o usare i dati esistenti.';
					|pl = 'Już istnieje kraj %2 z pełną nazwą %1. Zmień pełną nazwę lub używaj już istniejących danych.';
					|tr = 'Artık %1 tam isminde %2 ülkesi mevcut. Tam ismi değiştirin veya artık varolan verileri kullanın.'"),
				DescriptionFull, Selection.Description);
			Message.FieldName = "Object.DescriptionFull";
			
		ElsIf ValueIsFilled(CodeAlpha2)
				  And StrCompare(Selection.CodeAlpha2, CodeAlpha2) = 0 Then
			
			Message.MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Quốc gia %2 đã tồn tại với mã Alpha-2 %1. Thay đổi mã Alpha-2 hoặc sử dụng dữ liệu hiện có.';
					|ru = 'С кодом Альфа-2 %1 уже существует страна %2. Измените код Альфа-2 или используйте уже существующие данные.';
					|en = 'Alpha-2 code %1 already assigned to country %2. Change the Alpha-2 code, or use the existing data.'; fa = 'Alpha-2 code %1 already assigned to country %2. Change the Alpha-2 code, or use the existing data.';
					|it = 'Il codice Alfa-2 %1 è già in uso per il paese %2. Bisogna modificare il codice Alfa-2 o usare i dati esistenti.';
					|pl = 'Z kodem Alfa-2 %1 już istnieje kraj %2. Zmień kod Alfa-2 lub używaj już istniejących danych.';
					|tr = 'Alfa-2 %1 koduyla artık %2 ülkesi mevcut. Alfa-2 kodunu değiştirin veya artık varolan verileri kullanın.'"),
				CodeAlpha2, Selection.Description);
			Message.FieldName = "Object.CodeAlpha2";
			
		ElsIf ValueIsFilled(CodeAlpha3)
				  And StrCompare(Selection.CodeAlpha3, CodeAlpha3) = 0 Then
			
			Message.MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Quốc gia %2 đã tồn tại với mã Alpha-3 %1. Thay đổi mã Alpha-3 hoặc sử dụng dữ liệu hiện có.';
					|ru = 'С кодом Альфа-3 %1 уже существует страна %2. Измените код Альфа-3 или используйте уже существующие данные.';
					|en = 'Alpha-3 code %1 already assigned to country %2. Change the Alpha-3 code, or use the existing data.'; fa = 'Alpha-3 code %1 already assigned to country %2. Change the Alpha-3 code, or use the existing data.';
					|it = 'Il codice Alfa-3 %1 è già in uso per il paese %2. Bisogna modificare il codice Alfa-3 o usare i dati esistenti.';
					|pl = 'Z kodem Alfa-3 %1 już istnieje kraj %2. Zmień kod Alfa-3 lub używaj już istniejących danych.';
					|tr = 'Alfa-3 %1 kodlu %2 ülkesi zaten var. Kodu değiştirin veya varolan verileri kullanın.'"),
				CodeAlpha3, Selection.Description);
			Message.FieldName = "Object.CodeAlpha3";
			
		EndIf;
		
		If ValueIsFilled(Message.FieldName) Then
			Result.Add(Message);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Returns:
//  Structure:
//   FieldName - String
//   MessageText - String
//
Function NewErrorMessage()
	
	Result = New Structure;
	Result.Insert("FieldName",        "");
	Result.Insert("MessageText", "");
	
	Return Result;
	
EndFunction

Procedure CheckTheChangeOfAPredefinedElement()
	
	PreviousValues = Common.ObjectAttributesValues(Ref, "Code, Description");
	If StrCompare(PreviousValues.Description, Description) <> 0 Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không được phép thay đổi tên cho quốc gia %1';
				|ru = 'Не допускается изменение наименования для страны %1';
				|en = 'Description cannot be changed for country %1'; fa = 'Description cannot be changed for country %1';
				|it = 'Non è consentito modificare il nome del paese %1';
				|pl = 'Nie dopuszczalna jest zmiana nazwy dla kraju %1';
				|tr = '%1 ülkesi için isim değişliğine izin verilmiyor'"), PreviousValues.Description);
		Raise MessageText;
		
	EndIf;
	
	If StrCompare(PreviousValues.Code, Code) <> 0 Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không được phép thay đổi mã quốc gia đối với %1';
				|ru = 'Не допускается изменение кода для страны %1';
				|en = 'Code cannot be changed for country %1'; fa = 'Code cannot be changed for country %1';
				|it = 'Non è consentito modificare il codice del paese %1';
				|pl = 'Nie dopuszczalna jest zmiana kodu dla kraju %1';
				|tr = '%1 ülkesi kod değişikliğine izin verilmiyor'"), PreviousValues.Description);
		Raise MessageText;
		
	EndIf;

EndProcedure

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf