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
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ValueIsFilled(Owner) Then
		AdditionalValuesOwner = Common.ObjectAttributeValue(Owner,
			"AdditionalValuesOwner");
		
		If ValueIsFilled(AdditionalValuesOwner) Then
			ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Các giá trị bổ sung cho thuộc tính ""%1"", được tạo 
				           |theo mẫu thuộc tính ""%2"", phải được tạo cho thuộc tính mẫu.';
				           |ru = 'Дополнительные значения для свойства ""%1"", созданного
				           |по образцу свойства ""%2"" нужно создавать для свойства-образца.';
				           |en = 'The ""%1"" property is based
				           |on the ""%2"" master property. Please create additional values for the master property.'; fa = 'The ""%1"" property is based
				           |on the ""%2"" master property. Please create additional values for the master property.';
				           |it = 'I valori aggiuntivi per la proprietà ""%1"", creata
				           | secondo il modello della proprietà ""%2"", sono da creare per la proprietà-modello.';
				           |pl = 'Wartości dodatkowe dla właściwości ""%1"", utworzonej
				           |na wzór właściwości ""%2"" należy tworzyć dla właściwości wzorcowej.';
				           |tr = 'Örnek özelliği için%2 ""
				           |"" özellik kalıbı kullanılarak oluşturulan ""%1"" özelliği için ek değerler oluşturulmalıdır.'"),
				Owner,
				AdditionalValuesOwner);
			
			If IsNew() Then
				Raise ErrorDescription;
			Else
				Common.MessageToUser(ErrorDescription);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

Procedure OnReadPresentationsAtServer() Export
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		ModuleNationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
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