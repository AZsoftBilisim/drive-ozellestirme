///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Procedure OnWrite(Cancel, Replacing)
	
	// No need to check for DataExchange.Load.
	// Safe mode restricts writing internal data.
	If SafeModeManager.SafeModeSet() Then
		
		CurrentSafeMode = SafeMode();
		
		For Each Record In ThisObject Do
			
			If Record.SafeMode <> CurrentSafeMode Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chế độ an toàn %1 khác với chế độ hiện tại %2.';
						|ru = 'Безопасный режим %1 отличается от текущего %2.';
						|en = 'Safe mode (%1) is different from the current one (%2).'; fa = 'Safe mode (%1) is different from the current one (%2).';
						|it = 'Safe mode (%1) is different from the current one (%2).';
						|pl = 'Safe mode (%1) is different from the current one (%2).';
						|tr = 'Güvenli mod %1, geçerli mod %2 modundan farklı.'"),
					Record.SafeMode, CurrentSafeMode);
			EndIf;
			
			If Common.IsRecordSetDeletion(Replacing) Then
				Continue;
			EndIf;
			
			ProgramModule = SafeModeManagerInternal.ReferenceFormPermissionRegister(
				Record.OwnerType, Record.ModuleID);
			If ProgramModule = Catalogs.MetadataObjectIDs.EmptyRef() Then
				Continue;
			EndIf;
				
			ProgramModuleSafeMode = InformationRegisters.ExternalModulesAttachmentModes.ExternalModuleAttachmentMode(
				ProgramModule);
			If Record.SafeMode <> ProgramModuleSafeMode Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đối với mô-đun chương trình %1, không thể thực hiện truy vấn được phép từ chế độ an toàn %2.';
						|ru = 'Для программного модуля %1 не может быть выполнен запрос разрешений из безопасного режима %2.';
						|en = 'Cannot perform the permission request for the %1 program module in the %2 safe mode.'; fa = 'Cannot perform the permission request for the %1 program module in the %2 safe mode.';
						|it = 'Cannot perform the permission request for the %1 program module in the %2 safe mode.';
						|pl = 'Cannot perform the permission request for the %1 program module in the %2 safe mode.';
						|tr = '%1 uygulama modülü için %2 güvenli moddan izin sorgusu yapılamıyor.'"),
					String(ProgramModule), Record.SafeMode);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If DataExchange.Load Then
		Return;
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