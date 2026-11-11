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

Procedure BeforeWrite(Cancel, Replacing)
	
	// No need to check for DataExchange.Load.
	// Safe mode restricts writing internal data.
	SafeModeManagerInternal.OnSaveInternalData(ThisObject);

	If DataExchange.Load Then
		Return;
	EndIf;

	If Not Common.IsRecordSetDeletion(Replacing) Then
		For Each Record In ThisObject Do

			ProgramModule = SafeModeManagerInternal.ReferenceFormPermissionRegister(
				Record.ProgramModuleType, Record.ModuleID);
			Record.SoftwareModulePresentation = String(ProgramModule);

			Owner = SafeModeManagerInternal.ReferenceFormPermissionRegister(
				Record.OwnerType, Record.OwnerID);
			Record.OwnerPresentation = String(Owner);

		EndDo;
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