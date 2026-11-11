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
	
	Name = Parameters.Name;
	MiddleName = Parameters.MiddleName;
	NameAndMiddleName = Parameters.Name + ?(ValueIsFilled(Parameters.MiddleName)," " + Parameters.MiddleName, "");
	NewNameAndMiddleName = NameAndMiddleName;
	Items.NewNameAndMiddleName.TextColor = WebColors.Green;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NameOnChange(Item)
	SetColorInscriptionsNameAndPatronymic();
EndProcedure

&AtClient
Procedure MiddleNameOnChange(Item)
	SetColorInscriptionsNameAndPatronymic();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If NewNameAndMiddleName = NameAndMiddleName Then
		Close(New Structure("Name, MiddleName", TrimR(Name), TrimR(MiddleName)));
	Else
		ShowMessageBox( , StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tên và tên đệm phải là %1';
				|ru = 'Имя и отчество должны быть равны %1';
				|en = 'First name and middle name must be equal to %1'; fa = 'First name and middle name must be equal to %1';
				|it = 'Nome e patronimico devono essere uguali a %1';
				|pl = 'Imiona powinny być równe %1';
				|tr = 'Ad ve baba adı eşit olmalı %1'"), NameAndMiddleName));
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetColorInscriptionsNameAndPatronymic()
	
	NewNameAndMiddleName = TrimR(Name) + ?(IsBlankString(MiddleName), "", " " + TrimR(MiddleName));
	If NewNameAndMiddleName = NameAndMiddleName Then
		Items.NewNameAndMiddleName.TextColor = WebColors.Green;
	Else
		Items.NewNameAndMiddleName.TextColor = WebColors.Red;
	EndIf; 
	
EndProcedure

#EndRegion
