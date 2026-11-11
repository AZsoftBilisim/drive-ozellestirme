///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

// Intended for the "OnWrite" event handler.
Var PreviousValue2;

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	PreviousValue2 = AccessManagementInternal.ConstantLimitAccessAtRecordLevel();
	
	If Value = PreviousValue2 Then
		Return;
	EndIf;
	
	AccessManagementInternal.CheckIsAccessRestrictionDisabled();
	
	If Common.IsStandaloneWorkplace() Then
		ErrorText =
			NStr("vi = 'Cần thực hiện thay đổi hạn chế truy cập ở mức độ bản ghi trong ứng dụng trong dịch vụ.';
				|ru = 'Изменение ограничения доступа на уровне записей следует выполнить в приложении в сервисе.';
				|en = 'RLS access restrictions can only be changed in the SaaS version.'; fa = 'RLS access restrictions can only be changed in the SaaS version.';
				|it = 'Изменение ограничения доступа на уровне записей следует выполнить в приложении в сервисе.';
				|pl = 'RLS access restrictions can only be changed in the SaaS version.';
				|tr = 'Kayıt düzeyindeki erişim kısıtlamalarının değiştirilmesi servisteki uygulamada yapılmalıdır.'");
		Raise ErrorText;
		
	ElsIf Common.IsSubordinateDIBNode() Then
		ErrorText =
			NStr("vi = 'Cần thực hiện thay đổi hạn chế truy cập ở mức độ bản ghi trong nút chính của cơ sở thông tin.';
				|ru = 'Изменение ограничения доступа на уровне записей следует выполнить в главном узле информационной базы.';
				|en = 'RLS access restrictions can only be changed in the master node.'; fa = 'RLS access restrictions can only be changed in the master node.';
				|it = 'Изменение ограничения доступа на уровне записей следует выполнить в главном узле информационной базы.';
				|pl = 'RLS access restrictions can only be changed in the master node.';
				|tr = 'Kayıt düzeyindeki erişim kısıtlamalarının değiştirilmesi infobase''in ana düğümünde yapılmalıdır.'");
		Raise ErrorText;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Value <> PreviousValue2 Then
		RefreshReusableValues();
		Try
			AccessManagementInternal.OnChangeAccessRestrictionAtRecordLevel(
				Not PreviousValue2 And Value);
		Except
			RefreshReusableValues();
			Raise;
		EndTry;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// For internal use only.
Procedure RegisterChangeUponDataImport(DataElement) Export
	
	CurrentValue = AccessManagementInternal.ConstantLimitAccessAtRecordLevel();
	
	If DataElement.Value = CurrentValue
	 Or AccessManagementInternal.IsRecordLevelRestrictionDisabled()
	 Or Common.DataSeparationEnabled() Then
		// In the SWS, right settings are locked for editing and are not imported into the data area.
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	UsersInternal.RegisterRefs("LimitAccessAtRecordLevel", True);
	
EndProcedure

// For internal use only.
Procedure ProcessChangeRegisteredUponDataImport() Export
	
	If Common.DataSeparationEnabled() Then
		// In the SWS, right settings are locked for editing and are not imported into the data area.
		UsersInternal.RegisterRefs("LimitAccessAtRecordLevel", Null);
		Return;
	EndIf;
	
	Changes = UsersInternal.RegisteredRefs("LimitAccessAtRecordLevel");
	If Changes.Count() = 0 Then
		Return;
	EndIf;
	
	CurrentValue = AccessManagementInternal.ConstantLimitAccessAtRecordLevel();
	If Not AccessManagementInternal.IsRecordLevelRestrictionDisabled() Then
		AccessManagementInternal.OnChangeAccessRestrictionAtRecordLevel(CurrentValue);
	EndIf;
	
	UsersInternal.RegisterRefs("LimitAccessAtRecordLevel", Null);
	
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