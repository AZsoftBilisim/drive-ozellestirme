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

Var PreviousValue2, NewValue;

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	PreviousValue2 = Constants.LimitAccessAtRecordLevelUniversally.Get();
	
	If Not AccessManagementInternal.ScriptVariantRussian() Then
		Value = True;
	EndIf;
	
	NewValue = Value;
	
	If Value And Not PreviousValue2 Then // Enabled.
		InformationRegisters.AccessRestrictionParameters.UpdateRegisterData(, True);
	EndIf;
	
	If Value = PreviousValue2 Then
		Return;
	EndIf;
	
	If Common.IsStandaloneWorkplace() Then
		ErrorText =
			NStr("vi = 'Cần thực hiện thay đổi phương án làm việc Chuẩn/Tùy ý trong ứng dụng trong dịch vụ.';
				|ru = 'Изменение варианта работы Стандартный/Производительный следует выполнить в приложении в сервисе.';
				|en = 'The operation mode (standard or high-performance) can only be changed in the SaaS version.'; fa = 'The operation mode (standard or high-performance) can only be changed in the SaaS version.';
				|it = 'Изменение варианта работы Стандартный/Производительный следует выполнить в приложении в сервисе.';
				|pl = 'The operation mode (standard or high-performance) can only be changed in the SaaS version.';
				|tr = 'Standart/Üretken çalışma seçeneğinin değiştirilmesi servisteki uygulamada yapılmalıdır.'");
		Raise ErrorText;
	ElsIf Common.IsSubordinateDIBNode() Then
		ErrorText =
			NStr("vi = 'Cần thực hiện thay đổi phương án làm việc Chuẩn/Tùy ý trong nút chính của cơ sở thông tin.';
				|ru = 'Изменение варианта работы Стандартный/Производительный следует выполнить в главном узле информационной базы.';
				|en = 'The operation mode (standard or high-performance) can only be changed in the master node.'; fa = 'The operation mode (standard or high-performance) can only be changed in the master node.';
				|it = 'Изменение варианта работы Стандартный/Производительный следует выполнить в главном узле информационной базы.';
				|pl = 'The operation mode (standard or high-performance) can only be changed in the master node.';
				|tr = 'Standart/Üretken çalışma seçeneğinin değiştirilmesi, infobase''in master düğümünde yapılmalıdır.'");
		Raise ErrorText;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If NewValue <> Value Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không nên thay đổi giá trị hằng %1 trong các hàm sự kiện đăng ký sự kiện %2.';
				|ru = 'Нельзя изменять значение константы %1 в обработчиках подписок на событие %2.';
				|en = 'Cannot change the %1 constant value in the %2 event subscription handlers.'; fa = 'Cannot change the %1 constant value in the %2 event subscription handlers.';
				|it = 'Нельзя изменять значение константы %1 в обработчиках подписок на событие %2.';
				|pl = 'Cannot change the %1 constant value in the %2 event subscription handlers.';
				|tr = '%2 olayına abonelik işleyicilerindeki %1 sabitinin değerini değiştiremezsiniz.'"),
			"LimitAccessAtRecordLevelUniversally", "BeforeWrite");
		Raise ErrorText;
	EndIf;
	
	If Value And Not PreviousValue2 Then // Enabled.
		AccessManagementInternal.ClearLastAccessUpdate();
		PlanningParameters = AccessManagementInternal.AccessUpdatePlanningParameters();
		PlanningParameters.LongDesc = "EnabledRestrictAccessAtTheRecordLevelUniversally";
		AccessManagementInternal.ScheduleAccessUpdate(Undefined, PlanningParameters);
	EndIf;
	
	If Not Value And PreviousValue2 Then // Disabled.
		ValueManager = Constants.FirstAccessUpdateCompleted.CreateValueManager();
		ValueManager.Value = False;
		InfobaseUpdate.WriteData(ValueManager);
		AccessManagementInternal.EnableDataFillingForAccessRestriction();
	EndIf;
	
	If Value <> PreviousValue2 Then // Modified.
		AccessManagementInternal.UpdateSessionParameters();
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