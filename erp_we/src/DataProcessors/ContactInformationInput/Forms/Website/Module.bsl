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
	
	ContactInformationKind = Parameters.ContactInformationKind;
	If Not ValueIsFilled(ContactInformationKind) Then
		Raise NStr("vi = 'Lệnh không thể được thực thi cho đối tượng đã chỉ định do thực hiện thông tin liên hệ không chính xác.';
					|ru = 'Команда не может быть выполнена для указанного объекта из-за некорректного внедрения контактной информации.';
					|en = 'Cannot execute command for the object. Contact information is invalid.'; fa = 'Cannot execute command for the object. Contact information is invalid.';
					|it = 'Il comando non può essere eseguito per l''oggetto indicato a causa dell''implementazione errata delle informazioni di contatto.';
					|pl = 'Polecenie nie mogło zostać wykonane dla określonego obiektu z powodu nieprawidłowego wprowadzenia informacji kontaktowych.';
					|tr = 'İletişim bilgileri yanlış uygulandığı için belirtilen nesne için komut yürütülemiyor.'");
	EndIf;
	ContactInformationType = Enums.ContactInformationTypes.WebPage;
	
	Title = ?(IsBlankString(Parameters.Title), String(ContactInformationKind), Parameters.Title);
	
	FieldValues = DefineAddressValue(Parameters);
	
	If IsBlankString(FieldValues) Then
		Data = ContactsManager.NewContactInformationDetails(ContactInformationType);
	ElsIf ContactsManagerClientServer.IsJSONContactInformation(FieldValues) Then
		Data = ContactsManagerInternal.JSONToContactInformationByFields(FieldValues, Enums.ContactInformationTypes.WebPage);
	Else
		
		If ContactsManagerClientServer.IsXMLContactInformation(FieldValues) Then
				
				ReadResults = New Structure;
				ContactInformation = Undefined;
				ContactsManagerLocalization.OnConvertContactInformationFromXML(FieldValues, ContactInformation, ContactInformationType, ReadResults);
				If ContactInformation = Undefined Then
					Return;
				EndIf;
				
				If ReadResults.Property("ErrorText") Then
					// Recognition errors. A warning must be displayed when opening the form.
					ContactInformation.Presentation = Parameters.Presentation;
				EndIf;
				
				Data = ContactsManagerInternal.ContactInformationToJSONStructure(ContactInformation, ContactInformationType);
				
		Else
			Data = ContactsManager.NewContactInformationDetails(ContactInformationType);
			Data.value = FieldValues;
			Data.Comment = Parameters.Comment;
		EndIf;
		
	EndIf;
	
	Address        = Data.Value;
	Description = TrimAll(Parameters.Presentation);
	Comment  = Data.Comment;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	Close(SelectionResult(Address, Description, Comment));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function DefineAddressValue(Var_Parameters)
	
	If ValueIsFilled(Var_Parameters.Value) Then
		FieldValues = Var_Parameters.Value;
	Else
		FieldValues = Var_Parameters.FieldValues;
	EndIf;
	
	Return FieldValues;
	
EndFunction

&AtServerNoContext
Function SelectionResult(Address, Description, Comment)
	
	ContactInformationType = Enums.ContactInformationTypes.WebPage;
	WebsiteDescription = ?(ValueIsFilled(Description), Description, Address);
	
	ContactInformation         = ContactsManagerClientServer.NewContactInformationDetails(ContactInformationType );
	ContactInformation.value   = TrimAll(Address);
	ContactInformation.name    = TrimAll(WebsiteDescription);
	ContactInformation.comment = TrimAll(Comment);
	
	ChoiceData = ContactsManagerInternal.ToJSONStringStructure(ContactInformation);
	
	Result = New Structure();
	Result.Insert("Type",                  ContactInformationType);
	Result.Insert("Address",                Address);
	Result.Insert("ContactInformation", ContactsManager.ContactInformationToXML(ChoiceData, Description, ContactInformationType));
	Result.Insert("Value",             ChoiceData);
	Result.Insert("Presentation",        WebsiteDescription);
	Result.Insert("Comment",          ContactInformation.Comment);
	
	Return Result
	
EndFunction

#EndRegion